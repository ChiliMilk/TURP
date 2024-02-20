#ifndef UNIVERSAL_LIGHTING_INCLUDED
#define UNIVERSAL_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
//ToonShading
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ToonShadingCommon.hlsl"

#if defined(LIGHTMAP_ON)
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) float2 lmName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
    #define OUTPUT_SH(normalWS, OUT)
#else
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
    #define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
#endif

///////////////////////////////////////////////////////////////////////////////
//                      Lighting Functions                                   //
///////////////////////////////////////////////////////////////////////////////
half3 LightingLambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
}

half3 LightingSpecular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half4 specular, half smoothness)
{
    float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
    half NdotH = half(saturate(dot(normal, halfVec)));
    half modifier = pow(NdotH, smoothness);
    half3 specularReflection = specular.rgb * modifier;
    return lightColor * specularReflection;
}

half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
    half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
    half3 normalWS, half3 viewDirectionWS,
    half clearCoatMask, bool specularHighlightsOff)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
#ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
        // We rely on the compiler to merge these and compute them only once.
        half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

            // Mix clear coat and base layer using khronos glTF recommended formula
            // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
            // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
            half NoV = saturate(dot(normalWS, viewDirectionWS));
            // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
            // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
            half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

        brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
#endif // _CLEARCOAT
    }
#endif // _SPECULARHIGHLIGHTS_OFF

    return brdf * radiance;
}

half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff)
{
    return LightingPhysicallyBased(brdfData, brdfDataClearCoat, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, clearCoatMask, specularHighlightsOff);
}

// Backwards compatibility
half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    #ifdef _SPECULARHIGHLIGHTS_OFF
    bool specularHighlightsOff = true;
#else
    bool specularHighlightsOff = false;
#endif
    const BRDFData noClearCoat = (BRDFData)0;
    return LightingPhysicallyBased(brdfData, noClearCoat, light, normalWS, viewDirectionWS, 0.0, specularHighlightsOff);
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    Light light;
    light.color = lightColor;
    light.direction = lightDirectionWS;
    light.distanceAttenuation = lightAttenuation;
    light.shadowAttenuation   = 1;
    return LightingPhysicallyBased(brdfData, light, normalWS, viewDirectionWS);
}

half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    const BRDFData noClearCoat = (BRDFData)0;
    return LightingPhysicallyBased(brdfData, noClearCoat, light, normalWS, viewDirectionWS, 0.0, specularHighlightsOff);
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    Light light;
    light.color = lightColor;
    light.direction = lightDirectionWS;
    light.distanceAttenuation = lightAttenuation;
    light.shadowAttenuation   = 1;
    return LightingPhysicallyBased(brdfData, light, viewDirectionWS, specularHighlightsOff, specularHighlightsOff);
}

half3 LightingToonLit(BRDFData brdfData, ToonData toonData, Light light, half3 normalWS, half3 viewDirectionWS, half depthShadow, bool specularHighlightsOff)
{
    //ToonShading
    half NdotL = dot(normalWS, light.direction);
    half NdotL_Half = NdotL * 0.5 + 0.5;
    half3 radiance = 0.0;
    half specRadiance = 0.0;
#if defined(_DEFERRED_MAIN_LIGHT)
    radiance = SAMPLE_TEXTURE2D_X_LOD(_ToonDiffuseRamp, sampler_ToonDiffuseRamp_Point_Clamp, half2(NdotL_Half * light.shadowAttenuation * depthShadow, toonData.toonDiffuseRampV), 0) * light.distanceAttenuation;
    specRadiance = saturate(NdotL) * light.shadowAttenuation * light.distanceAttenuation * depthShadow;
#else
    radiance = SAMPLE_TEXTURE2D_X_LOD(_ToonDiffuseRamp, sampler_ToonDiffuseRamp_Point_Clamp, half2(NdotL_Half * light.shadowAttenuation, frac(toonData.toonDiffuseRampV * 10) * 0.1), 0) * light.distanceAttenuation;
    specRadiance = saturate(NdotL) * light.shadowAttenuation * light.distanceAttenuation;
#endif
    half3 toonColor = brdfData.diffuse * radiance;
#ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        toonColor += brdfData.specular * DirectBRDFSpecularToon(brdfData, toonData, normalWS, light.direction, viewDirectionWS) * specRadiance;
    }
#endif // _SPECULARHIGHLIGHTS_OFF

    return toonColor * light.color;
}

