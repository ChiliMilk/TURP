#ifndef UNIVERSAL_TOONSHADINGCOMMON_INCLUDED
#define UNIVERSAL_TOONSHADINGCOMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"

//ToonShading
TEXTURE2D_X(_ToonDiffuseRamp);
SAMPLER(sampler_ToonDiffuseRamp_Point_Clamp);
TEXTURE2D_X(_ToonDepthTexture);
SAMPLER(sampler_ToonDepthTexture_Point_Clamp);
TEXTURE2D_X(_ToonDataTexture);
SAMPLER(sampler_ToonDataTexture_Point_Clamp);

half StepFeatherToon(half value, half toonStep, half toonFeather)
{
    return saturate((value - toonStep + toonFeather) / toonFeather);
}

half DirectBRDFSpecularToon(BRDFData brdfData, ToonData toonData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
    float3 lightDirectionWSFloat3 = float3(lightDirectionWS);
    float3 halfDir = SafeNormalize(lightDirectionWSFloat3 + float3(viewDirectionWS));

    float NoH = saturate(dot(float3(normalWS), halfDir));
    half LoH = half(saturate(dot(lightDirectionWSFloat3, halfDir)));

    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
    float d2 = d * d;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d2) * max(0.1h, LoH2) * brdfData.normalizationTerm);
    half normalizeSpec = brdfData.roughness2 * brdfData.roughness2 * rcp(d2);

    specularTerm *= StepFeatherToon(normalizeSpec, 0.8, toonData.toonSpecularFeather);
#if REAL_IS_HALF
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0);
#endif

    return specularTerm;
}

half DirectSpecularToonSimpleLit(ToonData toonData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS, half smoothness)
{
    half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    half roughness = max(PerceptualRoughnessToRoughness(perceptualRoughness), HALF_MIN_SQRT);
    half roughness2 = max(roughness * roughness, HALF_MIN);
    half normalizationTerm = roughness * half(4.0) + half(2.0);
    half roughness2MinusOne = roughness2 - half(1.0);

    float3 lightDirectionWSFloat3 = float3(lightDirectionWS);
    float3 halfDir = SafeNormalize(lightDirectionWSFloat3 + float3(viewDirectionWS));

    float NoH = saturate(dot(float3(normalWS), halfDir));
    half LoH = half(saturate(dot(lightDirectionWSFloat3, halfDir)));

    float d = NoH * NoH * roughness2MinusOne + 1.00001f;
    float d2 = d * d;

    half LoH2 = LoH * LoH;
    half specularTerm = roughness2 / ((d2)*max(0.1h, LoH2) * normalizationTerm);
    half normalizeSpec = roughness2 * roughness2 * rcp(d2);

    specularTerm *= StepFeatherToon(normalizeSpec, 0.8, 0.01);
#if REAL_IS_HALF
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0);
#endif

    return specularTerm;
}

#endif
