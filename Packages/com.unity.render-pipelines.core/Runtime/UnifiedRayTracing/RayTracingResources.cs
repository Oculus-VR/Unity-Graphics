
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace UnityEngine.Rendering.UnifiedRayTracing
{
    internal class RayTracingResources
    {
        public ComputeShader geometryPoolKernels;
        public ComputeShader copyBuffer;
        public Shader hardwareRayTracingMaterial;

        public ComputeShader copyPositions;
        public ComputeShader bitHistogram;
        public ComputeShader blockReducePart;
        public ComputeShader blockScan;
        public ComputeShader buildHlbvh;
        public ComputeShader restructureBvh;
        public ComputeShader scatter;

#if UNITY_EDITOR
        public void Load()
        {
            const string path = "Packages/com.unity.rendering.light-transport/Runtime/";

            geometryPoolKernels        = AssetDatabase.LoadAssetAtPath<ComputeShader>(path + "UnifiedRayTracing/Common/GeometryPool/GeometryPoolKernels.compute");
            copyBuffer                 = AssetDatabase.LoadAssetAtPath<ComputeShader>(path + "UnifiedRayTracing/Common/Utilities/CopyBuffer.compute");
            hardwareRayTracingMaterial = AssetDatabase.LoadAssetAtPath<Shader>(path + "UnifiedRayTracing/Hardware/HWRayTracingMaterial.shader");

            copyPositions              = AssetDatabase.LoadAssetAtPath<ComputeShader>(path + "UnifiedRayTracing/Compute/RadeonRays/kernels/copyPositions.compute");
            bitHistogram               = AssetDatabase.LoadAssetAtPath<ComputeShader>(path + "UnifiedRayTracing/Compute/RadeonRays/kernels/bit_histogram.compute");
            blockReducePart            = AssetDatabase.LoadAssetAtPath<ComputeShader>(path + "UnifiedRayTracing/Compute/RadeonRays/kernels/block_reduce_part.compute");
            blockScan                  = AssetDatabase.LoadAssetAtPath<ComputeShader>(path + "UnifiedRayTracing/Compute/RadeonRays/kernels/block_scan.compute");
            buildHlbvh                 = AssetDatabase.LoadAssetAtPath<ComputeShader>(path + "UnifiedRayTracing/Compute/RadeonRays/kernels/build_hlbvh.compute");
            restructureBvh             = AssetDatabase.LoadAssetAtPath<ComputeShader>(path + "UnifiedRayTracing/Compute/RadeonRays/kernels/restructure_bvh.compute");
            scatter                    = AssetDatabase.LoadAssetAtPath<ComputeShader>(path + "UnifiedRayTracing/Compute/RadeonRays/kernels/scatter.compute");
        }
#endif

    }
}