half3 LightingToonSimpleLit(SurfaceData surfaceData, ToonData toonData, Light light, half3 normalWS, half3 viewDirectionWS, float depthShadow)
{
    //ToonShading
    half NdotL = dot(normalWS, light.direction);
    half NdotL_Half = NdotL * 0.5 + 0.5;
    float ToonDiffuseOffset = toonData.toonDiffuseRampOffset * 2.0 - 1.0;
    NdotL_Half = lerp(NdotL_Half, 1.0, toonData.toonSDFShadowEnable); //When use SDFShadow, ignore NdotL
    ToonDiffuseOffset = lerp(ToonDiffuseOffset, 0.0, toonData.toonSDFShadowEnable); //When use SDFShadow, ignore Offset
    half3 radiance = 0.0;
    half specRadiance = 0.0;
#if defined(_DEFERRED_MAIN_LIGHT)
    radiance = SAMPLE_TEXTURE2D_X_LOD(_ToonDiffuseRamp, sampler_ToonDiffuseRamp_Point_Clamp, half2(NdotL_Half * light.shadowAttenuation * toonData.toonStaticShadow * depthShadow + ToonDiffuseOffset, toonData.toonDiffuseRampV), 0) * light.distanceAttenuation;
    specRadiance = saturate(NdotL) * light.shadowAttenuation * light.distanceAttenuation * toonData.toonStaticShadow * depthShadow;
#else
    radiance = SAMPLE_TEXTURE2D_X_LOD(_ToonDiffuseRamp, sampler_ToonDiffuseRamp_Point_Clamp, half2(NdotL_Half * light.shadowAttenuation* toonData.toonStaticShadow + ToonDiffuseOffset, frac(toonData.toonDiffuseRampV * 10) * 0.1), 0) * light.distanceAttenuation; //10 RampColor, sample first one. 
    specRadiance = saturate(NdotL) * light.shadowAttenuation * light.distanceAttenuation * toonData.toonStaticShadow;
#endif
    half3 toonColor = surfaceData.albedo * radiance;
    toonColor += surfaceData.specular.r * DirectSpecularToonSimpleLit(toonData, normalWS, light.direction, viewDirectionWS, surfaceData.smoothness) * specRadiance;

    return toonColor * light.color;
}

half3 LightingToonForwardLit(BRDFData brdfData, ToonData toonData, Light light, half3 normalWS, half3 viewDirectionWS, float depthShadow, bool specularHighlightsOff, bool isMain)
{
    //ToonShading
    half NdotL = dot(normalWS, light.direction);
    half NdotL_Half = NdotL * 0.5 + 0.5;
    half3 radiance = 0.0;
    half specRadiance = 0.0;
    [branch] 
    if (isMain)
    {
        radiance = SAMPLE_TEXTURE2D_X_LOD(_ToonDiffuseRamp, sampler_ToonDiffuseRamp_Point_Clamp, half2(NdotL_Half * light.shadowAttenuation * depthShadow, toonData.toonDiffuseRampV), 0) * light.distanceAttenuation;
        specRadiance = saturate(NdotL) * light.shadowAttenuation * light.distanceAttenuation * depthShadow;
    }
    else
    {
        radiance = SAMPLE_TEXTURE2D_X_LOD(_ToonDiffuseRamp, sampler_ToonDiffuseRamp_Point_Clamp, half2(NdotL_Half * light.shadowAttenuation, frac(toonData.toonDiffuseRampV * 10) * 0.1), 0) * light.distanceAttenuation;
        specRadiance = saturate(NdotL) * light.shadowAttenuation * light.distanceAttenuation;
    }
    half3 toonColor = brdfData.diffuse * radiance;
#ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        toonColor += brdfData.specular * DirectBRDFSpecularToon(brdfData, toonData, normalWS, light.direction, viewDirectionWS) * specRadiance;
    }
#endif // _SPECULARHIGHLIGHTS_OFF

    return toonColor * light.color;
}

