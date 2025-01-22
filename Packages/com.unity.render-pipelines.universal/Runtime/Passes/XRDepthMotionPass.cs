#if ENABLE_VR && ENABLE_XR_MODULE
using System;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering.RenderGraphModule;

namespace UnityEngine.Rendering.Universal
{
    /// <summary>
    /// Render all objects that have a 'XRMotionVectors' pass into the given depth buffer and motionvec buffer.
    /// </summary>
    public class XRDepthMotionPass : ScriptableRenderPass
    {
        private static readonly ShaderTagId k_MotionOnlyShaderTagId = new ShaderTagId("MotionVectors");
        private static readonly int k_XRDepthTextureNameID = Shader.PropertyToID("_XRDepthTexture");
        private static LocalKeyword m_SubsampleDepthKeyword;
        private static GlobalKeyword m_ApplicationSpaceWarpMotionKeyword;
        private PassData m_PassData;
        private RTHandle m_XRMotionVectorColor;
        private TextureHandle xrMotionVectorColor;
        private RTHandle m_XRMotionVectorDepth;
        private TextureHandle xrMotionVectorDepth;

        /// <summary>
        /// Creates a new <c>XRDepthMotionPass</c> instance.
        /// </summary>
        /// <param name="evt">The <c>RenderPassEvent</c> to use.</param>
        /// <param name="xrMotionVector">The Shader used for rendering XR camera motion vector.</param>
        /// <seealso cref="RenderPassEvent"/>
        public XRDepthMotionPass(RenderPassEvent evt, Shader xrMotionVector)
        {
            base.profilingSampler = new ProfilingSampler(nameof(XRDepthMotionPass));
            m_PassData = new PassData();
            renderPassEvent = evt;
            ResetMotionData();
            m_XRMotionVectorMaterial = CoreUtils.CreateEngineMaterial(xrMotionVector);
            xrMotionVectorColor = TextureHandle.nullHandle;
            m_XRMotionVectorColor = null;
            xrMotionVectorDepth = TextureHandle.nullHandle;
            m_XRMotionVectorDepth = null;
            m_SubsampleDepthKeyword = new LocalKeyword(xrMotionVector, "_SUBSAMPLE_DEPTH");
            m_ApplicationSpaceWarpMotionKeyword = GlobalKeyword.Create("APPLICATION_SPACE_WARP_MOTION");
        }

        private class PassData
        {
            internal RendererListHandle objMotionRendererListHdl;
            internal RendererList objMotionRendererList;
            internal Matrix4x4[] previousViewProjectionStereo = new Matrix4x4[k_XRViewCount];
            internal Matrix4x4[] viewProjectionStereo = new Matrix4x4[k_XRViewCount];
            internal Material xrMotionVector;
            internal bool hasValidXRDepth;
            internal TextureHandle xrDepthSrc;
            internal bool requiresSubsampleDepth;
            internal LocalKeyword subsampleDepthKeyword;
        }

        ///  View projection data
        private const int k_XRViewCount = 2;
        private Matrix4x4[] m_ViewProjection = new Matrix4x4[k_XRViewCount];
        private Matrix4x4[] m_PreviousViewProjection = new Matrix4x4[k_XRViewCount];
        private int m_LastFrameIndex;

        // Motion Vector
        private Material m_XRMotionVectorMaterial;

        private RTHandle m_DepthSource;

        private static DrawingSettings GetObjectMotionDrawingSettings(Camera camera)
        {
            var sortingSettings = new SortingSettings(camera) { criteria = SortingCriteria.CommonOpaque };
            // Notes: Usually, PerObjectData.MotionVectors will filter the renderer nodes to only draw moving objects.
            // In our case, we use forceAllMotionVectorObjects in the filteringSettings to draw idle objects as well to populate depth.
            var drawingSettings = new DrawingSettings(k_MotionOnlyShaderTagId, sortingSettings)
            {
                perObjectData = PerObjectData.MotionVectors,
                enableDynamicBatching = false,
                enableInstancing = true,
            };
            drawingSettings.SetShaderPassName(0, k_MotionOnlyShaderTagId);

            return drawingSettings;
        }

