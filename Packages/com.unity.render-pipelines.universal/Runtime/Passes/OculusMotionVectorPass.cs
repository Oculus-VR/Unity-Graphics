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

        RenderTargetIdentifier motionVectorColorIdentifier;
        RenderTargetIdentifier motionVectorDepthIdentifier;

        private static readonly int s_MotionVectorsEnabledID = Shader.PropertyToID("_MotionVectorsEnabled");

        public OculusMotionVectorPass(string profilerTag, bool opaque, RenderPassEvent evt, RenderQueueRange renderQueueRange, LayerMask layerMask, StencilState stencilState, int stencilReference)
        {
            base.profilingSampler = new ProfilingSampler(nameof(OculusMotionVectorPass));
            m_ProfilingSampler = new ProfilingSampler(profilerTag);
            renderPassEvent = evt;
            m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);
        }

        internal OculusMotionVectorPass(URPProfileId profileId, bool opaque, RenderPassEvent evt, RenderQueueRange renderQueueRange, LayerMask layerMask, StencilState stencilState, int stencilReference)
            : this(profileId.GetType().Name, opaque, evt, renderQueueRange, layerMask, stencilState, stencilReference)
        {
            m_ProfilingSampler = ProfilingSampler.Get(profileId);
        }

        public void Setup(
            RenderTargetIdentifier motionVecColorIdentifier,
            RenderTargetIdentifier motionVecDepthIdentifier)
        {
            this.motionVectorColorIdentifier = motionVecColorIdentifier;
            this.motionVectorDepthIdentifier = motionVecDepthIdentifier;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureTarget(motionVectorColorIdentifier, motionVectorDepthIdentifier);
            ConfigureClear(ClearFlag.All, Color.black);
        }

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            // NOTE: Do NOT mix ProfilingScope with named CommandBuffers i.e. CommandBufferPool.Get("name").
            // Currently there's an issue which results in mismatched markers.
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                Camera camera = renderingData.cameraData.camera;
                Shader.SetGlobalFloat(s_MotionVectorsEnabledID, (float)(camera.depthTextureMode & DepthTextureMode.MotionVectors));

                var filterSettings = m_FilteringSettings;

                var drawSettings = CreateDrawingSettings(s_MotionVectorTag, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
                drawSettings.perObjectData = PerObjectData.MotionVectors;

                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref filterSettings);
                drawSettings.perObjectData = PerObjectData.None;
                filterSettings.excludeMotionVectorObjects = true;
                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref filterSettings);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
