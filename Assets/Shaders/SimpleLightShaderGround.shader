Shader "Unlit/SimpleLightShaderGround"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _SplatMap ("SplatMap", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _AORoughnessMetallicMap ("AO(R) Rough(G) Metal(B)", 2D) = "white" {}
        _DissolveTex ("DissolveTex", 2D) = "black" {}
        _MatcapTex ("MatcapTex", 2D) = "black" {}
        _Tile ("Tile", Float) = 1
        _EdgePadding ("EdgePadding", Range(0.01, 0.000001)) = 0.001 
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _WorldSize ("World Size", Float) = 1000
        _NormalStrength ("Normal Strength", Range(0,2)) = 1
        _CylinderRad ("CylinderRad", Range(8,128)) = 32
        _Softness ("Softness", Range(0,1)) = 0
        _TargetDist ("TargetDist", Float) = 0
        _DissolveRadius ("DissolveRadius", Float) = 0
        _NoiseScale ("NoiseScale", Float) = 0
        _MatcapIntensity ("MatcapIntensity", Float) = 0
        _Fade ("Fade", Float) = 0
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
            Stencil
            {
                Ref 1
                Comp NotEqual
                Pass Keep
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
                float2 uv          : TEXCOORD0;
                float3 positionWS  : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
                float3 tangentWS   : TEXCOORD3;
                float3 viewDirTS   : TEXCOORD4;
                float3 bitangentWS : TEXCOORD6;
                half fogFactor : TEXCOORD7;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_SplatMap); SAMPLER(sampler_SplatMap);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
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
                half _CylinderRad;
                half _Softness;
                half _DissolveRadius;
                half _TargetDist;
                half _NoiseScale;
                half _MatcapIntensity;
                half _Fade;
                half _Tile;
                half _EdgePadding;
                half _WorldSize;
            CBUFFER_END

            Varyings Vertex(Attributes v)
            {
                Varyings o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

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

            half2 Hash21(half2 p)
            {
                p = frac(p * half2(123.34h, 456.21h));
                p += dot(p, p + 45.32h);
                return frac(half2(p.x * p.y, p.x + p.y));
            }

            half4 Fragment(Varyings v) : SV_Target
            {               
                half3 posVS = mul(unity_MatrixV, float4(v.positionWS, 1.0)).xyz;  
                half pixelDepth = -posVS.z; 
                half distFromAxis = length(posVS.xy);
                half cylinderMask = 1.0 - saturate((distFromAxis - _CylinderRad) / max(0.001, _Softness));               
                half depthRatio = saturate(pixelDepth / max(0.001, _TargetDist));
                half dynamicRadius = depthRatio * _DissolveRadius;
                half coneMask = 1.0 - saturate((distFromAxis - dynamicRadius) / max(0.001, _Softness));
                half depthMask = saturate((_TargetDist - pixelDepth) / 0.5);  
                half dissolveFactor = coneMask * depthMask;
                half fade = (cylinderMask * depthMask);

                half threshold = Dither4x4(v.positionCS.xy); 
                half2 screenUV = v.positionCS.xy / _ScreenParams.xy; 
                half2 noiseUV = screenUV * _NoiseScale * half2(_ScreenParams.x / _ScreenParams.y, 1.0); 
                half2 noise = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, noiseUV).r; 
                clip(noise - dissolveFactor - _Fade);

                half2 splatUV = v.positionWS.xz / _WorldSize;
                half4 mask = SAMPLE_TEXTURE2D(_SplatMap, sampler_SplatMap, splatUV);
                half sum = mask.r + mask.g + mask.b + mask.a + 1e-5h;
                mask /= sum;
                half2 worldXZ = v.positionWS.xz;

                float tileSize = 1.0h / _Tile;
                half2 tileID = floor(worldXZ / tileSize);
                half2 uvLocal = frac(worldXZ / tileSize);

                uvLocal = uvLocal * (1.0h - 2.0h * _EdgePadding) + _EdgePadding;
                half2 uvAtlas = uvLocal * 0.5h;

                half2 o0 = half2(0.0h, 0.5h);
                half2 o1 = half2(0.5h, 0.5h);
                half2 o2 = half2(0.0h, 0.0h);
                half2 o3 = half2(0.5h, 0.0h);

                half4 c0 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvAtlas + o0);
                half4 c1 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvAtlas + o1);
                half4 c2 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvAtlas + o2);
                half4 c3 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvAtlas + o3);

                half4 color = c0 * mask.r + c1 * mask.g + c2 * mask.b + c3 * mask.a;
                color *= _BaseColor;

                half4 n0 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvAtlas + o0);
                half4 n1 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvAtlas + o1);
                half4 n2 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvAtlas + o2);
                half4 n3 = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvAtlas + o3);

                half3 nTS =
                    UnpackNormalScale(n0, _NormalStrength) * mask.r +
                    UnpackNormalScale(n1, _NormalStrength) * mask.g +
                    UnpackNormalScale(n2, _NormalStrength) * mask.b +
                    UnpackNormalScale(n3, _NormalStrength) * mask.a;

                half3x3 tbn = half3x3(v.tangentWS, v.bitangentWS, v.normalWS);
                half3 normalWS = normalize(mul(nTS, tbn));

                half3 arm0 = SAMPLE_TEXTURE2D(_AORoughnessMetallicMap, sampler_AORoughnessMetallicMap, uvAtlas + o0).rgb;
                half3 arm1 = SAMPLE_TEXTURE2D(_AORoughnessMetallicMap, sampler_AORoughnessMetallicMap, uvAtlas + o1).rgb;
                half3 arm2 = SAMPLE_TEXTURE2D(_AORoughnessMetallicMap, sampler_AORoughnessMetallicMap, uvAtlas + o2).rgb;
                half3 arm3 = SAMPLE_TEXTURE2D(_AORoughnessMetallicMap, sampler_AORoughnessMetallicMap, uvAtlas + o3).rgb;

                half3 ARM = arm0 * mask.r + arm1 * mask.g + arm2 * mask.b + arm3 * mask.a; 
        
                half3 viewDir = normalize(GetWorldSpaceViewDir(v.positionWS));

                half metalMask = saturate(ARM.b);
                half smoothness = saturate(1.0h - ARM.g);
                half3 ambient = SampleSH(normalWS);

                Light mainLight = GetMainLight(TransformWorldToShadowCoord(v.positionWS));
                InputData lighting = (InputData)0;
                lighting.positionWS = v.positionWS;
                lighting.shadowCoord = TransformWorldToShadowCoord(v.positionWS);
                lighting.viewDirectionWS = viewDir;
                lighting.normalWS = normalWS;
                lighting.bakedGI = max(ambient, 0.15h);

                SurfaceData surface = (SurfaceData)0;
                surface.albedo = color.rgb;
                surface.alpha = 1.0h;
                surface.occlusion = ARM.r;
                surface.metallic = 0.0h;
                surface.smoothness = smoothness;

                half4 col = UniversalFragmentBlinnPhong(lighting, surface);

                half3 customLightAccum = 0;
                half specMul = lerp(0.2h, 2.5h, metalMask);
                half diffMul = (1.0h - metalMask);
                half mainLightIntensity = dot(_MainLightColor.rgb, half3(0.2126h, 0.7152h, 0.0722h)); 
                half additionalLightFactor = lerp(1.0h, 0.1h, saturate(mainLightIntensity));

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

                    half specular = pow(NdotH, 32.0h);
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

                col.rgb += matcap * metalMask * _MatcapIntensity * (1.0h + fresnel);

                float finnoise = frac(sin(dot(v.positionCS.xy, float2(12.9898f, 78.233f))) * 43758.5453f);
                col.rgb += (finnoise - 0.5h) * 0.003h;

                half3 camPos = _WorldSpaceCameraPos;
                half dist = length(camPos - v.positionWS);

                half fogFactor = saturate((dist - _FogStart) / (_FogEnd - _FogStart));
    
                col.rgb = lerp(col.rgb, _FogColor.rgb, fogFactor);

                return half4(col.rgb, 1.0h);
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
