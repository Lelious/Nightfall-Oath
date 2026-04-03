Shader "HoaxGames/DistortionShader"
{
    Properties
    {
        _DistortionStrength("DistortionStrength", Range(0, 1)) = 0.1
        _ScaleWithDistanceFactor("ScaleWithDistanceFactor", Range(0, 1)) = 1
        _DistortionMoveSpeed("DistortionMoveSpeed", Vector) = (0, 0, 0, 0)
        _MaskMoveSpeed("MaskMoveSpeed", Vector) = (0, 0, 0, 0)
        [Normal]_DistortionMap("DistortionMap", 2D) = "bump" {}
        _DistortionMask("DistortionMask", 2D) = "white" {}
        _AlphaMask("AlphaMask", 2D) = "white" {}
        _StaticDistortionOverlayMask("StaticDistortionOverlayMask", 2D) = "white" {}
        _StaticAlphaOverlayMask("StaticAlphaOverlayMask", 2D) = "white" {}
        [HideInInspector]_CastShadows("_CastShadows", Float) = 0
        [HideInInspector]_Surface("_Surface", Float) = 1
        [HideInInspector]_Blend("_Blend", Float) = 0
        [HideInInspector]_AlphaClip("_AlphaClip", Float) = 0
        [HideInInspector]_SrcBlend("_SrcBlend", Float) = 1
        [HideInInspector]_DstBlend("_DstBlend", Float) = 0
        [HideInInspector][ToggleUI]_ZWrite("_ZWrite", Float) = 0
        [HideInInspector]_ZWriteControl("_ZWriteControl", Float) = 1
        [HideInInspector]_ZTest("_ZTest", Float) = 4
        [HideInInspector]_Cull("_Cull", Float) = 0
        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Unlit"
            "Queue"="Transparent"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalUnlitSubTarget"
            "LightMode" = "UseColorTexture"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                // LightMode: <None>
            }
        
        // Render State
        Cull [_Cull]
        Blend [_SrcBlend] [_DstBlend]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma shader_feature _ _SAMPLE_GI
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_UNLIT
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 texCoord0;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 ViewSpacePosition;
             float3 WorldSpacePosition;
             float4 ScreenPosition;
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float3 interp3 : INTERP3;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.texCoord0;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.texCoord0 = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Divide_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A / B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Absolute_float2(float2 In, out float2 Out)
        {
            Out = abs(In);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_b0e7f0b927814d28ae78e44fac766c14_Out_0 = UnityBuildTexture2DStructNoScale(_GrabbedTexture);
            float4 _ScreenPosition_08ed8b7a683140bc9d297b2264615b6a_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0);
            UnityTexture2D _Property_8cc9188a0d954ed9ade9acf343193fb7_Out_0 = UnityBuildTexture2DStruct(_DistortionMap);
            float4 _UV_924ffcd94bff4bb0a61fd479e64f5476_Out_0 = IN.uv0;
            float2 _Property_729fd3a3d9a149d391a815b4d3d00f8b_Out_0 = _DistortionMoveSpeed;
            float2 _Multiply_e45ac91c32c643b18b214bff13688107_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_729fd3a3d9a149d391a815b4d3d00f8b_Out_0, _Multiply_e45ac91c32c643b18b214bff13688107_Out_2);
            float2 _Add_8fa146493e654d65848a999cfedd957f_Out_2;
            Unity_Add_float2((_UV_924ffcd94bff4bb0a61fd479e64f5476_Out_0.xy), _Multiply_e45ac91c32c643b18b214bff13688107_Out_2, _Add_8fa146493e654d65848a999cfedd957f_Out_2);
            float4 _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0 = SAMPLE_TEXTURE2D(_Property_8cc9188a0d954ed9ade9acf343193fb7_Out_0.tex, _Property_8cc9188a0d954ed9ade9acf343193fb7_Out_0.samplerstate, _Property_8cc9188a0d954ed9ade9acf343193fb7_Out_0.GetTransformedUV(_Add_8fa146493e654d65848a999cfedd957f_Out_2));
            _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0);
            float _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_R_4 = _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0.r;
            float _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_G_5 = _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0.g;
            float _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_B_6 = _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0.b;
            float _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_A_7 = _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0.a;
            float4 _Combine_1be59d8bbaae437c865e6f65b8dbd680_RGBA_4;
            float3 _Combine_1be59d8bbaae437c865e6f65b8dbd680_RGB_5;
            float2 _Combine_1be59d8bbaae437c865e6f65b8dbd680_RG_6;
            Unity_Combine_float(_SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_R_4, _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_G_5, 0, 0, _Combine_1be59d8bbaae437c865e6f65b8dbd680_RGBA_4, _Combine_1be59d8bbaae437c865e6f65b8dbd680_RGB_5, _Combine_1be59d8bbaae437c865e6f65b8dbd680_RG_6);
            float _Distance_780066ed9fb74ff5bb56eeec2f0efb81_Out_2;
            Unity_Distance_float3(IN.ViewSpacePosition, float3(0, 0, 0), _Distance_780066ed9fb74ff5bb56eeec2f0efb81_Out_2);
            float _Property_a61848af4212401a9c8367fa43d0714f_Out_0 = _ScaleWithDistanceFactor;
            float _Lerp_eb0b8ae237984a25aaf6127dcbe567b0_Out_3;
            Unity_Lerp_float(1, _Distance_780066ed9fb74ff5bb56eeec2f0efb81_Out_2, _Property_a61848af4212401a9c8367fa43d0714f_Out_0, _Lerp_eb0b8ae237984a25aaf6127dcbe567b0_Out_3);
            float2 _Divide_3d3020e268d84e40be61eaa0b779259d_Out_2;
            Unity_Divide_float2(_Combine_1be59d8bbaae437c865e6f65b8dbd680_RG_6, (_Lerp_eb0b8ae237984a25aaf6127dcbe567b0_Out_3.xx), _Divide_3d3020e268d84e40be61eaa0b779259d_Out_2);
            float _Property_4950797c4ca949029974b7c801b7dfd0_Out_0 = _DistortionStrength;
            float2 _Multiply_b019fd71eeb545c2b226ae9e8651df0e_Out_2;
            Unity_Multiply_float2_float2(_Divide_3d3020e268d84e40be61eaa0b779259d_Out_2, (_Property_4950797c4ca949029974b7c801b7dfd0_Out_0.xx), _Multiply_b019fd71eeb545c2b226ae9e8651df0e_Out_2);
            UnityTexture2D _Property_f309e6cdabb94e3ab1d2658da014dd02_Out_0 = UnityBuildTexture2DStruct(_DistortionMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f309e6cdabb94e3ab1d2658da014dd02_Out_0.tex, _Property_f309e6cdabb94e3ab1d2658da014dd02_Out_0.samplerstate, _Property_f309e6cdabb94e3ab1d2658da014dd02_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_R_4 = _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_RGBA_0.r;
            float _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_G_5 = _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_RGBA_0.g;
            float _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_B_6 = _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_RGBA_0.b;
            float _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_A_7 = _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_RGBA_0.a;
            UnityTexture2D _Property_8d3be3ed2f46415587f12898629d65c9_Out_0 = UnityBuildTexture2DStruct(_StaticDistortionOverlayMask);
            float4 _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_RGBA_0 = SAMPLE_TEXTURE2D(_Property_8d3be3ed2f46415587f12898629d65c9_Out_0.tex, _Property_8d3be3ed2f46415587f12898629d65c9_Out_0.samplerstate, _Property_8d3be3ed2f46415587f12898629d65c9_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_R_4 = _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_RGBA_0.r;
            float _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_G_5 = _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_RGBA_0.g;
            float _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_B_6 = _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_RGBA_0.b;
            float _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_A_7 = _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_RGBA_0.a;
            float _Multiply_58da25c9c19f4830b1ee5573f6ae2621_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_be309306493d4951aeb0c2ecb2836231_A_7, _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_A_7, _Multiply_58da25c9c19f4830b1ee5573f6ae2621_Out_2);
            float2 _Multiply_386347834182406cb4ba3c161a2be521_Out_2;
            Unity_Multiply_float2_float2(_Multiply_b019fd71eeb545c2b226ae9e8651df0e_Out_2, (_Multiply_58da25c9c19f4830b1ee5573f6ae2621_Out_2.xx), _Multiply_386347834182406cb4ba3c161a2be521_Out_2);
            float2 _Add_5f4038e80cf14747a5d3786cf20746a5_Out_2;
            Unity_Add_float2((_ScreenPosition_08ed8b7a683140bc9d297b2264615b6a_Out_0.xy), _Multiply_386347834182406cb4ba3c161a2be521_Out_2, _Add_5f4038e80cf14747a5d3786cf20746a5_Out_2);
            float2 _Absolute_2a55bfb82c5444b0877d5738c207413b_Out_1;
            Unity_Absolute_float2(_Add_5f4038e80cf14747a5d3786cf20746a5_Out_2, _Absolute_2a55bfb82c5444b0877d5738c207413b_Out_1);
            float4 _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_b0e7f0b927814d28ae78e44fac766c14_Out_0.tex, _Property_b0e7f0b927814d28ae78e44fac766c14_Out_0.samplerstate, _Property_b0e7f0b927814d28ae78e44fac766c14_Out_0.GetTransformedUV(_Absolute_2a55bfb82c5444b0877d5738c207413b_Out_1));
            float _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_R_4 = _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0.r;
            float _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_G_5 = _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0.g;
            float _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_B_6 = _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0.b;
            float _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_A_7 = _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0.a;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.BaseColor = (_SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0.xyz);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ViewSpacePosition = TransformWorldToView(input.positionWS);
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float4 interp1 : INTERP1;
             float4 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.tangentWS;
            output.interp2.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.tangentWS = input.interp1.xyzw;
            output.texCoord0 = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float4 interp1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.texCoord0 = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull [_Cull]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float4 interp1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.texCoord0 = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Unlit"
            "Queue"="Transparent"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalUnlitSubTarget"
            "LightMode" = "UseColorTexture"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                // LightMode: <None>
            }
        
        // Render State
        Cull [_Cull]
        Blend [_SrcBlend] [_DstBlend]
        ZTest [_ZTest]
        ZWrite [_ZWrite]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma shader_feature _ _SAMPLE_GI
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_UNLIT
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 texCoord0;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 ViewSpacePosition;
             float3 WorldSpacePosition;
             float4 ScreenPosition;
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float3 interp3 : INTERP3;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.texCoord0;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.texCoord0 = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }
        
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Divide_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A / B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Absolute_float2(float2 In, out float2 Out)
        {
            Out = abs(In);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_b0e7f0b927814d28ae78e44fac766c14_Out_0 = UnityBuildTexture2DStructNoScale(_GrabbedTexture);
            float4 _ScreenPosition_08ed8b7a683140bc9d297b2264615b6a_Out_0 = float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0);
            UnityTexture2D _Property_8cc9188a0d954ed9ade9acf343193fb7_Out_0 = UnityBuildTexture2DStruct(_DistortionMap);
            float4 _UV_924ffcd94bff4bb0a61fd479e64f5476_Out_0 = IN.uv0;
            float2 _Property_729fd3a3d9a149d391a815b4d3d00f8b_Out_0 = _DistortionMoveSpeed;
            float2 _Multiply_e45ac91c32c643b18b214bff13688107_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_729fd3a3d9a149d391a815b4d3d00f8b_Out_0, _Multiply_e45ac91c32c643b18b214bff13688107_Out_2);
            float2 _Add_8fa146493e654d65848a999cfedd957f_Out_2;
            Unity_Add_float2((_UV_924ffcd94bff4bb0a61fd479e64f5476_Out_0.xy), _Multiply_e45ac91c32c643b18b214bff13688107_Out_2, _Add_8fa146493e654d65848a999cfedd957f_Out_2);
            float4 _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0 = SAMPLE_TEXTURE2D(_Property_8cc9188a0d954ed9ade9acf343193fb7_Out_0.tex, _Property_8cc9188a0d954ed9ade9acf343193fb7_Out_0.samplerstate, _Property_8cc9188a0d954ed9ade9acf343193fb7_Out_0.GetTransformedUV(_Add_8fa146493e654d65848a999cfedd957f_Out_2));
            _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0);
            float _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_R_4 = _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0.r;
            float _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_G_5 = _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0.g;
            float _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_B_6 = _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0.b;
            float _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_A_7 = _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_RGBA_0.a;
            float4 _Combine_1be59d8bbaae437c865e6f65b8dbd680_RGBA_4;
            float3 _Combine_1be59d8bbaae437c865e6f65b8dbd680_RGB_5;
            float2 _Combine_1be59d8bbaae437c865e6f65b8dbd680_RG_6;
            Unity_Combine_float(_SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_R_4, _SampleTexture2D_02c474a45d6746469e7e1a39a66aa9aa_G_5, 0, 0, _Combine_1be59d8bbaae437c865e6f65b8dbd680_RGBA_4, _Combine_1be59d8bbaae437c865e6f65b8dbd680_RGB_5, _Combine_1be59d8bbaae437c865e6f65b8dbd680_RG_6);
            float _Distance_780066ed9fb74ff5bb56eeec2f0efb81_Out_2;
            Unity_Distance_float3(IN.ViewSpacePosition, float3(0, 0, 0), _Distance_780066ed9fb74ff5bb56eeec2f0efb81_Out_2);
            float _Property_a61848af4212401a9c8367fa43d0714f_Out_0 = _ScaleWithDistanceFactor;
            float _Lerp_eb0b8ae237984a25aaf6127dcbe567b0_Out_3;
            Unity_Lerp_float(1, _Distance_780066ed9fb74ff5bb56eeec2f0efb81_Out_2, _Property_a61848af4212401a9c8367fa43d0714f_Out_0, _Lerp_eb0b8ae237984a25aaf6127dcbe567b0_Out_3);
            float2 _Divide_3d3020e268d84e40be61eaa0b779259d_Out_2;
            Unity_Divide_float2(_Combine_1be59d8bbaae437c865e6f65b8dbd680_RG_6, (_Lerp_eb0b8ae237984a25aaf6127dcbe567b0_Out_3.xx), _Divide_3d3020e268d84e40be61eaa0b779259d_Out_2);
            float _Property_4950797c4ca949029974b7c801b7dfd0_Out_0 = _DistortionStrength;
            float2 _Multiply_b019fd71eeb545c2b226ae9e8651df0e_Out_2;
            Unity_Multiply_float2_float2(_Divide_3d3020e268d84e40be61eaa0b779259d_Out_2, (_Property_4950797c4ca949029974b7c801b7dfd0_Out_0.xx), _Multiply_b019fd71eeb545c2b226ae9e8651df0e_Out_2);
            UnityTexture2D _Property_f309e6cdabb94e3ab1d2658da014dd02_Out_0 = UnityBuildTexture2DStruct(_DistortionMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f309e6cdabb94e3ab1d2658da014dd02_Out_0.tex, _Property_f309e6cdabb94e3ab1d2658da014dd02_Out_0.samplerstate, _Property_f309e6cdabb94e3ab1d2658da014dd02_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_R_4 = _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_RGBA_0.r;
            float _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_G_5 = _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_RGBA_0.g;
            float _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_B_6 = _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_RGBA_0.b;
            float _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_A_7 = _SampleTexture2D_be309306493d4951aeb0c2ecb2836231_RGBA_0.a;
            UnityTexture2D _Property_8d3be3ed2f46415587f12898629d65c9_Out_0 = UnityBuildTexture2DStruct(_StaticDistortionOverlayMask);
            float4 _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_RGBA_0 = SAMPLE_TEXTURE2D(_Property_8d3be3ed2f46415587f12898629d65c9_Out_0.tex, _Property_8d3be3ed2f46415587f12898629d65c9_Out_0.samplerstate, _Property_8d3be3ed2f46415587f12898629d65c9_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_R_4 = _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_RGBA_0.r;
            float _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_G_5 = _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_RGBA_0.g;
            float _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_B_6 = _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_RGBA_0.b;
            float _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_A_7 = _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_RGBA_0.a;
            float _Multiply_58da25c9c19f4830b1ee5573f6ae2621_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_be309306493d4951aeb0c2ecb2836231_A_7, _SampleTexture2D_956afe5a67064a08a3c094d53c4657ba_A_7, _Multiply_58da25c9c19f4830b1ee5573f6ae2621_Out_2);
            float2 _Multiply_386347834182406cb4ba3c161a2be521_Out_2;
            Unity_Multiply_float2_float2(_Multiply_b019fd71eeb545c2b226ae9e8651df0e_Out_2, (_Multiply_58da25c9c19f4830b1ee5573f6ae2621_Out_2.xx), _Multiply_386347834182406cb4ba3c161a2be521_Out_2);
            float2 _Add_5f4038e80cf14747a5d3786cf20746a5_Out_2;
            Unity_Add_float2((_ScreenPosition_08ed8b7a683140bc9d297b2264615b6a_Out_0.xy), _Multiply_386347834182406cb4ba3c161a2be521_Out_2, _Add_5f4038e80cf14747a5d3786cf20746a5_Out_2);
            float2 _Absolute_2a55bfb82c5444b0877d5738c207413b_Out_1;
            Unity_Absolute_float2(_Add_5f4038e80cf14747a5d3786cf20746a5_Out_2, _Absolute_2a55bfb82c5444b0877d5738c207413b_Out_1);
            float4 _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_b0e7f0b927814d28ae78e44fac766c14_Out_0.tex, _Property_b0e7f0b927814d28ae78e44fac766c14_Out_0.samplerstate, _Property_b0e7f0b927814d28ae78e44fac766c14_Out_0.GetTransformedUV(_Absolute_2a55bfb82c5444b0877d5738c207413b_Out_1));
            float _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_R_4 = _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0.r;
            float _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_G_5 = _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0.g;
            float _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_B_6 = _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0.b;
            float _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_A_7 = _SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0.a;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.BaseColor = (_SampleTexture2D_22191ccf140e4da89aecfbd94df4bb9e_RGBA_0.xyz);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.WorldSpacePosition = input.positionWS;
            output.ViewSpacePosition = TransformWorldToView(input.positionWS);
            output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float4 interp1 : INTERP1;
             float4 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.tangentWS;
            output.interp2.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.tangentWS = input.interp1.xyzw;
            output.texCoord0 = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float4 interp1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.texCoord0 = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull [_Cull]
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 interp0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.interp0.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
        
        // Render State
        Cull [_Cull]
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature_fragment _ _SURFACE_TYPE_TRANSPARENT
        #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON
        #pragma shader_feature_local_fragment _ _ALPHATEST_ON
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float4 interp1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            output.interp1.xyzw =  input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;
            output.texCoord0 = input.interp1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _DistortionMoveSpeed;
        float _DistortionStrength;
        float _ScaleWithDistanceFactor;
        float4 _DistortionMap_TexelSize;
        float4 _DistortionMap_ST;
        float4 _DistortionMask_TexelSize;
        float4 _DistortionMask_ST;
        float4 _AlphaMask_TexelSize;
        float4 _AlphaMask_ST;
        float2 _MaskMoveSpeed;
        float4 _StaticDistortionOverlayMask_TexelSize;
        float4 _StaticDistortionOverlayMask_ST;
        float4 _StaticAlphaOverlayMask_TexelSize;
        float4 _StaticAlphaOverlayMask_ST;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_DistortionMap);
        SAMPLER(sampler_DistortionMap);
        TEXTURE2D(_DistortionMask);
        SAMPLER(sampler_DistortionMask);
        TEXTURE2D(_AlphaMask);
        SAMPLER(sampler_AlphaMask);
        TEXTURE2D(_StaticDistortionOverlayMask);
        SAMPLER(sampler_StaticDistortionOverlayMask);
        TEXTURE2D(_StaticAlphaOverlayMask);
        SAMPLER(sampler_StaticAlphaOverlayMask);
        TEXTURE2D(_GrabbedTexture);
        SAMPLER(sampler_GrabbedTexture);
        float4 _GrabbedTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_892be006e1554999a18ecee47125c1a8_Out_0 = UnityBuildTexture2DStruct(_AlphaMask);
            float4 _UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0 = IN.uv0;
            float2 _Property_569e440d30a94fc88e60249971198f9d_Out_0 = _MaskMoveSpeed;
            float2 _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2;
            Unity_Multiply_float2_float2((IN.TimeParameters.x.xx), _Property_569e440d30a94fc88e60249971198f9d_Out_0, _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2);
            float2 _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2;
            Unity_Add_float2((_UV_1ccddc1c7a5c4c91897cccfc9b0f5ff2_Out_0.xy), _Multiply_29b0222f045240b294c2eb2a68e604d3_Out_2, _Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2);
            float4 _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0 = SAMPLE_TEXTURE2D(_Property_892be006e1554999a18ecee47125c1a8_Out_0.tex, _Property_892be006e1554999a18ecee47125c1a8_Out_0.samplerstate, _Property_892be006e1554999a18ecee47125c1a8_Out_0.GetTransformedUV(_Add_9f9c3a181647424cb926ec8a469f8bdb_Out_2));
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_R_4 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.r;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_G_5 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.g;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_B_6 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.b;
            float _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7 = _SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_RGBA_0.a;
            UnityTexture2D _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0 = UnityBuildTexture2DStruct(_StaticAlphaOverlayMask);
            float4 _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.tex, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.samplerstate, _Property_f1f8eec802f046e2948a7ecf916f831d_Out_0.GetTransformedUV(IN.uv0.xy));
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_R_4 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.r;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_G_5 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.g;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_B_6 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.b;
            float _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7 = _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_RGBA_0.a;
            float _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_25f627f67b7448dba0cdb2699214ca8a_A_7, _SampleTexture2D_1a1b78c8489f455da72c7b08da7f38de_A_7, _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2);
            surface.Alpha = _Multiply_0aa7d984712a41118a4822c6e2961a10_Out_2;
            surface.AlphaClipThreshold = 0.5;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
            output.uv0 = input.texCoord0;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    CustomEditorForRenderPipeline "UnityEditor.ShaderGraphUnlitGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}