Shader "Custom/StencilThrough"
{
    Properties
    {
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Opacity("Opacity (앞머리 위 투명도)", Range(0, 1)) = 0.5
        [IntRange] _StencilRef("Stencil Ref (머리카락 번호)", Range(0, 255)) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"            // ③ 불투명(앞머리)이 모두 그려진 "뒤"에 그리기
        }

        Pass
        {
            Name "StencilThrough"
            Tags { "LightMode" = "UniversalForward" }

            // ── 렌더 상태: 이 셰이더의 핵심 ──
            Stencil
            {
                Ref [_StencilRef]
                Comp Equal                      // 스텐실 == 1 (앞머리가 덮은 곳)에서만 통과
            }
            ZTest Always                        // 깊이 테스트 무시 → 앞머리에 가려져도 그림
            ZWrite Off                          // 반투명이라 깊이는 기록하지 않음
            Cull Back                           // 뒤에서 볼 때 눈썹 뒷면은 버림 (뒤통수 비침 방지)
            Blend SrcAlpha OneMinusSrcAlpha     // 반투명 섞기

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _Opacity;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 color = tex.rgb * _BaseColor.rgb;
                half alpha = tex.a * _BaseColor.a * _Opacity;   // 텍스처 알파로 눈썹 모양만 남기고, 투명도 조절
                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}