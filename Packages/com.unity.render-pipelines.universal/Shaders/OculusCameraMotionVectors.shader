Shader "Hidden/Universal Render Pipeline/CameraMotionVectors"
{
    SubShader
    {
        Pass
        {
            Name "Camera Motion Vectors"

            Cull Off
            ZWrite On

            HLSLPROGRAM
            #pragma multi_compile_fragment _ _FOVEATED_RENDERING_NON_UNIFORM_RASTER
            #pragma multi_compile_fragment _ _SUBSAMPLE_DEPTH
            #pragma never_use_dxc metal

            #pragma exclude_renderers d3d11_9x gles gles3
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag
            // texture arrays are not available everywhere,
            // only compile shader on platforms where they are
            #pragma require 2darray

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

            // -------------------------------------
            // Structs
            struct Attributes
            {
                uint vertexID   : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // -------------------------------------
            // Vertex
            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                // TODO: Use Core Blitter vert.
                output.position = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.uv = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }

            TEXTURE2D_X(_CameraDepthTexture);
            float4 _CameraDepthTextureScaleBias;
            SamplerState sampler_PointClamp;

            // -------------------------------------
            // Fragment
            half4 frag(Varyings input, out float outDepth : SV_Depth) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 uv = _CameraDepthTextureScaleBias.xy * UnityStereoTransformScreenSpaceTex(input.uv) + _CameraDepthTextureScaleBias.zw;

            #if _SUBSAMPLE_DEPTH
                float4 depth4 = GATHER_RED_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, uv);
                #if UNITY_REVERSED_Z
                    float depth = min(min(depth4.x, depth4.y), min(depth4.z, depth4.w));
                #else
                    float depth = max(max(depth4.x, depth4.y), max(depth4.z, depth4.w));
                #endif
            #else
                float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, uv).x;
            #endif

                // This is required to avoid artifacts from the motion vector pass outputting the same z
            #if UNITY_REVERSED_Z
                outDepth = depth - 0.0001; // Write depth with a small offset
            #else
                outDepth = depth + 0.0001; // Write depth with a small offset
                depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
            #endif

                // Reconstruct world position
                float3 posWS = ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);

                // Multiply with current and previous non-jittered view projection
                float4 posCS = TransformWorldToHClip(posWS);
                float4 prevPosCS = TransformWorldToPrevHClip(posWS);

                half3 posNDC = posCS.xyz * rcp(posCS.w);
                half3 prevPosNDC = prevPosCS.xyz * rcp(prevPosCS.w);

                // Calculate forward velocity
                half3 velocity = (posNDC - prevPosNDC);

                return half4(velocity, 1);
            }

            ENDHLSL
        }
    }
}
