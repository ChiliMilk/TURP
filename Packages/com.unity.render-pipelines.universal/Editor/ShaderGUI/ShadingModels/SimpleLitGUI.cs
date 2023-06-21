using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Scripting.APIUpdating;

namespace UnityEditor.Rendering.Universal.ShaderGUI
{
    /// <summary>
    /// Editor script for the SimpleLit material inspector.
    /// </summary>
    public static class SimpleLitGUI
    {
        /// <summary>
        /// Options for specular source.
        /// </summary>
        public enum SpecularSource
        {
            /// <summary>
            /// Use this to use specular texture and color.
            /// </summary>
            SpecularTextureAndColor,

            /// <summary>
            /// Use this when not using specular.
            /// </summary>
            NoSpecular
        }

        /// <summary>
        /// Options to select the texture channel where the smoothness value is stored.
        /// </summary>
        public enum SmoothnessMapChannel
        {
            /// <summary>
            /// Use this when smoothness is stored in the alpha channel of the Specular Map.
            /// </summary>
            SpecularAlpha,

            /// <summary>
            /// Use this when smoothness is stored in the alpha channel of the Albedo Map.
            /// </summary>
            AlbedoAlpha,
        }

        /// <summary>
        /// Container for the text and tooltips used to display the shader.
        /// </summary>
        public static class Styles
        {
            /// <summary>
            /// The text and tooltip for the specular map GUI.
            /// </summary>
            public static GUIContent specularMapText =
                EditorGUIUtility.TrTextContent("Specular Map(Only R Channel)", "Designates a Specular Map and specular color determining the apperance of reflections on this Material's surface.");

            //ToonShading
            public static GUIContent toonDiffuseRampVText = EditorGUIUtility.TrTextContent("ToonDiffuseRampV");
            public static GUIContent toonDiffuseRampOffsetText = EditorGUIUtility.TrTextContent("ToonDiffuseRampOffset");
            public static GUIContent toonOutlineEnableText = EditorGUIUtility.TrTextContent("ToonOutlineEnable");
            public static GUIContent toonOutlineSmoothNormalText = EditorGUIUtility.TrTextContent("ToonOutlineSmoothNormal");
            public static GUIContent toonOutlineWidthText = EditorGUIUtility.TrTextContent("ToonOutlineWidth");
            public static GUIContent toonOutlineWidthColorRText = EditorGUIUtility.TrTextContent("ToonOutlineWidthColorR");
            public static GUIContent toonOutlineColorText = EditorGUIUtility.TrTextContent("ToonOutlineColor");
            public static GUIContent toonDataText = EditorGUIUtility.TrTextContent("ToonData(Character)");
            public static GUIContent toonIDText = EditorGUIUtility.TrTextContent("ToonID(Character)");
            public static GUIContent toonPointShadowEnableText = EditorGUIUtility.TrTextContent("ToonPointShadowEnable");
            public static GUIContent toonDepthShadowEnableText = EditorGUIUtility.TrTextContent("ToonDepthShadowEnable");
            public static GUIContent toonStaticShadowMapText = EditorGUIUtility.TrTextContent("ToonStaticShadowMap");
            public static GUIContent toonSDFShadowEnableText = EditorGUIUtility.TrTextContent("ToonSDFShadowEnable");
            public static GUIContent toonSDFShadowMapText = EditorGUIUtility.TrTextContent("ToonSDFShadowMap");
            public static GUIContent toonMatCapMapText = EditorGUIUtility.TrTextContent("ToonMatCapMap");
            public static GUIContent toonMatCapUVScaleText = EditorGUIUtility.TrTextContent("ToonMatCapUVScale");
        }

        /// <summary>
        /// Container for the properties used in the <c>SimpleLitGUI</c> editor script.
        /// </summary>
        public struct SimpleLitProperties
        {
            // Surface Input Props

            /// <summary>
            /// The MaterialProperty for specular color.
            /// </summary>
            public MaterialProperty specColor;

            /// <summary>
            /// The MaterialProperty for specular smoothness map.
            /// </summary>
            public MaterialProperty specGlossMap;

            /// <summary>
            /// The MaterialProperty for specular highlights.
            /// </summary>
            public MaterialProperty specHighlights;

            /// <summary>
            /// The MaterialProperty for smoothness alpha channel.
            /// </summary>
            public MaterialProperty smoothnessMapChannel;

