Shader "Unlit/OculusMotionVectorDebugShader"
{
    Properties
    {
        _MainTex ("Texture", 2DArray) = "white" {}
        _MinValue ("Min Value", Float) = 0
        _MaxValue ("Max Value", Float) = 1
        [Toggle] _OnlyRed ("Only Red", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma require 2darray
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            UNITY_DECLARE_TEX2DARRAY(_MainTex);

            float _MinValue;
            float _MaxValue;
            float _OnlyRed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = float2(v.uv.x, 1 - v.uv.y);
                return o;
            }

            float3 inv_lerp(const float from, const float to, const float3 value){
              return (value - from) / (to - from);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float3 col = UNITY_SAMPLE_TEX2DARRAY(_MainTex, float3(i.uv, 0)).rgb;

                if (_OnlyRed == 1.0)
                {
                    col.gb = col.rr;
                }

                // Map to the specified range
                col = inv_lerp(_MinValue, _MaxValue, col);

                return float4(col, 1);
            }
            ENDCG
        }
    }
}
