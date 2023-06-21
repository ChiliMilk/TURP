Shader "ToonShding/RenderFeature/ToonIDOutlinePP"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _OutlineColor("OutlineColor", Color) = (0.0, 0.0, 0.0, 0.0)
        _OutlineBlend("OutlineBlend", Range(0.0, 1.0)) = 0.5
        _OutlineWidth("OutlineWidth", Float) = 1.0
        _OutlineMinDistance("OutlineMinDistance", Float) = 1
        _OutlineMaxDistance("OutlineMaxDistance", Float) = 100
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ToonShadingCommon.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_TexelSize;

            TEXTURE2D_X(_CameraDepthTexture);

            half4 _OutlineColor;
            float _OutlineWidth;
            float _OutlineBlend;
            half _OutlineMaxDistance;
            half _OutlineMinDistance;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;

                output.uv = input.texcoord;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float2 Offset = _MainTex_TexelSize.xy * _OutlineWidth;

                float depth = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, sampler_ToonDepthTexture_Point_Clamp, input.uv, 0).x;
                float toonDepth = SAMPLE_TEXTURE2D_X_LOD(_ToonDepthTexture, sampler_ToonDepthTexture_Point_Clamp, input.uv, 0).x;
                float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
                float toonLinearEyeDepth = LinearEyeDepth(toonDepth, _ZBufferParams);
                //float sobelX = 0.0;
                //float sobelY = 0.0;
                float outlineFactor = 0.0;
                [branch] if (toonLinearEyeDepth - linearEyeDepth < 0.01)
                {
                    float center = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.uv, 0).x * 255;
                    float lb = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.uv + float2(-1.0, -1.0) * Offset, 0).x * 255.0;
                    float l = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.uv + float2(-1.0, 0.0) * Offset, 0).x * 255.0;
                    float lt = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.uv + float2(-1.0, 1.0) * Offset, 0).x * 255.0;
                    float rt = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.uv + float2(1.0, 1.0) * Offset, 0).x * 255.0;
                    float r = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.uv + float2(1.0, 0.0) * Offset, 0).x * 255.0;
                    float rb = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.uv + float2(1.0, -1.0) * Offset, 0).x * 255.0;
                    float t = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.uv + float2(0.0, 1.0) * Offset, 0).x * 255.0;
                    float b = SAMPLE_TEXTURE2D_X_LOD(_ToonDataTexture, sampler_ToonDataTexture_Point_Clamp, input.uv + float2(0.0, -1.0) * Offset, 0).x * 255.0;

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
                half4 outlineColor = lerp(_OutlineColor, color, _OutlineBlend);
                float4 finalColor = lerp(color, outlineColor, outlineFactor);

                return finalColor;
            }
            ENDHLSL
        }
    }
}
