Shader "Custom/Stencil"
{
    Properties
    {
        [IntRange] _StencilRef ("Stencil Ref ID", Range(0, 255)) = 1
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "Queue"="Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Blend Zero One
            ZWrite Off
            ZTest LEqual
            Cull Front

            Stencil
            {
                Ref [_StencilRef]
                Comp Always
                Pass Keep
            }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings { float4 positionCS : SV_POSITION; };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }
            half4 frag(Varyings input) : SV_Target { return half4(0,0,0,0); }
            ENDHLSL
        }
    }
}
