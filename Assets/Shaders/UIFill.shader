Shader "Unlit/UIFill"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Fill ("Fill", Range(0,1)) = 1
        _EdgeWidth ("Edge Width", Range(0.001, 0.1)) = 0.02
        _EdgeColor ("Edge Color", Color) = (1,1,1,1)
        _EdgeIntensity ("Edge Intensity", Range(0,5)) = 2
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Fill;
            float _EdgeWidth;
            float4 _EdgeColor;
            float _EdgeIntensity;
            float4 _Color;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half2 uv = i.uv;
                half4 col = tex2D(_MainTex, uv) * i.color;
                half fillMask = step(uv.x, _Fill);
                col.a *= fillMask;
                half edge = smoothstep(_Fill - _EdgeWidth, _Fill, uv.x);
                col.rgb += _EdgeColor.rgb * edge * _EdgeIntensity;

                return col;
            }
            ENDHLSL
        }
    }
}
