Shader "Shader Graphs/Gravels_PixelDepthOffset_Shader"
{
    Properties
    {
        [NoScaleOffset] _BaseMap("BaseMap", 2D) = "white" {}
        [NoScaleOffset]_NormalMap("NormalMap", 2D) = "white" {}
        [NoScaleOffset]_HeightMap("HeightMap", 2D) = "white" {}
        [NoScaleOffset]_M_AO_SmoothnessMap("M_AO_SmoothnessMap", 2D) = "white" {}
        _NormalStrength("NormalStrength", Float) = 0
        _AOStrength("AOStrength", Float) = 0
        _TextureScale("TextureScale", Float) = 0
        [Toggle(_PARALLAX)]_PARALLAX("Parallax", Float) = 0
        _ParallaxAmplitude("ParallaxAmplitude", Float) = 2.5
        _ParallaxSteps("ParallaxSteps", Float) = 3
        _ParallaxLOD("ParallaxLOD", Float) = 0
        _ParallaxLODThreshold("ParallaxLODThreshold", Float) = 0
        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
        SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue" = "Geometry"
            "ShaderGraphShader" = "true"
            "ShaderGraphTargetId" = "UniversalLitSubTarget"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

        // Render State
        Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

        // Debug
        // <None>

        // --------------------------------------------------
        // Pass

        HLSLPROGRAM

        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

        // Keywords
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DYNAMICLIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma multi_compile _ _FORWARD_PLUS
        #pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS
        #pragma shader_feature_local _ _PARALLAX

        #if defined(_PARALLAX)
            #define KEYWORD_PERMUTATION_0
        #else
            #define KEYWORD_PERMUTATION_1
        #endif


        // Defines

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMALMAP 1
        #endif

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define _NORMAL_DROPOFF_TS 1
        #endif

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_NORMAL
        #endif

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TANGENT
        #endif

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TEXCOORD1
        #endif

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define ATTRIBUTES_NEED_TEXCOORD2
        #endif

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_POSITION_WS
        #endif

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_NORMAL_WS
        #endif

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_TANGENT_WS
        #endif

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #endif

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        #define VARYINGS_NEED_SHADOW_COORD
        #endif

        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_FORWARD
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

        // --------------------------------------------------
        // Structs and Packing

        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

        struct Attributes
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionOS : POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalOS : NORMAL;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentOS : TANGENT;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 uv1 : TEXCOORD1;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 uv2 : TEXCOORD2;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
            #endif
        };
        struct Varyings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 positionWS;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 normalWS;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 tangentWS;
            #endif
            #if defined(LIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 staticLightmapUV;
            #endif
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 dynamicLightmapUV;
            #endif
            #endif
            #if !defined(LIGHTMAP_ON)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 sh;
            #endif
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 fogFactorAndVertexLight;
            #endif
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 shadowCoord;
            #endif
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 TangentSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceBiTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpaceViewDirection;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 TangentSpaceViewDirection;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 WorldSpacePosition;
            #endif
        };
        struct VertexDescriptionInputs
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceNormal;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpaceTangent;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 ObjectSpacePosition;
            #endif
        };
        struct PackedVaryings
        {
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            linear noperspective centroid float4 positionCS : SV_POSITION;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 interp0 : INTERP0;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 interp1 : INTERP1;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 interp2 : INTERP2;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 interp3 : INTERP3;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float2 interp4 : INTERP4;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float3 interp5 : INTERP5;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 interp6 : INTERP6;
            #endif
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             float4 interp7 : INTERP7;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
            #endif
        };

        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
        PackedVaryings PackVaryings(Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz = input.positionWS;
            output.interp1.xyz = input.normalWS;
            output.interp2.xyzw = input.tangentWS;
            #if defined(LIGHTMAP_ON)
            output.interp3.xy = input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp4.xy = input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz = input.sh;
            #endif
            output.interp6.xyzw = input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp7.xyzw = input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

        Varyings UnpackVaryings(PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp3.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp7.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        #endif

        // --------------------------------------------------
        // Graph

        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _M_AO_SmoothnessMap_TexelSize;
        float4 _NormalMap_TexelSize;
        float4 _BaseMap_TexelSize;
        float _NormalStrength;
        float _TextureScale;
        float _ParallaxSteps;
        float _ParallaxAmplitude;
        float _ParallaxLOD;
        float _ParallaxLODThreshold;
        float _AOStrength;
        float4 _HeightMap_TexelSize;
        CBUFFER_END

            // Object and Global properties
            SAMPLER(SamplerState_Linear_Repeat);
            TEXTURE2D(_M_AO_SmoothnessMap);
            SAMPLER(sampler_M_AO_SmoothnessMap);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_HeightMap);
            SAMPLER(sampler_HeightMap);

            // Graph Includes
            // GraphIncludes: <None>

            // -- Property used by ScenePickingPass
            #ifdef SCENEPICKINGPASS
            float4 _SelectionID;
            #endif

            // -- Properties used by SceneSelectionPass
            #ifdef SCENESELECTIONPASS
            int _ObjectId;
            int _PassValue;
            #endif

            // Graph Functions

            void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
            {
                Out = A * B;
            }

            struct PerPixelHeightDisplacementParam
            {
                float2 uv;
            };


            float3 GetDisplacementObjectScale_float()
            {

                float3 objectScale = float3(1.0, 1.0, 1.0);
                float4x4 worldTransform = GetWorldToObjectMatrix();

                objectScale.x = length(float3(worldTransform._m00, worldTransform._m01, worldTransform._m02));
                objectScale.z = length(float3(worldTransform._m20, worldTransform._m21, worldTransform._m22));

                return objectScale;
            }

            // Required struct and function for the ParallaxOcclusionMapping function:
            float ComputePerPixelHeightDisplacement_ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3(float2 texOffsetCurrent, float lod, PerPixelHeightDisplacementParam param, TEXTURE2D_PARAM(heightTexture, heightSampler))
            {
                return SAMPLE_TEXTURE2D_LOD(heightTexture, heightSampler, param.uv + texOffsetCurrent, lod)[0];
            }
            #define ComputePerPixelHeightDisplacement ComputePerPixelHeightDisplacement_ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3
            #define POM_NAME_ID ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_float
            #define POM_USER_DATA_PARAMETERS , TEXTURE2D_PARAM(heightTexture, samplerState)
            #define POM_USER_DATA_ARGUMENTS , TEXTURE2D_ARGS(heightTexture, samplerState)
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/PerPixelDisplacement.hlsl"
            #undef ComputePerPixelHeightDisplacement
            #undef POM_NAME_ID
            #undef POM_USER_DATA_PARAMETERS
            #undef POM_USER_DATA_ARGUMENTS

            void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
            {
                Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
            }

            void Unity_Lerp_float(float A, float B, float T, out float Out)
            {
                Out = lerp(A, B, T);
            }

            // Custom interpolators pre vertex
            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

            // Graph Vertex
            struct VertexDescription
            {
                float3 Position;
                float3 Normal;
                float3 Tangent;
            };

            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
            {
                VertexDescription description = (VertexDescription)0;
                description.Position = IN.ObjectSpacePosition;
                description.Normal = IN.ObjectSpaceNormal;
                description.Tangent = IN.ObjectSpaceTangent;
                return description;
            }

            // Custom interpolators, pre surface
            #ifdef FEATURES_GRAPH_VERTEX
            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
            {
            return output;
            }
            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
            #endif

            // Graph Pixel
            struct SurfaceDescription
            {
                float3 BaseColor;
                float3 NormalTS;
                float3 Emission;
                float Metallic;
                float Smoothness;
                float Occlusion;
                float DepthOffset;
            };

            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                UnityTexture2D _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                UnityTexture2D _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0 = UnityBuildTexture2DStructNoScale(_HeightMap);
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float _Property_34ae852606aa456da62721e7b3551266_Out_0 = _ParallaxAmplitude;
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float _Property_f332b51593bd40da96cf2008daba83bd_Out_0 = _ParallaxSteps;
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float2 _Swizzle_ee146d512bf7434e89535d4eb2393221_Out_1 = IN.WorldSpacePosition.xz;
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float2 _Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2;
                Unity_Multiply_float2_float2(_Swizzle_ee146d512bf7434e89535d4eb2393221_Out_1, float2(-1, -1), _Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2);
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float _Property_3f60dffb796f4c4983fdc65d72109eba_Out_0 = _TextureScale;
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float2 _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2;
                Unity_Multiply_float2_float2(_Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2, (_Property_3f60dffb796f4c4983fdc65d72109eba_Out_0.xx), _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2);
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float _Property_b40967aecd8a44539f17591fc9186718_Out_0 = _ParallaxLOD;
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float _Property_9f91aa59b0df4e95b57576af55b4cdb3_Out_0 = _ParallaxLODThreshold;
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)

                float3 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir = IN.TangentSpaceViewDirection * GetDisplacementObjectScale_float().xzy;
                float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_NdotV = ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.z;
                float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight = _Property_34ae852606aa456da62721e7b3551266_Out_0 * 0.01; // cm in the interface so we multiply by 0.01 in the shader to convert in meter
                ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight *= 2.0 / (abs(float2 (1, 1).x) + abs(float2 (1, 1).y)); // reduce height based on the tiling values

                float2 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVSpaceScale = ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight * float2 (1, 1) / float2 (1, 1);

                // Transform the view vector into the UV space.
                float3 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDirUV = normalize(float3(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.xy * ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVSpaceScale, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.z)); // TODO: skip normalize

                PerPixelHeightDisplacementParam ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM;

                float2 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs = _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2 * float2 (1, 1) + float2 (0, 0);

                ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM.uv = _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.GetTransformedUV(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs);

                float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight;
                float2 _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ParallaxUVs_1 = _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.GetTransformedUV(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs) + ParallaxOcclusionMappingParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_float(_Property_b40967aecd8a44539f17591fc9186718_Out_0, _Property_9f91aa59b0df4e95b57576af55b4cdb3_Out_0, max(min(_Property_f332b51593bd40da96cf2008daba83bd_Out_0, 256), 1), ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDirUV, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight, TEXTURE2D_ARGS(_Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.tex, UnityBuildSamplerStateStruct(SamplerState_Linear_Repeat).samplerstate));

                float _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_PixelDepthOffset_0 = (ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight - ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight * ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight) / max(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_NdotV, 0.0001);
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #if defined(_PARALLAX)
                float2 _Parallax_c43cb4da16e14208b6c7e14870968070_Out_0 = _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ParallaxUVs_1;
                #else
                float2 _Parallax_c43cb4da16e14208b6c7e14870968070_Out_0 = _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2;
                #endif
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float4 _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0 = SAMPLE_TEXTURE2D(_Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.tex, _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.samplerstate, _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.GetTransformedUV(_Parallax_c43cb4da16e14208b6c7e14870968070_Out_0));
                float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_R_4 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.r;
                float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_G_5 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.g;
                float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_B_6 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.b;
                float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_A_7 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.a;
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                UnityTexture2D _Property_55f3a773f01447ad977f60bcc8169e99_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float4 _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0 = SAMPLE_TEXTURE2D(_Property_55f3a773f01447ad977f60bcc8169e99_Out_0.tex, _Property_55f3a773f01447ad977f60bcc8169e99_Out_0.samplerstate, _Property_55f3a773f01447ad977f60bcc8169e99_Out_0.GetTransformedUV(_Parallax_c43cb4da16e14208b6c7e14870968070_Out_0));
                _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0);
                float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_R_4 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.r;
                float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_G_5 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.g;
                float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_B_6 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.b;
                float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_A_7 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.a;
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float _Property_1abbba8fecc94ab4b0924b92ab2e75da_Out_0 = _NormalStrength;
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float3 _NormalStrength_f0cd04f23e214e93959f245d83360e3a_Out_2;
                Unity_NormalStrength_float((_SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.xyz), _Property_1abbba8fecc94ab4b0924b92ab2e75da_Out_0, _NormalStrength_f0cd04f23e214e93959f245d83360e3a_Out_2);
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                UnityTexture2D _Property_620bb953514847259e21e459cf67885a_Out_0 = UnityBuildTexture2DStructNoScale(_M_AO_SmoothnessMap);
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float4 _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_RGBA_0 = SAMPLE_TEXTURE2D(_Property_620bb953514847259e21e459cf67885a_Out_0.tex, _Property_620bb953514847259e21e459cf67885a_Out_0.samplerstate, _Property_620bb953514847259e21e459cf67885a_Out_0.GetTransformedUV(_Parallax_c43cb4da16e14208b6c7e14870968070_Out_0));
                float _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_R_4 = _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_RGBA_0.r;
                float _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_G_5 = _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_RGBA_0.g;
                float _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_A_7 = _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_RGBA_0.b;
                float _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_B_6 = _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_RGBA_0.a;

                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float _Property_856b95c978744be98d319d9f47c5304e_Out_0 = _AOStrength;
                #endif
                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                float _Lerp_1a8023b0ee7e4bb3878fa1af10029d39_Out_3;
                Unity_Lerp_float(1, _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_G_5, _Property_856b95c978744be98d319d9f47c5304e_Out_0, _Lerp_1a8023b0ee7e4bb3878fa1af10029d39_Out_3);
                #endif
                surface.BaseColor = (_SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.xyz);
                surface.NormalTS = _NormalStrength_f0cd04f23e214e93959f245d83360e3a_Out_2;
                surface.Emission = float3(0, 0, 0);
                surface.Metallic = 0;
                surface.Smoothness = _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_B_6;
                surface.Occlusion = _Lerp_1a8023b0ee7e4bb3878fa1af10029d39_Out_3;
                surface.DepthOffset = _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_PixelDepthOffset_0;
                return surface;
            }

            // --------------------------------------------------
            // Build Graph Inputs
            #ifdef HAVE_VFX_MODIFICATION
            #define VFX_SRP_ATTRIBUTES Attributes
            #define VFX_SRP_VARYINGS Varyings
            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
            #endif
            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
            {
                VertexDescriptionInputs output;
                ZERO_INITIALIZE(VertexDescriptionInputs, output);

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            output.ObjectSpaceNormal = input.normalOS;
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            output.ObjectSpaceTangent = input.tangentOS.xyz;
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            output.ObjectSpacePosition = input.positionOS;
            #endif


                return output;
            }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
            {
                SurfaceDescriptionInputs output;
                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

            #ifdef HAVE_VFX_MODIFICATION
                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

            #endif



            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 unnormalizedNormalWS = input.normalWS;
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
            #endif


            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            // use bitangent on the fly like in hdrp
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
            #endif


            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
            #endif


            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            output.WorldSpaceBiTangent = renormFactor * bitang;
            #endif


            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            output.WorldSpaceViewDirection = GetWorldSpaceNormalizeViewDir(input.positionWS);
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            float3x3 tangentSpaceTransform = float3x3(output.WorldSpaceTangent, output.WorldSpaceBiTangent, output.WorldSpaceNormal);
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            output.TangentSpaceViewDirection = mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
            #endif

            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
            output.WorldSpacePosition = input.positionWS;
            #endif


                #if UNITY_UV_STARTS_AT_TOP
                #else
                #endif


            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
            #else
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            #endif
            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                    return output;
            }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            void InitializeInputData(Varyings input, SurfaceDescription surfaceDescription, out InputData inputData)
            {
                inputData = (InputData)0;

                float3 posWS = input.positionWS;

#if defined(_PARALLAX)
                float3 V = GetWorldSpaceNormalizeViewDir(posWS);
                posWS += surfaceDescription.DepthOffset * (-normalize(V)) * 3.5f;
#endif

                inputData.positionWS = posWS;

#ifdef _NORMALMAP
                // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
                float3 bitangent = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

                inputData.tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
#if _NORMAL_DROPOFF_TS
                inputData.normalWS = TransformTangentToWorld(surfaceDescription.NormalTS, inputData.tangentToWorld);
#elif _NORMAL_DROPOFF_OS
                inputData.normalWS = TransformObjectToWorldNormal(surfaceDescription.NormalOS);
#elif _NORMAL_DROPOFF_WS
                inputData.normalWS = surfaceDescription.NormalWS;
#endif
#else
                inputData.normalWS = input.normalWS;
#endif
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
                inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

                inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
                inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
#if defined(DYNAMICLIGHTMAP_ON)
                inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV.xy, input.sh, inputData.normalWS);
