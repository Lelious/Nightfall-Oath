Shader "Unlit/SimpleLightShader"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _HeightMap ("Height Map", 2D) = "black" {}
        _AORoughnessMetallicMap ("AO(R) Rough(G) Metal(B)", 2D) = "white" {}
        _DissolveTex ("DissolveTex", 2D) = "black" {}
        _MatcapTex ("MatcapTex", 2D) = "black" {}

        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _NormalStrength ("Normal Strength", Range(0,2)) = 1
        _HeightScale ("Height Scale", Range(0,0.05)) = 0.005
        _CylinderRad ("CylinderRad", Range(8,128)) = 32
        _Softness ("Softness", Range(0,1)) = 0
        _TargetDist ("TargetDist", Float) = 0
        _DissolveRadius ("DissolveRadius", Float) = 0
        _NoiseScale ("NoiseScale", Float) = 0
        _MatcapIntensity("MatcapIntensity", Float) = 0
    }

    SubShader 
    { Tags 
        { 
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "Queue" = "Geometry" 
        } 
        Pass 
        { 
            Name "ForwardPass" 
            Tags 
            {
                "LightMode" = "UniversalForward"
            } 

            HLSLPROGRAM

            #pragma vertex Vertex 
            #pragma fragment Fragment 
            #pragma prefer_hlslcc gles 
            #pragma exclude_renderers d3d11_9x 
            #pragma shader_feature _LIGHTMODE_UNLIT _LIGHTMODE_LIT 
            #pragma shader_feature _FORWARD_PLUS 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN 
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS 
            #pragma multi_compile _ _SHADOWS_SOFT 
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half2 uv          : TEXCOORD0;
                half3 positionWS  : TEXCOORD1;
                half3 normalWS    : TEXCOORD2;
                half3 tangentWS   : TEXCOORD3;
                half3 viewDirTS   : TEXCOORD4;
                half3 bitangentWS : TEXCOORD6;
            };

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_HeightMap); SAMPLER(sampler_HeightMap);
            TEXTURE2D(_AORoughnessMetallicMap); SAMPLER(sampler_AORoughnessMetallicMap);
            TEXTURE2D(_DissolveTex); SAMPLER(sampler_DissolveTex);
            TEXTURE2D(_MatcapTex); SAMPLER(sampler_MatcapTex);

            #define MAX_BUFFER_LENGTH 50 
            float4 _LightPositions[MAX_BUFFER_LENGTH]; 
            float4 _LightColors[MAX_BUFFER_LENGTH]; 
            float _LightRadii[MAX_BUFFER_LENGTH]; 
            float _LightCount;

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _BaseMap_ST;
                half _NormalStrength;
                half _HeightScale;
                half _CylinderRad;
                half _Softness;
                half _DissolveRadius;
                half _TargetDist;
                half _NoiseScale;
                half _MatcapIntensity;
            CBUFFER_END

            Varyings Vertex(Attributes v)
            {
                Varyings o;

                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);

                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                float3 tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                o.tangentWS = float4(normalize(tangentWS), v.tangentOS.w);
                float3 bitangentWS = cross(o.normalWS, o.tangentWS.xyz) * v.tangentOS.w;
                o.bitangentWS = normalize(bitangentWS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

                half3 viewDirWS = GetWorldSpaceViewDir(o.positionWS);

                half3x3 tbn = half3x3(
                    o.tangentWS.xyz,
                    o.bitangentWS,
                    o.normalWS
);
                o.viewDirTS = mul(tbn, viewDirWS);
                return o;
            }

            half Dither4x4(half2 positionCS)
            {
                int2 p = int2(positionCS) & 3;

                static const half dither[16] =
                {
                    0.0h/16.0h,  8.0h/16.0h,  2.0h/16.0h, 10.0h/16.0h,
                    12.0h/16.0h, 4.0h/16.0h, 14.0h/16.0h, 6.0h/16.0h,
                    3.0h/16.0h, 11.0h/16.0h, 1.0h/16.0h,  9.0h/16.0h,
                    15.0h/16.0h,7.0h/16.0h, 13.0h/16.0h, 5.0h/16.0h
                };

                return dither[p.y * 4 + p.x];
            }

            half4 Fragment(Varyings v) : SV_Target
            {
                half3 posVS = mul(unity_MatrixV, float4(v.positionWS, 1.0)).xyz;  
                half pixelDepth = -posVS.z; 
                half distFromAxis = length(posVS.xy);

                half cylinderMask = 1.0 - saturate((distFromAxis - _CylinderRad) / max(0.001, _Softness));               
                float depthRatio = saturate(pixelDepth / max(0.001, _TargetDist));
                float dynamicRadius = depthRatio * _DissolveRadius;
                float coneMask = 1.0 - saturate((distFromAxis - dynamicRadius) / max(0.001, _Softness));
                float depthMask = saturate((_TargetDist - pixelDepth) / 0.5);  
                float dissolveFactor = coneMask * depthMask;
                half fade = (cylinderMask * depthMask);

                half threshold = Dither4x4(v.positionCS.xy); 
                half2 screenUV = v.positionCS.xy / _ScreenParams.xy; 
                half2 noiseUV = screenUV * _NoiseScale * half2(_ScreenParams.x / _ScreenParams.y, 1.0); 
                half2 noise = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, noiseUV).r; 
                clip(noise - dissolveFactor);

                half h = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, v.uv).r;
                half2 offset = (v.viewDirTS.xy / v.viewDirTS.z) * (h * _HeightScale);
                half2 uv = v.uv + offset;

                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, v.uv) * _BaseColor;

                half4 nSample = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
                half3 normalTS = UnpackNormalScale(nSample, _NormalStrength);
                half3x3 tbn = half3x3(v.tangentWS, v.bitangentWS, v.normalWS);
                half3 normalWS = normalize(mul(normalTS, tbn));

                half3 viewDir = normalize(GetWorldSpaceViewDir(v.positionWS));

                half3 ARM = SAMPLE_TEXTURE2D(_AORoughnessMetallicMap, sampler_AORoughnessMetallicMap, v.uv);
                half metalMask = ARM.b;
                half smoothness = 1 - ARM.g;

                InputData lighting = (InputData)0;
                lighting.positionWS = v.positionWS;
                lighting.shadowCoord = TransformWorldToShadowCoord(v.positionWS);
                lighting.viewDirectionWS = viewDir;
                lighting.normalWS = normalWS;
                lighting.bakedGI = SampleSH(normalWS);

                SurfaceData surface = (SurfaceData)0;
                surface.albedo = color.rgb;
                surface.alpha = 1;
                surface.occlusion = ARM.r;
                surface.metallic = 0;
                surface.smoothness = smoothness;

                half4 col = UniversalFragmentBlinnPhong(lighting, surface);

                half3 customLightAccum = 0;

                for (int idx = 0; idx < _LightCount; idx++)
                {
                    half3 lightPos = _LightPositions[idx].xyz;
                    half3 lightColor = _LightColors[idx].rgb;
                    half radius = _LightRadii[idx];

                    half3 L = lightPos - v.positionWS;
                    half dist = length(L);

                    if (dist > radius)
                        continue;

                    L /= dist;

                    half falloff = saturate(1.0h - dist / radius);
                    falloff *= falloff;

                    half NdotL = saturate(dot(normalWS, L));

                    half diffuse = NdotL;

                    half3 H = normalize(L + viewDir);
                    half NdotH = saturate(dot(normalWS, H));

                    half specPower = lerp(16.0h, 128.0h, smoothness);
                    half specular = NdotH * NdotH;
                    specular *= specular;
                    specular *= NdotL;

                    diffuse *= (1.0h - metalMask);
                    specular *= lerp(0.2h, 2.5h, metalMask);

                    customLightAccum += lightColor * (diffuse + specular) * falloff;
                }

                col.rgb += customLightAccum * color.rgb;

                half3 normalVS = mul((half3x3)UNITY_MATRIX_V, normalWS);
                normalVS = normalize(normalVS);

                half2 matcapUV = normalVS.xy * 0.5h + 0.5h;
                matcapUV.y = 1.0h - matcapUV.y;

                half3 matcap = SAMPLE_TEXTURE2D(_MatcapTex, sampler_MatcapTex, matcapUV).rgb;

                half fresnel = pow(1.0h - saturate(dot(normalWS, viewDir)), 4.0h);

                half matcapPower = metalMask * _MatcapIntensity;

                col.rgb += matcap * metalMask * _MatcapIntensity * (1.0h + fresnel);

                return half4(col.rgb, 1);
            }
            ENDHLSL
        }
        Pass 
        { 
            Name "ShadowCaster" 
            Tags 
            { 
                "LightMode"="ShadowCaster" 
            } 
            ZWrite On 
            ColorMask 0 

            HLSLPROGRAM 

            #pragma vertex vertShadow 
            #pragma fragment fragShadow 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" 

            struct Attributes 
            { 
                float4 positionOS : POSITION; 
            }; 

            struct Varyings 
            { 
                float4 positionHCS : SV_POSITION; 
            }; 

            Varyings vertShadow(Attributes v) 
            { 
                Varyings o; 
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz); 
                return o; 
            } 

            half4 fragShadow(Varyings i) : SV_Target 
            { 
                return 0; 
            } 
            ENDHLSL 
        }
    }
}
