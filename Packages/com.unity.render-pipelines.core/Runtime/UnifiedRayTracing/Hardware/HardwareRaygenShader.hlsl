#pragma max_recursion_depth 1

#ifndef UNIFIED_RT_RAYGEN_FUNC_NAME
#define UNIFIED_RT_RAYGEN_FUNC_NAME RayGenExecute
#endif

[shader("raygeneration")]
void MainRayGenShader()
{
    UnifiedRT::DispatchInfo dispatchInfo;
    dispatchInfo.dispatchThreadID = DispatchRaysIndex();
    dispatchInfo.dispatchDimensionsInThreads = DispatchRaysDimensions();
    dispatchInfo.localThreadIndex = 0;
    dispatchInfo.globalThreadIndex = DispatchRaysIndex().x + DispatchRaysIndex().y * DispatchRaysDimensions().x + DispatchRaysIndex().z * (DispatchRaysDimensions().x * DispatchRaysDimensions().y);

    UNIFIED_RT_RAYGEN_FUNC_NAME(dispatchInfo);
}

[shader("miss")]
void MainMissShader0(inout UnifiedRT::Hit hit : SV_RayPayload)
{
    hit.instanceID  = -1;
}
