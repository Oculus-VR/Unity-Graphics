Shader "Hidden/Universal Render Pipeline/XR/XROcclusionMesh"
{
    Properties
    {
        _YFlip("YFlip", Float) = -1.0
    }

    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #pragma exclude_renderers d3d11_9x gles
        #pragma multi_compile_instancing
        #pragma multi_compile _ XR_OCCLUSION_MESH_COMBINED

        // Not all platforms properly support SV_RenderTargetArrayIndex
        #if defined(STEREO_MULTIVIEW_ON)
            #define USE_XR_COMBINED_MESH_MULTIVIEW XR_OCCLUSION_MESH_COMBINED
        #elif defined(SHADER_API_D3D11) || defined(SHADER_API_VULKAN) || defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES3) || defined(SHADER_API_PSSL)
            #define USE_XR_COMBINED_MESH_RT_ARRAY_INDEX XR_OCCLUSION_MESH_COMBINED
        #endif

        struct Attributes
        {
            float4 vertex : POSITION;

            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Varyings
        {
            float4 vertex : SV_POSITION;

        #if USE_XR_COMBINED_MESH_RT_ARRAY_INDEX
            uint rtArrayIndex : SV_RenderTargetArrayIndex;
        #endif
        };

        float _YFlip;

        Varyings Vert(Attributes input)
        {
            UNITY_SETUP_INSTANCE_ID(input);

            Varyings output;
            output.vertex = float4(input.vertex.xy * float2(2.0f, 2.0f * _YFlip) + float2(-1.0f, -1.0f * _YFlip), UNITY_NEAR_CLIP_VALUE, 1.0f);


        #if USE_XR_COMBINED_MESH_RT_ARRAY_INDEX
            output.rtArrayIndex = input.vertex.z;
        #endif

        #if USE_XR_COMBINED_MESH_MULTIVIEW
            if (unity_StereoEyeIndex != uint(input.vertex.z)) {
                output.vertex = 0.0f;
            }
        #endif

            return output;
        }

        float4 Frag() : SV_Target
        {
            return (0.0f).xxxx;
        }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            ZWrite On ZTest Always Blend Off Cull Off
            ColorMask 0

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag
            ENDHLSL
        }
    }
    Fallback Off
}
