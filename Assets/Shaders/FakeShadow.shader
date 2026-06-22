Shader "Custom/FakeShadow"
{
    Properties
    {
        _ShadowTex ("Shadow Texture (Blur Circle)", 2D) = "black" {}
        _BaseAlpha ("Max Shadow Alpha", Range(0, 1)) = 0.6
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"
            "Queue"="Geometry+1"
            "RenderPipeline" = "UniversalPipeline" 
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off
        ZTest LEqual

        Pass
        {
            Name "ForwardPass"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                half alphaFactor    : TEXCOORD1;
                half color : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Texture2D _ShadowTex;
            SamplerState sampler_ShadowTex;
            half _BaseAlpha;

            CBUFFER_START(_CustomLightingBuffer)
                #define MAX_BUFFER_LENGTH 50 
                float4 _LightPositions[MAX_BUFFER_LENGTH]; 
                float4 _LightColors[MAX_BUFFER_LENGTH]; 
                float _LightRadius[MAX_BUFFER_LENGTH]; 
                half _LightCount;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                // 1. Получаем мировые координаты центра тени (под ногами) и текущей вершины
                float3 centerWS = TransformObjectToWorld(float3(0.0, 0.0, 0.0));
                float3 vertexWS = TransformObjectToWorld(input.positionOS.xyz);

                // Автоматическое гашение дня/ночи от солнца URP
                Light mainLight = GetMainLight();
                half sunBrightness = dot(mainLight.color.rgb, half3(0.2126h, 0.7152h, 0.0722h));
                half fakeShadowIntensity = 1.0h - sunBrightness;

                // Накапливаемые параметры
                float3 totalLightDir = float3(0.0, 0.0, 0.0);
                float totalWeight = 0.0001; 

                // Жесткие геометрические пороги
                float maxShadowRadius = 12.0; 
                
                // Переменная-триггер для отслеживания критической близости источника
                // 1.0 - все спокойно, 0.0 - ИСТОЧНИК СЛИШКОМ БЛИЗКО (Паника!)
                float safetyFactor = 1.0;

                // 2. ЦИКЛ СБОРА ГЕОМЕТРИИ И ПРОВЕРКИ НА КРИТИЧЕСКИЕ СИТУАЦИИ
                for (int idx = 0; idx < _LightCount; idx++)
                {
                    float3 lPos = _LightPositions[idx].xyz;
                    float3 toUnit = centerWS - lPos;
                    float dist = length(toUnit);

                    if (dist < maxShadowRadius)
                    {
                        float3 dir = toUnit / max(0.01, dist);
                        dir.y = 0.0;
                        dir = normalize(dir);

                        float weight = 1.0;
                        totalLightDir += dir * weight;
                        totalWeight += weight;

                        // ПРОВЕРКА НА БЛИЗОСТЬ: Если хоть один источник подобрался ближе 3.5 метров,
                        // этот smoothstep начнет стремительно падать в 0.0 по мере приближения к центру.
                        // Если в руке горящий меч (dist ~ 0.5м) -> safetyFactor для этого источника станет равен 0.0.
                        float localSafety = smoothstep(1.5, 3.5, dist);
                        safetyFactor = min(safetyFactor, localSafety); // Нам важен самый опасный/близкий источник!
                    }
                }

                // ПРОВЕРКА НА ОБЩУЮ ИНТЕНСИВНОСТЬ: 
                // Если на экране одновременно заспавнилось больше двух источников (totalWeight > 2.0),
                // мы начинаем плавно душить деформацию, так как в толпе эффектов тени гарантированно начнут прыгать.
                // Если источников 3 и более -> crowdDampen упадет в 0.0.
                float crowdDampen = smoothstep(3.0, 1.5, totalWeight);
                
                // Финальный коэффициент стабильности: если ХОТЬ ОДНО условие нарушено, он падает в 0.0
                float stabilityMatrix = safetyFactor * crowdDampen;

                half finalAlpha = _BaseAlpha * fakeShadowIntensity;

                // 3. ПРИМЕНЕНИЕ ЛОГИКИ СХЛОПЫВАНИЯ СТАБИЛЬНОСТ И
                if (totalWeight > 0.5 && fakeShadowIntensity > 0.01)
                {
                    if (length(totalLightDir) > 0.01)
                    {
                        float3 blendDir = normalize(totalLightDir);
                        float3 blendRight = float3(-blendDir.z, 0.0, blendDir.x);

                        float3 localOffset = vertexWS - centerWS;

                        float dotForward = dot(localOffset, blendDir);
                        float dotRight = dot(localOffset, blendRight);

                        // ЖЕСТКИЙ ПЕРЕКЛЮЧАТЕЛЬ ФОРМЫ НА ОСНОВЕ СТАБИЛЬНОСТ И:
                        // Если stabilityMatrix = 1.0 (все чисто, фаербол летит далеко и он один) -> Stretch = 1.45, Squeeze = 0.8.
                        // Если stabilityMatrix = 0.0 (меч в руке или куча магии) -> коэффициенты превращаются в 1.0 (ИДЕАЛЬНЫЙ КРУГ)!
                        float fixedStretch = lerp(1.05, 2.5, stabilityMatrix); 
                        float fixedSqueeze = lerp(0.95, 1.2, stabilityMatrix);  

                        // Сдвиг центра овала точно так же тает в ноль при любой непонятной ситуации
                        float3 shadowCenterOffset = blendDir * (fixedStretch - 1.5) * 0.5 * stabilityMatrix;

                        vertexWS = centerWS + shadowCenterOffset + 
                                   (blendDir * dotForward * fixedStretch) + 
                                   (blendRight * dotRight * fixedSqueeze);
                    }
                }

                output.positionCS = TransformWorldToHClip(vertexWS);
                output.uv = input.uv;
                output.color = finalAlpha;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                half4 tex = _ShadowTex.Sample(sampler_ShadowTex, input.uv);         
                return half4(0.0, 0.0, 0.0, tex.a * input.color);
            }
            ENDHLSL
        }
    }
}