#else
                inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.sh, inputData.normalWS);
#endif
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

#if defined(DEBUG_DISPLAY)
#if defined(DYNAMICLIGHTMAP_ON)
                inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
#endif
#if defined(LIGHTMAP_ON)
                inputData.staticLightmapUV = input.staticLightmapUV;
#else
                inputData.vertexSH = input.sh;
#endif
#endif
            }

            PackedVaryings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                output = BuildVaryings(input);
                PackedVaryings packedOutput = (PackedVaryings)0;
                packedOutput = PackVaryings(output);
                return packedOutput;
            }

            void frag(
                PackedVaryings packedInput
                , out half4 outColor : SV_Target0
                , out float outDepth : SV_DepthLessEqual
#ifdef _WRITE_RENDERING_LAYERS
                , out float4 outRenderingLayers : SV_Target1
#endif
            )
            {
                Varyings unpacked = UnpackVaryings(packedInput);
                UNITY_SETUP_INSTANCE_ID(unpacked);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(unpacked);
                SurfaceDescription surfaceDescription = BuildSurfaceDescription(unpacked);

#if defined(_SURFACE_TYPE_TRANSPARENT)
                bool isTransparent = true;
#else
                bool isTransparent = false;
#endif

#if defined(_ALPHATEST_ON)
                half alpha = AlphaDiscard(surfaceDescription.Alpha, surfaceDescription.AlphaClipThreshold);
#elif defined(_SURFACE_TYPE_TRANSPARENT)
                half alpha = surfaceDescription.Alpha;
#else
                half alpha = half(1.0);
#endif

#if defined(LOD_FADE_CROSSFADE) && USE_UNITY_CROSSFADE
                LODFadeCrossFade(unpacked.positionCS);
#endif

                InputData inputData;
                InitializeInputData(unpacked, surfaceDescription, inputData);
                // TODO: Mip debug modes would require this, open question how to do this on ShaderGraph.
                //SETUP_DEBUG_TEXTURE_DATA(inputData, unpacked.texCoord1.xy, _MainTex);

#ifdef _SPECULAR_SETUP
                float3 specular = surfaceDescription.Specular;
                float metallic = 1;
#else
                float3 specular = 0;
                float metallic = surfaceDescription.Metallic;
#endif

                half3 normalTS = half3(0, 0, 0);
#if defined(_NORMALMAP) && defined(_NORMAL_DROPOFF_TS)
                normalTS = surfaceDescription.NormalTS;
#endif

                SurfaceData surface;
                surface.albedo = surfaceDescription.BaseColor;
                surface.metallic = saturate(metallic);
                surface.specular = specular;
                surface.smoothness = saturate(surfaceDescription.Smoothness),
                surface.occlusion = surfaceDescription.Occlusion,
                surface.emission = surfaceDescription.Emission,
                surface.alpha = saturate(alpha);
                surface.normalTS = normalTS;
                surface.clearCoatMask = 0;
                surface.clearCoatSmoothness = 1;

#ifdef _CLEARCOAT
                surface.clearCoatMask = saturate(surfaceDescription.CoatMask);
                surface.clearCoatSmoothness = saturate(surfaceDescription.CoatSmoothness);
#endif

                surface.albedo = AlphaModulate(surface.albedo, surface.alpha);

#ifdef _DBUFFER
                ApplyDecalToSurfaceData(unpacked.positionCS, surface, inputData);
#endif

                half4 color = UniversalFragmentPBR(inputData, surface);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);

                color.a = OutputAlpha(color.a, isTransparent);

                outColor = color;

                float depth = ComputeNormalizedDeviceCoordinatesWithZ(inputData.positionWS, GetWorldToHClipMatrix()).z;
                outDepth = depth;


#ifdef _WRITE_RENDERING_LAYERS
                uint renderingLayers = GetMeshRenderingLayer();
                outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
#endif
            }

            // --------------------------------------------------
            // Visual Effect Vertex Invocations
            #ifdef HAVE_VFX_MODIFICATION
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
            #endif

            ENDHLSL
            }
            Pass
            {
                Name "GBuffer"
                Tags
                {
                    "LightMode" = "UniversalGBuffer"
                }

                // Render State
                Cull Back
                Blend One Zero
                ZTest LEqual
                ZWrite On

                // Debug
                // <None>

                // --------------------------------------------------
                // Pass

                HLSLPROGRAM

                // Pragmas
                #pragma target 4.5
                #pragma exclude_renderers gles gles3 glcore
                #pragma multi_compile_instancing
                #pragma multi_compile_fog
                #pragma instancing_options renderinglayer
                #pragma multi_compile _ DOTS_INSTANCING_ON
                #pragma vertex vert
                #pragma fragment frag

                // Keywords
                #pragma multi_compile _ LIGHTMAP_ON
                #pragma multi_compile _ DYNAMICLIGHTMAP_ON
                #pragma multi_compile _ DIRLIGHTMAP_COMBINED
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
                #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
                #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
                #pragma multi_compile_fragment _ _SHADOWS_SOFT
                #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
                #pragma multi_compile _ SHADOWS_SHADOWMASK
                #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
                #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
                #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
                #pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS
                #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
                #pragma multi_compile_fragment _ DEBUG_DISPLAY
                #pragma shader_feature_local _ _PARALLAX

                #if defined(_PARALLAX)
                    #define KEYWORD_PERMUTATION_0
                #else
                    #define KEYWORD_PERMUTATION_1
                #endif


                // Defines

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define _NORMALMAP 1
                #endif

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define _NORMAL_DROPOFF_TS 1
                #endif

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define ATTRIBUTES_NEED_NORMAL
                #endif

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define ATTRIBUTES_NEED_TANGENT
                #endif

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define ATTRIBUTES_NEED_TEXCOORD1
                #endif

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define ATTRIBUTES_NEED_TEXCOORD2
                #endif

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define VARYINGS_NEED_POSITION_WS
                #endif

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define VARYINGS_NEED_NORMAL_WS
                #endif

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define VARYINGS_NEED_TANGENT_WS
                #endif

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
                #endif

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                #define VARYINGS_NEED_SHADOW_COORD
                #endif

                #define FEATURES_GRAPH_VERTEX
                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                #define SHADERPASS SHADERPASS_GBUFFER
                #define _FOG_FRAGMENT 1
                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                // custom interpolator pre-include
                /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                // Includes
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                // --------------------------------------------------
                // Structs and Packing

                // custom interpolators pre packing
                /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                struct Attributes
                {
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 positionOS : POSITION;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 normalOS : NORMAL;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float4 tangentOS : TANGENT;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float4 uv1 : TEXCOORD1;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float4 uv2 : TEXCOORD2;
                    #endif
                    #if UNITY_ANY_INSTANCING_ENABLED
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     uint instanceID : INSTANCEID_SEMANTIC;
                    #endif
                    #endif
                };
                struct Varyings
                {
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float4 positionCS : SV_POSITION;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 positionWS;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 normalWS;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float4 tangentWS;
                    #endif
                    #if defined(LIGHTMAP_ON)
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float2 staticLightmapUV;
                    #endif
                    #endif
                    #if defined(DYNAMICLIGHTMAP_ON)
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float2 dynamicLightmapUV;
                    #endif
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 sh;
                    #endif
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float4 fogFactorAndVertexLight;
                    #endif
                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float4 shadowCoord;
                    #endif
                    #endif
                    #if UNITY_ANY_INSTANCING_ENABLED
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                    #endif
                };
                struct SurfaceDescriptionInputs
                {
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 WorldSpaceNormal;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 TangentSpaceNormal;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 WorldSpaceTangent;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 WorldSpaceBiTangent;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 WorldSpaceViewDirection;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 TangentSpaceViewDirection;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 WorldSpacePosition;
                    #endif
                };
                struct VertexDescriptionInputs
                {
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 ObjectSpaceNormal;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 ObjectSpaceTangent;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 ObjectSpacePosition;
                    #endif
                };
                struct PackedVaryings
                {
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    linear noperspective centroid float4 positionCS : SV_POSITION;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 interp0 : INTERP0;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 interp1 : INTERP1;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float4 interp2 : INTERP2;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float2 interp3 : INTERP3;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float2 interp4 : INTERP4;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float3 interp5 : INTERP5;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float4 interp6 : INTERP6;
                    #endif
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     float4 interp7 : INTERP7;
                    #endif
                    #if UNITY_ANY_INSTANCING_ENABLED
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     uint instanceID : CUSTOM_INSTANCE_ID;
                    #endif
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                    #endif
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                    #endif
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                    #endif
                    #endif
                };

                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                PackedVaryings PackVaryings(Varyings input)
                {
                    PackedVaryings output;
                    ZERO_INITIALIZE(PackedVaryings, output);
                    output.positionCS = input.positionCS;
                    output.interp0.xyz = input.positionWS;
                    output.interp1.xyz = input.normalWS;
                    output.interp2.xyzw = input.tangentWS;
                    #if defined(LIGHTMAP_ON)
                    output.interp3.xy = input.staticLightmapUV;
                    #endif
                    #if defined(DYNAMICLIGHTMAP_ON)
                    output.interp4.xy = input.dynamicLightmapUV;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    output.interp5.xyz = input.sh;
                    #endif
                    output.interp6.xyzw = input.fogFactorAndVertexLight;
                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.interp7.xyzw = input.shadowCoord;
                    #endif
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }

                Varyings UnpackVaryings(PackedVaryings input)
                {
                    Varyings output;
                    output.positionCS = input.positionCS;
                    output.positionWS = input.interp0.xyz;
                    output.normalWS = input.interp1.xyz;
                    output.tangentWS = input.interp2.xyzw;
                    #if defined(LIGHTMAP_ON)
                    output.staticLightmapUV = input.interp3.xy;
                    #endif
                    #if defined(DYNAMICLIGHTMAP_ON)
                    output.dynamicLightmapUV = input.interp4.xy;
                    #endif
                    #if !defined(LIGHTMAP_ON)
                    output.sh = input.interp5.xyz;
                    #endif
                    output.fogFactorAndVertexLight = input.interp6.xyzw;
                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = input.interp7.xyzw;
                    #endif
                    #if UNITY_ANY_INSTANCING_ENABLED
                    output.instanceID = input.instanceID;
                    #endif
                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                    #endif
                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                    #endif
                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    output.cullFace = input.cullFace;
                    #endif
                    return output;
                }
                #endif

                // --------------------------------------------------
                // Graph

                // Graph Properties
                CBUFFER_START(UnityPerMaterial)
                float4 _M_AO_SmoothnessMap_TexelSize;
                float4 _NormalMap_TexelSize;
                float4 _BaseMap_TexelSize;
                float _NormalStrength;
                float _TextureScale;
                float _ParallaxSteps;
                float _ParallaxAmplitude;
                float _ParallaxLOD;
                float _ParallaxLODThreshold;
                float _AOStrength;
                float4 _HeightMap_TexelSize;
                CBUFFER_END

                    // Object and Global properties
                    SAMPLER(SamplerState_Linear_Repeat);
                    TEXTURE2D(_M_AO_SmoothnessMap);
                    SAMPLER(sampler_M_AO_SmoothnessMap);
                    TEXTURE2D(_NormalMap);
                    SAMPLER(sampler_NormalMap);
                    TEXTURE2D(_BaseMap);
                    SAMPLER(sampler_BaseMap);
                    TEXTURE2D(_HeightMap);
                    SAMPLER(sampler_HeightMap);

                    // Graph Includes
                    // GraphIncludes: <None>

                    // -- Property used by ScenePickingPass
                    #ifdef SCENEPICKINGPASS
                    float4 _SelectionID;
                    #endif

                    // -- Properties used by SceneSelectionPass
                    #ifdef SCENESELECTIONPASS
                    int _ObjectId;
                    int _PassValue;
                    #endif

                    // Graph Functions

                    void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                    {
                        Out = A * B;
                    }

                    struct PerPixelHeightDisplacementParam
                    {
                        float2 uv;
                    };


                    float3 GetDisplacementObjectScale_float()
                    {

                        float3 objectScale = float3(1.0, 1.0, 1.0);
                        float4x4 worldTransform = GetWorldToObjectMatrix();

                        objectScale.x = length(float3(worldTransform._m00, worldTransform._m01, worldTransform._m02));
                        objectScale.z = length(float3(worldTransform._m20, worldTransform._m21, worldTransform._m22));

                        return objectScale;
                    }

                    // Required struct and function for the ParallaxOcclusionMapping function:
                    float ComputePerPixelHeightDisplacement_ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3(float2 texOffsetCurrent, float lod, PerPixelHeightDisplacementParam param, TEXTURE2D_PARAM(heightTexture, heightSampler))
                    {
                        return SAMPLE_TEXTURE2D_LOD(heightTexture, heightSampler, param.uv + texOffsetCurrent, lod)[0];
                    }
                    #define ComputePerPixelHeightDisplacement ComputePerPixelHeightDisplacement_ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3
                    #define POM_NAME_ID ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_float
                    #define POM_USER_DATA_PARAMETERS , TEXTURE2D_PARAM(heightTexture, samplerState)
                    #define POM_USER_DATA_ARGUMENTS , TEXTURE2D_ARGS(heightTexture, samplerState)
                    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/PerPixelDisplacement.hlsl"
                    #undef ComputePerPixelHeightDisplacement
                    #undef POM_NAME_ID
                    #undef POM_USER_DATA_PARAMETERS
                    #undef POM_USER_DATA_ARGUMENTS

                    void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
                    {
                        Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
                    }

                    void Unity_Lerp_float(float A, float B, float T, out float Out)
                    {
                        Out = lerp(A, B, T);
                    }

                    // Custom interpolators pre vertex
                    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                    // Graph Vertex
                    struct VertexDescription
                    {
                        float3 Position;
                        float3 Normal;
                        float3 Tangent;
                    };

                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                    {
                        VertexDescription description = (VertexDescription)0;
                        description.Position = IN.ObjectSpacePosition;
                        description.Normal = IN.ObjectSpaceNormal;
                        description.Tangent = IN.ObjectSpaceTangent;
                        return description;
                    }

                    // Custom interpolators, pre surface
                    #ifdef FEATURES_GRAPH_VERTEX
                    Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                    {
                    return output;
                    }
                    #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                    #endif

                    // Graph Pixel
                    struct SurfaceDescription
                    {
                        float3 BaseColor;
                        float3 NormalTS;
                        float3 Emission;
                        float Metallic;
                        float Smoothness;
                        float Occlusion;
                        float DepthOffset;
                    };

                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                    {
                        SurfaceDescription surface = (SurfaceDescription)0;
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        UnityTexture2D _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        UnityTexture2D _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0 = UnityBuildTexture2DStructNoScale(_HeightMap);
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float _Property_34ae852606aa456da62721e7b3551266_Out_0 = _ParallaxAmplitude;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float _Property_f332b51593bd40da96cf2008daba83bd_Out_0 = _ParallaxSteps;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float2 _Swizzle_ee146d512bf7434e89535d4eb2393221_Out_1 = IN.WorldSpacePosition.xz;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float2 _Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2;
                        Unity_Multiply_float2_float2(_Swizzle_ee146d512bf7434e89535d4eb2393221_Out_1, float2(-1, -1), _Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2);
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float _Property_3f60dffb796f4c4983fdc65d72109eba_Out_0 = _TextureScale;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float2 _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2;
                        Unity_Multiply_float2_float2(_Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2, (_Property_3f60dffb796f4c4983fdc65d72109eba_Out_0.xx), _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2);
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float _Property_b40967aecd8a44539f17591fc9186718_Out_0 = _ParallaxLOD;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float _Property_9f91aa59b0df4e95b57576af55b4cdb3_Out_0 = _ParallaxLODThreshold;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)

                        float3 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir = IN.TangentSpaceViewDirection * GetDisplacementObjectScale_float().xzy;
                        float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_NdotV = ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.z;
                        float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight = _Property_34ae852606aa456da62721e7b3551266_Out_0 * 0.01; // cm in the interface so we multiply by 0.01 in the shader to convert in meter
                        ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight *= 2.0 / (abs(float2 (1, 1).x) + abs(float2 (1, 1).y)); // reduce height based on the tiling values

                        float2 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVSpaceScale = ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight * float2 (1, 1) / float2 (1, 1);

                        // Transform the view vector into the UV space.
                        float3 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDirUV = normalize(float3(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.xy * ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVSpaceScale, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.z)); // TODO: skip normalize

                        PerPixelHeightDisplacementParam ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM;

                        float2 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs = _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2 * float2 (1, 1) + float2 (0, 0);

                        ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM.uv = _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.GetTransformedUV(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs);

                        float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight;
                        float2 _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ParallaxUVs_1 = _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.GetTransformedUV(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs) + ParallaxOcclusionMappingParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_float(_Property_b40967aecd8a44539f17591fc9186718_Out_0, _Property_9f91aa59b0df4e95b57576af55b4cdb3_Out_0, max(min(_Property_f332b51593bd40da96cf2008daba83bd_Out_0, 256), 1), ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDirUV, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight, TEXTURE2D_ARGS(_Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.tex, UnityBuildSamplerStateStruct(SamplerState_Linear_Repeat).samplerstate));

                        float _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_PixelDepthOffset_0 = (ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight - ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight * ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight) / max(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_NdotV, 0.0001);
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        #if defined(_PARALLAX)
                        float2 _Parallax_c43cb4da16e14208b6c7e14870968070_Out_0 = _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ParallaxUVs_1;
                        #else
                        float2 _Parallax_c43cb4da16e14208b6c7e14870968070_Out_0 = _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2;
                        #endif
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float4 _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0 = SAMPLE_TEXTURE2D(_Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.tex, _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.samplerstate, _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.GetTransformedUV(_Parallax_c43cb4da16e14208b6c7e14870968070_Out_0));
                        float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_R_4 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.r;
                        float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_G_5 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.g;
                        float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_B_6 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.b;
                        float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_A_7 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.a;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        UnityTexture2D _Property_55f3a773f01447ad977f60bcc8169e99_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float4 _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0 = SAMPLE_TEXTURE2D(_Property_55f3a773f01447ad977f60bcc8169e99_Out_0.tex, _Property_55f3a773f01447ad977f60bcc8169e99_Out_0.samplerstate, _Property_55f3a773f01447ad977f60bcc8169e99_Out_0.GetTransformedUV(_Parallax_c43cb4da16e14208b6c7e14870968070_Out_0));
                        _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0);
                        float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_R_4 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.r;
                        float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_G_5 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.g;
                        float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_B_6 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.b;
                        float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_A_7 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.a;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float _Property_1abbba8fecc94ab4b0924b92ab2e75da_Out_0 = _NormalStrength;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float3 _NormalStrength_f0cd04f23e214e93959f245d83360e3a_Out_2;
                        Unity_NormalStrength_float((_SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.xyz), _Property_1abbba8fecc94ab4b0924b92ab2e75da_Out_0, _NormalStrength_f0cd04f23e214e93959f245d83360e3a_Out_2);
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        UnityTexture2D _Property_620bb953514847259e21e459cf67885a_Out_0 = UnityBuildTexture2DStructNoScale(_M_AO_SmoothnessMap);
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float4 _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_RGBA_0 = SAMPLE_TEXTURE2D(_Property_620bb953514847259e21e459cf67885a_Out_0.tex, _Property_620bb953514847259e21e459cf67885a_Out_0.samplerstate, _Property_620bb953514847259e21e459cf67885a_Out_0.GetTransformedUV(_Parallax_c43cb4da16e14208b6c7e14870968070_Out_0));
                        float _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_R_4 = _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_RGBA_0.r;
                        float _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_G_5 = _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_RGBA_0.g;
                        float _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_B_6 = _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_RGBA_0.b;
                        float _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_A_7 = _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_RGBA_0.a;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float _Property_856b95c978744be98d319d9f47c5304e_Out_0 = _AOStrength;
                        #endif
                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        float _Lerp_1a8023b0ee7e4bb3878fa1af10029d39_Out_3;
                        Unity_Lerp_float(1, _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_G_5, _Property_856b95c978744be98d319d9f47c5304e_Out_0, _Lerp_1a8023b0ee7e4bb3878fa1af10029d39_Out_3);
                        #endif
                        surface.BaseColor = (_SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.xyz);
                        surface.NormalTS = _NormalStrength_f0cd04f23e214e93959f245d83360e3a_Out_2;
                        surface.Emission = float3(0, 0, 0);
                        surface.Metallic = 0;
                        surface.Smoothness = _SampleTexture2D_6c4aaacb9c8c4dd781ca51dbed546bc8_B_6;
                        surface.Occlusion = _Lerp_1a8023b0ee7e4bb3878fa1af10029d39_Out_3;
                        surface.DepthOffset = _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_PixelDepthOffset_0;
                        return surface;
                    }

                    // --------------------------------------------------
                    // Build Graph Inputs
                    #ifdef HAVE_VFX_MODIFICATION
                    #define VFX_SRP_ATTRIBUTES Attributes
                    #define VFX_SRP_VARYINGS Varyings
                    #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                    #endif
                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                    {
                        VertexDescriptionInputs output;
                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    output.ObjectSpaceNormal = input.normalOS;
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    output.ObjectSpaceTangent = input.tangentOS.xyz;
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    output.ObjectSpacePosition = input.positionOS;
                    #endif


                        return output;
                    }
                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                    {
                        SurfaceDescriptionInputs output;
                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                    #ifdef HAVE_VFX_MODIFICATION
                        // FragInputs from VFX come from two places: Interpolator or CBuffer.
                        /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                    #endif



                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    float3 unnormalizedNormalWS = input.normalWS;
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                    #endif


                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    // use bitangent on the fly like in hdrp
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    #endif


                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
                    #endif


                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    output.WorldSpaceBiTangent = renormFactor * bitang;
                    #endif


                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    output.WorldSpaceViewDirection = GetWorldSpaceNormalizeViewDir(input.positionWS);
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    float3x3 tangentSpaceTransform = float3x3(output.WorldSpaceTangent, output.WorldSpaceBiTangent, output.WorldSpaceNormal);
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    output.TangentSpaceViewDirection = mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                    #endif

                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                    output.WorldSpacePosition = input.positionWS;
                    #endif


                        #if UNITY_UV_STARTS_AT_TOP
                        #else
                        #endif


                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                    #else
                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                    #endif
                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                            return output;
                    }

                    // --------------------------------------------------
                    // Main

                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
                    //#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

                    void InitializeInputData(Varyings input, SurfaceDescription surfaceDescription, out InputData inputData)
                    {
                        inputData = (InputData)0;

                        float3 posWS = input.positionWS;

#if defined(_PARALLAX)
                        float3 V = GetWorldSpaceNormalizeViewDir(posWS);
                        posWS += surfaceDescription.DepthOffset * (-normalize(V)) * 3.5f;
#endif

                        inputData.positionWS = posWS;

                        inputData.positionCS = input.positionCS;

#ifdef _NORMALMAP
                        // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                        float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
                        float3 bitangent = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

                        inputData.tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
#if _NORMAL_DROPOFF_TS
                        inputData.normalWS = TransformTangentToWorld(surfaceDescription.NormalTS, inputData.tangentToWorld);
#elif _NORMAL_DROPOFF_OS
                        inputData.normalWS = TransformObjectToWorldNormal(surfaceDescription.NormalOS);
#elif _NORMAL_DROPOFF_WS
                        inputData.normalWS = surfaceDescription.NormalWS;
#endif
#else
                        inputData.normalWS = input.normalWS;
#endif
                        inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                        inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);

