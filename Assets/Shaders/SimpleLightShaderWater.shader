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
        _NormalStrength ("Normal Strength", Range(0,2)) = 1
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
        _FogColor ("Fog Color", Color) = (0.5,0.6,0.7,1)
        _FogStart ("Fog Start", Float) = 10
        _FogEnd ("Fog End", Float) = 60
        _FogHeight ("Fog Height", Float) = 2
        _FogDensity ("Fog Density", Float) = 0.5
        _DissolveEdge ("Dissolve Edge", Float) = 0
        _DissolveColor ("Dissolve Color", Color) = (1,1,1,1)
        _EdgeIntensity ("Edge Intensity", Float) = 0
        _WaterFlowSpeed("Water Flow Speed", Vector) = (0, 0, 0, 0)
        _FineNoiseScale("Fine Noise Scale", Float) = 2
        _FineNoiseSpeed("Fine Noise Speed", Vector) = (0.2, 0.15, 0, 0)
        _FoamDistance("Foam Distance", Range(0, 5)) = 0.5
        _FoamOpacity("Foam Opacity", Range(0, 1)) = 1
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
            #pragma prefer_hlslcc gles 
            #pragma exclude_renderers d3d11_9x 
            #pragma shader_feature _LIGHTMODE_UNLIT _LIGHTMODE_LIT 
            #pragma shader_feature _FORWARD_PLUS 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN 
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS 
            #pragma multi_compile _ _SHADOWS_SOFT 
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

            #define MAX_BUFFER_LENGTH 50 
            float4 _LightPositions[MAX_BUFFER_LENGTH]; 
            float4 _LightColors[MAX_BUFFER_LENGTH]; 
            float _LightRadii[MAX_BUFFER_LENGTH]; 
            half _LightCount;

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
                half4 _FogColor;
                half _FogStart;
                half _FogEnd;
                half _FogHeight;
                half _FogDensity;
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
                float3 positionWS = v.positionWS;
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - positionWS);
                float3 posVS = mul(unity_MatrixV, float4(positionWS, 1.0)).xyz;
                float depth = -posVS.z;
                float distToCam = length(_WorldSpaceCameraPos - positionWS);

                float distFromCenter = length(posVS.xy + _Offset);
                half t = saturate(depth / max(0.001, (float)_MaxDistance));
                half radius = lerp(_MaxRadius, _MinRadius, t);
                half coneMask = smoothstep(radius + _Softness, radius, distFromCenter);
                half depthMask = step(0.0, depth) * step(depth, (float)_MaxDistance);
                half dissolveFactor = coneMask * depthMask;

                float2 dissolveUV = v.uv * _NoiseScale;
                half noise = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, dissolveUV).r;
                half d = noise - dissolveFactor - _Fade;
                half edge = pow(1.0 - saturate(d / max(0.0001, _DissolveEdge)), 2.0) * step(0.0, d);
                clip(d);

                float time = _Time.y;
                float2 wUV = positionWS.xz * _FineNoiseScale;

                float2 flowDir = normalize(_WaterFlowSpeed.xy);
                float flowSpeed = length(_WaterFlowSpeed.xy);

                float turbX = sin(positionWS.x * 0.13 + time * 0.01);
                float turbZ = cos(positionWS.z * 0.07 + time * 0.01);

                float2 distortion = float2(turbX, turbZ) * 0.01; 

                float2 flowUV1 = wUV + flowDir * (time * flowSpeed);
                float2 flowUV2 = (wUV * 1.5) + flowDir * (time * flowSpeed * 0.6) + float2(0.2, 0.5);
                float2 flowUV3 = (wUV * 0.5) + flowDir * (time * flowSpeed * 0.3);

                half3 n1 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, flowUV1).rgb;
                half3 n2 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, flowUV2).rgb;
                half3 n3 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, flowUV3).rgb;


                half3 combinedNoise = (n1 + n2 + n3) * 10; 
                half waveHeight = combinedNoise.r;
                half crestMask = saturate(waveHeight); 
                crestMask = pow(crestMask, 1.0h); 
                half3 normalTS = UnpackNormal(half4(combinedNoise, 1.0));
                normalTS = normalize(normalTS);
                float3x3 tbn = float3x3(normalize(v.tangentWS), normalize(v.bitangentWS), normalize(v.normalWS));
                float3 normalWS = normalize(mul(normalTS, tbn));


                Light mainLight = GetMainLight(TransformWorldToShadowCoord(positionWS));

                half4 color = _BaseColor;   
                half3 waterSurfaceColor = color.rgb + (waveHeight * 0.2h * color.rgb);

                half3 ARM = SAMPLE_TEXTURE2D(_AORoughnessMetallicMap, sampler_AORoughnessMetallicMap, v.uv).rgb;
                half metalMask = ARM.b;
                half smoothness = 1 - ARM.g;

                InputData lighting = (InputData)0;
                lighting.positionWS = v.positionWS;
                lighting.shadowCoord = TransformWorldToShadowCoord(v.positionWS);
                lighting.viewDirectionWS = viewDirWS;
                lighting.normalWS = normalWS * _NormalStrength;
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
                    half radius = _LightRadii[idx];

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

                    half3 H = normalize(L + viewDirWS);
                    half NdotH = saturate(dot(normalWS, H));

                    half specular = NdotH * NdotH;
                    specular *= specular * crestMask;

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

                half fresnel = pow(1.0h - saturate(dot(normalWS, viewDirWS)), 4.0h);

                half matcapPower = metalMask * _MatcapIntensity;

                col.rgb += matcap * metalMask * _MatcapIntensity * (1.0h + fresnel);                
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

                half foamNoise = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, wUV * 0.5 + time * 0.1).r;
                half foamMask = smoothstep(0.5, 0.8, foamLine + foamNoise * foamLine);

                half3 foamColor = saturate(color.rgb);
                col.rgb = lerp(col.rgb, foamColor * mainLight.color, foamMask * _FoamOpacity);
                half fogFactor = saturate((dist - _FogStart) / (_FogEnd - _FogStart));
                half3 adjustedFogColor = _FogColor.rgb * mainLight.color;

                fogFactor = smoothstep(0.0, 1.0, fogFactor);

                col.rgb = lerp(col.rgb, adjustedFogColor, fogFactor);
                return half4(col);
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