        private void InitObjectMotionRendererLists(ref PassData passData, ref CullingResults cullResults, ScriptableRenderContext context, RenderGraph renderGraph, bool useRenderGraph, Camera camera, bool forceAllMotionVectorObjects)
        {
            var objectMotionDrawingSettings = GetObjectMotionDrawingSettings(camera);

            // Draw motion vectors for all objects with matching shaders, including transparent
            var filteringSettings = new FilteringSettings(RenderQueueRange.all, camera.cullingMask);
            // Also render game objects that are not moved since last frame to save depth prepass requirement for camera motion.
            filteringSettings.forceAllMotionVectorObjects = forceAllMotionVectorObjects;
            var renderStateBlock = new RenderStateBlock(RenderStateMask.Nothing);

            if (useRenderGraph)
            {
                RenderingUtils.CreateRendererListWithRenderStateBlock(renderGraph, ref cullResults,
                    objectMotionDrawingSettings, filteringSettings, renderStateBlock,
                    ref passData.objMotionRendererListHdl);
            }
            else
            {
                RenderingUtils.CreateRendererListWithRenderStateBlock(context, ref cullResults,
                    objectMotionDrawingSettings, filteringSettings, renderStateBlock,
                    ref passData.objMotionRendererList);
            }
        }

        public void Setup(in UniversalCameraData cameraData, RTHandle sourceDepth)
        {
            // These flags are still required in SRP or the engine won't compute previous model matrices...
            // If the flag hasn't been set yet on this camera, motion vectors will skip a frame.
            cameraData.camera.depthTextureMode |= DepthTextureMode.MotionVectors | DepthTextureMode.Depth;

            InitXRMotionColorAndDepthTextures(cameraData);
            m_DepthSource = sourceDepth;
        }

        /// <inheritdoc/>
        [Obsolete(DeprecationMessage.CompatibilityScriptingAPIObsolete, false)]
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            // Disable obsolete warning for internal usage
#pragma warning disable CS0618
            ConfigureClear(ClearFlag.All, Color.clear);
            ConfigureTarget(m_XRMotionVectorColor, m_XRMotionVectorDepth);
#pragma warning restore CS0618
        }

        /// <inheritdoc/>
        [Obsolete(DeprecationMessage.CompatibilityScriptingAPIObsolete, false)]
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            UniversalCameraData cameraData = renderingData.frameData.Get<UniversalCameraData>();

            // XR should be enabled and single pass should be enabled.
            if (!cameraData.xr.enabled || !cameraData.xr.singlePassEnabled)
            {
                Debug.LogWarning("XRDepthMotionPass::Execute is skipped because either XR is not enabled or singlepass rendering is not enabled.");
                return;
            }

            // XR motion vector pass should be enabled.
            if (!cameraData.xr.hasMotionVectorPass)
            {
                Debug.LogWarning("XRDepthMotionPass::Execute is skipped because XR motion vector is not enabled for the current XRPass.");
                return;
            }

            // Logic to detect if we already has valid XR depth data in the eye texture depth attachment
            bool hasValidXRDepth = cameraData.xr.copyDepth;

            // In case we don't have valid depth, setup the renderer list to draw both static objects and moving objects to populate color+depth at the same time.
            bool forceAllMotionVectorObjects = !hasValidXRDepth;

            // Setup RendererList
            InitObjectMotionRendererLists(ref m_PassData, ref renderingData.cullResults, context, default(RenderGraph), false, cameraData.camera, forceAllMotionVectorObjects);
            // Setup rest of the passData
            InitPassData(ref m_PassData, cameraData);

            // Setup the relevant passData fields
            if (hasValidXRDepth)
            {
                // backBufferDepth(eyeTexture depth) has valid data to read from
                m_PassData.hasValidXRDepth = true;

                // Subsample Depth if the motion vector render target is smaller than the color render target
                bool subsampleDepth = cameraData.xr.motionVectorRenderTargetDesc.width < cameraData.xr.renderTargetDesc.width;
                m_PassData.requiresSubsampleDepth = subsampleDepth;
            }

