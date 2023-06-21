#ifndef UNIVERSAL_SIMPLE_LIT_INPUT_INCLUDED
#define UNIVERSAL_SIMPLE_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    half4 _BaseColor;
    half4 _SpecColor;
    half4 _EmissionColor;
    half _Cutoff;
    half _Surface;
    //ToonShading
    half _ToonDiffuseRampV;
    half _ToonDiffuseRampOffset;
    half _ToonOutlineWidth;
    half _ToonOutlineWidthColorR;
    half4 _ToonOutlineColor;
    half _ToonPointShadowEnable;
    half3 _ToonPointShadowPosition;
    half _ToonDepthShadowEnable;
    half _ToonSDFShadowEnable;
    half2 _ToonSDFShadowLdotFL;
    half3 _ToonMatCapColor;
    half _ToonMatCapUVScale;
    float _ToonID;
CBUFFER_END

#ifdef UNITY_DOTS_INSTANCING_ENABLED
    UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
        UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
        UNITY_DOTS_INSTANCED_PROP(float4, _SpecColor)
        UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
        UNITY_DOTS_INSTANCED_PROP(float , _Cutoff)
        UNITY_DOTS_INSTANCED_PROP(float , _Surface)
        //ToonShading
        UNITY_DOTS_INSTANCED_PROP(float, _ToonDiffuseRampV)
        UNITY_DOTS_INSTANCED_PROP(float, _ToonDiffuseRampOffset)
        UNITY_DOTS_INSTANCED_PROP(float, _ToonOutlineWidth)
        UNITY_DOTS_INSTANCED_PROP(float, _ToonOutlineWidthColorR)
        UNITY_DOTS_INSTANCED_PROP(float4, _ToonOutlineColor)
        UNITY_DOTS_INSTANCED_PROP(float, _ToonPointShadowEnable)
        UNITY_DOTS_INSTANCED_PROP(float3, _ToonPointShadowPosition)
        UNITY_DOTS_INSTANCED_PROP(float, _ToonDepthShadowEnable)
        UNITY_DOTS_INSTANCED_PROP(float, _ToonSDFShadowEnable)
        UNITY_DOTS_INSTANCED_PROP(float2, _ToonSDFShadowLdotFL)
        UNITY_DOTS_INSTANCED_PROP(float3, _ToonMatCapColor)
        UNITY_DOTS_INSTANCED_PROP(float, _ToonMatCapUVScale)
        UNITY_DOTS_INSTANCED_PROP(float, _ToonID)
    UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

    #define _BaseColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4 , _BaseColor)
    #define _SpecColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4 , _SpecColor)
    #define _EmissionColor      UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4 , _EmissionColor)
    #define _Cutoff             UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _Cutoff)
    #define _Surface            UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _Surface)
    //ToonShading
    #define _ToonDiffuseRampV             UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ToonDiffuseRampV)
    #define _ToonDiffuseRampOffset           UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ToonDiffuseRampOffset)
    #define _ToonOutlineWidth             UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ToonOutlineWidth)
    #define _ToonOutlineWidthColorR             UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ToonOutlineWidthColorR)
    #define _ToonOutlineColor             UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4  , _ToonOutlineColor)
    #define _ToonPointShadowEnable            UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ToonPointShadowEnable)
    #define _ToonPointShadowPosition             UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float3  , _ToonPointShadowPosition)
    #define _ToonDepthShadowEnable         UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ToonDepthShadowEnable)
    #define _ToonSDFShadowEnable         UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ToonSDFShadowEnable)
    #define _ToonSDFShadowLdotF         UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float2  , _ToonSDFShadowLdotFL)
    #define _ToonMatCapColor         UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float3  , _ToonMatCapColor)
    #define _ToonMatCapUVScale         UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ToonMatCapUVScale)
    #define _ToonID           UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ToonID)
#endif

TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);

