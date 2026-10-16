#ifndef CUSTOM_LIT_OUTLINE_PASS_INCLUDED
#define CUSTOM_LIT_OUTLINE_PASS_INCLUDED

#include "CustomLitInput.hlsl"   // CBUFFER 공유 (SRP Batcher 호환)

struct OutlineAttributes
{
    float4 positionOS : POSITION;
    float3 normalOS   : NORMAL;
    float2 texcoord   : TEXCOORD0;      // ★ 텍스처 색을 쓰기 위해 UV 추가
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct OutlineVaryings
{
    float4 positionCS : SV_POSITION;
    float2 uv         : TEXCOORD0;      // ★ 프래그먼트로 UV 전달
};

OutlineVaryings OutlinePassVertex(OutlineAttributes input)
{
    OutlineVaryings output = (OutlineVaryings)0;
    UNITY_SETUP_INSTANCE_ID(input);

#if defined(_OUTLINE_ON)
    // 3단계: 클립 공간(화면 기준)에서 밀어내기
    float4 positionCS = TransformObjectToHClip(input.positionOS.xyz);

    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    float3 normalCS = TransformWorldToHClipDir(normalWS);

    // 0.005 고정값 → 슬라이더 (Width 1 ≈ 1080p에서 약 0.5픽셀)
    float2 offset = normalize(normalCS.xy) * (_OutlineWidth * 0.001) * positionCS.w;
    offset.x *= _ScreenParams.y / _ScreenParams.x;

    positionCS.xy += offset;
    output.positionCS = positionCS;
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
#else
    // 외곽선 OFF: 화면 밖(클립 공간 범위 바깥)으로 보내서 그리지 않음
    output.positionCS = float4(2.0, 2.0, 2.0, 1.0);
#endif

    return output;
}

half4 OutlinePassFragment(OutlineVaryings input) : SV_Target
{
    // 단색 외곽선과 "텍스처 색 × 외곽선 색"을 섞기
    half3 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb;
    half3 outlineColor = _OutlineColor.rgb * lerp(1.0, baseColor, _OutlineBaseMapBlend);
    return half4(outlineColor, 1);
}

#endif