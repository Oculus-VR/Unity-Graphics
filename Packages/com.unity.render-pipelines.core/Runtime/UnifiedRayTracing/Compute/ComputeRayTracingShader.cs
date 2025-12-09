using Unity.Mathematics;
using UnityEngine.Assertions;

namespace UnityEngine.Rendering.UnifiedRayTracing
{
    internal class ComputeRayTracingShader : IRayTracingShader
    {
        readonly ComputeShader m_Shader;
        readonly int m_KernelIndex;
        readonly int m_ComputeIndirectDispatchDimsKernelIndex;
        uint3 m_ThreadGroupSizes;

        // Temp buffer containing the dispatch dimensions
        // For standard dispatches, it contains the dims counted in work groups.
        // For indirect dispatches, it contains the dims counted in threads.

        readonly GraphicsBuffer m_DispatchBuffer;

        internal ComputeRayTracingShader(ComputeShader shader, string dispatchFuncName, GraphicsBuffer dispatchBuffer)
        {
            m_Shader = shader;
            m_KernelIndex = m_Shader.FindKernel(dispatchFuncName);
            m_ComputeIndirectDispatchDimsKernelIndex = m_Shader.FindKernel("ComputeIndirectDispatchDims");
            m_Shader.GetKernelThreadGroupSizes(m_KernelIndex,
                out m_ThreadGroupSizes.x, out m_ThreadGroupSizes.y, out m_ThreadGroupSizes.z);
            m_DispatchBuffer = dispatchBuffer;
        }

        public uint3 GetThreadGroupSizes()
        {
            return m_ThreadGroupSizes;
        }

        public void SetAccelerationStructure(CommandBuffer cmd, string name, IRayTracingAccelStruct accelStruct)
        {
            var computeAccelStruct = accelStruct as ComputeRayTracingAccelStruct;
            Assert.IsNotNull(computeAccelStruct);

            computeAccelStruct.Bind(cmd, name, this);
        }

        public void SetIntParam(CommandBuffer cmd, int nameID, int val)
        {
            cmd.SetComputeIntParam(m_Shader, nameID, val);
        }

        public void SetFloatParam(CommandBuffer cmd, int nameID, float val)
        {
            cmd.SetComputeFloatParam(m_Shader, nameID, val);
        }

        public void SetVectorParam(CommandBuffer cmd, int nameID, Vector4 val)
        {
            cmd.SetComputeVectorParam(m_Shader, nameID, val);
        }

        public void SetMatrixParam(CommandBuffer cmd, int nameID, Matrix4x4 val)
        {
            cmd.SetComputeMatrixParam(m_Shader, nameID, val);
        }

        public void SetTextureParam(CommandBuffer cmd, int nameID, RenderTargetIdentifier rt)
        {
            cmd.SetComputeTextureParam(m_Shader, m_KernelIndex, nameID, rt);
        }

        public void SetBufferParam(CommandBuffer cmd, int nameID, GraphicsBuffer buffer)
        {
            cmd.SetComputeBufferParam(m_Shader, m_KernelIndex, nameID, buffer);
        }
        public void SetBufferParam(CommandBuffer cmd, int nameID, ComputeBuffer buffer)
        {
            cmd.SetComputeBufferParam(m_Shader, m_KernelIndex, nameID, buffer);
        }

        public void Dispatch(CommandBuffer cmd, GraphicsBuffer scratchBuffer, uint width, uint height, uint depth)
        {
            var requiredScratchSize = GetTraceScratchBufferRequiredSizeInBytes(width, height, depth);
            if (requiredScratchSize > 0)
            {
                Debug.Assert(scratchBuffer != null && ((ulong)(scratchBuffer.count * scratchBuffer.stride) >= requiredScratchSize), "scratchBuffer size is too small");
                Debug.Assert(scratchBuffer.stride == 4, "scratchBuffer stride must be 4");
            }

            cmd.SetComputeBufferParam(m_Shader, m_KernelIndex, RadeonRays.SID.g_stack, scratchBuffer);
            cmd.SetBufferData(m_DispatchBuffer, new uint[] { width, height, depth });
            SetBufferParam(cmd, RadeonRays.SID.g_dispatch_dimensions, m_DispatchBuffer);

            uint workgroupsX = (uint)GraphicsHelpers.DivUp((int)width, m_ThreadGroupSizes.x);
            uint workgroupsY = (uint)GraphicsHelpers.DivUp((int)height, m_ThreadGroupSizes.y);
            uint workgroupsZ = (uint)GraphicsHelpers.DivUp((int)depth, m_ThreadGroupSizes.z);
            cmd.DispatchCompute(m_Shader, m_KernelIndex, (int)workgroupsX, (int)workgroupsY, (int)workgroupsZ);
        }

        public void Dispatch(CommandBuffer cmd, GraphicsBuffer scratchBuffer, GraphicsBuffer argsBuffer)
        {
            SetIndirectDispatchDimensions(cmd, argsBuffer);
            DispatchIndirect(cmd, scratchBuffer, argsBuffer);
        }

        internal void SetIndirectDispatchDimensions(CommandBuffer cmd, GraphicsBuffer argsBuffer)
        {
            cmd.SetComputeBufferParam(m_Shader, m_ComputeIndirectDispatchDimsKernelIndex, RadeonRays.SID.g_dispatch_dimensions, argsBuffer);
            cmd.SetComputeBufferParam(m_Shader, m_ComputeIndirectDispatchDimsKernelIndex, RadeonRays.SID.g_dispatch_dims_in_workgroups, m_DispatchBuffer);
            cmd.DispatchCompute(m_Shader, m_ComputeIndirectDispatchDimsKernelIndex, 1, 1, 1);
        }

        internal void DispatchIndirect(CommandBuffer cmd, GraphicsBuffer scratchBuffer, GraphicsBuffer argsBuffer)
        {
            cmd.SetComputeBufferParam(m_Shader, m_KernelIndex, RadeonRays.SID.g_stack, scratchBuffer);
            cmd.SetComputeBufferParam(m_Shader, m_KernelIndex, RadeonRays.SID.g_dispatch_dimensions, argsBuffer);
            cmd.DispatchCompute(m_Shader, m_KernelIndex, m_DispatchBuffer, 0);
        }

        public ulong GetTraceScratchBufferRequiredSizeInBytes(uint width, uint height, uint depth)
        {
            uint rayCount = width * height * depth;
            return (RadeonRays.RadeonRaysAPI.GetTraceMemoryRequirements(rayCount) * 4);
        }
    }
}


