Shader "Custom/UIFast"
{
       Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        
        // ќб€зательно дл€ масок Canvas
        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
            "RenderPipeline" = "UniversalPipeline" // ”казываем, что это строго URP шейдер
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [geometry]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                half4 color       : COLOR;
                float2 texcoord   : TEXCOORD0;
            };

            Texture2D _MainTex;
            SamplerState sampler_MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata_t v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.vertex.xyz);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.color = v.color;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 color = _MainTex.Sample(sampler_MainTex, i.texcoord) * i.color;
                return color;
            }
            ENDHLSL
        }
    }
}
