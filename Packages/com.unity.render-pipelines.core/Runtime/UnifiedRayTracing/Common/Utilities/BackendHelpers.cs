using System;

namespace UnityEngine.Rendering.UnifiedRayTracing
{
    internal static class BackendHelpers
    {
        internal static string GetFileNameOfShader(RayTracingBackend backend, string fileName)
        {
            string postFix = backend switch
            {
                RayTracingBackend.Hardware => "raytrace",
                RayTracingBackend.Compute => "compute",
                _ => throw new ArgumentOutOfRangeException(nameof(backend), backend, null)
            };
            return $"{fileName}.{postFix}";
        }

        internal static Type GetTypeOfShader(RayTracingBackend backend)
        {
            Type shaderType = backend switch
            {
                RayTracingBackend.Hardware => typeof(RayTracingShader),
                RayTracingBackend.Compute => typeof(ComputeShader),
                _ => throw new ArgumentOutOfRangeException(nameof(backend), backend, null)
            };
            return shaderType;
        }
    }
}
