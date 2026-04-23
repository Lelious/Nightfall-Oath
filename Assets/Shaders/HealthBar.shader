Shader "Unlit/HealthBar"
{
    Properties
    {
        _NoiseTex ("NoiseTex", 2D) = "gray" {}

        _Fill ("HP Fill", Range(0,1)) = 1
        _HealFill ("Heal Fill", Range(0,1)) = 0

        _NoiseScale ("Noise Scale", Float) = 4
        _NoiseSpeed ("Noise Speed", Float) = 1
        _NoiseStrength ("Noise Strength", Float) = 0.02

        _EdgeColor ("Edge Color", Color) = (1,1,1,1)
        _EdgeWidth ("Edge Width", Float) = 0.02
        _EdgeIntensity ("Edge Intensity", Float) = 1

        _LowHPThreshold ("Low HP Threshold", Range(0,1)) = 0.3
        _PulseSpeed ("Pulse Speed", Float) = 4
        _PulseIntensity ("Pulse Intensity", Float) = 0.3

        _HealAlpha ("Heal Alpha", Range(0,1)) = 0.6
        _Fuck("Fuck", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalPipeline"
            "IgnoreProjector"="True"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                half4 color : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
                float _Fill;
                float _HealFill;

                float _NoiseScale;
                float _NoiseSpeed;
                float _NoiseStrength;
                float _NoiseOffset;

                float4 _EdgeColor;
                float _EdgeWidth;
                float _EdgeIntensity;

                float _LowHPThreshold;
                float _PulseSpeed;
                float _PulseIntensity;

                float _HealAlpha;
                half _Fuck;
            CBUFFER_END

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);

            Varyings vert (Attributes v)
            {
                Varyings o;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                o.color = v.color;

                return o;
            }

            half4 frag (Varyings i) : SV_Target 
            { 
                half2 uv = i.uv; 
                half2 centeredUV = uv * 2.0 - 1.0; 
                half dist = length(centeredUV); 
                half circleMask = step(dist, 1.0); 

                half2 noiseUV = uv * _NoiseScale + _Time.y * _NoiseSpeed + _NoiseOffset;
                half noiseSample = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r; 
                half noise = (noiseSample - 0.5) * _NoiseStrength;  
                half distFromTop = _Fill - uv.y;
                half noiseFade = saturate(distFromTop / 0.05);
                half bottomSafe = saturate(uv.y * 10.0);
                half noiseOffset = noise * noiseFade * bottomSafe;
                half contrastedNoise = pow(noiseSample, _Fuck);
                half hpMask = step(uv.y, _Fill) * circleMask;
                half healTop = _Fill + _HealFill; 
                half healMask = step(_Fill, uv.y) * step(uv.y, healTop) > _Fill; 
                half emptyMask = hpMask > healMask ? 1 - hpMask : 1 - healMask; 
                half4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv); 
                half lowHP = step(_Fill, _LowHPThreshold); 
                half pulse = sin(_Time.y * _PulseSpeed) * 0.5 + 0.5; 
                half hpPulse = 1.0 + pulse * _PulseIntensity * step(_Fill, _LowHPThreshold) * hpMask; 

                half4 hpCol = baseCol * i.color; 
                hpCol.a *= hpMask * circleMask; 
                hpCol.rgb *= hpPulse; 
                half noiseVisual = lerp(0.1, 1.8, contrastedNoise); 
                hpCol.rgb *= noiseVisual;

                half4 healCol = baseCol * i.color; 
                half alpha = _HealAlpha * healMask * circleMask;
                healCol = baseCol * i.color;
                healCol.a = alpha;

                half centerFactor = saturate(1.0 - abs(centeredUV.x)); 
                half curvedEdgeWidth = _EdgeWidth * lerp(0.4, 1.2, centerFactor); 
                half4 emptyColor = baseCol * emptyMask; 
                emptyColor.a = 0.05f * circleMask; 
                half edge = smoothstep(_Fill - curvedEdgeWidth, _Fill, uv.y + noiseOffset); 
                half3 edgeColor = _EdgeColor.rgb * edge * _EdgeIntensity * hpMask; 

                half4 col = hpCol + healCol; 
                col.rgb += edgeColor; 
                col += emptyColor; 
                col.a = saturate(col.a); 

                return col; 
            }
            ENDHLSL
        }
    }
}
