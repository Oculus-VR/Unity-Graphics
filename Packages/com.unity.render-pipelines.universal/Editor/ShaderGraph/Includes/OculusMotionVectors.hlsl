#ifndef SG_MOTION_VECTORS_INCLUDED
#define SG_MOTION_VECTORS_INCLUDED

PackedVaryings vert(Attributes input)
{
    Varyings output = (Varyings)0;
    output = BuildVaryings(input);
    PackedVaryings packedOutput = (PackedVaryings)0;
    packedOutput = PackVaryings(output);
    return packedOutput;
}

half4 frag(PackedVaryings packedInput) : SV_TARGET
{
    Varyings unpacked = UnpackVaryings(packedInput);
    UNITY_SETUP_INSTANCE_ID(unpacked);

    #if _ALPHATEST_ON
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(unpacked);
        SurfaceDescription surfaceDescription = BuildSurfaceDescription(unpacked);

        clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
    #endif

    float3 screenPos = unpacked.curPositionCS.xyz / unpacked.curPositionCS.w;
    float3 screenPosPrev = unpacked.prevPositionCS.xyz / unpacked.prevPositionCS.w;
    half4 color = (1);
    color.xyz = screenPos - screenPosPrev;

    return color;
}
#endif
