Shader "Unlit/SimpleLightShaderWind"
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
        _Softness ("Softness", Range(0,1)) = 0
        _TargetDist ("TargetDist", Float) = 0
        _DissolveRadius ("DissolveRadius", Float) = 0
        _MaxRadius ("Max Radius (Near)", Float) = 10
        _MinRadius ("Min Radius (Far)", Float) = 0
        _MaxDistance ("Max Distance", Float) = 20
        _NoiseScale ("NoiseScale", Float) = 0
        _DitherIntensity("Dither Intensity", Range(0, 1)) = 0.2
        _MatcapIntensity ("MatcapIntensity", Float) = 0
        _Fade ("Fade", Float) = 0
        _Cutoff("Cutoff", Float) = 0
        _DissolveEdge ("Dissolve Edge", Float) = 0
        _WindStrength ("Wind Strength", Range(0,1)) = 0.2
        _WindSpeed ("Wind Speed", Float) = 1
        _WindScale ("Wind Scale", Float) = 1
    }

    SubShader 
    { 
        Tags 
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
            #pragma exclude_renderers d3d11_9x 
            #pragma shader_feature _LIGHTMODE_LIT
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE 
            #pragma multi_compile_instancing
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID 
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
                UNITY_VERTEX_INPUT_INSTANCE_ID 
            };

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_HeightMap); SAMPLER(sampler_HeightMap);
            TEXTURE2D(_AORoughnessMetallicMap); SAMPLER(sampler_AORoughnessMetallicMap);
            TEXTURE2D(_DissolveTex); SAMPLER(sampler_DissolveTex);
            TEXTURE2D(_MatcapTex); SAMPLER(sampler_MatcapTex);

            CBUFFER_START(_CustomLightingBuffer)
                #define MAX_BUFFER_LENGTH 50 
                float4 _LightPositions[MAX_BUFFER_LENGTH]; 
                float4 _LightColors[MAX_BUFFER_LENGTH]; 
                float _LightRadius[MAX_BUFFER_LENGTH]; 
                half _LightCount;
            CBUFFER_END

            CBUFFER_START(_GlobalFogBuffer)
                half4 _FogColor;
                float _FogStart;
                float _FogEnd;
            CBUFFER_END

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _BaseMap_ST;
                half _NormalStrength;
                half _HeightScale;
                half _Softness;
                half _DissolveRadius;
                half _MaxRadius;
                half _MinRadius;
                half _MaxDistance;
                half _TargetDist;
                half _NoiseScale;
                half _MatcapIntensity;
                half _Fade;
                half _Cutoff;
                half _DissolveEdge;
                half _WindStrength;
                half _WindSpeed;
                half _WindScale;
                half _DitherIntensity;
            CBUFFER_END
            
            half hash(half2 p)
            {
                p = frac(p * 0.3183099 + half2(0.1, 0.2));
                p *= 17.0;
                return frac(p.x * p.y * (p.x + p.y));
            }

            Varyings Vertex(Attributes v)
            {
                Varyings o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                half3 posOS = v.positionOS;

                half distXZ = length(posOS.xz);
                half heightMask = saturate(posOS.y);
                half rnd = hash(posOS.xz);
                half t = _Time.y * _WindSpeed;
                half wind1 = sin(t + posOS.x * 0.5 + rnd * 6.28);
                half wind2 = sin(t * 1.7 + posOS.z * 1.3 + rnd * 3.14);
                half wind3 = sin(t * 2.3 + (posOS.x + posOS.z) * 0.8);
                half wind = (wind1 + wind2 * 0.5 + wind3 * 0.25);
                wind *= 0.5;
                half strength = wind * _WindStrength * heightMask * (0.5 + distXZ);

                posOS.x += strength;
                posOS.z += strength * 0.5;
                posOS.y += strength * 0.2f;

                half flutter = sin(t * 5 + rnd * 10 + posOS.y * 8) * 0.02;
                posOS.xz += flutter * heightMask;
                o.positionWS = TransformObjectToWorld(posOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);

                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
     
                float3 tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                o.tangentWS = normalize(tangentWS);
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

            half Dither8x8(half2 screenPos)
            {
                const half bayer8x8[64] = {
                    0.0156f, 0.5156f, 0.1406f, 0.6406f, 0.0469f, 0.5469f, 0.1719f, 0.6719f,
                    0.7656f, 0.2656f, 0.8906f, 0.3906f, 0.7969f, 0.2969f, 0.9219f, 0.4219f,
                    0.2031f, 0.7031f, 0.0781f, 0.5781f, 0.2344f, 0.7344f, 0.1094f, 0.6094f,
                    0.9531f, 0.4531f, 0.8281f, 0.3281f, 0.9844f, 0.4844f, 0.8594f, 0.3594f,
                    0.0625f, 0.5625f, 0.1875f, 0.6875f, 0.0312f, 0.5312f, 0.1562f, 0.6562f,
                    0.8125f, 0.3125f, 0.9375f, 0.4375f, 0.7812f, 0.2812f, 0.9062f, 0.4062f,
                    0.2500f, 0.7500f, 0.1250f, 0.6250f, 0.2188f, 0.7188f, 0.0938f, 0.5938f,
                    1.0000f, 0.5000f, 0.8750f, 0.3750f, 0.9688f, 0.4688f, 0.8438f, 0.3438f
                };

                half2 signCorrectedPos = floor(screenPos);
                int x = int(fmod(signCorrectedPos.x, 8.0f));
                int y = int(fmod(signCorrectedPos.y, 8.0f));
    
                if (x < 0) x += 8;
                if (y < 0) y += 8;

                return bayer8x8[y * 8 + x];
            }

            half4 Fragment(Varyings v) : SV_Target
            {
                float3 positionWS = v.positionWS;
                float3 posVS = mul(unity_MatrixV, float4(positionWS, 1.0f)).xyz;  
                float pixelDepth = -posVS.z; 
                float distFromAxis = length(posVS.xy);
                float depthRatio = saturate(pixelDepth / max(0.001f, _TargetDist));
                float dynamicRadius = lerp(_MaxRadius, _MinRadius, depthRatio);

                float coneMask = 1.0f - saturate((distFromAxis - dynamicRadius) / max(0.001f, _Softness));
                float depthMask = saturate((_TargetDist - pixelDepth) / 0.5f);  
                float dissolveFactor = coneMask * depthMask;

                float threshold = Dither8x8(v.positionCS.xy);
                float d = (dissolveFactor * (1.0f - _DitherIntensity)) - threshold - _Fade;

                half edge = saturate(d / max(0.0001f, _DissolveEdge));
                edge = 1.0h - edge;
                edge *= step(0.0h, d);
                edge = pow(edge, 2.0h);
                edge *= step(0.001f, dissolveFactor);

                clip(-d); 

                half h = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, v.uv).r;
                half2 offset = (v.viewDirTS.xy / v.viewDirTS.z) * (h * _HeightScale);
                half2 uv = v.uv + offset;

                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor;
                clip(color.a - _Cutoff);

                half4 nSample = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
                half3 normalTS = UnpackNormalScale(nSample, _NormalStrength);
                half3x3 tbn = half3x3(v.tangentWS, v.bitangentWS, v.normalWS);
                half3 normalWS = normalize(mul(normalTS, tbn));

                half3 viewDir = normalize(GetWorldSpaceViewDir(v.positionWS));
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(v.positionWS));

                half3 ARM = SAMPLE_TEXTURE2D(_AORoughnessMetallicMap, sampler_AORoughnessMetallicMap, uv).rgb;
                half metalMask = saturate(ARM.b);
                half smoothness = saturate(1.0h - ARM.g);

                InputData lighting = (InputData)0;
                lighting.positionWS = v.positionWS;
                lighting.shadowCoord = TransformWorldToShadowCoord(v.positionWS);
                lighting.viewDirectionWS = viewDir;
                lighting.normalWS = normalWS;
                lighting.bakedGI = SampleSH(normalWS);

                SurfaceData surface = (SurfaceData)0;
                surface.albedo = color.rgb;
                surface.alpha = color.a;
                surface.occlusion = ARM.r;
                surface.metallic = metalMask;
                surface.smoothness = smoothness;

                half4 col = UniversalFragmentBlinnPhong(lighting, surface);

                half3 customLightAccum = 0;
                half specMul = lerp(0.2h, 2.5h, metalMask);
                half diffMul = (1.0h - metalMask);
                half mainLightIntensity = dot(_MainLightColor.rgb, half3(0.2126h, 0.7152h, 0.0722h)); 
                half additionalLightFactor = saturate(1.0h - mainLightIntensity / 2.2h);

                for (int idx = 0; idx < _LightCount; idx++)
                {
                    half3 lightPos = _LightPositions[idx].xyz;
                    half3 lightColor = _LightColors[idx].rgb;
                    half radius = _LightRadius[idx];

                    half3 L = lightPos - v.positionWS;
                    half distSqr = dot(L, L);
                    half radiusSqr = radius * radius;

                    if (distSqr > radiusSqr) continue;

                    half invDist = rsqrt(distSqr);
                    L *= invDist;

                    half falloff = saturate(1.0h - distSqr / radiusSqr);
                    falloff *= falloff;

                    half diffuse = saturate(dot(normalWS, L));
                    if (diffuse <= 0) continue;

                    half3 H = normalize(L + viewDir);
                    half NdotH = saturate(dot(normalWS, H));

                    half specular = NdotH * NdotH;
                    specular *= specular;

                    diffuse *= diffMul;
                    specular *= specMul;

                    customLightAccum += lightColor * (diffuse + specular) * falloff;
                }

                customLightAccum *= additionalLightFactor;
                col.rgb += customLightAccum * color.rgb;

                half3 normalVS = mul((half3x3)UNITY_MATRIX_V, normalWS);
                normalVS = normalize(normalVS);

                half2 matcapUV = normalVS.xy * 0.5h + 0.5h;
                matcapUV.y = 1.0h - matcapUV.y;

                half3 matcap = SAMPLE_TEXTURE2D(_MatcapTex, sampler_MatcapTex, matcapUV).rgb;
                half fresnel = pow(1.0h - saturate(dot(normalWS, viewDir)), 4.0h);

                col.rgb += matcap * surface.metallic * _MatcapIntensity * (1.0h + fresnel);

                half3 camPos = _WorldSpaceCameraPos;
                half dist = length(camPos - v.positionWS);

                half fogFactor = saturate((dist - _FogStart) / (_FogEnd - _FogStart));

                col.rgb = lerp(col.rgb, _FogColor.rgb, fogFactor);

                return half4(col.rgb, col.a);
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

            Cull Back
            ColorMask 0
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM 

            #pragma vertex vertShadow 
            #pragma fragment fragShadow 
            #pragma multi_compile_instancing
            #pragma multi_compile_shadowcaster
            #pragma target 2.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" 

            float3 _LightDirection;

            struct Attributes 
            { 
                float4 positionOS : POSITION; 
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            }; 

            struct Varyings 
            { 
                float4 positionHCS : SV_POSITION; 
                UNITY_VERTEX_INPUT_INSTANCE_ID
            }; 

            Varyings vertShadow(Attributes v) 
            { 
                Varyings o; 
                UNITY_SETUP_INSTANCE_ID(v); 
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);
                
                float3 lightDirectionWS = _MainLightPosition.xyz;
                
                o.positionHCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
                
                #if UNITY_REVERSED_Z
                    o.positionHCS.z = min(o.positionHCS.z, o.positionHCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    o.positionHCS.z = max(o.positionHCS.z, o.positionHCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                
                return o; 
            } 

            half4 fragShadow(Varyings i) : SV_Target 
            { 
                UNITY_SETUP_INSTANCE_ID(i); 
                return 0; 
            } 
            ENDHLSL 
        }
    }
}