#if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
                        inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

                        inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
                        inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
#if defined(DYNAMICLIGHTMAP_ON)
                        inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV.xy, input.sh, inputData.normalWS);
#else
                        inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.sh, inputData.normalWS);
#endif
                        inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                        inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

#if defined(DEBUG_DISPLAY)
#if defined(DYNAMICLIGHTMAP_ON)
                        inputData.dynamicLightmapUV = input.dynamicLightmapUV.xy;
#endif
#if defined(LIGHTMAP_ON)
                        inputData.staticLightmapUV = input.staticLightmapUV;
#else
                        inputData.vertexSH = input.sh;
#endif
#endif
                    }

                    PackedVaryings vert(Attributes input)
                    {
                        Varyings output = (Varyings)0;
                        output = BuildVaryings(input);
                        PackedVaryings packedOutput = (PackedVaryings)0;
                        packedOutput = PackVaryings(output);
                        return packedOutput;
                    }

                    FragmentOutput frag(PackedVaryings packedInput, out float outDepth : SV_DepthLessEqual)
                    {
                        Varyings unpacked = UnpackVaryings(packedInput);
                        UNITY_SETUP_INSTANCE_ID(unpacked);
                        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(unpacked);
                        SurfaceDescription surfaceDescription = BuildSurfaceDescription(unpacked);

#if _ALPHATEST_ON
                        half alpha = surfaceDescription.Alpha;
                        clip(alpha - surfaceDescription.AlphaClipThreshold);
#elif _SURFACE_TYPE_TRANSPARENT
                        half alpha = surfaceDescription.Alpha;
#else
                        half alpha = 1;
#endif

#if defined(LOD_FADE_CROSSFADE) && USE_UNITY_CROSSFADE
                        LODFadeCrossFade(unpacked.positionCS);
#endif

                        InputData inputData;
                        InitializeInputData(unpacked, surfaceDescription, inputData);

                        // ADD PIXELDEPTHPOSITION

                        // TODO: Mip debug modes would require this, open question how to do this on ShaderGraph.
                        //SETUP_DEBUG_TEXTURE_DATA(inputData, unpacked.uv, _MainTex);

#ifdef _SPECULAR_SETUP
                        float3 specular = surfaceDescription.Specular;
                        float metallic = 1;
#else
                        float3 specular = 0;
                        float metallic = surfaceDescription.Metallic;
#endif

#ifdef _DBUFFER
                        ApplyDecal(unpacked.positionCS,
                            surfaceDescription.BaseColor,
                            specular,
                            inputData.normalWS,
                            metallic,
                            surfaceDescription.Occlusion,
                            surfaceDescription.Smoothness);
#endif

                        // in LitForwardPass GlobalIllumination (and temporarily LightingPhysicallyBased) are called inside UniversalFragmentPBR
                        // in Deferred rendering we store the sum of these values (and of emission as well) in the GBuffer
                        BRDFData brdfData;
                        InitializeBRDFData(surfaceDescription.BaseColor, metallic, specular, surfaceDescription.Smoothness, alpha, brdfData);

                        Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
                        MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
                        half3 color = GlobalIllumination(brdfData, inputData.bakedGI, surfaceDescription.Occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);

                        float depth = ComputeNormalizedDeviceCoordinatesWithZ(inputData.positionWS, GetWorldToHClipMatrix()).z;
                        outDepth = depth;

                        return BRDFDataToGbuffer(brdfData, inputData, surfaceDescription.Smoothness, surfaceDescription.Emission + color, surfaceDescription.Occlusion);
                    }

                    // --------------------------------------------------
                    // Visual Effect Vertex Invocations
                    #ifdef HAVE_VFX_MODIFICATION
                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                    #endif

                    ENDHLSL
                    }
                    Pass
                    {
                        Name "ShadowCaster"
                        Tags
                        {
                            "LightMode" = "ShadowCaster"
                        }

                        // Render State
                        Cull Back
                        ZTest LEqual
                        ZWrite On
                        ColorMask 0

                        // Debug
                        // <None>

                        // --------------------------------------------------
                        // Pass

                        HLSLPROGRAM

                        // Pragmas
                        #pragma target 4.5
                        #pragma exclude_renderers gles gles3 glcore
                        #pragma multi_compile_instancing
                        #pragma multi_compile _ DOTS_INSTANCING_ON
                        #pragma vertex vert
                        #pragma fragment frag

                        // Keywords
                        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
                        #pragma shader_feature_local _ _PARALLAX

                        #if defined(_PARALLAX)
                            #define KEYWORD_PERMUTATION_0
                        #else
                            #define KEYWORD_PERMUTATION_1
                        #endif


                        // Defines

                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        #define _NORMALMAP 1
                        #endif

                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        #define _NORMAL_DROPOFF_TS 1
                        #endif

                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        #define ATTRIBUTES_NEED_NORMAL
                        #endif

                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        #define ATTRIBUTES_NEED_TANGENT
                        #endif

                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        #define VARYINGS_NEED_NORMAL_WS
                        #endif

                        #define FEATURES_GRAPH_VERTEX
                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                        #define SHADERPASS SHADERPASS_SHADOWCASTER
                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                        // custom interpolator pre-include
                        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                        // Includes
                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                        // --------------------------------------------------
                        // Structs and Packing

                        // custom interpolators pre packing
                        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                        struct Attributes
                        {
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             float3 positionOS : POSITION;
                            #endif
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             float3 normalOS : NORMAL;
                            #endif
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             float4 tangentOS : TANGENT;
                            #endif
                            #if UNITY_ANY_INSTANCING_ENABLED
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             uint instanceID : INSTANCEID_SEMANTIC;
                            #endif
                            #endif
                        };
                        struct Varyings
                        {
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             float4 positionCS : SV_POSITION;
                            #endif
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             float3 normalWS;
                            #endif
                            #if UNITY_ANY_INSTANCING_ENABLED
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             uint instanceID : CUSTOM_INSTANCE_ID;
                            #endif
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                            #endif
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                            #endif
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                            #endif
                            #endif
                        };
                        struct SurfaceDescriptionInputs
                        {
                        };
                        struct VertexDescriptionInputs
                        {
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             float3 ObjectSpaceNormal;
                            #endif
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             float3 ObjectSpaceTangent;
                            #endif
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             float3 ObjectSpacePosition;
                            #endif
                        };
                        struct PackedVaryings
                        {
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             float4 positionCS : SV_POSITION;
                            #endif
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             float3 interp0 : INTERP0;
                            #endif
                            #if UNITY_ANY_INSTANCING_ENABLED
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             uint instanceID : CUSTOM_INSTANCE_ID;
                            #endif
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                            #endif
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                            #endif
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                            #endif
                            #endif
                        };

                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                        PackedVaryings PackVaryings(Varyings input)
                        {
                            PackedVaryings output;
                            ZERO_INITIALIZE(PackedVaryings, output);
                            output.positionCS = input.positionCS;
                            output.interp0.xyz = input.normalWS;
                            #if UNITY_ANY_INSTANCING_ENABLED
                            output.instanceID = input.instanceID;
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            output.cullFace = input.cullFace;
                            #endif
                            return output;
                        }

                        Varyings UnpackVaryings(PackedVaryings input)
                        {
                            Varyings output;
                            output.positionCS = input.positionCS;
                            output.normalWS = input.interp0.xyz;
                            #if UNITY_ANY_INSTANCING_ENABLED
                            output.instanceID = input.instanceID;
                            #endif
                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                            #endif
                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                            #endif
                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            output.cullFace = input.cullFace;
                            #endif
                            return output;
                        }
                        #endif

                        // --------------------------------------------------
                        // Graph

                        // Graph Properties
                        CBUFFER_START(UnityPerMaterial)
                        float4 _M_AO_SmoothnessMap_TexelSize;
                        float4 _NormalMap_TexelSize;
                        float4 _BaseMap_TexelSize;
                        float _NormalStrength;
                        float _TextureScale;
                        float _ParallaxSteps;
                        float _ParallaxAmplitude;
                        float _ParallaxLOD;
                        float _ParallaxLODThreshold;
                        float _AOStrength;
                        float4 _HeightMap_TexelSize;
                        CBUFFER_END

                            // Object and Global properties
                            SAMPLER(SamplerState_Linear_Repeat);
                            TEXTURE2D(_M_AO_SmoothnessMap);
                            SAMPLER(sampler_M_AO_SmoothnessMap);
                            TEXTURE2D(_NormalMap);
                            SAMPLER(sampler_NormalMap);
                            TEXTURE2D(_BaseMap);
                            SAMPLER(sampler_BaseMap);
                            TEXTURE2D(_HeightMap);
                            SAMPLER(sampler_HeightMap);

                            // Graph Includes
                            // GraphIncludes: <None>

                            // -- Property used by ScenePickingPass
                            #ifdef SCENEPICKINGPASS
                            float4 _SelectionID;
                            #endif

                            // -- Properties used by SceneSelectionPass
                            #ifdef SCENESELECTIONPASS
                            int _ObjectId;
                            int _PassValue;
                            #endif

                            // Graph Functions
                            // GraphFunctions: <None>

                            // Custom interpolators pre vertex
                            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                            // Graph Vertex
                            struct VertexDescription
                            {
                                float3 Position;
                                float3 Normal;
                                float3 Tangent;
                            };

                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                            {
                                VertexDescription description = (VertexDescription)0;
                                description.Position = IN.ObjectSpacePosition;
                                description.Normal = IN.ObjectSpaceNormal;
                                description.Tangent = IN.ObjectSpaceTangent;
                                return description;
                            }

                            // Custom interpolators, pre surface
                            #ifdef FEATURES_GRAPH_VERTEX
                            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                            {
                            return output;
                            }
                            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                            #endif

                            // Graph Pixel
                            struct SurfaceDescription
                            {
                            };

                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                            {
                                SurfaceDescription surface = (SurfaceDescription)0;
                                return surface;
                            }

                            // --------------------------------------------------
                            // Build Graph Inputs
                            #ifdef HAVE_VFX_MODIFICATION
                            #define VFX_SRP_ATTRIBUTES Attributes
                            #define VFX_SRP_VARYINGS Varyings
                            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                            #endif
                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                            {
                                VertexDescriptionInputs output;
                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                            output.ObjectSpaceNormal = input.normalOS;
                            #endif

                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                            output.ObjectSpaceTangent = input.tangentOS.xyz;
                            #endif

                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                            output.ObjectSpacePosition = input.positionOS;
                            #endif


                                return output;
                            }
                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                            {
                                SurfaceDescriptionInputs output;
                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                            #ifdef HAVE_VFX_MODIFICATION
                                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                            #endif








                                #if UNITY_UV_STARTS_AT_TOP
                                #else
                                #endif


                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                            #else
                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                            #endif
                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                    return output;
                            }

                            // --------------------------------------------------
                            // Main

                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

                            // --------------------------------------------------
                            // Visual Effect Vertex Invocations
                            #ifdef HAVE_VFX_MODIFICATION
                            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                            #endif

                            ENDHLSL
                            }
                            Pass
                            {
                                Name "DepthOnly"
                                Tags
                                {
                                    "LightMode" = "DepthOnly"
                                }

                                // Render State
                                Cull Back
                                ZTest LEqual
                                ZWrite On
                                ColorMask R

                                // Debug
                                // <None>

                                // --------------------------------------------------
                                // Pass

                                HLSLPROGRAM

                                // Pragmas
                                #pragma target 4.5
                                #pragma exclude_renderers gles gles3 glcore
                                #pragma multi_compile_instancing
                                #pragma multi_compile _ DOTS_INSTANCING_ON
                                #pragma vertex vert
                                #pragma fragment frag

                                // Keywords
                                // PassKeywords: <None>
                                #pragma shader_feature_local _ _PARALLAX

                                #if defined(_PARALLAX)
                                    #define KEYWORD_PERMUTATION_0
                                #else
                                    #define KEYWORD_PERMUTATION_1
                                #endif


                                // Defines

                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                #define _NORMALMAP 1
                                #endif

                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                #define _NORMAL_DROPOFF_TS 1
                                #endif

                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                #define ATTRIBUTES_NEED_NORMAL
                                #endif

                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                #define ATTRIBUTES_NEED_TANGENT
                                #endif

                                #define FEATURES_GRAPH_VERTEX
                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                #define SHADERPASS SHADERPASS_DEPTHONLY
                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                // custom interpolator pre-include
                                /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                // Includes
                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                // --------------------------------------------------
                                // Structs and Packing

                                // custom interpolators pre packing
                                /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                struct Attributes
                                {
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     float3 positionOS : POSITION;
                                    #endif
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     float3 normalOS : NORMAL;
                                    #endif
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     float4 tangentOS : TANGENT;
                                    #endif
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     uint instanceID : INSTANCEID_SEMANTIC;
                                    #endif
                                    #endif
                                };
                                struct Varyings
                                {
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     float4 positionCS : SV_POSITION;
                                    #endif
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                    #endif
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                    #endif
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                    #endif
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                    #endif
                                    #endif
                                };
                                struct SurfaceDescriptionInputs
                                {
                                };
                                struct VertexDescriptionInputs
                                {
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     float3 ObjectSpaceNormal;
                                    #endif
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     float3 ObjectSpaceTangent;
                                    #endif
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     float3 ObjectSpacePosition;
                                    #endif
                                };
                                struct PackedVaryings
                                {
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     float4 positionCS : SV_POSITION;
                                    #endif
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                    #endif
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                    #endif
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                    #endif
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                    #endif
                                    #endif
                                };

                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                PackedVaryings PackVaryings(Varyings input)
                                {
                                    PackedVaryings output;
                                    ZERO_INITIALIZE(PackedVaryings, output);
                                    output.positionCS = input.positionCS;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    output.instanceID = input.instanceID;
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    output.cullFace = input.cullFace;
                                    #endif
                                    return output;
                                }

                                Varyings UnpackVaryings(PackedVaryings input)
                                {
                                    Varyings output;
                                    output.positionCS = input.positionCS;
                                    #if UNITY_ANY_INSTANCING_ENABLED
                                    output.instanceID = input.instanceID;
                                    #endif
                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                    #endif
                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                    #endif
                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    output.cullFace = input.cullFace;
                                    #endif
                                    return output;
                                }
                                #endif

                                // --------------------------------------------------
                                // Graph

                                // Graph Properties
                                CBUFFER_START(UnityPerMaterial)
                                float4 _M_AO_SmoothnessMap_TexelSize;
                                float4 _NormalMap_TexelSize;
                                float4 _BaseMap_TexelSize;
                                float _NormalStrength;
                                float _TextureScale;
                                float _ParallaxSteps;
                                float _ParallaxAmplitude;
                                float _ParallaxLOD;
                                float _ParallaxLODThreshold;
                                float _AOStrength;
                                float4 _HeightMap_TexelSize;
                                CBUFFER_END

                                    // Object and Global properties
                                    SAMPLER(SamplerState_Linear_Repeat);
                                    TEXTURE2D(_M_AO_SmoothnessMap);
                                    SAMPLER(sampler_M_AO_SmoothnessMap);
                                    TEXTURE2D(_NormalMap);
                                    SAMPLER(sampler_NormalMap);
                                    TEXTURE2D(_BaseMap);
                                    SAMPLER(sampler_BaseMap);
                                    TEXTURE2D(_HeightMap);
                                    SAMPLER(sampler_HeightMap);

                                    // Graph Includes
                                    // GraphIncludes: <None>

                                    // -- Property used by ScenePickingPass
                                    #ifdef SCENEPICKINGPASS
                                    float4 _SelectionID;
                                    #endif

                                    // -- Properties used by SceneSelectionPass
                                    #ifdef SCENESELECTIONPASS
                                    int _ObjectId;
                                    int _PassValue;
                                    #endif

                                    // Graph Functions
                                    // GraphFunctions: <None>

                                    // Custom interpolators pre vertex
                                    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                    // Graph Vertex
                                    struct VertexDescription
                                    {
                                        float3 Position;
                                        float3 Normal;
                                        float3 Tangent;
                                    };

                                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                    {
                                        VertexDescription description = (VertexDescription)0;
                                        description.Position = IN.ObjectSpacePosition;
                                        description.Normal = IN.ObjectSpaceNormal;
                                        description.Tangent = IN.ObjectSpaceTangent;
                                        return description;
                                    }

                                    // Custom interpolators, pre surface
                                    #ifdef FEATURES_GRAPH_VERTEX
                                    Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                    {
                                    return output;
                                    }
                                    #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                    #endif

                                    // Graph Pixel
                                    struct SurfaceDescription
                                    {
                                    };

                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                    {
                                        SurfaceDescription surface = (SurfaceDescription)0;
                                        return surface;
                                    }

                                    // --------------------------------------------------
                                    // Build Graph Inputs
                                    #ifdef HAVE_VFX_MODIFICATION
                                    #define VFX_SRP_ATTRIBUTES Attributes
                                    #define VFX_SRP_VARYINGS Varyings
                                    #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                    #endif
                                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                    {
                                        VertexDescriptionInputs output;
                                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                    output.ObjectSpaceNormal = input.normalOS;
                                    #endif

                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                    output.ObjectSpaceTangent = input.tangentOS.xyz;
                                    #endif

                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                    output.ObjectSpacePosition = input.positionOS;
                                    #endif


                                        return output;
                                    }
                                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                    {
                                        SurfaceDescriptionInputs output;
                                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                    #ifdef HAVE_VFX_MODIFICATION
                                        // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                        /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                    #endif








                                        #if UNITY_UV_STARTS_AT_TOP
                                        #else
                                        #endif


                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                    #else
                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                    #endif
                                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                            return output;
                                    }

                                    // --------------------------------------------------
                                    // Main

                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

                                    // --------------------------------------------------
                                    // Visual Effect Vertex Invocations
                                    #ifdef HAVE_VFX_MODIFICATION
                                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                    #endif

                                    ENDHLSL
                                    }
                                    Pass
                                    {
                                        Name "DepthNormals"
                                        Tags
                                        {
                                            "LightMode" = "DepthNormals"
                                        }

                                        // Render State
                                        Cull Back
                                        ZTest LEqual
                                        ZWrite On

                                        // Debug
                                        // <None>

                                        // --------------------------------------------------
                                        // Pass

                                        HLSLPROGRAM

                                        // Pragmas
                                        #pragma target 4.5
                                        #pragma exclude_renderers gles gles3 glcore
                                        #pragma multi_compile_instancing
                                        #pragma multi_compile _ DOTS_INSTANCING_ON
                                        #pragma vertex vert
                                        #pragma fragment frag

                                        // Keywords
                                        #pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS
                                        #pragma shader_feature_local _ _PARALLAX

                                        #if defined(_PARALLAX)
                                            #define KEYWORD_PERMUTATION_0
                                        #else
                                            #define KEYWORD_PERMUTATION_1
                                        #endif


                                        // Defines

                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                        #define _NORMALMAP 1
                                        #endif

                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                        #define _NORMAL_DROPOFF_TS 1
                                        #endif

                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                        #define ATTRIBUTES_NEED_NORMAL
                                        #endif

                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                        #define ATTRIBUTES_NEED_TANGENT
                                        #endif

                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                        #define ATTRIBUTES_NEED_TEXCOORD1
                                        #endif

                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                        #define VARYINGS_NEED_POSITION_WS
                                        #endif

                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                        #define VARYINGS_NEED_NORMAL_WS
                                        #endif

                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                        #define VARYINGS_NEED_TANGENT_WS
                                        #endif

                                        #define FEATURES_GRAPH_VERTEX
                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                        #define SHADERPASS SHADERPASS_DEPTHNORMALS
                                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                        // custom interpolator pre-include
                                        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                        // Includes
                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                        // --------------------------------------------------
                                        // Structs and Packing

                                        // custom interpolators pre packing
                                        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                        struct Attributes
                                        {
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 positionOS : POSITION;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 normalOS : NORMAL;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float4 tangentOS : TANGENT;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float4 uv1 : TEXCOORD1;
                                            #endif
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             uint instanceID : INSTANCEID_SEMANTIC;
                                            #endif
                                            #endif
                                        };
                                        struct Varyings
                                        {
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float4 positionCS : SV_POSITION;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 positionWS;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 normalWS;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float4 tangentWS;
                                            #endif
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                            #endif
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                            #endif
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                            #endif
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                            #endif
                                            #endif
                                        };
                                        struct SurfaceDescriptionInputs
                                        {
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 WorldSpaceNormal;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 TangentSpaceNormal;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 WorldSpaceTangent;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 WorldSpaceBiTangent;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 WorldSpaceViewDirection;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 TangentSpaceViewDirection;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 WorldSpacePosition;
                                            #endif
                                        };
                                        struct VertexDescriptionInputs
                                        {
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 ObjectSpaceNormal;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 ObjectSpaceTangent;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 ObjectSpacePosition;
                                            #endif
                                        };
                                        struct PackedVaryings
                                        {
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float4 positionCS : SV_POSITION;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 interp0 : INTERP0;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float3 interp1 : INTERP1;
                                            #endif
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             float4 interp2 : INTERP2;
                                            #endif
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                            #endif
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                            #endif
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                            #endif
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                            #endif
                                            #endif
                                        };

                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                        PackedVaryings PackVaryings(Varyings input)
                                        {
                                            PackedVaryings output;
                                            ZERO_INITIALIZE(PackedVaryings, output);
                                            output.positionCS = input.positionCS;
                                            output.interp0.xyz = input.positionWS;
                                            output.interp1.xyz = input.normalWS;
                                            output.interp2.xyzw = input.tangentWS;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            output.instanceID = input.instanceID;
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            output.cullFace = input.cullFace;
                                            #endif
                                            return output;
                                        }

                                        Varyings UnpackVaryings(PackedVaryings input)
                                        {
                                            Varyings output;
                                            output.positionCS = input.positionCS;
                                            output.positionWS = input.interp0.xyz;
                                            output.normalWS = input.interp1.xyz;
                                            output.tangentWS = input.interp2.xyzw;
                                            #if UNITY_ANY_INSTANCING_ENABLED
                                            output.instanceID = input.instanceID;
                                            #endif
                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                            #endif
                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                            #endif
                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            output.cullFace = input.cullFace;
                                            #endif
                                            return output;
                                        }
                                        #endif

                                        // --------------------------------------------------
                                        // Graph

                                        // Graph Properties
                                        CBUFFER_START(UnityPerMaterial)
                                        float4 _M_AO_SmoothnessMap_TexelSize;
                                        float4 _NormalMap_TexelSize;
                                        float4 _BaseMap_TexelSize;
                                        float _NormalStrength;
                                        float _TextureScale;
                                        float _ParallaxSteps;
                                        float _ParallaxAmplitude;
                                        float _ParallaxLOD;
                                        float _ParallaxLODThreshold;
                                        float _AOStrength;
                                        float4 _HeightMap_TexelSize;
                                        CBUFFER_END

                                            // Object and Global properties
                                            SAMPLER(SamplerState_Linear_Repeat);
                                            TEXTURE2D(_M_AO_SmoothnessMap);
                                            SAMPLER(sampler_M_AO_SmoothnessMap);
                                            TEXTURE2D(_NormalMap);
                                            SAMPLER(sampler_NormalMap);
                                            TEXTURE2D(_BaseMap);
                                            SAMPLER(sampler_BaseMap);
                                            TEXTURE2D(_HeightMap);
                                            SAMPLER(sampler_HeightMap);

                                            // Graph Includes
                                            // GraphIncludes: <None>

                                            // -- Property used by ScenePickingPass
                                            #ifdef SCENEPICKINGPASS
                                            float4 _SelectionID;
                                            #endif

                                            // -- Properties used by SceneSelectionPass
                                            #ifdef SCENESELECTIONPASS
                                            int _ObjectId;
                                            int _PassValue;
                                            #endif

                                            // Graph Functions

                                            void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                                            {
                                                Out = A * B;
                                            }

                                            struct PerPixelHeightDisplacementParam
                                            {
                                                float2 uv;
                                            };


                                            float3 GetDisplacementObjectScale_float()
                                            {

                                                float3 objectScale = float3(1.0, 1.0, 1.0);
                                                float4x4 worldTransform = GetWorldToObjectMatrix();

                                                objectScale.x = length(float3(worldTransform._m00, worldTransform._m01, worldTransform._m02));
                                                objectScale.z = length(float3(worldTransform._m20, worldTransform._m21, worldTransform._m22));

                                                return objectScale;
                                            }

                                            // Required struct and function for the ParallaxOcclusionMapping function:
                                            float ComputePerPixelHeightDisplacement_ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3(float2 texOffsetCurrent, float lod, PerPixelHeightDisplacementParam param, TEXTURE2D_PARAM(heightTexture, heightSampler))
                                            {
                                                return SAMPLE_TEXTURE2D_LOD(heightTexture, heightSampler, param.uv + texOffsetCurrent, lod)[0];
                                            }
                                            #define ComputePerPixelHeightDisplacement ComputePerPixelHeightDisplacement_ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3
                                            #define POM_NAME_ID ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_float
                                            #define POM_USER_DATA_PARAMETERS , TEXTURE2D_PARAM(heightTexture, samplerState)
                                            #define POM_USER_DATA_ARGUMENTS , TEXTURE2D_ARGS(heightTexture, samplerState)
                                            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/PerPixelDisplacement.hlsl"
                                            #undef ComputePerPixelHeightDisplacement
                                            #undef POM_NAME_ID
                                            #undef POM_USER_DATA_PARAMETERS
                                            #undef POM_USER_DATA_ARGUMENTS

                                            void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
                                            {
                                                Out = float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
                                            }

                                            // Custom interpolators pre vertex
                                            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                            // Graph Vertex
                                            struct VertexDescription
                                            {
                                                float3 Position;
                                                float3 Normal;
                                                float3 Tangent;
                                            };

                                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                            {
                                                VertexDescription description = (VertexDescription)0;
                                                description.Position = IN.ObjectSpacePosition;
                                                description.Normal = IN.ObjectSpaceNormal;
                                                description.Tangent = IN.ObjectSpaceTangent;
                                                return description;
                                            }

                                            // Custom interpolators, pre surface
                                            #ifdef FEATURES_GRAPH_VERTEX
                                            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                            {
                                            return output;
                                            }
                                            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                            #endif

                                            // Graph Pixel
                                            struct SurfaceDescription
                                            {
                                                float3 NormalTS;
                                                float DepthOffset;
                                            };

                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                            {
                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                UnityTexture2D _Property_55f3a773f01447ad977f60bcc8169e99_Out_0 = UnityBuildTexture2DStructNoScale(_NormalMap);
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                UnityTexture2D _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0 = UnityBuildTexture2DStructNoScale(_HeightMap);
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float _Property_34ae852606aa456da62721e7b3551266_Out_0 = _ParallaxAmplitude;
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float _Property_f332b51593bd40da96cf2008daba83bd_Out_0 = _ParallaxSteps;
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float2 _Swizzle_ee146d512bf7434e89535d4eb2393221_Out_1 = IN.WorldSpacePosition.xz;
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float2 _Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2;
                                                Unity_Multiply_float2_float2(_Swizzle_ee146d512bf7434e89535d4eb2393221_Out_1, float2(-1, -1), _Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2);
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float _Property_3f60dffb796f4c4983fdc65d72109eba_Out_0 = _TextureScale;
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float2 _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2;
                                                Unity_Multiply_float2_float2(_Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2, (_Property_3f60dffb796f4c4983fdc65d72109eba_Out_0.xx), _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2);
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float _Property_b40967aecd8a44539f17591fc9186718_Out_0 = _ParallaxLOD;
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float _Property_9f91aa59b0df4e95b57576af55b4cdb3_Out_0 = _ParallaxLODThreshold;
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)

                                                float3 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir = IN.TangentSpaceViewDirection * GetDisplacementObjectScale_float().xzy;
                                                float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_NdotV = ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.z;
                                                float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight = _Property_34ae852606aa456da62721e7b3551266_Out_0 * 0.01; // cm in the interface so we multiply by 0.01 in the shader to convert in meter
                                                ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight *= 2.0 / (abs(float2 (1, 1).x) + abs(float2 (1, 1).y)); // reduce height based on the tiling values

                                                float2 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVSpaceScale = ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight * float2 (1, 1) / float2 (1, 1);

                                                // Transform the view vector into the UV space.
                                                float3 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDirUV = normalize(float3(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.xy * ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVSpaceScale, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.z)); // TODO: skip normalize

                                                PerPixelHeightDisplacementParam ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM;

                                                float2 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs = _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2 * float2 (1, 1) + float2 (0, 0);

                                                ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM.uv = _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.GetTransformedUV(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs);

                                                float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight;
                                                float2 _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ParallaxUVs_1 = _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.GetTransformedUV(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs) + ParallaxOcclusionMappingParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_float(_Property_b40967aecd8a44539f17591fc9186718_Out_0, _Property_9f91aa59b0df4e95b57576af55b4cdb3_Out_0, max(min(_Property_f332b51593bd40da96cf2008daba83bd_Out_0, 256), 1), ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDirUV, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight, TEXTURE2D_ARGS(_Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.tex, UnityBuildSamplerStateStruct(SamplerState_Linear_Repeat).samplerstate));

                                                float _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_PixelDepthOffset_0 = (ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight - ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight * ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight) / max(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_NdotV, 0.0001);
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #if defined(_PARALLAX)
                                                float2 _Parallax_c43cb4da16e14208b6c7e14870968070_Out_0 = _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ParallaxUVs_1;
                                                #else
                                                float2 _Parallax_c43cb4da16e14208b6c7e14870968070_Out_0 = _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2;
                                                #endif
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float4 _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0 = SAMPLE_TEXTURE2D(_Property_55f3a773f01447ad977f60bcc8169e99_Out_0.tex, _Property_55f3a773f01447ad977f60bcc8169e99_Out_0.samplerstate, _Property_55f3a773f01447ad977f60bcc8169e99_Out_0.GetTransformedUV(_Parallax_c43cb4da16e14208b6c7e14870968070_Out_0));
                                                _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0);
                                                float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_R_4 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.r;
                                                float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_G_5 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.g;
                                                float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_B_6 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.b;
                                                float _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_A_7 = _SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.a;
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float _Property_1abbba8fecc94ab4b0924b92ab2e75da_Out_0 = _NormalStrength;
                                                #endif
                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                float3 _NormalStrength_f0cd04f23e214e93959f245d83360e3a_Out_2;
                                                Unity_NormalStrength_float((_SampleTexture2D_0046458503bf42cc9beaae50aa8cc001_RGBA_0.xyz), _Property_1abbba8fecc94ab4b0924b92ab2e75da_Out_0, _NormalStrength_f0cd04f23e214e93959f245d83360e3a_Out_2);
                                                #endif
                                                surface.NormalTS = _NormalStrength_f0cd04f23e214e93959f245d83360e3a_Out_2;
                                                surface.DepthOffset = _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_PixelDepthOffset_0;
                                                return surface;
                                            }

                                            // --------------------------------------------------
                                            // Build Graph Inputs
                                            #ifdef HAVE_VFX_MODIFICATION
                                            #define VFX_SRP_ATTRIBUTES Attributes
                                            #define VFX_SRP_VARYINGS Varyings
                                            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                            #endif
                                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                            {
                                                VertexDescriptionInputs output;
                                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            output.ObjectSpaceNormal = input.normalOS;
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            output.ObjectSpaceTangent = input.tangentOS.xyz;
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            output.ObjectSpacePosition = input.positionOS;
                                            #endif


                                                return output;
                                            }
                                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                            {
                                                SurfaceDescriptionInputs output;
                                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                            #ifdef HAVE_VFX_MODIFICATION
                                                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                            #endif



                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            float3 unnormalizedNormalWS = input.normalWS;
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                                            #endif


                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            // use bitangent on the fly like in hdrp
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
                                            #endif


                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
                                            #endif


                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            output.WorldSpaceBiTangent = renormFactor * bitang;
                                            #endif


                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            output.WorldSpaceViewDirection = GetWorldSpaceNormalizeViewDir(input.positionWS);
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            float3x3 tangentSpaceTransform = float3x3(output.WorldSpaceTangent, output.WorldSpaceBiTangent, output.WorldSpaceNormal);
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            output.TangentSpaceViewDirection = mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                                            #endif

                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                            output.WorldSpacePosition = input.positionWS;
                                            #endif


                                                #if UNITY_UV_STARTS_AT_TOP
                                                #else
                                                #endif


                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                            #else
                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                            #endif
                                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                    return output;
                                            }

                                            // --------------------------------------------------
                                            // Main

                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                            //#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"