            using (new ProfilingScope(renderingData.commandBuffer, profilingSampler))
            {
                if (hasValidXRDepth)
                    renderingData.commandBuffer.SetGlobalTexture(k_XRDepthTextureNameID, m_DepthSource, RenderTextureSubElement.Depth);

                ExecutePass(CommandBufferHelpers.GetRasterCommandBuffer(renderingData.commandBuffer), m_PassData, m_PassData.objMotionRendererList);
            }
        }

        /// <summary>
        /// Initialize the RenderGraph pass data.
        /// </summary>
        /// <param name="passData"></param>
        private void InitPassData(ref PassData passData, UniversalCameraData cameraData)
        {
            // XRTODO: Use XRSystem prevViewMatrix that is compatible with late latching. Currently blocked due to late latching engine side issue.
            //var gpuP0 = GL.GetGPUProjectionMatrix(cameraData.xr.GetProjMatrix(0), false);
            //var gpuP1 = GL.GetGPUProjectionMatrix(cameraData.xr.GetProjMatrix(1), false);
            //passData.viewProjectionStereo[0] = gpuP0 * cameraData.xr.GetViewMatrix(0);
            //passData.viewProjectionStereo[1] = gpuP1 * cameraData.xr.GetViewMatrix(1);
            //passData.previousViewProjectionStereo[0] = gpuP0 * cameraData.xr.GetPrevViewMatrix(0);
            //passData.previousViewProjectionStereo[1] = gpuP0 * cameraData.xr.GetPrevViewMatrix(1);

            // Setup matrices and shader
            passData.previousViewProjectionStereo = m_PreviousViewProjection;
            passData.viewProjectionStereo = m_ViewProjection;

            // Setup camera motion material
            passData.xrMotionVector = m_XRMotionVectorMaterial;

            // Setup the default XR valid depth flag
            passData.hasValidXRDepth = false;
        }

        /// <summary>
        /// Import the XR motion color and depth targets into the RenderGraph.
        /// </summary>
        /// <param name="cameraData"> UniversalCameraData that holds XR pass data. </param>
        private void InitXRMotionColorAndDepthTextures(UniversalCameraData cameraData)
        {
            var rtMotionId = cameraData.xr.motionVectorRenderTarget;
            if (m_XRMotionVectorColor == null)
            {
                m_XRMotionVectorColor = RTHandles.Alloc(rtMotionId);
            }
            else if (m_XRMotionVectorColor.nameID != rtMotionId)
            {
                RTHandleStaticHelpers.SetRTHandleUserManagedWrapper(ref m_XRMotionVectorColor, rtMotionId);
            }

            // ID is the same since a RenderTexture encapsulates all the attachments, including both color+depth.
            var depthId = cameraData.xr.motionVectorRenderTarget;
            if (m_XRMotionVectorDepth == null)
            {
                m_XRMotionVectorDepth = RTHandles.Alloc(depthId);
            }
            else if (m_XRMotionVectorDepth.nameID != depthId)
            {
                RTHandleStaticHelpers.SetRTHandleUserManagedWrapper(ref m_XRMotionVectorDepth, depthId);
            }
        }

        /// <summary>
        /// Import the XR motion color and depth targets into the RenderGraph.
        /// </summary>
        /// <param name="cameraData"> UniversalCameraData that holds XR pass data. </param>
        private void ImportXRMotionColorAndDepth(RenderGraph renderGraph, UniversalCameraData cameraData)
        {
            InitXRMotionColorAndDepthTextures(cameraData);

            // Import motion color and depth into the render graph.
            RenderTargetInfo importInfo = new RenderTargetInfo();
            importInfo.width = cameraData.xr.motionVectorRenderTargetDesc.width;
            importInfo.height = cameraData.xr.motionVectorRenderTargetDesc.height;
            importInfo.volumeDepth = cameraData.xr.motionVectorRenderTargetDesc.volumeDepth;
            importInfo.msaaSamples = cameraData.xr.motionVectorRenderTargetDesc.msaaSamples;
            importInfo.format = cameraData.xr.motionVectorRenderTargetDesc.graphicsFormat;

            RenderTargetInfo importInfoDepth = new RenderTargetInfo();
            importInfoDepth = importInfo;
            importInfoDepth.format = cameraData.xr.motionVectorRenderTargetDesc.depthStencilFormat;

            ImportResourceParams importMotionColorParams = new ImportResourceParams();
            importMotionColorParams.clearOnFirstUse = true;
            importMotionColorParams.clearColor = Color.black;
            importMotionColorParams.discardOnLastUse = false;

            ImportResourceParams importMotionDepthParams = new ImportResourceParams();
            importMotionDepthParams.clearOnFirstUse = true;
            importMotionDepthParams.clearColor = Color.black;
            importMotionDepthParams.discardOnLastUse = false;

            xrMotionVectorColor = renderGraph.ImportTexture(m_XRMotionVectorColor, importInfo, importMotionColorParams);
            xrMotionVectorDepth = renderGraph.ImportTexture(m_XRMotionVectorDepth, importInfoDepth, importMotionDepthParams);
        }

