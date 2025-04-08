using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class BuildAutomation
{
    [MenuItem("Meta/Build Subpass Depth Input Scenes")]
    static void BuildSubpassDepthInputScenes()
    {
#if UNITY_EDITOR
        PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "com.meta.ShaderGraphDepthInput");
        BuildPipeline.BuildPlayer(new string[] { "Assets/Scenes/ShaderGraphWater/ShaderGraphWater.unity" }, "ShaderGraphDepthInput.apk", BuildTarget.Android, BuildOptions.Development);

        PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "com.meta.HLSLDepthInput");
        BuildPipeline.BuildPlayer(new string[] { "Assets/Scenes/AmbientOcclusion_HLSL/AmbientOcclusion.unity" }, "HLSLDepthInput.apk", BuildTarget.Android, BuildOptions.Development);
#endif
    }
}