half3 LightingToonForwardSimpleLit(SurfaceData surfaceData, ToonData toonData, Light light, half3 normalWS, half3 viewDirectionWS, float depthShadow, bool isMain)
{
    //ToonShading
    half NdotL = dot(normalWS, light.direction);
    half NdotL_Half = NdotL * 0.5 + 0.5;
    float ToonDiffuseOffset = toonData.toonDiffuseRampOffset * 2.0 - 1.0;
    NdotL_Half = lerp(NdotL_Half, 1.0, toonData.toonSDFShadowEnable); //When use SDFShadow, ignore NdotL
    ToonDiffuseOffset = lerp(ToonDiffuseOffset, 0.0, toonData.toonSDFShadowEnable); //When use SDFShadow, ignore Offset
    half3 radiance = 0.0;
    half specRadiance = 0.0;
    [branch]
    if (isMain)
    {
        radiance = SAMPLE_TEXTURE2D_X_LOD(_ToonDiffuseRamp, sampler_ToonDiffuseRamp_Point_Clamp, half2(NdotL_Half * light.shadowAttenuation * toonData.toonStaticShadow * depthShadow + ToonDiffuseOffset, toonData.toonDiffuseRampV), 0) * light.distanceAttenuation;
        specRadiance = saturate(NdotL) * light.shadowAttenuation * light.distanceAttenuation * toonData.toonStaticShadow * depthShadow;
    }
    else
    {
        radiance = SAMPLE_TEXTURE2D_X_LOD(_ToonDiffuseRamp, sampler_ToonDiffuseRamp_Point_Clamp, half2(NdotL_Half * light.shadowAttenuation * toonData.toonStaticShadow + ToonDiffuseOffset, frac(toonData.toonDiffuseRampV * 10) * 0.1), 0) * light.distanceAttenuation;
        specRadiance = saturate(NdotL) * light.shadowAttenuation * light.distanceAttenuation * toonData.toonStaticShadow;
    }
    half3 toonColor = surfaceData.albedo * radiance;
    toonColor += surfaceData.specular.r * DirectSpecularToonSimpleLit(toonData, normalWS, light.direction, viewDirectionWS, surfaceData.smoothness) * specRadiance;

    return toonColor * light.color;
}

half3 VertexLighting(float3 positionWS, half3 normalWS)
{
    half3 vertexLightColor = half3(0.0, 0.0, 0.0);

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint lightsCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(lightsCount)
        Light light = GetAdditionalLight(lightIndex, positionWS);
        half3 lightColor = light.color * light.distanceAttenuation;
        vertexLightColor += LightingLambert(lightColor, light.direction, normalWS);
    LIGHT_LOOP_END
#endif

    return vertexLightColor;
}

struct LightingData
{
    half3 giColor;
    half3 mainLightColor;
    half3 additionalLightsColor;
    half3 vertexLightingColor;
    half3 emissionColor;
};

half3 CalculateLightingColor(LightingData lightingData, half3 albedo)
{
    half3 lightingColor = 0;

    if (IsOnlyAOLightingFeatureEnabled())
    {
        return lightingData.giColor; // Contains white + AO
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_GLOBAL_ILLUMINATION))
    {
        lightingColor += lightingData.giColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_MAIN_LIGHT))
    {
        lightingColor += lightingData.mainLightColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_ADDITIONAL_LIGHTS))
    {
        lightingColor += lightingData.additionalLightsColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_VERTEX_LIGHTING))
    {
        lightingColor += lightingData.vertexLightingColor;
    }

    lightingColor *= albedo;

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_EMISSION))
    {
        lightingColor += lightingData.emissionColor;
    }

    return lightingColor;
}

half4 CalculateFinalColor(LightingData lightingData, half alpha)
{
    half3 finalColor = CalculateLightingColor(lightingData, 1);

    return half4(finalColor, alpha);
}

half4 CalculateFinalColor(LightingData lightingData, half3 albedo, half alpha, float fogCoord)
{
    #if defined(_FOG_FRAGMENT)
        #if (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))
        float viewZ = -fogCoord;
        float nearToFarZ = max(viewZ - _ProjectionParams.y, 0);
        half fogFactor = ComputeFogFactorZ0ToFar(nearToFarZ);
    #else
        half fogFactor = 0;
        #endif
    #else
    half fogFactor = fogCoord;
    #endif
    half3 lightingColor = CalculateLightingColor(lightingData, albedo);
    half3 finalColor = MixFog(lightingColor, fogFactor);

    return half4(finalColor, alpha);
}

LightingData CreateLightingData(InputData inputData, SurfaceData surfaceData)
{
    LightingData lightingData;

    lightingData.giColor = inputData.bakedGI;
    lightingData.emissionColor = surfaceData.emission;
    lightingData.vertexLightingColor = 0;
    lightingData.mainLightColor = 0;
    lightingData.additionalLightsColor = 0;

    return lightingData;
}