            /// <summary>
            /// The MaterialProperty for smoothness value.
            /// </summary>
            public MaterialProperty smoothness;

            /// <summary>
            /// The MaterialProperty for normal map.
            /// </summary>
            public MaterialProperty bumpMapProp;

            //ToonShading
            public MaterialProperty toonSpecularIntensity;
            public MaterialProperty toonDiffuseRampV;
            public MaterialProperty toonDiffuseRampOffset;
            public MaterialProperty toonOutlineEnable;
            public MaterialProperty toonOutlineSmoothNormal;
            public MaterialProperty toonOutlineWidth;
            public MaterialProperty toonOutlineWidthColorR;
            public MaterialProperty toonOutlineColor;
            public MaterialProperty toonData;
            public MaterialProperty toonID;
            public MaterialProperty toonPointShadowEnable;
            public MaterialProperty toonDepthShadowEnable;
            public MaterialProperty toonStaticShadowMap;
            public MaterialProperty toonSDFShadowEnable;
            public MaterialProperty toonSDFShadowMap;
            public MaterialProperty toonMatCapMap;
            public MaterialProperty toonMatCapColor;
            public MaterialProperty toonMatCapUVScale;

            /// <summary>
            /// Constructor for the <c>SimpleLitProperties</c> container struct.
            /// </summary>
            /// <param name="properties"></param>
            public SimpleLitProperties(MaterialProperty[] properties)
            {
                // Surface Input Props
                specColor = BaseShaderGUI.FindProperty("_SpecColor", properties);
                specGlossMap = BaseShaderGUI.FindProperty("_SpecGlossMap", properties, false);
                specHighlights = BaseShaderGUI.FindProperty("_SpecularHighlights", properties, false);
                smoothnessMapChannel = BaseShaderGUI.FindProperty("_SmoothnessSource", properties, false);
                smoothness = BaseShaderGUI.FindProperty("_Smoothness", properties, false);
                bumpMapProp = BaseShaderGUI.FindProperty("_BumpMap", properties, false);

                //ToonShading
                toonSpecularIntensity = BaseShaderGUI.FindProperty("_ToonSpecularIntensity", properties, false);
                toonDiffuseRampV = BaseShaderGUI.FindProperty("_ToonDiffuseRampV", properties, false);
                toonDiffuseRampOffset = BaseShaderGUI.FindProperty("_ToonDiffuseRampOffset", properties, false);
                toonOutlineEnable = BaseShaderGUI.FindProperty("_ToonOutlineEnable", properties, false);
                toonOutlineSmoothNormal = BaseShaderGUI.FindProperty("_ToonOutlineSmoothNormal", properties, false);
                toonOutlineWidth = BaseShaderGUI.FindProperty("_ToonOutlineWidth", properties, false);
                toonOutlineWidthColorR = BaseShaderGUI.FindProperty("_ToonOutlineWidthColorR", properties, false);
                toonOutlineColor = BaseShaderGUI.FindProperty("_ToonOutlineColor", properties, false);
                toonData = BaseShaderGUI.FindProperty("_ToonData", properties, false);
                toonID = BaseShaderGUI.FindProperty("_ToonID", properties, false);
                toonPointShadowEnable = BaseShaderGUI.FindProperty("_ToonPointShadowEnable", properties, false);
                toonDepthShadowEnable = BaseShaderGUI.FindProperty("_ToonDepthShadowEnable", properties, false);
                toonStaticShadowMap = BaseShaderGUI.FindProperty("_ToonStaticShadowMap", properties, false);
                toonSDFShadowEnable = BaseShaderGUI.FindProperty("_ToonSDFShadowEnable", properties, false);
                toonSDFShadowMap = BaseShaderGUI.FindProperty("_ToonSDFShadowMap", properties, false);
                toonMatCapMap = BaseShaderGUI.FindProperty("_ToonMatCapMap", properties, false);
                toonMatCapColor = BaseShaderGUI.FindProperty("_ToonMatCapColor", properties, false);
                toonMatCapUVScale = BaseShaderGUI.FindProperty("_ToonMatCapUVScale", properties, false);
            }
        }

