using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class OculusMotionVectorWindow : EditorWindow {

    private const int k_MotionVectorTextureSize = 512;

    private Material m_DebugMotionVectorMaterial;
    private Material m_DebugDepthMaterial;

    private float m_MaxVectorValue = 0.1f;
    private float m_MaxDepth = 0.01f;

    [MenuItem ("Oculus/Debug Motion Vectors")]
    public static void  ShowWindow ()
    {
        EditorWindow.GetWindow(typeof(OculusMotionVectorWindow));
    }

    private Material GetNamedMaterial(string name) {
        var shaderGuid = AssetDatabase.FindAssets($"t:Shader {name}").FirstOrDefault();

        return shaderGuid != null ? new Material(AssetDatabase.LoadAssetAtPath<Shader>(AssetDatabase.GUIDToAssetPath(shaderGuid))) : null;
    }

    private void InitMotionVectors() {

        if (UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.motionVectorRenderTarget == null)
        {
            UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.motionVectorRenderTargetDesc = new RenderTextureDescriptor(k_MotionVectorTextureSize, k_MotionVectorTextureSize, RenderTextureFormat.ARGBFloat, 0) { vrUsage = VRTextureUsage.TwoEyes, dimension = TextureDimension.Tex2DArray, volumeDepth = 2 };
            UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.motionVectorRenderTarget = new RenderTexture(UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.motionVectorRenderTargetDesc);
        }

        if (UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.depthRenderTarget == null)
        {
            UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.depthRenderTargetDesc = new RenderTextureDescriptor(k_MotionVectorTextureSize, k_MotionVectorTextureSize, RenderTextureFormat.Depth, 24) { vrUsage = VRTextureUsage.TwoEyes, dimension = TextureDimension.Tex2DArray, volumeDepth = 2 };
            UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.depthRenderTarget = new RenderTexture(UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.depthRenderTargetDesc);
        }
    }

    private void Awake() {

        InitMotionVectors();
        m_DebugMotionVectorMaterial = GetNamedMaterial("OculusMotionVectorDebugShader");
        m_DebugMotionVectorMaterial.SetFloat("_OnlyRed", 0.0f);
        m_DebugDepthMaterial = GetNamedMaterial("OculusMotionVectorDebugShader");
        m_DebugDepthMaterial.SetFloat("_OnlyRed", 1.0f);
    }

    private void OnDestroy() {

        DestroyImmediate(m_DebugMotionVectorMaterial);
    }

    void Update() {

        Repaint();
    }

    void OnGUI () {

        InitMotionVectors();
        if (m_DebugMotionVectorMaterial == null) {
            Awake();
        }

        UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.enableDebugMotionVectors =
            EditorGUILayout.Toggle("Enable Motion Vectors",
                UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.enableDebugMotionVectors);

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.BeginVertical();

        m_DebugMotionVectorMaterial.SetFloat("_MinValue", -m_MaxVectorValue);
        m_DebugMotionVectorMaterial.SetFloat("_MaxValue", m_MaxVectorValue);
        EditorGUI.DrawPreviewTexture(
            EditorGUILayout.GetControlRect(false, GUILayout.Height(k_MotionVectorTextureSize), GUILayout.Width(k_MotionVectorTextureSize)),
            UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.motionVectorRenderTarget,
            m_DebugMotionVectorMaterial);

        m_MaxVectorValue = 1 / EditorGUILayout.Slider("Vector Scale", 1 / m_MaxVectorValue, 1, 100);
        EditorGUILayout.EndVertical();

        EditorGUILayout.BeginVertical();

        m_DebugDepthMaterial.SetFloat("_MinValue", 0);
        m_DebugDepthMaterial.SetFloat("_MaxValue", m_MaxDepth);

        EditorGUI.DrawPreviewTexture(
            EditorGUILayout.GetControlRect(false, GUILayout.Height(k_MotionVectorTextureSize), GUILayout.Width(k_MotionVectorTextureSize)),
            UnityEngine.Rendering.Universal.DebugOculusMotionVectorSettings.depthRenderTarget,
            m_DebugDepthMaterial);

        m_MaxDepth = 1 / EditorGUILayout.Slider("Depth Scale", 1 / m_MaxDepth, 1, 100);
        EditorGUILayout.EndVertical();
        EditorGUILayout.EndHorizontal();

    }
}
