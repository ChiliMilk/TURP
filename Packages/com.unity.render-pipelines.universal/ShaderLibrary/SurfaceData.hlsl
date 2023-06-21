#ifndef UNIVERSAL_SURFACE_DATA_INCLUDED
#define UNIVERSAL_SURFACE_DATA_INCLUDED

// Must match Universal ShaderGraph master node
struct SurfaceData
{
    half3 albedo;
    half3 specular;
    half  metallic;
    half  smoothness;
    half3 normalTS;
    half3 emission;
    half  occlusion;
    half  alpha;
    half  clearCoatMask;
    half  clearCoatSmoothness;
};

struct ToonData
{
    half toonDiffuseRampV;
    half toonSpecularFeather;
    half toonPointShadowEnable;
    half3 toonPointShadowPosition;
    half toonInLighting;
    half toonDiffuseRampOffset;
    half toonDepthShadowEnable;
    half toonStaticShadow;
    half toonSDFShadowEnable;
};

#endif