#region Recording
        internal void Render(RenderGraph renderGraph, ContextContainer frameData)
        {
            UniversalRenderingData renderingData = frameData.Get<UniversalRenderingData>();
            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            // XR should be enabled and single pass should be enabled.
            if (!cameraData.xr.enabled || !cameraData.xr.singlePassEnabled)
            {
                Debug.LogWarning("XRDepthMotionPass::Render is skipped because either XR is not enabled or singlepass rendering is not enabled.");
                return;
            }

            // XR motion vector pass should be enabled.
            if (!cameraData.xr.hasMotionVectorPass)
            {
                Debug.LogWarning("XRDepthMotionPass::Render is skipped because XR motion vector is not enabled for the current XRPass.");
                return;
            }

            // First, import XR motion color and depth targets into the RenderGraph
            ImportXRMotionColorAndDepth(renderGraph, cameraData);

            // These flags are still required in SRP or the engine won't compute previous model matrices...
            // If the flag hasn't been set yet on this camera, motion vectors will skip a frame.
            cameraData.camera.depthTextureMode |= DepthTextureMode.MotionVectors | DepthTextureMode.Depth;

            // Start recording the pass
            using (var builder = renderGraph.AddRasterRenderPass<PassData>("XR Motion Pass", out var passData, base.profilingSampler))
            {
                builder.EnableFoveatedRasterization(cameraData.xr.supportsFoveatedRendering);
                // Setup Color and Depth attachments
                builder.SetRenderAttachment(xrMotionVectorColor, 0, AccessFlags.Write);
                builder.SetRenderAttachmentDepth(xrMotionVectorDepth, AccessFlags.Write);

                // Logic to detect if we already has valid XR depth data in the eye texture depth attachment
                bool hasValidXRDepth = cameraData.xr.copyDepth;

                // In case we don't have valid depth, setup the renderer list to draw both static objects and moving objects to populate color+depth at the same time.
                bool forceAllMotionVectorObjects = !hasValidXRDepth;

                // Setup RendererList
                InitObjectMotionRendererLists(ref passData, ref renderingData.cullResults, default(ScriptableRenderContext), renderGraph, true, cameraData.camera, forceAllMotionVectorObjects);
                builder.UseRendererList(passData.objMotionRendererListHdl);

                // Allow setting up global matrix array
                builder.AllowGlobalStateModification(true);
                // Setup rest of the passData
                InitPassData(ref passData, cameraData);

                // Setup the relevant passData fields
                if (hasValidXRDepth)
                {
                    // backBufferDepth(eyeTexture depth) has valid data to read from
                    builder.UseTexture(resourceData.backBufferDepth, AccessFlags.Read);
                    passData.xrDepthSrc = resourceData.backBufferDepth;
                    passData.hasValidXRDepth = true;

                    // Subsample Depth if the motion vector render target is smaller than the color render target
                    bool subsampleDepth = cameraData.xr.motionVectorRenderTargetDesc.width < cameraData.xr.renderTargetDesc.width;
                    passData.requiresSubsampleDepth = subsampleDepth;
                }

                builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
                {
                    if (data.hasValidXRDepth)
                        context.cmd.SetGlobalTexture(k_XRDepthTextureNameID, data.xrDepthSrc,
                            RenderTextureSubElement.Depth);

                    ExecutePass(context.cmd, data, data.objMotionRendererListHdl);
                });
            }
        }
