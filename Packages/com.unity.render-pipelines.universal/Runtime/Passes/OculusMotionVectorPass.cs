using System;
using System.Collections.Generic;
using UnityEngine.Profiling;

namespace UnityEngine.Rendering.Universal.Internal
{
    /// <summary>
    /// Draw  motion vectors into the given color and depth target. Both come from the Oculus runtime.
    ///
    /// This will render objects that have a material and/or shader with the pass name "MotionVectors".
    /// </summary>
    public class OculusMotionVectorPass : ScriptableRenderPass
    {
        FilteringSettings m_FilteringSettings;
        ProfilingSampler m_ProfilingSampler;

        private static readonly ShaderTagId s_MotionVectorTag = new ShaderTagId("MotionVectors");
        private static readonly string kCameraDepthTextureName = "_CameraDepthTexture";
        private static readonly string kCameraDepthTextureScaleBiasName = "_CameraDepthTextureScaleBias";
        private static readonly string kSubsampleDepthKeyword = "_SUBSAMPLE_DEPTH";
        private Material m_CameraMaterial;

        RTHandle motionVectorColorHandle;
        RTHandle motionVectorDepthHandle;
        RTHandle depthTextureHandle;
        bool subsampleDepth;

        public OculusMotionVectorPass(string profilerTag, bool opaque, RenderPassEvent evt, RenderQueueRange renderQueueRange, LayerMask layerMask, StencilState stencilState, int stencilReference, Material cameraMaterial)
        {
            base.profilingSampler = new ProfilingSampler(nameof(OculusMotionVectorPass));
            m_ProfilingSampler = new ProfilingSampler(profilerTag);
            renderPassEvent = evt;
            m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);
            m_CameraMaterial = cameraMaterial;
        }

        internal OculusMotionVectorPass(URPProfileId profileId, bool opaque, RenderPassEvent evt, RenderQueueRange renderQueueRange, LayerMask layerMask, StencilState stencilState, int stencilReference, Material cameraMaterial)
            : this(profileId.GetType().Name, opaque, evt, renderQueueRange, layerMask, stencilState, stencilReference, cameraMaterial)
        {
            m_ProfilingSampler = ProfilingSampler.Get(profileId);
        }

        public void Setup(
            RTHandle motionVecColorHandle,
            RTHandle motionVecDepthHandle,
            RTHandle depthTextureHandle,
            bool subsampleDepth)
        {
            this.motionVectorColorHandle = motionVecColorHandle;
            this.motionVectorDepthHandle = motionVecDepthHandle;
            this.depthTextureHandle = depthTextureHandle;
            this.subsampleDepth = subsampleDepth;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureTarget(motionVectorColorHandle, motionVectorDepthHandle);
            ConfigureClear(ClearFlag.All, Color.black);
        }

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!renderingData.cameraData.xr.enabled)
            {
                return;
            }

            // NOTE: Do NOT mix ProfilingScope with named CommandBuffers i.e. CommandBufferPool.Get("name").
            // Currently there's an issue which results in mismatched markers.
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                // If we are copying depth from the main pass, we can prime the motion vector buffer
                // using the main path depth information.
                if (renderingData.cameraData.xr.copyDepth)
                {
                    Vector2 viewportScale = Vector2.one;
                    if (new RenderTargetIdentifier(depthTextureHandle.nameID, 0, CubemapFace.Unknown, 0) == new RenderTargetIdentifier(renderingData.cameraData.xr.renderTarget, 0, CubemapFace.Unknown, 0))
                    {
                        // xrViewport is in pixel coordinates
                        var xrViewport = renderingData.cameraData.xr.GetViewport();
                        viewportScale.x = xrViewport.width / renderingData.cameraData.xr.renderTargetDesc.width;
                        viewportScale.y = xrViewport.height / renderingData.cameraData.xr.renderTargetDesc.height;
                    }
                    else if (depthTextureHandle.useScaling)
                    {
                        viewportScale.x = depthTextureHandle.rtHandleProperties.rtHandleScale.x;
                        viewportScale.y = depthTextureHandle.rtHandleProperties.rtHandleScale.y;
                    }
                    bool yflip = renderingData.cameraData.IsHandleYFlipped(motionVectorDepthHandle) == renderingData.cameraData.IsHandleYFlipped(depthTextureHandle);
                    Vector4 scaleBias = yflip ? new Vector4(viewportScale.x, -viewportScale.y, 0, viewportScale.y) : new Vector4(viewportScale.x, viewportScale.y, 0, 0);

                    cmd.SetGlobalTexture(kCameraDepthTextureName, depthTextureHandle, RenderTextureSubElement.Depth);
                    cmd.SetGlobalVector(kCameraDepthTextureScaleBiasName, scaleBias);
                    if (subsampleDepth)
                    {
                        cmd.EnableShaderKeyword(kSubsampleDepthKeyword);
                    }
                    else
                    {
                        cmd.DisableShaderKeyword(kSubsampleDepthKeyword);
                    }

                    cmd.DrawProcedural(Matrix4x4.identity, m_CameraMaterial, 0, MeshTopology.Triangles, 3, 1);
                    context.ExecuteCommandBuffer(cmd);
                }

                var filterSettings = m_FilteringSettings;
                var drawSettings = CreateDrawingSettings(s_MotionVectorTag, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
                drawSettings.perObjectData = PerObjectData.MotionVectors;
                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref filterSettings);

                // If we are not copying depth from the main pass, draw motion vectors for static objects as well
                if (!renderingData.cameraData.xr.copyDepth)
                {
                    drawSettings.perObjectData = PerObjectData.None;
                    filterSettings.excludeMotionVectorObjects = true;
                    context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref filterSettings);
                }
            }
            CommandBufferPool.Release(cmd);
        }
    }
}
