using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;
using Benchmarking;

[CustomEditor(typeof(PerformanceTest))]
public class PerformanceTestEditor : Editor
{

    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        PerformanceTest performnceTest = (PerformanceTest)target;

        //Add current
        if (GUILayout.Button("Add current"))
        {
            PerformanceTestStage stage = new PerformanceTestStage();
            stage.sceneName = SceneManager.GetActiveScene().name;
            Transform sceneCamTransform = SceneView.lastActiveSceneView.camera.transform;
            stage.cameraPosition = sceneCamTransform.position;
            stage.cameraRotation = sceneCamTransform.rotation;
            performnceTest._stages.Add(stage);
        }
    }
}
