Shader "Unlit/WorldBillboardShader"
{
        Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _Fill("Fill", Float) = 0
        _ScaleX("Scale X", Float) = 1.0
        _ScaleY("Scale Y", Float) = 1.0
    }

    SubShader
    {
        Tags { "Queue"="Overlay" "RenderType"="Transparent" }

        Pass
        {
            ZTest Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float _Fill;
                float _ScaleX;
                float _ScaleY;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o;

                float3 worldScale = float3(
                    length(UNITY_MATRIX_M._m00_m01_m02),
                    length(UNITY_MATRIX_M._m10_m11_m12),
                    length(UNITY_MATRIX_M._m20_m21_m22)
                );

                float4 centerVS = mul(UNITY_MATRIX_MV, float4(0,0,0,1));

                float4 offset = float4(
                    v.positionOS.x * worldScale.x * _ScaleX,
                    v.positionOS.y * worldScale.y * _ScaleY,
                    0.0,
                    0.0
                );

                float4 posVS = centerVS + offset;

                o.positionHCS = mul(UNITY_MATRIX_P, posVS);
                o.uv = v.uv;

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float2 uv = float2(i.uv);
                half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;

                return half4(color, 1);
            }

            ENDHLSL
        }
    }
}
