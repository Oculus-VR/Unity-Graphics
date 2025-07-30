Shader "Hidden/Universal Render Pipeline/XR/XRMotionVector"
{
    SubShader
    {
        Tags{ "RenderPipeline" = "UniversalPipeline" }

        // Pass 0: Draw camera motion vector
        Pass
        {
            Name "XR Camera MotionVectors"

            Cull Off
            ZWrite On
            ColorMask RGBA

            // Stencil test to only fill the pixels that doesn't have object motion data filled by the previous pass.
            Stencil
            {
                WriteMask 1
                ReadMask 1
                Ref 1
                Comp NotEqual

                // Fail Zero
                // Pass Zero
            }

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex Vert
            #pragma fragment Frag

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
                float4 posCS : TEXCOORD0;
                float4 prevPosCS : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // -------------------------------------
            // Vertex
            Varyings Vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.position = GetFullScreenTriangleVertexPosition(input.vertexID);

                float depth = 1 - UNITY_NEAR_CLIP_VALUE;
                output.position.z = depth;

                // Reconstruct world position
                float4 posWS = mul(UNITY_MATRIX_I_VP, output.position);

                // Multiply with current and previous non-jittered view projection
                output.posCS = mul(_NonJitteredViewProjMatrix, posWS.xyz);
                output.prevPosCS = mul(_PrevViewProjMatrix, posWS.xyz);

                return output;
            }

            // -------------------------------------
            // Fragment
            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // Non-uniform raster needs to keep the posNDC values in float to avoid additional conversions
                // since uv remap functions use floats
                float3 posNDC = input.posCS.xyz * rcp(input.posCS.w);
                float3 prevPosNDC = input.prevPosCS.xyz * rcp(input.prevPosCS.w);

                // Calculate forward velocity
                float3 velocity = (posNDC - prevPosNDC);

                return float4(velocity.xyz, 0);
            }
            ENDHLSL
        }

        // Pass 1: Blit valid depth data from _XRDepthTexture to motionvector depth target
        Pass
        {
            Name "XR MotionVector Depth Copy"

            Cull Off
            ZWrite On
            ColorMask RGBA

            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_fragment _ _SUBSAMPLE_DEPTH

            #pragma vertex Vert
            #pragma fragment Frag

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
                float4 posCS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            float4 _XRDepthTexture_ST;

            // -------------------------------------
            // Vertex
            Varyings Vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.position = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.posCS = output.position;
                output.uv = GetFullScreenTriangleTexCoord(input.vertexID);
                output.uv = TRANSFORM_TEX(output.uv, _XRDepthTexture);
                return output;
            }

            TEXTURE2D_X(_XRDepthTexture);
            SAMPLER(sampler_XRDepthTexture);

            // -------------------------------------
            // Fragment
            float4 Frag(Varyings input, out float outDepth : SV_Depth) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 uv = input.uv;

             #if _SUBSAMPLE_DEPTH
                float4 depth4 = GATHER_RED_TEXTURE2D_X(_XRDepthTexture, sampler_XRDepthTexture, uv);
                #if UNITY_REVERSED_Z
                    float depth = min(min(depth4.x, depth4.y), min(depth4.z, depth4.w));
                #else
                    float depth = max(max(depth4.x, depth4.y), max(depth4.z, depth4.w));
                #endif
            #else
                float depth = SAMPLE_TEXTURE2D_X(_XRDepthTexture, sampler_XRDepthTexture, uv).x;
            #endif

                // This is required to avoid artifacts from the motion vector pass outputting the same z
            #if UNITY_REVERSED_Z
                outDepth = depth - 0.0001; // Write depth with a small offset
            #else
                outDepth = depth + 0.0001; // Write depth with a small offset
            #endif

                // Calculate world pos from jittered clipspace pos
                float4 jitteredPosCS = float4(input.posCS.xy, depth, 1.0);
                float4 posWS = mul(UNITY_MATRIX_I_VP, jitteredPosCS);

                // Multiply with current and previous non-jittered view projection
                float4 posCS = mul(_NonJitteredViewProjMatrix, posWS);
                float4 prevPosCS = mul(_PrevViewProjMatrix, posWS);

                // Non-uniform raster needs to keep the posNDC values in float to avoid additional conversions
                // since uv remap functions use floats
                float3 posNDC = posCS.xyz * rcp(posCS.w);
                float3 prevPosNDC = prevPosCS.xyz * rcp(prevPosCS.w);

                // Calculate forward velocity
                float3 velocity = (posNDC - prevPosNDC);

                return float4(velocity.xyz, 0);
            }
            ENDHLSL
        }
    }
    Fallback Off
}