        /// <summary>
        /// Draws the surface inputs GUI.
        /// </summary>
        /// <param name="properties"></param>
        /// <param name="materialEditor"></param>
        /// <param name="material">The material to use.</param>
        public static void Inputs(SimpleLitProperties properties, MaterialEditor materialEditor, Material material)
        {
            DoSpecularArea(properties, materialEditor, material);
            BaseShaderGUI.DrawNormalArea(materialEditor, properties.bumpMapProp);
            DoToonArea(properties, materialEditor, material);
        }

        /// <summary>
        /// Draws the advanced GUI.
        /// </summary>
        /// <param name="properties"></param>
        public static void Advanced(SimpleLitProperties properties)
        {
            SpecularSource specularSource = (SpecularSource)properties.specHighlights.floatValue;
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = properties.specHighlights.hasMixedValue;
            bool enabled = EditorGUILayout.Toggle(LitGUI.Styles.highlightsText, specularSource == SpecularSource.SpecularTextureAndColor);
            if (EditorGUI.EndChangeCheck())
                properties.specHighlights.floatValue = enabled ? (float)SpecularSource.SpecularTextureAndColor : (float)SpecularSource.NoSpecular;
            EditorGUI.showMixedValue = false;
        }

        /// <summary>
        /// Draws the specular area GUI.
        /// </summary>
        /// <param name="properties"></param>
        /// <param name="materialEditor"></param>
        /// <param name="material">The material to use.</param>
        public static void DoSpecularArea(SimpleLitProperties properties, MaterialEditor materialEditor, Material material)
        {
            SpecularSource specSource = (SpecularSource)properties.specHighlights.floatValue;
            EditorGUI.BeginDisabledGroup(specSource == SpecularSource.NoSpecular);
            //BaseShaderGUI.TextureColorProps(materialEditor, Styles.specularMapText, properties.specGlossMap, properties.specColor, true);
            //ToonShading
            materialEditor.TexturePropertySingleLine(Styles.specularMapText, properties.specGlossMap, properties.toonSpecularIntensity);
            LitGUI.DoSmoothness(materialEditor, material, properties.smoothness, properties.smoothnessMapChannel, LitGUI.Styles.specularSmoothnessChannelNames);
            EditorGUI.EndDisabledGroup();
        }

        public static void DoToonArea(SimpleLitProperties properties, MaterialEditor materialEditor, Material material)
        {
            EditorGUILayout.Space();
            if (properties.toonDiffuseRampV != null)
            {
                materialEditor.ShaderProperty(properties.toonDiffuseRampV, Styles.toonDiffuseRampVText);
            }
            if (properties.toonDiffuseRampOffset != null)
            {
                materialEditor.ShaderProperty(properties.toonDiffuseRampOffset, Styles.toonDiffuseRampOffsetText);
            }
            EditorGUILayout.Space();
            if (properties.toonStaticShadowMap != null)
            {
                EditorGUI.indentLevel += 2;
                BaseShaderGUI.TextureColorProps(materialEditor, Styles.toonStaticShadowMapText, properties.toonStaticShadowMap, null, false);
                EditorGUI.indentLevel -= 2;
            }
            if(properties.toonSDFShadowEnable != null)
            {
                materialEditor.ShaderProperty(properties.toonSDFShadowEnable, Styles.toonSDFShadowEnableText);
                if (properties.toonSDFShadowEnable.floatValue == 1.0)
                {
                    EditorGUI.indentLevel += 2;
                    BaseShaderGUI.TextureColorProps(materialEditor, Styles.toonSDFShadowMapText, properties.toonSDFShadowMap, null, false);
                    EditorGUI.indentLevel -= 2;
                }
            }
            if (properties.toonPointShadowEnable != null)
            {
                materialEditor.ShaderProperty(properties.toonPointShadowEnable, Styles.toonPointShadowEnableText);
            }
            if (properties.toonDepthShadowEnable != null)
            {
                materialEditor.ShaderProperty(properties.toonDepthShadowEnable, Styles.toonDepthShadowEnableText);
            }
            EditorGUILayout.Space();
            if (properties.toonMatCapMap != null)
            {
                materialEditor.TexturePropertyWithHDRColor(Styles.toonMatCapMapText, properties.toonMatCapMap, properties.toonMatCapColor, false);
                materialEditor.ShaderProperty(properties.toonMatCapUVScale, Styles.toonMatCapUVScaleText);
            }
            EditorGUILayout.Space();
            if (properties.toonOutlineEnable != null)
            {
                materialEditor.ShaderProperty(properties.toonOutlineEnable, Styles.toonOutlineEnableText);
                if (properties.toonOutlineEnable.floatValue == 1.0)
                {
                    EditorGUI.indentLevel += 2;
                    materialEditor.ShaderProperty(properties.toonOutlineSmoothNormal, Styles.toonOutlineSmoothNormalText);
                    materialEditor.ShaderProperty(properties.toonOutlineWidth, Styles.toonOutlineWidthText);
                    materialEditor.ShaderProperty(properties.toonOutlineWidthColorR, Styles.toonOutlineWidthColorRText);
                    materialEditor.ShaderProperty(properties.toonOutlineColor, Styles.toonOutlineColorText);
                    EditorGUI.indentLevel -= 2;
                }
            }
            EditorGUILayout.Space();
            if (properties.toonData != null)
            {
                materialEditor.ShaderProperty(properties.toonData, Styles.toonDataText);
                if (properties.toonData.floatValue == 1.0)
                {
                    materialEditor.ShaderProperty(properties.toonID, Styles.toonIDText);
                }
            }
            EditorGUILayout.Space();
        }

