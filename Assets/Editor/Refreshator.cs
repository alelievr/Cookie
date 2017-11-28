using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class Refreshator : EditorWindow
{
    [MenuItem("Window/Refreshator")]
    public static void ShowWindow()
    {
        Refreshator.GetWindow< Refreshator >().Show();
    }

    public void OnEnable()
    {
         SceneView.onSceneGUIDelegate += OnScene;
         Application.runInBackground = true;
    }

    void OnScene(SceneView v)
    {
        if (Event.current.type == EventType.Layout)
            SceneView.RepaintAll();
    }

    public void OnDIsable()
    {
        SceneView.onSceneGUIDelegate -= OnScene;
    }
}
