
using System.Collections.Generic;

namespace UnityEngine.Rendering.UnifiedRayTracing
{
    internal sealed class HardwareRayTracingAccelStruct : IRayTracingAccelStruct
    {
        public RayTracingAccelerationStructure accelStruct { get; }

        readonly Shader m_HWMaterialShader;
        Material m_RayTracingMaterial;
        readonly RayTracingAccelerationStructureBuildFlags m_BuildFlags;
        // keep a reference to Meshes because RayTracingAccelerationStructure impl is to automatically
        // remove instances when the mesh is disposed
        readonly Dictionary<int, Mesh> m_Meshes = new();
        readonly ReferenceCounter m_Counter;

        internal HardwareRayTracingAccelStruct(AccelerationStructureOptions options, Shader hwMaterialShader, ReferenceCounter counter, bool enableCompaction)
        {
            m_HWMaterialShader = hwMaterialShader;
            LoadRayTracingMaterial();
            m_BuildFlags = (RayTracingAccelerationStructureBuildFlags)options.buildFlags;

            RayTracingAccelerationStructure.Settings settings = new RayTracingAccelerationStructure.Settings();
            settings.rayTracingModeMask = RayTracingAccelerationStructure.RayTracingModeMask.Everything;
            settings.managementMode = RayTracingAccelerationStructure.ManagementMode.Manual;
            settings.enableCompaction = enableCompaction;
            settings.layerMask = 255;
            settings.buildFlagsStaticGeometries = m_BuildFlags;

            accelStruct = new RayTracingAccelerationStructure(settings);

            m_Counter = counter;
            m_Counter.Inc();
        }

        public void Dispose()
        {
            m_Counter.Dec();

            accelStruct?.Dispose();

            if (m_RayTracingMaterial != null)
                Utils.Destroy(m_RayTracingMaterial);
        }

        public int AddInstance(MeshInstanceDesc meshInstance)
        {
            LoadRayTracingMaterial();

            var instanceDesc = new RayTracingMeshInstanceConfig(meshInstance.mesh, (uint)meshInstance.subMeshIndex, m_RayTracingMaterial);
            instanceDesc.mask = meshInstance.mask;
            instanceDesc.enableTriangleCulling = meshInstance.enableTriangleCulling;
            instanceDesc.frontTriangleCounterClockwise = meshInstance.frontTriangleCounterClockwise;
            int instanceHandle = accelStruct.AddInstance(instanceDesc, meshInstance.localToWorldMatrix, null, meshInstance.instanceID);
            m_Meshes.Add(instanceHandle, meshInstance.mesh);
            return instanceHandle;
        }

        public void RemoveInstance(int instanceHandle)
        {
            m_Meshes.Remove(instanceHandle);
            accelStruct.RemoveInstance(instanceHandle);
        }

        public void ClearInstances()
        {
            m_Meshes.Clear();
            accelStruct.ClearInstances();
        }

        public void UpdateInstanceTransform(int instanceHandle, Matrix4x4 localToWorldMatrix)
        {
            accelStruct.UpdateInstanceTransform(instanceHandle, localToWorldMatrix);
        }

        public void UpdateInstanceID(int instanceHandle, uint instanceID)
        {
            accelStruct.UpdateInstanceID(instanceHandle, instanceID);
        }

        public void UpdateInstanceMask(int instanceHandle, uint mask)
        {
            accelStruct.UpdateInstanceMask(instanceHandle, mask);
        }

        public void Build(CommandBuffer cmd, GraphicsBuffer scratchBuffer)
        {
            var buildSettings = new RayTracingAccelerationStructure.BuildSettings()
            {
                buildFlags = m_BuildFlags,
                relativeOrigin = Vector3.zero
            };
            cmd.BuildRayTracingAccelerationStructure(accelStruct, buildSettings);
        }

        public ulong GetBuildScratchBufferRequiredSizeInBytes()
        {
            // Unity's Hardware impl (RayTracingAccelerationStructure) does not require any scratchbuffers.
            // They are directly handled internally by the GfxDevice.
            return 0;
        }

        private void LoadRayTracingMaterial()
        {
            if (m_RayTracingMaterial == null)
                m_RayTracingMaterial = new Material(m_HWMaterialShader);
        }
    }
}

