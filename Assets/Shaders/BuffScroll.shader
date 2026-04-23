Shader "Unlit/BuffScroll"

{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "black" {}

        [HDR] _Color("Color", Color) = (1,1,1,1)

        _SpeedScroll("Main Scroll Speed", Vector) = (0, 0, 0, 0)
        _NoiseSpeed("Noise Scroll Speed", Vector) = (0, 0, 0, 0)

        _DistortionStrength("Distortion Strength", Float) = 0.1

        [Header(Blend State)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DestBlend", Float) = 0
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            Blend [_SrcBlend] [_DstBlend]
            ZWrite Off
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            float4 _MainTex_ST;
            float4 _NoiseTex_ST;

            float4 _Color;

            float2 _SpeedScroll;
            float2 _NoiseSpeed;

            float _DistortionStrength;

            Varyings vert (Attributes v)
            {
                Varyings o;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                half2 uv = TRANSFORM_TEX(v.uv, _MainTex);

                uv += _Time.y * _SpeedScroll;

                o.uv = uv;

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half2 noiseUV = i.uv + _Time.y * _NoiseSpeed;
                half noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;

                noise = noise * 2.0 - 1.0;

                half2 distortedUV = i.uv + noise * _DistortionStrength;

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, distortedUV);

                col *= _Color;

                return col;
            }

            ENDHLSL
        }
    }
}
