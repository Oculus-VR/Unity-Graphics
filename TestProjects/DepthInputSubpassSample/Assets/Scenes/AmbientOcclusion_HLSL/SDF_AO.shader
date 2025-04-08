Shader "Custom/SDF_AO"
{
    Properties
    {
        // Define the SDF of the sphere
        _Position("Position", Vector) = (.0, .0, .0)
        _Radius("Radius", Float) = 0.5
        _AO_Strength ("Ambient Occlusion Strength", Float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            Blend DstColor Zero

            HLSLPROGRAM
            #pragma multi_compile _ _DEPTH_INPUT_ATTACHMENT

            #pragma vertex vert
            #pragma fragment frag

                           
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"            
            #if defined(_DEPTH_INPUT_ATTACHMENT)
                #define depth_input 0
                FRAMEBUFFER_INPUT_FLOAT_MS(depth_input);
            #else
                // Use the default depth texture when _DEPTH_INPUT_ATTACHMENT was not set 
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #endif


            float3 _Position;
            float _Radius;
            float _AO_Strength; 

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            //v2f output struct

            struct v2f
            {
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO 
            };


            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {    
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                float2 uv = i.vertex.xy / _ScaledScreenParams.xy;
                #if defined(_DEPTH_INPUT_ATTACHMENT)
                    float depth = LOAD_FRAMEBUFFER_INPUT_MS(depth_input, 0, float2(0,0));
                #else
                    float depth = SampleSceneDepth(uv);
                #endif
                float3 worldPos = ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);

                // Distance between world pos and the sphere
                float distance = length(worldPos - _Position) - _Radius; 

                // The point is on the SDF object
                if (distance < 0.01) {
                    distance = 1.0;
                }

                // Calculate the weight based on distance
                float weight = pow(2.0 * distance, _AO_Strength);

                float3 color = lerp(0.0, 1.0, weight);
                return float4(color, 1.0);


            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
