using System.Collections;
using System.Collections.Generic;
using UnityEditor;

using UnityEngine;

public class BuildBenchmark
{
    [MenuItem("Meta/Build PostProcess Sample Project")]
    static void BuildProject()
    {
        EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.Android, BuildTarget.Android);
        PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "com.meta.PostProcessSubpass");
        BuildPipeline.BuildPlayer(new string[] { "Assets/Scenes/Garden/GardenScene.unity" }, "PostProcessSubpass.apk", BuildTarget.Android, BuildOptions.None);
    }
}
