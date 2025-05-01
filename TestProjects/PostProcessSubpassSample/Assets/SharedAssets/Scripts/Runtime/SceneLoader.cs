using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;

/// <summary>
/// Will Load scene when trigger is entered (could be merged with scene trigger)
/// </summary>
public class SceneLoader : MonoBehaviour
{
    //What scene to load
    public string SceneName;

    [SerializeField]
    private Volume m_CurrentVolume;

    [SerializeField]
    private Volume m_DestinationVolume;

    //Used for cinemachine transition
    [SerializeField] private bool m_SkipLoading;

    [SerializeField] public GameObject ControllPanel;

    public ScreenController screen;
    public Transform ReferencePoint;

    private GameObject m_Root;
    private int m_LoadedIndex;

    public void Start()
    {
        if (!SceneTransitionManager.IsAvailable())
        {
            Destroy(this);
            return;
        }

        if (!m_SkipLoading)
        {
            LoadScene();
        }

    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            EnableScene();
        }
    }

    public void EnableScene()
    {
        SceneTransitionManager.EnableScene(this);
    }

    public void DisableScene()
    {
        SceneTransitionManager.DisableScene(this);
    }

    private void OnTriggerExit(Collider other)
    {
        DisableScene();
    }

    private void LoadScene()
    {
        if (!SceneTransitionManager.IsLoaded(SceneName))
        {
            SceneManager.LoadSceneAsync(SceneName, LoadSceneMode.Additive);
            SceneTransitionManager.NotifySceneLoading();
        }
    }

    public void SetVolumeWeights(float weight)
    {
        if (m_CurrentVolume != null)
        {
            m_CurrentVolume.weight = weight;
        }

        if (m_DestinationVolume != null)
        {
            m_DestinationVolume.weight = 1 - weight;
        }
    }

    public void SetCurrentVolume(Volume volume)
    {
        m_CurrentVolume = volume;
    }

    public Volume GetDestinationVolume()
    {
        return m_DestinationVolume;
    }
}