#ifndef SG_DEPTH_NORMALS_PASS_INCLUDED
#define SG_DEPTH_NORMALS_PASS_INCLUDED

                                            PackedVaryings vert(Attributes input)
                                            {
                                                Varyings output = (Varyings)0;
                                                output = BuildVaryings(input);
                                                PackedVaryings packedOutput = (PackedVaryings)0;
                                                packedOutput = PackVaryings(output);
                                                return packedOutput;
                                            }

                                            void frag(
                                                PackedVaryings packedInput
                                                , out half4 outNormalWS : SV_Target0
                                                , out float outDepth : SV_DepthLessEqual
#ifdef _WRITE_RENDERING_LAYERS
                                                , out float4 outRenderingLayers : SV_Target1
#endif
                                            )
                                            {
                                                Varyings unpacked = UnpackVaryings(packedInput);
                                                UNITY_SETUP_INSTANCE_ID(unpacked);
                                                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(unpacked);
                                                SurfaceDescription surfaceDescription = BuildSurfaceDescription(unpacked);

#if _ALPHATEST_ON
                                                clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
#endif

#if defined(LOD_FADE_CROSSFADE) && USE_UNITY_CROSSFADE
                                                LODFadeCrossFade(unpacked.positionCS);
#endif

#if defined(_GBUFFER_NORMALS_OCT)
                                                float3 normalWS = normalize(unpacked.normalWS);
                                                float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
                                                float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
                                                half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
                                                outNormalWS = half4(packedNormalWS, 0.0);
                                                outDepth = packedInput.positionCS.z;
#else
                                                // Retrieve the normal from the bump map or mesh normal
#if defined(_NORMALMAP)
#if _NORMAL_DROPOFF_TS
    // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                                                float crossSign = (unpacked.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
                                                float3 bitangent = crossSign * cross(unpacked.normalWS.xyz, unpacked.tangentWS.xyz);
                                                float3 normalWS = TransformTangentToWorld(surfaceDescription.NormalTS, half3x3(unpacked.tangentWS.xyz, bitangent, unpacked.normalWS.xyz));
#elif _NORMAL_DROPOFF_OS
                                                float3 normalWS = TransformObjectToWorldNormal(surfaceDescription.NormalOS);
#elif _NORMAL_DROPOFF_WS
                                                float3 normalWS = surfaceDescription.NormalWS;
#endif
#else
                                                float3 normalWS = unpacked.normalWS;
#endif

                                                outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);

                                                float3 posWS = unpacked.positionWS;