half3 CalculateBlinnPhong(Light light, InputData inputData, SurfaceData surfaceData)
{
    half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
    half3 lightDiffuseColor = LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);

    half3 lightSpecularColor = half3(0,0,0);
    #if defined(_SPECGLOSSMAP) || defined(_SPECULAR_COLOR)
    half smoothness = exp2(10 * surfaceData.smoothness + 1);

    lightSpecularColor += LightingSpecular(attenuatedLightColor, light.direction, inputData.normalWS, inputData.viewDirectionWS, half4(surfaceData.specular, 1), smoothness);
    #endif

#if _ALPHAPREMULTIPLY_ON
    return lightDiffuseColor * surfaceData.albedo * surfaceData.alpha + lightSpecularColor;
#else
    return lightDiffuseColor * surfaceData.albedo + lightSpecularColor;
#endif
}

///////////////////////////////////////////////////////////////////////////////
//                      Fragment Functions                                   //
//       Used by ShaderGraph and others builtin renderers                    //
///////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// PBR lighting...
////////////////////////////////////////////////////////////////////////////////
half4 UniversalFragmentPBR(InputData inputData, SurfaceData surfaceData)
{
    #if defined(_SPECULARHIGHLIGHTS_OFF)
    bool specularHighlightsOff = true;
    #else
    bool specularHighlightsOff = false;
    #endif
    BRDFData brdfData;

    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);

    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        return debugColor;
    }
    #endif

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                              inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor = LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                              mainLight,
                                                              inputData.normalWS, inputData.viewDirectionWS,
                                                              surfaceData.clearCoatMask, specularHighlightsOff);
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

    return CalculateFinalColor(lightingData, surfaceData.alpha);
}

half4 UniversalFragmentToon(InputData inputData, SurfaceData surfaceData, ToonData toonData, float4 positionCS)
{
#if defined(_SPECULARHIGHLIGHTS_OFF)
    bool specularHighlightsOff = true;
#else
    bool specularHighlightsOff = false;
#endif
    BRDFData brdfData;

    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);

#if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        return debugColor;
    }
#endif

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
#ifdef _RECEIVE_SHADOWS_OFF
    [branch] if (toonData.toonPointShadowEnable) 
    {
        toonData.toonInLighting = MainLightRealtimeShadowPoint(toonData.toonPointShadowPosition);
        mainLight.shadowAttenuation = toonData.toonInLighting;
    }
#endif

    //Toon Rim and DepthShadow
    half DepthShadow = 1.0;
    [branch] if (toonData.toonDepthShadowEnable)
    {
        float linearEyeDepth = LinearEyeDepth(positionCS.z / positionCS.w, _ZBufferParams);
        float toonDepth = SAMPLE_TEXTURE2D_X_LOD(_ToonDepthTexture, sampler_ToonDepthTexture_Point_Clamp, inputData.normalizedScreenSpaceUV, 0).x;
        float linearToonEyeDepth = LinearEyeDepth(toonDepth, _ZBufferParams);

        /*float2 offsetUVRim = normalize(TransformWorldToViewDir(mainLight.direction).xy) * _ScreenSize.zw * lerp(_ToonRimWidth, 0.0, saturate(linearEyeDepth / _ToonRimMaxDistance));
        float toonDepthRim = SAMPLE_TEXTURE2D_X_LOD(_ToonDepthTexture, sampler_ToonDepthTexture_Point_Clamp, inputData.normalizedScreenSpaceUV + offsetUVRim, 0).x;
        float linearRimEyeDepth = LinearEyeDepth(toonDepthRim, _ZBufferParams);
        if ((linearRimEyeDepth - linearToonEyeDepth) > _ToonRimThreshold)
        {
            mainLight.color *= 1.0 + _ToonRimIntensity;
        }*/

        //Toon DepthShadow
        float2 offsetUVShadow = normalize(TransformWorldToViewDir(mainLight.direction).xy) * _ScreenSize.zw * lerp(_ToonDepthShadowOffset, 0.0, saturate(linearEyeDepth / _ToonDepthShadowMaxDistance));
        float toonDepthShadow = SAMPLE_TEXTURE2D_X_LOD(_ToonDepthTexture, sampler_ToonDepthTexture_Point_Clamp, inputData.normalizedScreenSpaceUV + offsetUVShadow, 0).x;
        float lineaDepthShadowrEyeDepth = LinearEyeDepth(toonDepthShadow, _ZBufferParams);
        int toonID = (int)(SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, inputData.normalizedScreenSpaceUV, 0).x * 255.0);
        int toonIDOffset = (int)(SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, inputData.normalizedScreenSpaceUV + offsetUVShadow, 0).x * 255.0);
        if (linearToonEyeDepth - lineaDepthShadowrEyeDepth > _ToonDepthShadowThreshold && toonID != toonIDOffset)
        {
            DepthShadow = 0.0;
        }
    }

    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
        inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
        inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor = LightingToonForwardLit(brdfData, toonData, mainLight,
            inputData.normalWS, inputData.viewDirectionWS, DepthShadow, specularHighlightsOff, true);
    }

