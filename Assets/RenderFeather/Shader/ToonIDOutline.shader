Shader "ToonShding/RenderFeature/ToonIDOutlinePP"
{
    Properties
    {
        //_MainTex("Texture", 2D) = "white" {}
        _OutlineColor("OutlineColor", Color) = (0.0, 0.0, 0.0, 0.0)
        _OutlineBlend("OutlineBlend", Range(0.0, 1.0)) = 0.5
        _OutlineWidth("OutlineWidth", Float) = 1.0
        _OutlineMinDistance("OutlineMinDistance", Float) = 1
        _OutlineMaxDistance("OutlineMaxDistance", Float) = 100
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            Blend One SrcAlpha

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ToonShadingCommon.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #pragma vertex Vert
            #pragma fragment frag

            float4 _BlitTexture_TexelSize;

            TEXTURE2D_X(_CameraDepthTexture);

            half3 _OutlineColor;
            float _OutlineWidth;
            float _OutlineBlend;
            half _OutlineMaxDistance;
            half _OutlineMinDistance;

            /*struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 texcoord : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;

                output.texcoord = input.texcoord;
                return output;
            }*/

            half4 frag(Varyings input) : SV_Target
            {
                //half3 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, input.texcoord).rgb;
                float2 Offset = _BlitTexture_TexelSize.xy * _OutlineWidth;

                float depth = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, sampler_ToonDepthTexture_Point_Clamp, input.texcoord, 0).x;
                float toonDepth = SAMPLE_TEXTURE2D_X_LOD(_ToonDepthTexture, sampler_ToonDepthTexture_Point_Clamp, input.texcoord, 0).x;
                float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
                float toonLinearEyeDepth = LinearEyeDepth(toonDepth, _ZBufferParams);
                //float sobelX = 0.0;
                //float sobelY = 0.0;
                float outlineFactor = 0.0;
                [branch] if (toonLinearEyeDepth - linearEyeDepth < 0.01)
                {
                    float center = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.texcoord, 0).x * 255;
                    float lb = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.texcoord + float2(-1.0, -1.0) * Offset, 0).x * 255.0;
                    float l = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.texcoord + float2(-1.0, 0.0) * Offset, 0).x * 255.0;
                    float lt = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.texcoord + float2(-1.0, 1.0) * Offset, 0).x * 255.0;
                    float rt = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.texcoord + float2(1.0, 1.0) * Offset, 0).x * 255.0;
                    float r = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.texcoord + float2(1.0, 0.0) * Offset, 0).x * 255.0;
                    float rb = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.texcoord + float2(1.0, -1.0) * Offset, 0).x * 255.0;
                    float t = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.texcoord + float2(0.0, 1.0) * Offset, 0).x * 255.0;
                    float b = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.texcoord + float2(0.0, -1.0) * Offset, 0).x * 255.0;

                    outlineFactor = max(outlineFactor, abs(center - lb));
                    outlineFactor = max(outlineFactor, abs(center - l));
                    outlineFactor = max(outlineFactor, abs(center - lt));
                    outlineFactor = max(outlineFactor, abs(center - rt));
                    outlineFactor = max(outlineFactor, abs(center - r));
                    outlineFactor = max(outlineFactor, abs(center - rb));
                    outlineFactor = max(outlineFactor, abs(center - t));
                    outlineFactor = max(outlineFactor, abs(center - b));
                    //sobelX = lb + lt + l * 2 - (rb + rt + r * 2);
                    //sobelY = lt + rt + t * 2 - (lb + rb + b * 2);
                }
                outlineFactor = saturate(outlineFactor);
                outlineFactor *= 1- saturate((linearEyeDepth - _OutlineMinDistance) / _OutlineMaxDistance);
                //half3 outlineColor = lerp(color, _OutlineColor, _OutlineBlend);
                //float4 finalColor = lerp(color, outlineColor, outlineFactor);

                return float4(_OutlineColor * _OutlineBlend * outlineFactor, 1.0 - _OutlineBlend * outlineFactor);
            }
            ENDHLSL
        }
    }
}