#if defined(_PARALLAX)
                                                float3 V = GetWorldSpaceNormalizeViewDir(posWS);
                                                posWS += surfaceDescription.DepthOffset * (-normalize(V)) * 3.5f;
#endif
                                                float depth = ComputeNormalizedDeviceCoordinatesWithZ(posWS, GetWorldToHClipMatrix()).z;
                                                outDepth = depth;

#endif

#ifdef _WRITE_RENDERING_LAYERS
                                                uint renderingLayers = GetMeshRenderingLayer();
                                                outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
#endif
                                            }

#endif

                                            // --------------------------------------------------
                                            // Visual Effect Vertex Invocations
                                            #ifdef HAVE_VFX_MODIFICATION
                                            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                            #endif

                                            ENDHLSL
                                            }
                                            Pass
                                            {
                                                Name "Meta"
                                                Tags
                                                {
                                                    "LightMode" = "Meta"
                                                }

                                                // Render State
                                                Cull Off

                                                // Debug
                                                // <None>

                                                // --------------------------------------------------
                                                // Pass

                                                HLSLPROGRAM

                                                // Pragmas
                                                #pragma target 4.5
                                                #pragma exclude_renderers gles gles3 glcore
                                                #pragma multi_compile _ DOTS_INSTANCING_ON
                                                #pragma vertex vert
                                                #pragma fragment frag

                                                // Keywords
                                                #pragma shader_feature _ EDITOR_VISUALIZATION
                                                #pragma shader_feature_local _ _PARALLAX

                                                #if defined(_PARALLAX)
                                                    #define KEYWORD_PERMUTATION_0
                                                #else
                                                    #define KEYWORD_PERMUTATION_1
                                                #endif


                                                // Defines

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define _NORMALMAP 1
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define _NORMAL_DROPOFF_TS 1
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define ATTRIBUTES_NEED_NORMAL
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define ATTRIBUTES_NEED_TANGENT
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define ATTRIBUTES_NEED_TEXCOORD0
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define ATTRIBUTES_NEED_TEXCOORD1
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define ATTRIBUTES_NEED_TEXCOORD2
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define VARYINGS_NEED_POSITION_WS
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define VARYINGS_NEED_NORMAL_WS
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define VARYINGS_NEED_TANGENT_WS
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define VARYINGS_NEED_TEXCOORD0
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define VARYINGS_NEED_TEXCOORD1
                                                #endif

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                #define VARYINGS_NEED_TEXCOORD2
                                                #endif

                                                #define FEATURES_GRAPH_VERTEX
                                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                #define SHADERPASS SHADERPASS_META
                                                #define _FOG_FRAGMENT 1
                                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                // custom interpolator pre-include
                                                /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                // Includes
                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
                                                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                // --------------------------------------------------
                                                // Structs and Packing

                                                // custom interpolators pre packing
                                                /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                struct Attributes
                                                {
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 positionOS : POSITION;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 normalOS : NORMAL;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 tangentOS : TANGENT;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 uv0 : TEXCOORD0;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 uv1 : TEXCOORD1;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 uv2 : TEXCOORD2;
                                                    #endif
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     uint instanceID : INSTANCEID_SEMANTIC;
                                                    #endif
                                                    #endif
                                                };
                                                struct Varyings
                                                {
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 positionCS : SV_POSITION;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 positionWS;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 normalWS;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 tangentWS;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 texCoord0;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 texCoord1;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 texCoord2;
                                                    #endif
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                    #endif
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                    #endif
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                    #endif
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                    #endif
                                                    #endif
                                                };
                                                struct SurfaceDescriptionInputs
                                                {
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 WorldSpaceNormal;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 WorldSpaceTangent;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 WorldSpaceBiTangent;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 WorldSpaceViewDirection;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 TangentSpaceViewDirection;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 WorldSpacePosition;
                                                    #endif
                                                };
                                                struct VertexDescriptionInputs
                                                {
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 ObjectSpaceNormal;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 ObjectSpaceTangent;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 ObjectSpacePosition;
                                                    #endif
                                                };
                                                struct PackedVaryings
                                                {
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 positionCS : SV_POSITION;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 interp0 : INTERP0;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float3 interp1 : INTERP1;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 interp2 : INTERP2;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 interp3 : INTERP3;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 interp4 : INTERP4;
                                                    #endif
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     float4 interp5 : INTERP5;
                                                    #endif
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                    #endif
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                    #endif
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                    #endif
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                    #endif
                                                    #endif
                                                };

                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                PackedVaryings PackVaryings(Varyings input)
                                                {
                                                    PackedVaryings output;
                                                    ZERO_INITIALIZE(PackedVaryings, output);
                                                    output.positionCS = input.positionCS;
                                                    output.interp0.xyz = input.positionWS;
                                                    output.interp1.xyz = input.normalWS;
                                                    output.interp2.xyzw = input.tangentWS;
                                                    output.interp3.xyzw = input.texCoord0;
                                                    output.interp4.xyzw = input.texCoord1;
                                                    output.interp5.xyzw = input.texCoord2;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    output.instanceID = input.instanceID;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    output.cullFace = input.cullFace;
                                                    #endif
                                                    return output;
                                                }

                                                Varyings UnpackVaryings(PackedVaryings input)
                                                {
                                                    Varyings output;
                                                    output.positionCS = input.positionCS;
                                                    output.positionWS = input.interp0.xyz;
                                                    output.normalWS = input.interp1.xyz;
                                                    output.tangentWS = input.interp2.xyzw;
                                                    output.texCoord0 = input.interp3.xyzw;
                                                    output.texCoord1 = input.interp4.xyzw;
                                                    output.texCoord2 = input.interp5.xyzw;
                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                    output.instanceID = input.instanceID;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                    #endif
                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                    #endif
                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    output.cullFace = input.cullFace;
                                                    #endif
                                                    return output;
                                                }
                                                #endif

                                                // --------------------------------------------------
                                                // Graph

                                                // Graph Properties
                                                CBUFFER_START(UnityPerMaterial)
                                                float4 _M_AO_SmoothnessMap_TexelSize;
                                                float4 _NormalMap_TexelSize;
                                                float4 _BaseMap_TexelSize;
                                                float _NormalStrength;
                                                float _TextureScale;
                                                float _ParallaxSteps;
                                                float _ParallaxAmplitude;
                                                float _ParallaxLOD;
                                                float _ParallaxLODThreshold;
                                                float _AOStrength;
                                                float4 _HeightMap_TexelSize;
                                                CBUFFER_END

                                                    // Object and Global properties
                                                    SAMPLER(SamplerState_Linear_Repeat);
                                                    TEXTURE2D(_M_AO_SmoothnessMap);
                                                    SAMPLER(sampler_M_AO_SmoothnessMap);
                                                    TEXTURE2D(_NormalMap);
                                                    SAMPLER(sampler_NormalMap);
                                                    TEXTURE2D(_BaseMap);
                                                    SAMPLER(sampler_BaseMap);
                                                    TEXTURE2D(_HeightMap);
                                                    SAMPLER(sampler_HeightMap);

                                                    // Graph Includes
                                                    // GraphIncludes: <None>

                                                    // -- Property used by ScenePickingPass
                                                    #ifdef SCENEPICKINGPASS
                                                    float4 _SelectionID;
                                                    #endif

                                                    // -- Properties used by SceneSelectionPass
                                                    #ifdef SCENESELECTIONPASS
                                                    int _ObjectId;
                                                    int _PassValue;
                                                    #endif

                                                    // Graph Functions

                                                    void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                                                    {
                                                        Out = A * B;
                                                    }

                                                    struct PerPixelHeightDisplacementParam
                                                    {
                                                        float2 uv;
                                                    };


                                                    float3 GetDisplacementObjectScale_float()
                                                    {

                                                        float3 objectScale = float3(1.0, 1.0, 1.0);
                                                        float4x4 worldTransform = GetWorldToObjectMatrix();

                                                        objectScale.x = length(float3(worldTransform._m00, worldTransform._m01, worldTransform._m02));
                                                        objectScale.z = length(float3(worldTransform._m20, worldTransform._m21, worldTransform._m22));

                                                        return objectScale;
                                                    }

                                                    // Required struct and function for the ParallaxOcclusionMapping function:
                                                    float ComputePerPixelHeightDisplacement_ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3(float2 texOffsetCurrent, float lod, PerPixelHeightDisplacementParam param, TEXTURE2D_PARAM(heightTexture, heightSampler))
                                                    {
                                                        return SAMPLE_TEXTURE2D_LOD(heightTexture, heightSampler, param.uv + texOffsetCurrent, lod)[0];
                                                    }
                                                    #define ComputePerPixelHeightDisplacement ComputePerPixelHeightDisplacement_ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3
                                                    #define POM_NAME_ID ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_float
                                                    #define POM_USER_DATA_PARAMETERS , TEXTURE2D_PARAM(heightTexture, samplerState)
                                                    #define POM_USER_DATA_ARGUMENTS , TEXTURE2D_ARGS(heightTexture, samplerState)
                                                    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/PerPixelDisplacement.hlsl"
                                                    #undef ComputePerPixelHeightDisplacement
                                                    #undef POM_NAME_ID
                                                    #undef POM_USER_DATA_PARAMETERS
                                                    #undef POM_USER_DATA_ARGUMENTS

                                                    // Custom interpolators pre vertex
                                                    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                    // Graph Vertex
                                                    struct VertexDescription
                                                    {
                                                        float3 Position;
                                                        float3 Normal;
                                                        float3 Tangent;
                                                    };

                                                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                    {
                                                        VertexDescription description = (VertexDescription)0;
                                                        description.Position = IN.ObjectSpacePosition;
                                                        description.Normal = IN.ObjectSpaceNormal;
                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                        return description;
                                                    }

                                                    // Custom interpolators, pre surface
                                                    #ifdef FEATURES_GRAPH_VERTEX
                                                    Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                    {
                                                    return output;
                                                    }
                                                    #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                    #endif

                                                    // Graph Pixel
                                                    struct SurfaceDescription
                                                    {
                                                        float3 BaseColor;
                                                        float3 Emission;
                                                    };

                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                    {
                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        UnityTexture2D _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        UnityTexture2D _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0 = UnityBuildTexture2DStructNoScale(_HeightMap);
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        float _Property_34ae852606aa456da62721e7b3551266_Out_0 = _ParallaxAmplitude;
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        float _Property_f332b51593bd40da96cf2008daba83bd_Out_0 = _ParallaxSteps;
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        float2 _Swizzle_ee146d512bf7434e89535d4eb2393221_Out_1 = IN.WorldSpacePosition.xz;
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        float2 _Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2;
                                                        Unity_Multiply_float2_float2(_Swizzle_ee146d512bf7434e89535d4eb2393221_Out_1, float2(-1, -1), _Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2);
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        float _Property_3f60dffb796f4c4983fdc65d72109eba_Out_0 = _TextureScale;
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        float2 _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2;
                                                        Unity_Multiply_float2_float2(_Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2, (_Property_3f60dffb796f4c4983fdc65d72109eba_Out_0.xx), _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2);
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        float _Property_b40967aecd8a44539f17591fc9186718_Out_0 = _ParallaxLOD;
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        float _Property_9f91aa59b0df4e95b57576af55b4cdb3_Out_0 = _ParallaxLODThreshold;
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)

                                                        float3 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir = IN.TangentSpaceViewDirection * GetDisplacementObjectScale_float().xzy;
                                                        float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_NdotV = ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.z;
                                                        float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight = _Property_34ae852606aa456da62721e7b3551266_Out_0 * 0.01; // cm in the interface so we multiply by 0.01 in the shader to convert in meter
                                                        ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight *= 2.0 / (abs(float2 (1, 1).x) + abs(float2 (1, 1).y)); // reduce height based on the tiling values

                                                        float2 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVSpaceScale = ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight * float2 (1, 1) / float2 (1, 1);

                                                        // Transform the view vector into the UV space.
                                                        float3 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDirUV = normalize(float3(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.xy * ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVSpaceScale, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.z)); // TODO: skip normalize

                                                        PerPixelHeightDisplacementParam ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM;

                                                        float2 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs = _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2 * float2 (1, 1) + float2 (0, 0);

                                                        ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM.uv = _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.GetTransformedUV(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs);

                                                        float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight;
                                                        float2 _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ParallaxUVs_1 = _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.GetTransformedUV(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs) + ParallaxOcclusionMappingParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_float(_Property_b40967aecd8a44539f17591fc9186718_Out_0, _Property_9f91aa59b0df4e95b57576af55b4cdb3_Out_0, max(min(_Property_f332b51593bd40da96cf2008daba83bd_Out_0, 256), 1), ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDirUV, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight, TEXTURE2D_ARGS(_Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.tex, UnityBuildSamplerStateStruct(SamplerState_Linear_Repeat).samplerstate));

                                                        float _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_PixelDepthOffset_0 = (ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight - ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight * ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight) / max(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_NdotV, 0.0001);
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        #if defined(_PARALLAX)
                                                        float2 _Parallax_c43cb4da16e14208b6c7e14870968070_Out_0 = _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ParallaxUVs_1;
                                                        #else
                                                        float2 _Parallax_c43cb4da16e14208b6c7e14870968070_Out_0 = _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2;
                                                        #endif
                                                        #endif
                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        float4 _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0 = SAMPLE_TEXTURE2D(_Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.tex, _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.samplerstate, _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.GetTransformedUV(_Parallax_c43cb4da16e14208b6c7e14870968070_Out_0));
                                                        float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_R_4 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.r;
                                                        float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_G_5 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.g;
                                                        float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_B_6 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.b;
                                                        float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_A_7 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.a;
                                                        #endif
                                                        surface.BaseColor = (_SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.xyz);
                                                        surface.Emission = float3(0, 0, 0);
                                                        return surface;
                                                    }

                                                    // --------------------------------------------------
                                                    // Build Graph Inputs
                                                    #ifdef HAVE_VFX_MODIFICATION
                                                    #define VFX_SRP_ATTRIBUTES Attributes
                                                    #define VFX_SRP_VARYINGS Varyings
                                                    #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                    #endif
                                                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                    {
                                                        VertexDescriptionInputs output;
                                                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    output.ObjectSpaceNormal = input.normalOS;
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    output.ObjectSpacePosition = input.positionOS;
                                                    #endif


                                                        return output;
                                                    }
                                                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                    {
                                                        SurfaceDescriptionInputs output;
                                                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                    #ifdef HAVE_VFX_MODIFICATION
                                                        // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                        /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                    #endif



                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    float3 unnormalizedNormalWS = input.normalWS;
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                                                    #endif


                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    // use bitangent on the fly like in hdrp
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
                                                    #endif


                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
                                                    #endif


                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    output.WorldSpaceBiTangent = renormFactor * bitang;
                                                    #endif


                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    output.WorldSpaceViewDirection = GetWorldSpaceNormalizeViewDir(input.positionWS);
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    float3x3 tangentSpaceTransform = float3x3(output.WorldSpaceTangent, output.WorldSpaceBiTangent, output.WorldSpaceNormal);
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    output.TangentSpaceViewDirection = mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                                                    #endif

                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                    output.WorldSpacePosition = input.positionWS;
                                                    #endif


                                                        #if UNITY_UV_STARTS_AT_TOP
                                                        #else
                                                        #endif


                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                    #else
                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                    #endif
                                                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                            return output;
                                                    }

                                                    // --------------------------------------------------
                                                    // Main

                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

                                                    // --------------------------------------------------
                                                    // Visual Effect Vertex Invocations
                                                    #ifdef HAVE_VFX_MODIFICATION
                                                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                    #endif

                                                    ENDHLSL
                                                    }
                                                    Pass
                                                    {
                                                        Name "SceneSelectionPass"
                                                        Tags
                                                        {
                                                            "LightMode" = "SceneSelectionPass"
                                                        }

                                                        // Render State
                                                        Cull Off

                                                        // Debug
                                                        // <None>

                                                        // --------------------------------------------------
                                                        // Pass

                                                        HLSLPROGRAM

                                                        // Pragmas
                                                        #pragma target 4.5
                                                        #pragma exclude_renderers gles gles3 glcore
                                                        #pragma multi_compile _ DOTS_INSTANCING_ON
                                                        #pragma vertex vert
                                                        #pragma fragment frag

                                                        // Keywords
                                                        // PassKeywords: <None>
                                                        #pragma shader_feature_local _ _PARALLAX

                                                        #if defined(_PARALLAX)
                                                            #define KEYWORD_PERMUTATION_0
                                                        #else
                                                            #define KEYWORD_PERMUTATION_1
                                                        #endif


                                                        // Defines

                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        #define _NORMALMAP 1
                                                        #endif

                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        #define _NORMAL_DROPOFF_TS 1
                                                        #endif

                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        #define ATTRIBUTES_NEED_NORMAL
                                                        #endif

                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        #define ATTRIBUTES_NEED_TANGENT
                                                        #endif

                                                        #define FEATURES_GRAPH_VERTEX
                                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                        #define SHADERPASS SHADERPASS_DEPTHONLY
                                                        #define SCENESELECTIONPASS 1
                                                        #define ALPHA_CLIP_THRESHOLD 1
                                                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                        // custom interpolator pre-include
                                                        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                        // Includes
                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                        // --------------------------------------------------
                                                        // Structs and Packing

                                                        // custom interpolators pre packing
                                                        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                        struct Attributes
                                                        {
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             float3 positionOS : POSITION;
                                                            #endif
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             float3 normalOS : NORMAL;
                                                            #endif
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             float4 tangentOS : TANGENT;
                                                            #endif
                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             uint instanceID : INSTANCEID_SEMANTIC;
                                                            #endif
                                                            #endif
                                                        };
                                                        struct Varyings
                                                        {
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             float4 positionCS : SV_POSITION;
                                                            #endif
                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                                            #endif
                                                            #endif
                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                            #endif
                                                            #endif
                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                            #endif
                                                            #endif
                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                            #endif
                                                            #endif
                                                        };
                                                        struct SurfaceDescriptionInputs
                                                        {
                                                        };
                                                        struct VertexDescriptionInputs
                                                        {
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             float3 ObjectSpaceNormal;
                                                            #endif
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             float3 ObjectSpaceTangent;
                                                            #endif
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             float3 ObjectSpacePosition;
                                                            #endif
                                                        };
                                                        struct PackedVaryings
                                                        {
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             float4 positionCS : SV_POSITION;
                                                            #endif
                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                                            #endif
                                                            #endif
                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                            #endif
                                                            #endif
                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                            #endif
                                                            #endif
                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                            #endif
                                                            #endif
                                                        };

                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                        PackedVaryings PackVaryings(Varyings input)
                                                        {
                                                            PackedVaryings output;
                                                            ZERO_INITIALIZE(PackedVaryings, output);
                                                            output.positionCS = input.positionCS;
                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                            output.instanceID = input.instanceID;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                            #endif
                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                            output.cullFace = input.cullFace;
                                                            #endif
                                                            return output;
                                                        }

                                                        Varyings UnpackVaryings(PackedVaryings input)
                                                        {
                                                            Varyings output;
                                                            output.positionCS = input.positionCS;
                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                            output.instanceID = input.instanceID;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                            #endif
                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                            #endif
                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                            output.cullFace = input.cullFace;
                                                            #endif
                                                            return output;
                                                        }
                                                        #endif

                                                        // --------------------------------------------------
                                                        // Graph

                                                        // Graph Properties
                                                        CBUFFER_START(UnityPerMaterial)
                                                        float4 _M_AO_SmoothnessMap_TexelSize;
                                                        float4 _NormalMap_TexelSize;
                                                        float4 _BaseMap_TexelSize;
                                                        float _NormalStrength;
                                                        float _TextureScale;
                                                        float _ParallaxSteps;
                                                        float _ParallaxAmplitude;
                                                        float _ParallaxLOD;
                                                        float _ParallaxLODThreshold;
                                                        float _AOStrength;
                                                        float4 _HeightMap_TexelSize;
                                                        CBUFFER_END

                                                            // Object and Global properties
                                                            SAMPLER(SamplerState_Linear_Repeat);
                                                            TEXTURE2D(_M_AO_SmoothnessMap);
                                                            SAMPLER(sampler_M_AO_SmoothnessMap);
                                                            TEXTURE2D(_NormalMap);
                                                            SAMPLER(sampler_NormalMap);
                                                            TEXTURE2D(_BaseMap);
                                                            SAMPLER(sampler_BaseMap);
                                                            TEXTURE2D(_HeightMap);
                                                            SAMPLER(sampler_HeightMap);

                                                            // Graph Includes
                                                            // GraphIncludes: <None>

                                                            // -- Property used by ScenePickingPass
                                                            #ifdef SCENEPICKINGPASS
                                                            float4 _SelectionID;
                                                            #endif

                                                            // -- Properties used by SceneSelectionPass
                                                            #ifdef SCENESELECTIONPASS
                                                            int _ObjectId;
                                                            int _PassValue;
                                                            #endif

                                                            // Graph Functions
                                                            // GraphFunctions: <None>

                                                            // Custom interpolators pre vertex
                                                            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                            // Graph Vertex
                                                            struct VertexDescription
                                                            {
                                                                float3 Position;
                                                                float3 Normal;
                                                                float3 Tangent;
                                                            };

                                                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                            {
                                                                VertexDescription description = (VertexDescription)0;
                                                                description.Position = IN.ObjectSpacePosition;
                                                                description.Normal = IN.ObjectSpaceNormal;
                                                                description.Tangent = IN.ObjectSpaceTangent;
                                                                return description;
                                                            }

                                                            // Custom interpolators, pre surface
                                                            #ifdef FEATURES_GRAPH_VERTEX
                                                            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                            {
                                                            return output;
                                                            }
                                                            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                            #endif

                                                            // Graph Pixel
                                                            struct SurfaceDescription
                                                            {
                                                            };

                                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                            {
                                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                                return surface;
                                                            }

                                                            // --------------------------------------------------
                                                            // Build Graph Inputs
                                                            #ifdef HAVE_VFX_MODIFICATION
                                                            #define VFX_SRP_ATTRIBUTES Attributes
                                                            #define VFX_SRP_VARYINGS Varyings
                                                            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                            #endif
                                                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                            {
                                                                VertexDescriptionInputs output;
                                                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                            output.ObjectSpaceNormal = input.normalOS;
                                                            #endif

                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                            output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                            #endif

                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                            output.ObjectSpacePosition = input.positionOS;
                                                            #endif


                                                                return output;
                                                            }
                                                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                            {
                                                                SurfaceDescriptionInputs output;
                                                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                            #endif








                                                                #if UNITY_UV_STARTS_AT_TOP
                                                                #else
                                                                #endif


                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                            #else
                                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                            #endif
                                                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                                    return output;
                                                            }

                                                            // --------------------------------------------------
                                                            // Main

                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

                                                            // --------------------------------------------------
                                                            // Visual Effect Vertex Invocations
                                                            #ifdef HAVE_VFX_MODIFICATION
                                                            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                            #endif

                                                            ENDHLSL
                                                            }
                                                            Pass
                                                            {
                                                                Name "ScenePickingPass"
                                                                Tags
                                                                {
                                                                    "LightMode" = "Picking"
                                                                }

                                                                // Render State
                                                                Cull Back

                                                                // Debug
                                                                // <None>

                                                                // --------------------------------------------------
                                                                // Pass

                                                                HLSLPROGRAM

                                                                // Pragmas
                                                                #pragma target 4.5
                                                                #pragma exclude_renderers gles gles3 glcore
                                                                #pragma multi_compile _ DOTS_INSTANCING_ON
                                                                #pragma vertex vert
                                                                #pragma fragment frag

                                                                // Keywords
                                                                // PassKeywords: <None>
                                                                #pragma shader_feature_local _ _PARALLAX

                                                                #if defined(_PARALLAX)
                                                                    #define KEYWORD_PERMUTATION_0
                                                                #else
                                                                    #define KEYWORD_PERMUTATION_1
                                                                #endif


                                                                // Defines

                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                #define _NORMALMAP 1
                                                                #endif

                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                #define _NORMAL_DROPOFF_TS 1
                                                                #endif

                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                #define ATTRIBUTES_NEED_NORMAL
                                                                #endif

                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                #define ATTRIBUTES_NEED_TANGENT
                                                                #endif

                                                                #define FEATURES_GRAPH_VERTEX
                                                                /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                #define SHADERPASS SHADERPASS_DEPTHONLY
                                                                #define SCENEPICKINGPASS 1
                                                                #define ALPHA_CLIP_THRESHOLD 1
                                                                /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                                // custom interpolator pre-include
                                                                /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                                // Includes
                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                                #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                                // --------------------------------------------------
                                                                // Structs and Packing

                                                                // custom interpolators pre packing
                                                                /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                                struct Attributes
                                                                {
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     float3 positionOS : POSITION;
                                                                    #endif
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     float3 normalOS : NORMAL;
                                                                    #endif
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     float4 tangentOS : TANGENT;
                                                                    #endif
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     uint instanceID : INSTANCEID_SEMANTIC;
                                                                    #endif
                                                                    #endif
                                                                };
                                                                struct Varyings
                                                                {
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     float4 positionCS : SV_POSITION;
                                                                    #endif
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                                    #endif
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                    #endif
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                    #endif
                                                                    #endif
                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                    #endif
                                                                    #endif
                                                                };
                                                                struct SurfaceDescriptionInputs
                                                                {
                                                                };
                                                                struct VertexDescriptionInputs
                                                                {
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     float3 ObjectSpaceNormal;
                                                                    #endif
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     float3 ObjectSpaceTangent;
                                                                    #endif
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     float3 ObjectSpacePosition;
                                                                    #endif
                                                                };
                                                                struct PackedVaryings
                                                                {
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     float4 positionCS : SV_POSITION;
                                                                    #endif
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     uint instanceID : CUSTOM_INSTANCE_ID;
                                                                    #endif
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                    #endif
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                    #endif
                                                                    #endif
                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                     FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                    #endif
                                                                    #endif
                                                                };

                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                PackedVaryings PackVaryings(Varyings input)
                                                                {
                                                                    PackedVaryings output;
                                                                    ZERO_INITIALIZE(PackedVaryings, output);
                                                                    output.positionCS = input.positionCS;
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                    output.instanceID = input.instanceID;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                    #endif
                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                    output.cullFace = input.cullFace;
                                                                    #endif
                                                                    return output;
                                                                }

                                                                Varyings UnpackVaryings(PackedVaryings input)
                                                                {
                                                                    Varyings output;
                                                                    output.positionCS = input.positionCS;
                                                                    #if UNITY_ANY_INSTANCING_ENABLED
                                                                    output.instanceID = input.instanceID;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                    #endif
                                                                    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                    #endif
                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                    output.cullFace = input.cullFace;
                                                                    #endif
                                                                    return output;
                                                                }
                                                                #endif

                                                                // --------------------------------------------------
                                                                // Graph

                                                                // Graph Properties
                                                                CBUFFER_START(UnityPerMaterial)
                                                                float4 _M_AO_SmoothnessMap_TexelSize;
                                                                float4 _NormalMap_TexelSize;
                                                                float4 _BaseMap_TexelSize;
                                                                float _NormalStrength;
                                                                float _TextureScale;
                                                                float _ParallaxSteps;
                                                                float _ParallaxAmplitude;
                                                                float _ParallaxLOD;
                                                                float _ParallaxLODThreshold;
                                                                float _AOStrength;
                                                                float4 _HeightMap_TexelSize;
                                                                CBUFFER_END

                                                                    // Object and Global properties
                                                                    SAMPLER(SamplerState_Linear_Repeat);
                                                                    TEXTURE2D(_M_AO_SmoothnessMap);
                                                                    SAMPLER(sampler_M_AO_SmoothnessMap);
                                                                    TEXTURE2D(_NormalMap);
                                                                    SAMPLER(sampler_NormalMap);
                                                                    TEXTURE2D(_BaseMap);
                                                                    SAMPLER(sampler_BaseMap);
                                                                    TEXTURE2D(_HeightMap);
                                                                    SAMPLER(sampler_HeightMap);

                                                                    // Graph Includes
                                                                    // GraphIncludes: <None>

                                                                    // -- Property used by ScenePickingPass
                                                                    #ifdef SCENEPICKINGPASS
                                                                    float4 _SelectionID;
                                                                    #endif

                                                                    // -- Properties used by SceneSelectionPass
                                                                    #ifdef SCENESELECTIONPASS
                                                                    int _ObjectId;
                                                                    int _PassValue;
                                                                    #endif

                                                                    // Graph Functions
                                                                    // GraphFunctions: <None>

                                                                    // Custom interpolators pre vertex
                                                                    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                                    // Graph Vertex
                                                                    struct VertexDescription
                                                                    {
                                                                        float3 Position;
                                                                        float3 Normal;
                                                                        float3 Tangent;
                                                                    };

                                                                    VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                                    {
                                                                        VertexDescription description = (VertexDescription)0;
                                                                        description.Position = IN.ObjectSpacePosition;
                                                                        description.Normal = IN.ObjectSpaceNormal;
                                                                        description.Tangent = IN.ObjectSpaceTangent;
                                                                        return description;
                                                                    }

                                                                    // Custom interpolators, pre surface
                                                                    #ifdef FEATURES_GRAPH_VERTEX
                                                                    Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                                    {
                                                                    return output;
                                                                    }
                                                                    #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                                    #endif

                                                                    // Graph Pixel
                                                                    struct SurfaceDescription
                                                                    {
                                                                    };

                                                                    SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                    {
                                                                        SurfaceDescription surface = (SurfaceDescription)0;
                                                                        return surface;
                                                                    }

                                                                    // --------------------------------------------------
                                                                    // Build Graph Inputs
                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                    #define VFX_SRP_ATTRIBUTES Attributes
                                                                    #define VFX_SRP_VARYINGS Varyings
                                                                    #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                                    #endif
                                                                    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                                    {
                                                                        VertexDescriptionInputs output;
                                                                        ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                    output.ObjectSpaceNormal = input.normalOS;
                                                                    #endif

                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                    output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                                    #endif

                                                                    #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                    output.ObjectSpacePosition = input.positionOS;
                                                                    #endif


                                                                        return output;
                                                                    }
                                                                    SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                                    {
                                                                        SurfaceDescriptionInputs output;
                                                                        ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                        // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                                        /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                                    #endif








                                                                        #if UNITY_UV_STARTS_AT_TOP
                                                                        #else
                                                                        #endif


                                                                    #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                                    #else
                                                                    #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                                    #endif
                                                                    #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                                            return output;
                                                                    }

                                                                    // --------------------------------------------------
                                                                    // Main

                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                                    #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

                                                                    // --------------------------------------------------
                                                                    // Visual Effect Vertex Invocations
                                                                    #ifdef HAVE_VFX_MODIFICATION
                                                                    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                                    #endif

                                                                    ENDHLSL
                                                                    }
                                                                    Pass
                                                                    {
                                                                        // Name: <None>
                                                                        Tags
                                                                        {
                                                                            "LightMode" = "Universal2D"
                                                                        }

                                                                        // Render State
                                                                        Cull Back
                                                                        Blend One Zero
                                                                        ZTest LEqual
                                                                        ZWrite On

                                                                        // Debug
                                                                        // <None>

                                                                        // --------------------------------------------------
                                                                        // Pass

                                                                        HLSLPROGRAM

                                                                        // Pragmas
                                                                        #pragma target 4.5
                                                                        #pragma exclude_renderers gles gles3 glcore
                                                                        #pragma multi_compile _ DOTS_INSTANCING_ON
                                                                        #pragma vertex vert
                                                                        #pragma fragment frag

                                                                        // Keywords
                                                                        // PassKeywords: <None>
                                                                        #pragma shader_feature_local _ _PARALLAX

                                                                        #if defined(_PARALLAX)
                                                                            #define KEYWORD_PERMUTATION_0
                                                                        #else
                                                                            #define KEYWORD_PERMUTATION_1
                                                                        #endif


                                                                        // Defines

                                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                        #define _NORMALMAP 1
                                                                        #endif

                                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                        #define _NORMAL_DROPOFF_TS 1
                                                                        #endif

                                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                        #define ATTRIBUTES_NEED_NORMAL
                                                                        #endif

                                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                        #define ATTRIBUTES_NEED_TANGENT
                                                                        #endif

                                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                        #define VARYINGS_NEED_POSITION_WS
                                                                        #endif

                                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                        #define VARYINGS_NEED_NORMAL_WS
                                                                        #endif

                                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                        #define VARYINGS_NEED_TANGENT_WS
                                                                        #endif

                                                                        #define FEATURES_GRAPH_VERTEX
                                                                        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
                                                                        #define SHADERPASS SHADERPASS_2D
                                                                        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */


                                                                        // custom interpolator pre-include
                                                                        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */

                                                                        // Includes
                                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
                                                                        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

                                                                        // --------------------------------------------------
                                                                        // Structs and Packing

                                                                        // custom interpolators pre packing
                                                                        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */

                                                                        struct Attributes
                                                                        {
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 positionOS : POSITION;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 normalOS : NORMAL;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float4 tangentOS : TANGENT;
                                                                            #endif
                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             uint instanceID : INSTANCEID_SEMANTIC;
                                                                            #endif
                                                                            #endif
                                                                        };
                                                                        struct Varyings
                                                                        {
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float4 positionCS : SV_POSITION;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 positionWS;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 normalWS;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float4 tangentWS;
                                                                            #endif
                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                                                            #endif
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                            #endif
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                            #endif
                                                                            #endif
                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                            #endif
                                                                            #endif
                                                                        };
                                                                        struct SurfaceDescriptionInputs
                                                                        {
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 WorldSpaceNormal;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 WorldSpaceTangent;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 WorldSpaceBiTangent;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 WorldSpaceViewDirection;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 TangentSpaceViewDirection;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 WorldSpacePosition;
                                                                            #endif
                                                                        };
                                                                        struct VertexDescriptionInputs
                                                                        {
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 ObjectSpaceNormal;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 ObjectSpaceTangent;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 ObjectSpacePosition;
                                                                            #endif
                                                                        };
                                                                        struct PackedVaryings
                                                                        {
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float4 positionCS : SV_POSITION;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 interp0 : INTERP0;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float3 interp1 : INTERP1;
                                                                            #endif
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             float4 interp2 : INTERP2;
                                                                            #endif
                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             uint instanceID : CUSTOM_INSTANCE_ID;
                                                                            #endif
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                                                                            #endif
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                                                                            #endif
                                                                            #endif
                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
                                                                            #endif
                                                                            #endif
                                                                        };

                                                                        #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                        PackedVaryings PackVaryings(Varyings input)
                                                                        {
                                                                            PackedVaryings output;
                                                                            ZERO_INITIALIZE(PackedVaryings, output);
                                                                            output.positionCS = input.positionCS;
                                                                            output.interp0.xyz = input.positionWS;
                                                                            output.interp1.xyz = input.normalWS;
                                                                            output.interp2.xyzw = input.tangentWS;
                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                            output.instanceID = input.instanceID;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                            #endif
                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                            output.cullFace = input.cullFace;
                                                                            #endif
                                                                            return output;
                                                                        }

                                                                        Varyings UnpackVaryings(PackedVaryings input)
                                                                        {
                                                                            Varyings output;
                                                                            output.positionCS = input.positionCS;
                                                                            output.positionWS = input.interp0.xyz;
                                                                            output.normalWS = input.interp1.xyz;
                                                                            output.tangentWS = input.interp2.xyzw;
                                                                            #if UNITY_ANY_INSTANCING_ENABLED
                                                                            output.instanceID = input.instanceID;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                                                                            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                                                                            #endif
                                                                            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                                                                            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                                                                            #endif
                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                            output.cullFace = input.cullFace;
                                                                            #endif
                                                                            return output;
                                                                        }
                                                                        #endif

                                                                        // --------------------------------------------------
                                                                        // Graph

                                                                        // Graph Properties
                                                                        CBUFFER_START(UnityPerMaterial)
                                                                        float4 _M_AO_SmoothnessMap_TexelSize;
                                                                        float4 _NormalMap_TexelSize;
                                                                        float4 _BaseMap_TexelSize;
                                                                        float _NormalStrength;
                                                                        float _TextureScale;
                                                                        float _ParallaxSteps;
                                                                        float _ParallaxAmplitude;
                                                                        float _ParallaxLOD;
                                                                        float _ParallaxLODThreshold;
                                                                        float _AOStrength;
                                                                        float4 _HeightMap_TexelSize;
                                                                        CBUFFER_END

                                                                            // Object and Global properties
                                                                            SAMPLER(SamplerState_Linear_Repeat);
                                                                            TEXTURE2D(_M_AO_SmoothnessMap);
                                                                            SAMPLER(sampler_M_AO_SmoothnessMap);
                                                                            TEXTURE2D(_NormalMap);
                                                                            SAMPLER(sampler_NormalMap);
                                                                            TEXTURE2D(_BaseMap);
                                                                            SAMPLER(sampler_BaseMap);
                                                                            TEXTURE2D(_HeightMap);
                                                                            SAMPLER(sampler_HeightMap);

                                                                            // Graph Includes
                                                                            // GraphIncludes: <None>

                                                                            // -- Property used by ScenePickingPass
                                                                            #ifdef SCENEPICKINGPASS
                                                                            float4 _SelectionID;
                                                                            #endif

                                                                            // -- Properties used by SceneSelectionPass
                                                                            #ifdef SCENESELECTIONPASS
                                                                            int _ObjectId;
                                                                            int _PassValue;
                                                                            #endif

                                                                            // Graph Functions

                                                                            void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
                                                                            {
                                                                                Out = A * B;
                                                                            }

                                                                            struct PerPixelHeightDisplacementParam
                                                                            {
                                                                                float2 uv;
                                                                            };


                                                                            float3 GetDisplacementObjectScale_float()
                                                                            {

                                                                                float3 objectScale = float3(1.0, 1.0, 1.0);
                                                                                float4x4 worldTransform = GetWorldToObjectMatrix();

                                                                                objectScale.x = length(float3(worldTransform._m00, worldTransform._m01, worldTransform._m02));
                                                                                objectScale.z = length(float3(worldTransform._m20, worldTransform._m21, worldTransform._m22));

                                                                                return objectScale;
                                                                            }

                                                                            // Required struct and function for the ParallaxOcclusionMapping function:
                                                                            float ComputePerPixelHeightDisplacement_ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3(float2 texOffsetCurrent, float lod, PerPixelHeightDisplacementParam param, TEXTURE2D_PARAM(heightTexture, heightSampler))
                                                                            {
                                                                                return SAMPLE_TEXTURE2D_LOD(heightTexture, heightSampler, param.uv + texOffsetCurrent, lod)[0];
                                                                            }
                                                                            #define ComputePerPixelHeightDisplacement ComputePerPixelHeightDisplacement_ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3
                                                                            #define POM_NAME_ID ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_float
                                                                            #define POM_USER_DATA_PARAMETERS , TEXTURE2D_PARAM(heightTexture, samplerState)
                                                                            #define POM_USER_DATA_ARGUMENTS , TEXTURE2D_ARGS(heightTexture, samplerState)
                                                                            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/PerPixelDisplacement.hlsl"
                                                                            #undef ComputePerPixelHeightDisplacement
                                                                            #undef POM_NAME_ID
                                                                            #undef POM_USER_DATA_PARAMETERS
                                                                            #undef POM_USER_DATA_ARGUMENTS

                                                                            // Custom interpolators pre vertex
                                                                            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

                                                                            // Graph Vertex
                                                                            struct VertexDescription
                                                                            {
                                                                                float3 Position;
                                                                                float3 Normal;
                                                                                float3 Tangent;
                                                                            };

                                                                            VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
                                                                            {
                                                                                VertexDescription description = (VertexDescription)0;
                                                                                description.Position = IN.ObjectSpacePosition;
                                                                                description.Normal = IN.ObjectSpaceNormal;
                                                                                description.Tangent = IN.ObjectSpaceTangent;
                                                                                return description;
                                                                            }

                                                                            // Custom interpolators, pre surface
                                                                            #ifdef FEATURES_GRAPH_VERTEX
                                                                            Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
                                                                            {
                                                                            return output;
                                                                            }
                                                                            #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
                                                                            #endif

                                                                            // Graph Pixel
                                                                            struct SurfaceDescription
                                                                            {
                                                                                float3 BaseColor;
                                                                            };

                                                                            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
                                                                            {
                                                                                SurfaceDescription surface = (SurfaceDescription)0;
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                UnityTexture2D _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0 = UnityBuildTexture2DStructNoScale(_BaseMap);
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                UnityTexture2D _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0 = UnityBuildTexture2DStructNoScale(_HeightMap);
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                float _Property_34ae852606aa456da62721e7b3551266_Out_0 = _ParallaxAmplitude;
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                float _Property_f332b51593bd40da96cf2008daba83bd_Out_0 = _ParallaxSteps;
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                float2 _Swizzle_ee146d512bf7434e89535d4eb2393221_Out_1 = IN.WorldSpacePosition.xz;
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                float2 _Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2;
                                                                                Unity_Multiply_float2_float2(_Swizzle_ee146d512bf7434e89535d4eb2393221_Out_1, float2(-1, -1), _Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2);
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                float _Property_3f60dffb796f4c4983fdc65d72109eba_Out_0 = _TextureScale;
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                float2 _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2;
                                                                                Unity_Multiply_float2_float2(_Multiply_f6dabdef430742aa8a0371067299c6b5_Out_2, (_Property_3f60dffb796f4c4983fdc65d72109eba_Out_0.xx), _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2);
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                float _Property_b40967aecd8a44539f17591fc9186718_Out_0 = _ParallaxLOD;
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                float _Property_9f91aa59b0df4e95b57576af55b4cdb3_Out_0 = _ParallaxLODThreshold;
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)

                                                                                float3 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir = IN.TangentSpaceViewDirection * GetDisplacementObjectScale_float().xzy;
                                                                                float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_NdotV = ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.z;
                                                                                float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight = _Property_34ae852606aa456da62721e7b3551266_Out_0 * 0.01; // cm in the interface so we multiply by 0.01 in the shader to convert in meter
                                                                                ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight *= 2.0 / (abs(float2 (1, 1).x) + abs(float2 (1, 1).y)); // reduce height based on the tiling values

                                                                                float2 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVSpaceScale = ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight * float2 (1, 1) / float2 (1, 1);

                                                                                // Transform the view vector into the UV space.
                                                                                float3 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDirUV = normalize(float3(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.xy * ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVSpaceScale, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDir.z)); // TODO: skip normalize

                                                                                PerPixelHeightDisplacementParam ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM;

                                                                                float2 ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs = _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2 * float2 (1, 1) + float2 (0, 0);

                                                                                ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM.uv = _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.GetTransformedUV(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs);

                                                                                float ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight;
                                                                                float2 _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ParallaxUVs_1 = _Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.GetTransformedUV(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_UVs) + ParallaxOcclusionMappingParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_float(_Property_b40967aecd8a44539f17591fc9186718_Out_0, _Property_9f91aa59b0df4e95b57576af55b4cdb3_Out_0, max(min(_Property_f332b51593bd40da96cf2008daba83bd_Out_0, 256), 1), ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ViewDirUV, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_POM, ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight, TEXTURE2D_ARGS(_Property_d36f28a4156240cda7fb3c9cf1c1bcdc_Out_0.tex, UnityBuildSamplerStateStruct(SamplerState_Linear_Repeat).samplerstate));

                                                                                float _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_PixelDepthOffset_0 = (ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight - ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_OutHeight * ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_MaxHeight) / max(ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_NdotV, 0.0001);
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                #if defined(_PARALLAX)
                                                                                float2 _Parallax_c43cb4da16e14208b6c7e14870968070_Out_0 = _ParallaxOcclusionMapping_29edfcc3861c48ce9dd09bf24be5c9c3_ParallaxUVs_1;
                                                                                #else
                                                                                float2 _Parallax_c43cb4da16e14208b6c7e14870968070_Out_0 = _Multiply_8eaf0fd14d154ffdbbf737e4f37d8bc6_Out_2;
                                                                                #endif
                                                                                #endif
                                                                                #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                                float4 _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0 = SAMPLE_TEXTURE2D(_Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.tex, _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.samplerstate, _Property_b766e72e9df249c4a3c63551b8318aa0_Out_0.GetTransformedUV(_Parallax_c43cb4da16e14208b6c7e14870968070_Out_0));
                                                                                float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_R_4 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.r;
                                                                                float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_G_5 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.g;
                                                                                float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_B_6 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.b;
                                                                                float _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_A_7 = _SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.a;
                                                                                #endif
                                                                                surface.BaseColor = (_SampleTexture2D_c1f15f1d446447e5a19ae2a574eed858_RGBA_0.xyz);
                                                                                return surface;
                                                                            }

                                                                            // --------------------------------------------------
                                                                            // Build Graph Inputs
                                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                            #define VFX_SRP_ATTRIBUTES Attributes
                                                                            #define VFX_SRP_VARYINGS Varyings
                                                                            #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
                                                                            #endif
                                                                            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
                                                                            {
                                                                                VertexDescriptionInputs output;
                                                                                ZERO_INITIALIZE(VertexDescriptionInputs, output);

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            output.ObjectSpaceNormal = input.normalOS;
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            output.ObjectSpaceTangent = input.tangentOS.xyz;
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            output.ObjectSpacePosition = input.positionOS;
                                                                            #endif


                                                                                return output;
                                                                            }
                                                                            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
                                                                            {
                                                                                SurfaceDescriptionInputs output;
                                                                                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

                                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                                // FragInputs from VFX come from two places: Interpolator or CBuffer.
                                                                                /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */

                                                                            #endif



                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            float3 unnormalizedNormalWS = input.normalWS;
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
                                                                            #endif


                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            // use bitangent on the fly like in hdrp
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);
                                                                            #endif


                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
                                                                            #endif


                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            // to pr               eserve mikktspace compliance we use same scale renormFactor as was used on the normal.
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            // This                is explained in section 2.2 in "surface gradient based bump mapping framework"
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            output.WorldSpaceTangent = renormFactor * input.tangentWS.xyz;
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            output.WorldSpaceBiTangent = renormFactor * bitang;
                                                                            #endif


                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            output.WorldSpaceViewDirection = GetWorldSpaceNormalizeViewDir(input.positionWS);
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            float3x3 tangentSpaceTransform = float3x3(output.WorldSpaceTangent, output.WorldSpaceBiTangent, output.WorldSpaceNormal);
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            output.TangentSpaceViewDirection = mul(tangentSpaceTransform, output.WorldSpaceViewDirection);
                                                                            #endif

                                                                            #if defined(KEYWORD_PERMUTATION_0) || defined(KEYWORD_PERMUTATION_1)
                                                                            output.WorldSpacePosition = input.positionWS;
                                                                            #endif


                                                                                #if UNITY_UV_STARTS_AT_TOP
                                                                                #else
                                                                                #endif


                                                                            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
                                                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
                                                                            #else
                                                                            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
                                                                            #endif
                                                                            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

                                                                                    return output;
                                                                            }

                                                                            // --------------------------------------------------
                                                                            // Main

                                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
                                                                            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

                                                                            // --------------------------------------------------
                                                                            // Visual Effect Vertex Invocations
                                                                            #ifdef HAVE_VFX_MODIFICATION
                                                                            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
                                                                            #endif

                                                                            ENDHLSL
                                                                            }
    }

                                                                                CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
                                                                                                                                                CustomEditorForRenderPipeline "UnityEditor.ShaderGraphLitGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
                                                                                                                                                FallBack "Hidden/Shader Graph/FallbackError"
}