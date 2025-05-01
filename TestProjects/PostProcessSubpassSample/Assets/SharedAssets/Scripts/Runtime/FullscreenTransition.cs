using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class FullscreenTransition : FullscreenEffect
{
    [SerializeField]
    private string _screenCameraTag = "ScreenCamera";

    public override void OnBeginCamera(ScriptableRenderContext ctx, Camera cam)
    {
        if (!SceneTransitionManager.DissolveNeeded() || cam.CompareTag(_screenCameraTag))
        {
            return;
        }

        base.OnBeginCamera(ctx, cam);
    }
}