//ToonShading
TEXTURE2D(_ToonStaticShadowMap);
TEXTURE2D(_ToonSDFShadowMap);
TEXTURE2D(_ToonMatCapMap);       SAMPLER(sampler_ToonMatCapMap_Linear_Clamp);

half4 SampleSpecularSmoothness(float2 uv, half alpha, half4 specColor, TEXTURE2D_PARAM(specMap, sampler_specMap))
{
    half4 specularSmoothness = half4(0, 0, 0, 1);
#ifdef _SPECGLOSSMAP
    specularSmoothness = SAMPLE_TEXTURE2D(specMap, sampler_specMap, uv) * specColor;
#elif defined(_SPECULAR_COLOR)
    specularSmoothness = specColor;
#endif

#ifdef _GLOSSINESS_FROM_BASE_ALPHA
    specularSmoothness.a = alpha;
#endif

    return specularSmoothness;
}

inline void InitializeSimpleLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    outSurfaceData = (SurfaceData)0;

    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = albedoAlpha.a * _BaseColor.a;
    outSurfaceData.alpha = AlphaDiscard(outSurfaceData.alpha, _Cutoff);

    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    outSurfaceData.albedo = AlphaModulate(outSurfaceData.albedo, outSurfaceData.alpha);

    half4 specularSmoothness = SampleSpecularSmoothness(uv, outSurfaceData.alpha, _SpecColor, TEXTURE2D_ARGS(_SpecGlossMap, sampler_SpecGlossMap));
    outSurfaceData.metallic = 0.0; // unused
    outSurfaceData.specular = specularSmoothness.rgb;
    outSurfaceData.smoothness = specularSmoothness.a;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
    outSurfaceData.occlusion = 1.0;
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
}

half ToonSDFShadow(float2 uv)
{
    float flipUVx = step(0.0, _ToonSDFShadowLdotFL.y) * 2.0 - 1.0;
    float2 SDF_UV = float2(uv.x * flipUVx, uv.y);
    float SDFShadowMask = SAMPLE_TEXTURE2D(_ToonSDFShadowMap, sampler_BaseMap, SDF_UV);
    const float SDFShadowFeather = 0.0;
    float SDFShadow = 1.0 - saturate((1 - SDFShadowMask - saturate(_ToonSDFShadowLdotFL.x) - _ToonDiffuseRampOffset) / SDFShadowFeather + 1.0);
    
    SDFShadow = lerp(1.0, SDFShadow, _ToonSDFShadowEnable);
    return SDFShadow;
}

half3 SampleToonMatCap(half3 normalWS)
{
    half3 viewNormal = TransformWorldToViewDir(normalWS);
    float2 uv = viewNormal.xy * 0.5 + 0.5;
    return SAMPLE_TEXTURE2D(_ToonMatCapMap, sampler_ToonMatCapMap_Linear_Clamp, (uv - _ToonMatCapUVScale) / (1 - 2 * _ToonMatCapUVScale)).rgb * _ToonMatCapColor;
}

ToonData InitializeToonData(float2 uv)
{
    ToonData outToonData = (ToonData)0;
    outToonData.toonDiffuseRampV = _ToonDiffuseRampV;
    outToonData.toonDiffuseRampOffset = _ToonDiffuseRampOffset * 0.5 + 0.5;
    outToonData.toonPointShadowEnable = _ToonPointShadowEnable;
    outToonData.toonPointShadowPosition = _ToonPointShadowPosition;
    outToonData.toonInLighting = 1.0;
    outToonData.toonDepthShadowEnable = _ToonDepthShadowEnable;
    outToonData.toonStaticShadow = SAMPLE_TEXTURE2D(_ToonStaticShadowMap, sampler_BaseMap, uv);
    outToonData.toonStaticShadow *= ToonSDFShadow(uv);
    outToonData.toonSDFShadowEnable = _ToonSDFShadowEnable;

    return outToonData;
}

#endif