#if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

            Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += LightingToonForwardLit(brdfData, toonData, light,
                inputData.normalWS, inputData.viewDirectionWS, DepthShadow, specularHighlightsOff, false);
        }
    }
#endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.additionalLightsColor += LightingToonForwardLit(brdfData, toonData, light,
            inputData.normalWS, inputData.viewDirectionWS, DepthShadow, specularHighlightsOff, false);
    }
    LIGHT_LOOP_END
#endif

#if defined(_ADDITIONAL_LIGHTS_VERTEX)
        lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
#endif

    return CalculateFinalColor(lightingData, surfaceData.alpha);
}

half4 UniversalFragmentToonSimpleLit(InputData inputData, SurfaceData surfaceData, ToonData toonData, float4 positionCS)
{
#if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }
#endif

    uint meshRenderingLayers = GetMeshRenderingLayer();
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
#ifdef _RECEIVE_SHADOWS_OFF
    [branch] if (toonData.toonPointShadowEnable)
    {
        toonData.toonInLighting = MainLightRealtimeShadowPoint(toonData.toonPointShadowPosition);
        mainLight.shadowAttenuation = toonData.toonInLighting;
    }
#endif

    //Toon Rim and DepthShadow
    half DepthShadow = 1.0;
    [branch] if (toonData.toonDepthShadowEnable)
    {
        float linearEyeDepth = LinearEyeDepth(positionCS.z / positionCS.w, _ZBufferParams);
        float toonDepth = SAMPLE_TEXTURE2D_X_LOD(_ToonDepthTexture, sampler_ToonDepthTexture_Point_Clamp, inputData.normalizedScreenSpaceUV, 0).x;
        float linearToonEyeDepth = LinearEyeDepth(toonDepth, _ZBufferParams);

        /*float2 offsetUVRim = normalize(TransformWorldToViewDir(mainLight.direction).xy) * _ScreenSize.zw * lerp(_ToonRimWidth, 0.0, saturate(linearEyeDepth / _ToonRimMaxDistance));
        float toonDepthRim = SAMPLE_TEXTURE2D_X_LOD(_ToonDepthTexture, sampler_ToonDepthTexture_Point_Clamp, inputData.normalizedScreenSpaceUV + offsetUVRim, 0).x;
        float linearRimEyeDepth = LinearEyeDepth(toonDepthRim, _ZBufferParams);
        if ((linearRimEyeDepth - linearToonEyeDepth) > _ToonRimThreshold)
        {
            mainLight.color *= 1.0 + _ToonRimIntensity;
        }*/

        //Toon DepthShadow
        float2 offsetUVShadow = normalize(TransformWorldToViewDir(mainLight.direction).xy) * _ScreenSize.zw * lerp(_ToonDepthShadowOffset, 0.0, saturate(linearEyeDepth / _ToonDepthShadowMaxDistance));
        float toonDepthShadow = SAMPLE_TEXTURE2D_X_LOD(_ToonDepthTexture, sampler_ToonDepthTexture_Point_Clamp, inputData.normalizedScreenSpaceUV + offsetUVShadow, 0).x;
        float lineaDepthShadowrEyeDepth = LinearEyeDepth(toonDepthShadow, _ZBufferParams);
        int toonID = (int)(SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, inputData.normalizedScreenSpaceUV, 0).x * 255.0);
        int toonIDOffset = (int)(SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, inputData.normalizedScreenSpaceUV + offsetUVShadow, 0).x * 255.0);
        if (linearToonEyeDepth - lineaDepthShadowrEyeDepth > _ToonDepthShadowThreshold && toonID != toonIDOffset)
        {
            DepthShadow = 0.0;
        }
    }

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, aoFactor);

    inputData.bakedGI *= surfaceData.albedo;

    LightingData lightingData = CreateLightingData(inputData, surfaceData);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor += LightingToonForwardSimpleLit(surfaceData, toonData, mainLight, inputData.normalWS, inputData.viewDirectionWS, DepthShadow, true);
    }

