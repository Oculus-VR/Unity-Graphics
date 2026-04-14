using UnityEngine;
using UnityEngine.Rendering;

/// <summary>
/// Async shader compilation is disabled for offscreen cameras by default.
/// As all the cameras in the TerminalScene are updating every frame,
/// therefore this script enables async shader compilation for all the cameras in the scene.
/// If you only need to enable async shader compilation for a specific camera,
/// you can use the Begin/EndCameraRendering callbacks instead.
/// </summary>
public class AsyncShaderCompileForCamera : MonoBehaviour
{
#if UNITY_EDITOR
    private bool m_PrevState = true;
  
    private void OnEnable()
    {
        RenderPipelineManager.beginFrameRendering += BeginFrame;
        RenderPipelineManager.endFrameRendering += EndFrame;
    }
    
    private void OnDisable()
    {
        RenderPipelineManager.beginFrameRendering -= BeginFrame;
        RenderPipelineManager.endFrameRendering -= EndFrame;
    }
  
    private void BeginFrame(ScriptableRenderContext context, Camera[] cams)
    {
        m_PrevState = UnityEditor.ShaderUtil.allowAsyncCompilation;
        UnityEditor.ShaderUtil.allowAsyncCompilation = true;
    }
  
    private void EndFrame(ScriptableRenderContext context, Camera[] cams)
    {
        UnityEditor.ShaderUtil.allowAsyncCompilation = m_PrevState;
    }
#endif
}
