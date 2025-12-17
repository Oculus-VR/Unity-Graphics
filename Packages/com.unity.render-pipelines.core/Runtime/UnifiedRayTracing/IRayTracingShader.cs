using Unity.Mathematics;

namespace UnityEngine.Rendering.UnifiedRayTracing
{
    internal interface IRayTracingShader
    {
        uint3 GetThreadGroupSizes();
        void SetAccelerationStructure(CommandBuffer cmd, string name, IRayTracingAccelStruct accelStruct);
        void SetIntParam(CommandBuffer cmd, int nameID, int val);
        void SetFloatParam(CommandBuffer cmd, int nameID, float val);
        void SetVectorParam(CommandBuffer cmd, int nameID, Vector4 val);
        void SetMatrixParam(CommandBuffer cmd, int nameID, Matrix4x4 val);
        void SetTextureParam(CommandBuffer cmd, int nameID, RenderTargetIdentifier rt);
        void SetBufferParam(CommandBuffer cmd, int nameID, GraphicsBuffer buffer);
        void SetBufferParam(CommandBuffer cmd, int nameID, ComputeBuffer buffer);
        void Dispatch(CommandBuffer cmd, GraphicsBuffer scratchBuffer, uint width, uint height, uint depth);
        void Dispatch(CommandBuffer cmd, GraphicsBuffer scratchBuffer, GraphicsBuffer argsBuffer);
        ulong GetTraceScratchBufferRequiredSizeInBytes(uint width, uint height, uint depth);
    }
}


