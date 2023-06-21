
#ifndef URP_TOON_OUTLINE_PASS_INCLUDED
#define URP_TOON_OUTLINE_PASS_INCLUDED

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
#ifdef _OUTLINESMOOTHNORMAL
    float4 tangentOS : TANGENT;
    float2 texcoord3 : TEXCOORD3;
#endif
    float4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    half fogFactor : TEXCOORD1;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

float3 GetSmoothedWorldNormal(float2 bake, float3x3 t_tbn)
{
    float3 normal = float3(bake, 0);
    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
    return mul(normal, t_tbn);
}

Varyings ToonOutlineVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

#ifdef _OUTLINESMOOTHNORMAL
    float3 normalDir = TransformObjectToWorldNormal(input.normalOS);
    float3 tangentDir = TransformObjectToWorldNormal(input.tangentOS.xyz);
    float3 bitangentDir = normalize(cross(normalDir, tangentDir) * input.tangentOS.w);
    float3x3 t_tbn = float3x3(tangentDir, bitangentDir, normalDir);
    float3 normalWS = GetSmoothedWorldNormal(input.texcoord3, t_tbn);
#else
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
#endif

    float4 positionCS = TransformObjectToHClip(input.positionOS.xyz);
    float3 clipNormal = TransformWorldToHClipDir(normalWS);

    float2 projectedNormal = normalize(clipNormal.xy);
    float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
    float aspect = abs(nearUpperRight.y / nearUpperRight.x);
    projectedNormal.x *= aspect;
    projectedNormal *= min(positionCS.w, 3);
    positionCS.xy += 0.01 * projectedNormal.xy * _ToonOutlineWidth * lerp(1.0, input.color.r, _ToonOutlineWidthColorR);

    output.fogFactor = ComputeFogFactor(positionCS.z);
    output.positionCS = positionCS;
    return output;
}

half4 ToonOutlineFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    half3 color = MixFog(_ToonOutlineColor.rgb, input.fogFactor);
    return half4(color, 1.0);
}
#endif