#if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

            Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += LightingToonForwardSimpleLit(surfaceData, toonData, mainLight, inputData.normalWS, inputData.viewDirectionWS, DepthShadow, false);
        }
    }
#endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.additionalLightsColor += LightingToonForwardSimpleLit(surfaceData, toonData, mainLight, inputData.normalWS, inputData.viewDirectionWS, DepthShadow, false);
    }
    LIGHT_LOOP_END
#endif

#if defined(_ADDITIONAL_LIGHTS_VERTEX)
        lightingData.vertexLightingColor += inputData.vertexLighting * surfaceData.albedo;
#endif

    return CalculateFinalColor(lightingData, surfaceData.alpha);
}

// Deprecated: Use the version which takes "SurfaceData" instead of passing all of these arguments...
half4 UniversalFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha)
{
    SurfaceData surfaceData;

    surfaceData.albedo = albedo;
    surfaceData.specular = specular;
    surfaceData.metallic = metallic;
    surfaceData.smoothness = smoothness;
    surfaceData.normalTS = half3(0, 0, 1);
    surfaceData.emission = emission;
    surfaceData.occlusion = occlusion;
    surfaceData.alpha = alpha;
    surfaceData.clearCoatMask = 0;
    surfaceData.clearCoatSmoothness = 1;

    return UniversalFragmentPBR(inputData, surfaceData);
}

////////////////////////////////////////////////////////////////////////////////
/// Phong lighting...
////////////////////////////////////////////////////////////////////////////////
half4 UniversalFragmentBlinnPhong(InputData inputData, SurfaceData surfaceData)
{
    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }
    #endif

    uint meshRenderingLayers = GetMeshRenderingLayer();
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, aoFactor);

    inputData.bakedGI *= surfaceData.albedo;

    LightingData lightingData = CreateLightingData(inputData, surfaceData);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor += CalculateBlinnPhong(mainLight, inputData, surfaceData);
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * surfaceData.albedo;
    #endif

    return CalculateFinalColor(lightingData, surfaceData.alpha);
}

// Deprecated: Use the version which takes "SurfaceData" instead of passing all of these arguments...
half4 UniversalFragmentBlinnPhong(InputData inputData, half3 diffuse, half4 specularGloss, half smoothness, half3 emission, half alpha, half3 normalTS)
{
    SurfaceData surfaceData;

    surfaceData.albedo = diffuse;
    surfaceData.alpha = alpha;
    surfaceData.emission = emission;
    surfaceData.metallic = 0;
    surfaceData.occlusion = 1;
    surfaceData.smoothness = smoothness;
    surfaceData.specular = specularGloss.rgb;
    surfaceData.clearCoatMask = 0;
    surfaceData.clearCoatSmoothness = 1;
    surfaceData.normalTS = normalTS;

    return UniversalFragmentBlinnPhong(inputData, surfaceData);
}

////////////////////////////////////////////////////////////////////////////////
/// Unlit
////////////////////////////////////////////////////////////////////////////////
half4 UniversalFragmentBakedLit(InputData inputData, SurfaceData surfaceData)
{
    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }
    #endif

    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_AMBIENT_OCCLUSION))
    {
        lightingData.giColor *= aoFactor.indirectAmbientOcclusion;
    }

    return CalculateFinalColor(lightingData, surfaceData.albedo, surfaceData.alpha, inputData.fogCoord);
}

// Deprecated: Use the version which takes "SurfaceData" instead of passing all of these arguments...
half4 UniversalFragmentBakedLit(InputData inputData, half3 color, half alpha, half3 normalTS)
{
    SurfaceData surfaceData;

    surfaceData.albedo = color;
    surfaceData.alpha = alpha;
    surfaceData.emission = half3(0, 0, 0);
    surfaceData.metallic = 0;
    surfaceData.occlusion = 1;
    surfaceData.smoothness = 1;
    surfaceData.specular = half3(0, 0, 0);
    surfaceData.clearCoatMask = 0;
    surfaceData.clearCoatSmoothness = 1;
    surfaceData.normalTS = normalTS;

    return UniversalFragmentBakedLit(inputData, surfaceData);
}

#endif
