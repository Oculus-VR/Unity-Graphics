using System;

namespace UnityEngine.Rendering.UnifiedRayTracing
{
    internal struct MeshInstanceDesc
    {
        public Mesh mesh;
        public int subMeshIndex;
        public Matrix4x4 localToWorldMatrix;
        public uint mask;
        public uint instanceID;
        public bool enableTriangleCulling;
        public bool frontTriangleCounterClockwise;

        public MeshInstanceDesc(Mesh mesh, int subMeshIndex = 0)
        {
            this.mesh = mesh;
            this.subMeshIndex = subMeshIndex;
            localToWorldMatrix = Matrix4x4.identity;
            mask = 0xFFFFFFFF;
            instanceID = 0xFFFFFFFF;
            enableTriangleCulling = true;
            frontTriangleCounterClockwise = false;
        }
    }

    internal interface IRayTracingAccelStruct : IDisposable
    {
        int AddInstance(MeshInstanceDesc meshInstance);
        void RemoveInstance(int instanceHandle);
        void ClearInstances();
        void UpdateInstanceTransform(int instanceHandle, Matrix4x4 localToWorldMatrix);
        void UpdateInstanceID(int instanceHandle, uint instanceID);
        void UpdateInstanceMask(int instanceHandle, uint mask);
        void Build(CommandBuffer cmd, GraphicsBuffer scratchBuffer);
        ulong GetBuildScratchBufferRequiredSizeInBytes();
    }
}

