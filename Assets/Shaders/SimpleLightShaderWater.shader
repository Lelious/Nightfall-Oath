Shader "Unlit/SimpleLightShaderWater"
{
    Properties
    {
        _NormalMap ("Normal Map", 2D) = "white" {}
        _AORoughnessMetallicMap ("AO(R) Rough(G) Metal(B)", 2D) = "white" {}
        _DissolveTex ("DissolveTex", 2D) = "black" {}
        _MatcapTex ("MatcapTex", 2D) = "black" {}
        _Offset("Offset", Vector) = (0,0,0,0)
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _NormalStrength ("Normal Strength", Range(0,10)) = 1
        _Softness ("Softness", Range(0,1)) = 0
        _TargetDist ("TargetDist", Float) = 0
        _DissolveRadius ("DissolveRadius", Float) = 0
        _MaxRadius ("Max Radius (Near)", Float) = 10
        _MinRadius ("Min Radius (Far)", Float) = 0
        _MaxDistance ("Max Distance", Float) = 20
        _NoiseScale ("NoiseScale", Float) = 0
        _MatcapIntensity ("MatcapIntensity", Float) = 0
        _Fade ("Fade", Float) = 0
        _Cutoff("Cutoff", Float) = 0
        _DissolveEdge ("Dissolve Edge", Float) = 0
        _DissolveColor ("Dissolve Color", Color) = (1,1,1,1)
        _EdgeIntensity ("Edge Intensity", Float) = 0
        _WaterFlowSpeed("Water Flow Speed", Vector) = (0, 0, 0, 0)
        _FineNoiseScale("Fine Noise Scale", Float) = 2
        _FineNoiseSpeed("Fine Noise Speed", Vector) = (0.2, 0.15, 0, 0)
        _FoamDistance("Foam Distance", Range(0, 5)) = 0.5
        _FoamOpacity("Foam Opacity", Range(0, 1)) = 1
        _WaterViewBias("WaterBias", Range(-10, 10)) = 0.35
         _DitherIntensity("Dither Intensity", Range(0, 1)) = 0.4
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
            #pragma shader_feature _LIGHTMODE_UNLIT _LIGHTMODE_LIT 
            #pragma multi_compile _ _FORWARD_PLUS  
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN 
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS 
            #pragma multi_compile _ _SHADOWS_SOFT 
            #pragma multi_compile_instancing
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                half3 positionOS : POSITION;
                half3 normalOS   : NORMAL;
                half4 tangentOS  : TANGENT;
                half2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                half4 positionCS : SV_POSITION;
                half2 uv          : TEXCOORD0;
                float3 positionWS  : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
                float3 tangentWS   : TEXCOORD3;
                half3 viewDirTS   : TEXCOORD4;
                float3 bitangentWS : TEXCOORD6;
            };

            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_AORoughnessMetallicMap); SAMPLER(sampler_AORoughnessMetallicMap);
            TEXTURE2D(_DissolveTex); SAMPLER(sampler_DissolveTex);
            TEXTURE2D(_MatcapTex); SAMPLER(sampler_MatcapTex);
            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

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
                half _NormalStrength;
                half _HeightScale;
                half _CylinderRad;
                half _Softness;
                half _DissolveRadius;
                half _TargetDist;
                half _NoiseScale;
                half _MatcapIntensity;
                half _Fade;
                half _Cutoff;
                half _DissolveEdge;
                half4 _DissolveColor;
                half _EdgeIntensity;
                half _MaxRadius;
                half _MinRadius;
                half _MaxDistance;
                half4 _Offset;
                half4 _WaterFlowSpeed;
                half _FineNoiseScale;
                half4 _FineNoiseSpeed;
                half _FoamDistance;
                half _FoamOpacity;
                half _WaterViewBias;
                half _DitherIntensity;
            CBUFFER_END

            Varyings Vertex(Attributes v)
            {
                Varyings o;

                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);

                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                float3 tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                o.tangentWS = normalize(tangentWS);
                float3 bitangentWS = cross(o.normalWS, o.tangentWS.xyz) * v.tangentOS.w;
                o.bitangentWS = normalize(bitangentWS);
                o.uv = v.uv;

                float3 viewDirWS = GetWorldSpaceViewDir(o.positionWS);

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

                float period = 10.0f; 
                
                float t1 = frac(_Time.y / period);
                float t2 = frac((_Time.y + period * 0.5f) / period);

                half flowWeight1 = 1.0h - abs(t1 - 0.5h) * 2.0h;
                half flowWeight2 = 1.0h - abs(t2 - 0.5h) * 2.0h;

                float2 wUV = positionWS.xz * _FineNoiseScale;
                float2 flowDir = normalize(_WaterFlowSpeed.xy);
                float flowSpeed = length(_WaterFlowSpeed.xy) * period;

                float turbTime = frac(_Time.y * 0.01f) * 6.2831f;
                float turbX = sin(positionWS.x * 0.13f + turbTime);
                float turbZ = cos(positionWS.z * 0.07f + turbTime);
                float2 distortion = float2(turbX, turbZ) * 0.01f; 

                float2 flowUV1_A = wUV + flowDir * (t1 * flowSpeed) + distortion;
                float2 flowUV2_A = (wUV * 1.5f) + flowDir * (t1 * flowSpeed * 0.6f) + float2(0.2f, 0.5f) + distortion;
                float2 flowUV3_A = (wUV * 0.5f) + flowDir * (t1 * flowSpeed * 0.3f) + distortion;

                half3 n1_A = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, flowUV1_A));
                half3 n2_A = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, flowUV2_A));
                half3 n3_A = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, flowUV3_A));
                half3 normalTS_A = normalize(n1_A + n2_A + n3_A);

                float2 flowUV1_B = wUV + flowDir * (t2 * flowSpeed) + distortion;
                float2 flowUV2_B = (wUV * 1.5f) + flowDir * (t2 * flowSpeed * 0.6f) + float2(0.2f, 0.5f) + distortion;
                float2 flowUV3_B = (wUV * 0.5f) + flowDir * (t2 * flowSpeed * 0.3f) + distortion;

                half3 n1_B = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, flowUV1_B));
                half3 n2_B = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, flowUV2_B));
                half3 n3_B = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, flowUV3_B));
                half3 normalTS_B = normalize(n1_B + n2_B + n3_B);

                half3 normalTS = normalize(normalTS_A * flowWeight1 + normalTS_B * flowWeight2);
                normalTS.xy *= _NormalStrength;
                normalTS = normalize(normalTS);

                half waveHeight = saturate(1.0h - normalTS.z); 
                half crestMask = pow(waveHeight, 2.0h);

                float3x3 tbn = float3x3(normalize(v.tangentWS), normalize(v.bitangentWS), normalize(v.normalWS));
                float3 normalWS = normalize(mul(normalTS, tbn));
                half3 viewDir = normalize(GetWorldSpaceViewDir(v.positionWS));
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(positionWS));

                half4 color = _BaseColor;   
                half3 waterSurfaceColor = color.rgb + (crestMask * 0.4h * mainLight.color); 

                half3 ARM = SAMPLE_TEXTURE2D(_AORoughnessMetallicMap, sampler_AORoughnessMetallicMap, v.uv).rgb;
                half metalMask = saturate(ARM.b);
                half smoothness = saturate(1.0h - ARM.g);

                InputData lighting = (InputData)0;
                lighting.positionWS = v.positionWS;
                lighting.shadowCoord = TransformWorldToShadowCoord(v.positionWS);
                lighting.viewDirectionWS = viewDir;
                lighting.normalWS = normalWS;
                lighting.bakedGI = SampleSH(normalWS);

                SurfaceData surface = (SurfaceData)0;
                surface.albedo = waterSurfaceColor;
                surface.alpha = 1;
                surface.occlusion = ARM.r;
                surface.metallic = 0;
                surface.smoothness = smoothness;

                float4 col = UniversalFragmentBlinnPhong(lighting, surface);

                float3 customLightAccum = 0;

                half specMul = lerp(0.2h, 2.5h, metalMask);
                half diffMul = (1.0h - metalMask);
                half mainLightIntensity = dot(_MainLightColor.rgb, half3(0.2126, 0.7152, 0.0722)); 
                half additionalLightFactor = saturate(1.0 - mainLightIntensity / 2.2);

                for (int idx = 0; idx < _LightCount; idx++)
                {
                    half3 lightPos = _LightPositions[idx].xyz;
                    half3 lightColor = _LightColors[idx].rgb;
                    half radius = _LightRadius[idx];

                    half3 L = lightPos - v.positionWS;
                    half distSqr = dot(L, L);
                    half radiusSqr = radius * radius;

                    if (distSqr > radiusSqr)
                        continue;

                    half invDist = rsqrt(distSqr);
                    L *= invDist;

                    half falloff = saturate(1.0h - distSqr / radiusSqr);
                    falloff *= falloff;

                    half diffuse = saturate(dot(normalWS, L));

                    if(diffuse <= 0)
                        continue;

                    half3 H = normalize(L + viewDir);
                    half NdotH = saturate(dot(normalWS, H));

                    half specular = NdotH * NdotH;
                    specular *= specular * crestMask;

                    diffuse *= diffMul;
                    specular *= specMul;

                    customLightAccum += lightColor * (diffuse + specular) * falloff;
                }

                customLightAccum *= additionalLightFactor;

                col.rgb += saturate(customLightAccum);

                half3 normalVS = mul((half3x3)UNITY_MATRIX_V, normalWS);
                normalVS = normalize(normalVS);

                half2 matcapUV = normalVS.xy * 0.5h + 0.5h;
                matcapUV.y = 1.0h - matcapUV.y;

                half3 matcap = SAMPLE_TEXTURE2D(_MatcapTex, sampler_MatcapTex, matcapUV).rgb;

                half fresnel = pow(1.0h - saturate(dot(normalWS, viewDir)), 4.0h);

                half matcapPower = metalMask * _MatcapIntensity;

                col.rgb += matcap * metalMask * saturate(mainLightIntensity - 0.05h) * (1.0h + fresnel);              
                col.rgb += edge * _DissolveColor.rgb * _EdgeIntensity;

                half3 camPos = _WorldSpaceCameraPos;
                half dist = length(camPos - v.positionWS);
                float2 screenUV = v.positionCS.xy / _ScreenParams.xy;

                float rawDepth = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV, 0).r;
                float sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams);

                float waterZ = v.positionCS.w;

                float depthDiff = sceneZ - waterZ;

                half foamLine = 1.0 - saturate(depthDiff / _FoamDistance);
                foamLine = pow(foamLine, 2.0);
                half foamTime = frac(_Time.y * 0.1f);
                half foamNoise = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, wUV * 0.5 + foamTime).r;
                half foamMask = smoothstep(0.5, 0.8, foamLine + foamNoise * foamLine);

                half3 foamColor = saturate(color.rgb);
                col.rgb = lerp(col.rgb, foamColor * mainLight.color, foamMask * _FoamOpacity);

                half fogFactor = saturate((dist - _FogStart) / (_FogEnd - _FogStart));

                col.rgb = lerp(col.rgb, _FogColor.rgb, fogFactor);
                return half4(col.rgb, _BaseColor.a);
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
            ZTest LEqual
            ColorMask 0 

            HLSLPROGRAM 

            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma vertex vertShadow 
            #pragma fragment fragShadow 

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
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