        /// <summary>
        /// Sets up the keywords for the material and shader.
        /// </summary>
        /// <param name="material">The material to use.</param>
        public static void SetMaterialKeywords(Material material)
        {
            UpdateMaterialSpecularSource(material);
            UpdateMaterialToon(material);
        }

        private static void UpdateMaterialSpecularSource(Material material)
        {
            var opaque = ((BaseShaderGUI.SurfaceType)material.GetFloat("_Surface") ==
                BaseShaderGUI.SurfaceType.Opaque);
            SpecularSource specSource = (SpecularSource)material.GetFloat("_SpecularHighlights");
            if (specSource == SpecularSource.NoSpecular)
            {
                CoreUtils.SetKeyword(material, "_SPECGLOSSMAP", false);
                CoreUtils.SetKeyword(material, "_SPECULAR_COLOR", false);
                CoreUtils.SetKeyword(material, "_GLOSSINESS_FROM_BASE_ALPHA", false);
            }
            else
            {
                var smoothnessSource = (SmoothnessMapChannel)material.GetFloat("_SmoothnessSource");
                bool hasMap = material.GetTexture("_SpecGlossMap");
                CoreUtils.SetKeyword(material, "_SPECGLOSSMAP", hasMap);
                CoreUtils.SetKeyword(material, "_SPECULAR_COLOR", !hasMap);
                if (opaque)
                    CoreUtils.SetKeyword(material, "_GLOSSINESS_FROM_BASE_ALPHA", smoothnessSource == SmoothnessMapChannel.AlbedoAlpha);
                else
                    CoreUtils.SetKeyword(material, "_GLOSSINESS_FROM_BASE_ALPHA", false);

                string color;
                if (smoothnessSource != SmoothnessMapChannel.AlbedoAlpha || !opaque)
                    color = "_SpecColor";
                else
                    color = "_BaseColor";

                var col = material.GetColor(color);

                float smoothness = material.GetFloat("_Smoothness");
                if (smoothness != col.a)
                {
                    col.a = smoothness;
                    material.SetColor(color, col);
                }

                //ToonShading
                float intensity = material.GetFloat("_ToonSpecularIntensity");
                Color specColor = material.GetColor("_SpecColor");
                specColor = new Color(intensity, intensity, intensity, specColor.a);
                material.SetColor("_SpecColor", specColor);
            }
        }

        private static void UpdateMaterialToon(Material material)
        {
            //ToonShading
            if (material.HasProperty("_ToonOutlineEnable"))
            {
                material.SetShaderPassEnabled("ToonOutline", material.GetFloat("_ToonOutlineEnable") == 1.0f);
            }
            if (material.HasProperty("_ToonOutlineSmoothNormal"))
            {
                CoreUtils.SetKeyword(material, "_OUTLINESMOOTHNORMAL", material.GetFloat("_ToonOutlineSmoothNormal") == 1.0f);
            }
            if (material.HasProperty("_ToonData"))
            {
                material.SetShaderPassEnabled("ToonData", material.GetFloat("_ToonData") == 1.0f);
            }
        }
    }
}
