Shader "Custom/TargetFrameShader"
{
    Properties
    {
        [MainTexture] _BaseMap("Target Texture (With Beaks)", 2D) = "white" {}
        [HDR][MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)
        
        _Selected("Is Selected (0 or 1)", Float) = 0.0
        _CutoffRadius("Auto Target Cutoff Radius", Range(0.0, 0.5)) = 0.35
        
        _RotationSpeed("Rotation Speed", Float) = 2.0
        _PulseSpeed("Pulse Speed", Float) = 3.0
        _PulseAmount("Pulse Amount", Float) = 0.1
    }

    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent" 
            "Queue" = "Transparent+100" 
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off  
            ZTest Always                    
            Cull Off                        

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float2 rawUV        : TEXCOORD1;
            };

            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;

            half4 _BaseColor;
            half _Selected;
            half _CutoffRadius;
            half _RotationSpeed;
            half _PulseSpeed;
            half _PulseAmount;

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                float3 localPos = input.positionOS.xyz;

                float pulse = sin(_Time.y * _PulseSpeed) * _PulseAmount;
                localPos.xyz *= 1.0 + (pulse * _Selected);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(localPos);
                output.positionCS = vertexInput.positionCS;
                
                output.rawUV = input.uv;

                float angle = _Time.y * _RotationSpeed * _Selected;
                float cosAngle = cos(angle);
                float sinAngle = sin(angle);

                float2 uvCentered = input.uv - 0.5;
                float2 rotatedUV;
                rotatedUV.x = uvCentered.x * cosAngle - uvCentered.y * sinAngle;
                rotatedUV.y = uvCentered.x * sinAngle + uvCentered.y * cosAngle;
                
                output.uv = rotatedUV + 0.5;

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {              
                float2 uvCentered = input.rawUV - 0.5;
                float dist = length(uvCentered);
                float currentMaskRadius = lerp(_CutoffRadius, 0.7, _Selected);
                
                if (dist > currentMaskRadius)
                {
                    discard;
                }

                float4 texColor = _BaseMap.Sample(sampler_BaseMap, input.uv);               
                float4 finalColor = texColor * _BaseColor;
                
                clip(finalColor.a - 0.01); 

                return finalColor;
            }
            ENDHLSL
        }
    }
}
