#ifndef URPSAMPLECUSTOM_INCLUDED
#define URPSAMPLECUSTOM_INCLUDED

void AdditionalLightSSS_float(float3 worldPos, float3 worldNormal, float2 screenSpaceUV, out float3 contribution)
{
    contribution = float3(0,0,0);

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    //Forward+ light loop needs this inputdata
    InputData inputData = (InputData) 0;
    inputData.positionWS = worldPos;
    inputData.normalizedScreenSpaceUV = screenSpaceUV;

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, worldPos, half4(0,0,0,0));
        float NdotL = saturate(dot(-worldNormal, normalize(light.direction)));
    
        contribution += saturate(NdotL * light.shadowAttenuation * light.distanceAttenuation * 2 * light.color);
    LIGHT_LOOP_END
    
    #endif
}
#endif

void ChannelSelect_float( float4 i, float channel, out float o)
{
    int i_channel = (int) clamp(channel, 0, 3.1);
    o = i[i_channel];
}