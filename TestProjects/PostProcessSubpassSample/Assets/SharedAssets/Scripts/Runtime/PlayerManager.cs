using Cinemachine;
using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Timeline;
using Benchmarking;
using UnityEngine.EventSystems;

/// <summary>
/// This class will enable the touch input canvas on handheld devices and will trigger the camera flythrough if the player is idle
/// </summary>
public class PlayerManager : MonoBehaviour
{
    [SerializeField] private bool m_FlythroughWhenIdle;
    [SerializeField] private float m_IdleTransitionTime;
    [SerializeField] private GameObject m_CrosshairCanvas;
    [SerializeField] private GameObject m_TouchInputCanvas;
    [SerializeField] private GameObject m_EventSystem;

    public PlayableDirector FlythroughDirector;

    private bool m_InFlythrough;
    private float m_TimeIdle;
    private CinemachineVirtualCamera m_VirtualCamera;
    private bool m_HasFocus;

    void Start()
    {
        if (EventSystem.current == null)
        {
            m_EventSystem.SetActive(true);
        }

        if (PerformanceTest.RunningBenchmark)
        {
            Destroy(gameObject);
            return;
        }

        m_InFlythrough = false;

        if (SystemInfo.deviceType == DeviceType.Handheld)
        {
            m_TouchInputCanvas.SetActive(true);
        }

        m_VirtualCamera = GetComponentInChildren<CinemachineVirtualCamera>();
    }

    void Update()
    {
        if (m_FlythroughWhenIdle && m_TimeIdle > m_IdleTransitionTime && !m_InFlythrough)
        {
            m_TimeIdle = 0;
            EnableFlythrough();
        }
#if UNITY_EDITOR
        if(m_HasFocus) m_TimeIdle += Time.unscaledDeltaTime;
#else
        m_TimeIdle += Time.unscaledDeltaTime;
#endif
    }

    private void Awake()
    {
        if (transform.parent == null)
        {
            DontDestroyOnLoad(gameObject);
        }
    }

    public void EnableFlythrough()
    {
        if (SceneTransitionManager.IsAvailable())
        {
            SceneTransitionManager.DisableLoadedScene();
            SceneTransitionManager.StopTransition();
        }

        if (FlythroughDirector == null)
        {
            m_VirtualCamera.gameObject.SetActive(false);
            m_InFlythrough = true;
        }
        else
        {
            FlythroughDirector.gameObject.SetActive(true);

            TimelineAsset timeline = FlythroughDirector.playableAsset as TimelineAsset;
            FlythroughDirector.SetGenericBinding(timeline.GetOutputTrack(0), GetComponentInChildren<CinemachineBrain>());

            FlythroughDirector.time = 0;
            FlythroughDirector.Play();
            m_InFlythrough = true;
            m_CrosshairCanvas.SetActive(false);

            if (SystemInfo.deviceType == DeviceType.Handheld)
            {
                m_TouchInputCanvas.SetActive(false);
            }
        }
    }

    private void OnApplicationFocus(bool hasFocus)
    {
        m_HasFocus = hasFocus;
    }

    public void EnableFirstPersonController()
    {
        if (SceneTransitionManager.IsAvailable())
        {
            SceneTransitionManager.DisableLoadedScene();
            SceneTransitionManager.StopTransition();
        }

        m_VirtualCamera.gameObject.SetActive(true);
        m_CrosshairCanvas.SetActive(true);

        if (FlythroughDirector != null)
        {
            FlythroughDirector.gameObject.SetActive(false);
        }
        m_InFlythrough = false;

    }

    public void NotifyPlayerMoved()
    {
        m_TimeIdle = 0;
        if (m_InFlythrough)
        {
            EnableFirstPersonController();
            if (SystemInfo.deviceType == DeviceType.Handheld)
            {
                m_TouchInputCanvas.SetActive(true);
            }
        }
    }
}