#endregion

    private static void ExecutePass(RasterCommandBuffer cmd, PassData data, RendererList objMotionRendererList)
    {
        // Setup camera stereo buffer
        cmd.SetGlobalMatrixArray(ShaderPropertyId.previousViewProjectionNoJitterStereo, data.previousViewProjectionStereo);
        cmd.SetGlobalMatrixArray(ShaderPropertyId.viewProjectionNoJitterStereo, data.viewProjectionStereo);
        cmd.SetGlobalMatrixArray(ShaderPropertyId.previousViewProjectionStereoLegacy, data.previousViewProjectionStereo);

        // If we have valid depth data, copy the data to the motionvector depth to avoid rasterizing the static objects
        if (data.hasValidXRDepth)
        {
            if (data.requiresSubsampleDepth)
            {
                data.xrMotionVector.EnableKeyword(data.subsampleDepthKeyword);
            }
            else
            {
                data.xrMotionVector.DisableKeyword(data.subsampleDepthKeyword);
            }

            cmd.DrawProcedural(Matrix4x4.identity, data.xrMotionVector, shaderPass: 1, MeshTopology.Triangles, 3, 1);
        }

        // Object Motion for both static and dynamic objects, fill stencil for mv filled pixels.
        cmd.SetKeyword(m_ApplicationSpaceWarpMotionKeyword, true);
        cmd.DrawRendererList(objMotionRendererList);
        cmd.SetKeyword(m_ApplicationSpaceWarpMotionKeyword, false);

        if (!data.hasValidXRDepth)
        {
            // Fill mv texture with camera motion for pixels that don't have mv stencil bit.
            cmd.DrawProcedural(Matrix4x4.identity, data.xrMotionVector, shaderPass: 0,
                MeshTopology.Triangles, 3, 1);
        }
    }

        private void ResetMotionData()
        {
            for (int i = 0; i < k_XRViewCount; i++)
            {
                m_ViewProjection[i] = Matrix4x4.identity;
                m_PreviousViewProjection[i] = Matrix4x4.identity;
            }
            m_LastFrameIndex = -1;
        }

        /// <summary>
        /// Update XRDepthMotionPass to use camera's view and projection matrix for motion vector calculation.
        /// </summary>
        /// <param name="cameraData"> The cameraData used for rendering to XR moition textures. </param>
        public void Update(ref UniversalCameraData cameraData)
        {
            if (!cameraData.xr.enabled || !cameraData.xr.singlePassEnabled)
            {
                Debug.LogWarning("XRDepthMotionPass::Update is skipped because either XR is not enabled or singlepass rendering is not enabled.");
                return;
            }

            if (m_LastFrameIndex != Time.frameCount)
            {
                {
                    var gpuVP0 = GL.GetGPUProjectionMatrix(cameraData.GetProjectionMatrixNoJitter(0), renderIntoTexture: false) * cameraData.GetViewMatrix(0);
                    var gpuVP1 = GL.GetGPUProjectionMatrix(cameraData.GetProjectionMatrixNoJitter(1), renderIntoTexture: false) * cameraData.GetViewMatrix(1);
                    m_PreviousViewProjection[0] = m_ViewProjection[0];
                    m_PreviousViewProjection[1] = m_ViewProjection[1];
                    m_ViewProjection[0] = gpuVP0;
                    m_ViewProjection[1] = gpuVP1;
                }
                m_LastFrameIndex = Time.frameCount;
            }
        }

        /// <summary>
        /// Cleans up resources used by the pass.
        /// </summary>
        public void Dispose()
        {
            m_XRMotionVectorColor?.Release();
            m_XRMotionVectorDepth?.Release();
            CoreUtils.Destroy(m_XRMotionVectorMaterial);
        }
    }
}
#endif
