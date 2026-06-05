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
        _Offset("Offset", Vector) = (0,0,0,0)
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

            Stencil
            {
                Ref 1
                Comp NotEqual
                Pass Keep
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
            float _LightRadius[MAX_BUFFER_LENGTH]; 
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

                half depth = -posVS.z;
                half distFromCenter = length(posVS.xy + _Offset);
                half t = saturate(depth / max(0.001, _MaxDistance));
                half radius = lerp(_MaxRadius, _MinRadius, t);
                half coneMask = smoothstep(radius + _Softness, radius, distFromCenter);
                half depthMask = step(0.0, depth) * step(depth, _MaxDistance);

                half dissolveFactor = coneMask * depthMask;
                half fade = (dissolveFactor * depthMask);

                half threshold = Dither4x4(v.positionCS.xy); 
                half2 screenUV = v.positionCS.xy / _ScreenParams.xy; 
                half2 noiseUV = v.uv * _NoiseScale;
                half noise = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, noiseUV).r;
                half noise2 = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, noiseUV * 2.3 + 17.0).r;
                noise = lerp(noise, noise * noise2, 0.5);
                noise = pow(noise, 1.5);
                half d = noise - dissolveFactor;
                d -= _Fade;
                half edge = saturate(d / max(0.0001, _DissolveEdge));
                edge = 1.0 - edge;
                edge *= step(0.0, d);
                edge = pow(edge, 2.0);
                clip(d);

                half h = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, v.uv).r;
                half2 offset = (v.viewDirTS.xy / v.viewDirTS.z) * (h * _HeightScale);
                half2 uv = v.uv + offset;

                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, v.uv) * _BaseColor;
                clip(color.a - _Cutoff);

                half4 nSample = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
                half3 normalTS = UnpackNormalScale(nSample, _NormalStrength);
                half3x3 tbn = half3x3(v.tangentWS, v.bitangentWS, v.normalWS);
                half3 normalWS = normalize(mul(normalTS, tbn));

                half3 viewDir = normalize(GetWorldSpaceViewDir(v.positionWS));


                Light mainLight = GetMainLight(TransformWorldToShadowCoord(v.positionWS));

                half3 ARM = SAMPLE_TEXTURE2D(_AORoughnessMetallicMap, sampler_AORoughnessMetallicMap, v.uv).rgb;
                half metalMask = ARM.b;
                half smoothness = 1 - ARM.g;               
                half3 ambient = SampleSH(normalWS);

                InputData lighting = (InputData)0;
                lighting.positionWS = v.positionWS;
                lighting.shadowCoord = TransformWorldToShadowCoord(v.positionWS);
                lighting.viewDirectionWS = viewDir;
                lighting.normalWS = normalWS;
                lighting.bakedGI = max(ambient, 0.15);

                SurfaceData surface = (SurfaceData)0;
                surface.albedo = color.rgb;
                surface.alpha = 1;
                surface.occlusion = ARM.r;
                surface.metallic = 0;
                surface.smoothness = smoothness;

                half4 col = UniversalFragmentBlinnPhong(lighting, surface);

                half3 customLightAccum = 0;

                half specMul = lerp(0.2h, 2.5h, metalMask);
                half diffMul = (1.0h - metalMask);
                half mainLightIntensity = dot(mainLight.color, half3(0.2126, 0.7152, 0.0722)); 
                //half additionalLightFactor = saturate(1.0 - mainLightIntensity / 3.0);
                half additionalLightFactor = lerp(1.0, 0.1, saturate(mainLightIntensity));

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

                    half specular = pow(NdotH, 32.0);
                    specular *= smoothness;

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

                half matcapPower = metalMask * _MatcapIntensity;

                col.rgb += matcap * metalMask * _MatcapIntensity * (1.0h + fresnel);                
                col.rgb += edge * _DissolveColor.rgb * _EdgeIntensity;

                half3 camPos = _WorldSpaceCameraPos;
                half dist = length(camPos - v.positionWS);

                half fogFactor = saturate((dist - _FogStart) / (_FogEnd - _FogStart));
                half3 adjustedFogColor = _FogColor.rgb * mainLight.color;
                fogFactor = smoothstep(0.0, 1.0, fogFactor);
                col.rgb = lerp(col.rgb, adjustedFogColor, fogFactor);
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
