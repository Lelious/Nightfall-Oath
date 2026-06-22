Shader "Custom/SoftParticles"
{
   Properties
   {
        _MainTex ("Particle Texture", 2D) = "white" {}
        _InvFade ("Soft Particles Factor", Float) = 1.0
   }

   SubShader
   {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue"="Transparent" 
            "RenderPipeline" = "UniversalPipeline" 
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off 
        ZWrite Off

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag            
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 color        : COLOR;
                float4 uvAndCustom  : TEXCOORD0; 
                float4 customStream : TEXCOORD1; 

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                half4 color         : COLOR;
                float2 uv           : TEXCOORD0;
                float4 projPos      : TEXCOORD1;
                half hdrMultiplier  : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Texture2D _MainTex;
            SamplerState sampler_MainTex;
            float _InvFade;

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                
                output.color = input.color;
                output.uv = input.uvAndCustom.xy + input.uvAndCustom.zw;
                output.hdrMultiplier = input.customStream.z;

                output.projPos = ComputeScreenPos(output.positionCS);              

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                half4 texColor = _MainTex.Sample(sampler_MainTex, input.uv);
                half4 finalColor = texColor * input.color;

                finalColor.rgb *= input.hdrMultiplier;
                float2 screenUV = input.projPos.xy / input.projPos.w;
                
                float rawDepth = SampleSceneDepth(screenUV);
                float sceneZ = LinearEyeDepth(rawDepth, _ZBufferParams);             
                float partZ = input.projPos.w;
                
                float fade = saturate(_InvFade * (sceneZ - partZ));
                finalColor.a *= fade;

                clip(finalColor.a - 0.001);

                return finalColor;
            }
            ENDHLSL
        }
   }
}
