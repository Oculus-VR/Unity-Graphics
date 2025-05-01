using System;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
public class ScreenController : MonoBehaviour
{
    public LoadingBar controlPanel;
    private Action m_Callback;
    private MeshRenderer m_MeshRenderer;
    private Animator m_ScreenAnimator;

    private void Start()
    {
        m_MeshRenderer = GetComponent<MeshRenderer>();
        m_ScreenAnimator = GetComponent<Animator>();
    }

    public void TurnScreenOn()
    {
        if (SceneTransitionManager.IsAvailable())
        {
            m_MeshRenderer.material.SetTexture("_ScreenColor", SceneTransitionManager.GetScreenRT());
        }

        if (m_ScreenAnimator != null)
        {
            m_ScreenAnimator.SetBool("ScreenOn", true);
        }

        if (controlPanel != null)
        {
            controlPanel.TurnOn();
        }

        Shader.SetGlobalColor("_TransitionColor", m_MeshRenderer.material.GetColor("_TransitionEdgeColor"));
    }

    public void TurnScreenOff(Action callback)
    {
        m_Callback = callback;
        if (m_ScreenAnimator != null)
        {
            m_ScreenAnimator.SetBool("ScreenOn", false);
        }

        if (controlPanel != null)
        {
            controlPanel.TurnOff();
        }
    }

    //This is called by the animation clip when the screens have switched off
    public void Callback()
    {
        if (m_Callback != null)
        {
            m_Callback();
        }
    }
}
