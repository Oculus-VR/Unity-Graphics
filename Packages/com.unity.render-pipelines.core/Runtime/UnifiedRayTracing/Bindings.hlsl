#ifndef _UNIFIEDRAYTRACING_BINDINGS_HLSL_
#define _UNIFIEDRAYTRACING_BINDINGS_HLSL_

#if defined(UNIFIED_RT_BACKEND_COMPUTE)

#ifndef UNIFIED_RT_GROUP_SIZE_X
#define UNIFIED_RT_GROUP_SIZE_X 16
#endif

#ifndef UNIFIED_RT_GROUP_SIZE_Y
#define UNIFIED_RT_GROUP_SIZE_Y 8
#endif

#ifndef UNIFIED_RT_GROUP_SIZE_Z
#define UNIFIED_RT_GROUP_SIZE_Z 1
#endif

#define GROUP_SIZE (UNIFIED_RT_GROUP_SIZE_X*UNIFIED_RT_GROUP_SIZE_Y)
#include "Packages/com.unity.render-pipelines.core/Runtime/UnifiedRayTracing/Compute/RadeonRays/kernels/trace_ray.hlsl"
#endif


namespace UnifiedRT {

struct Ray
{
    float3 origin;
    float  tMin;
    float3 direction;
    float  tMax;
};

struct Hit
{
    uint instanceID;
    uint primitiveIndex;
    float2 uvBarycentrics;
    float hitDistance;
    bool isFrontFace;

    bool IsValid()
    {
        return instanceID != -1;
    }

    static Hit Invalid()
    {
        Hit hit = (Hit)0;
        hit.instanceID = -1;
        return hit;
    }
};


struct InstanceData
{
    float4x4 localToWorld;
    float4x4 previousLocalToWorld;
    float4x4 localToWorldNormals;
    uint renderingLayerMask;
    uint instanceMask;
    uint userMaterialID;
    uint geometryIndex;
};

struct DispatchInfo
{
    uint3 dispatchThreadID;
    uint localThreadIndex;
    uint3 dispatchDimensionsInThreads;
    uint globalThreadIndex;
};

struct RayTracingAccelStruct
{
#if defined(UNIFIED_RT_BACKEND_HARDWARE)
    RaytracingAccelerationStructure accelStruct;
#elif defined(UNIFIED_RT_BACKEND_COMPUTE)
    StructuredBuffer<BvhNode> bvh;
    StructuredBuffer<BvhNode> bottom_bvhs;
    StructuredBuffer<uint4> bottom_bvh_leaves;
    StructuredBuffer<InstanceInfo> instance_infos;
    StructuredBuffer<uint> vertexBuffer;
    int vertexStride;

#else
    #pragma message("Error, you must define either UNIFIED_RT_BACKEND_HARDWARE or UNIFIED_RT_BACKEND_COMPUTE")
#endif

};

#if defined(UNIFIED_RT_BACKEND_HARDWARE)
RayTracingAccelStruct GetAccelStruct(RaytracingAccelerationStructure accelStruct)
{
    RayTracingAccelStruct res;
    res.accelStruct = accelStruct;
    return res;
}

#define UNIFIED_RT_DECLARE_ACCEL_STRUCT(name) RaytracingAccelerationStructure name##accelStruct
#define UNIFIED_RT_GET_ACCEL_STRUCT(name) UnifiedRT::GetAccelStruct(name##accelStruct)

#elif defined(UNIFIED_RT_BACKEND_COMPUTE)
RayTracingAccelStruct GetAccelStruct(
    StructuredBuffer<BvhNode> bvh,
    StructuredBuffer<BvhNode> bottomBvhs,
    StructuredBuffer<uint4> bottomBvhLeaves,
    StructuredBuffer<InstanceInfo> instanceInfos,
    StructuredBuffer<uint> vertexBuffer,
    int vertexStride)
{
    RayTracingAccelStruct res;
    res.bvh = bvh;
    res.bottom_bvhs = bottomBvhs;
    res.bottom_bvh_leaves = bottomBvhLeaves;
    res.instance_infos = instanceInfos;
    res.vertexBuffer = vertexBuffer;
    res.vertexStride = vertexStride;
    return res;
}

#define UNIFIED_RT_DECLARE_ACCEL_STRUCT(name) StructuredBuffer<BvhNode> name##bvh; StructuredBuffer<BvhNode> name##bottomBvhs; StructuredBuffer<uint4> name##bottomBvhLeaves; StructuredBuffer<InstanceInfo> name##instanceInfos; StructuredBuffer<uint> name##vertexBuffer; int name##vertexStride
#define UNIFIED_RT_GET_ACCEL_STRUCT(name) UnifiedRT::GetAccelStruct(name##bvh, name##bottomBvhs, name##bottomBvhLeaves, name##instanceInfos, name##vertexBuffer, name##vertexStride)

#endif

} // namespace UnifiedRT

#if defined(UNIFIED_RT_BACKEND_COMPUTE)
RWStructuredBuffer<uint> g_stack;
#endif

#endif // UNIFIEDRAYTRACING_BINDINGS_HLSL
