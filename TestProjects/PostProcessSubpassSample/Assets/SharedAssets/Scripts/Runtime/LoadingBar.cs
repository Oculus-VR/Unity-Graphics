using System;
using UnityEngine;

/// <summary>
/// This class is responsible for checking if the player is looking at the control panel hologram and triggering a transition if so
/// </summary>
public class LoadingBar : MonoBehaviour
{
    [SerializeField] private bool m_Armed;
    [SerializeField] private Transform m_LookAtTransform;
    [SerializeField] private float m_ActivationDistance = 3;
    [SerializeField] private float m_LookSize;
    [SerializeField] private bool m_AlwaysOn;

    private bool m_Loading;
    private GameObject m_BaseCam;
    private Animator m_ControlPanelAnimator;


    void Start()
    {
        if (SceneTransitionManager.IsAvailable())
        {
            m_BaseCam = SceneTransitionManager.GetMainCamera();
            m_ControlPanelAnimator = GetComponent<Animator>();
        }
        else
        {
            Destroy(this);
        }


    }

    private void OnEnable()
    {
        if (m_AlwaysOn) TurnOn();
    }

    void Update()
    {
        Vector3 cameraLookDirection = m_BaseCam.transform.forward;
        Vector3 cameraPosition = m_BaseCam.transform.position;

        UpdateRotation(cameraPosition);

        if (m_Armed && PointOfViewWithinArea(cameraPosition, cameraLookDirection))
        {
            StartLoading();
        }
        else if (m_Loading)
        {
            StopLoading();
        }
    }

    private void UpdateRotation(Vector3 cameraPosition)
    {
        if (m_LookAtTransform != null)
        {
            var targetRotation = Quaternion.LookRotation(cameraPosition - m_LookAtTransform.position);

            m_LookAtTransform.rotation = Quaternion.Slerp(m_LookAtTransform.rotation, targetRotation, 1 * Time.deltaTime);
        }
    }

    //This function determines if the player is close enough and looking at the hologram
    private bool PointOfViewWithinArea(Vector3 cameraPosition, Vector3 cameraLookDirection)
    {
        float distance = Vector3.Distance(m_LookAtTransform.position, cameraPosition);

        if (distance > m_ActivationDistance) return false;

        float activationAngle = Mathf.Atan(m_LookSize * 0.5f / distance) * 57.2957f;
        Vector3 directionToLoader = (m_LookAtTransform.position - m_BaseCam.transform.position).normalized;

        if (Vector3.Angle(directionToLoader, cameraLookDirection) < activationAngle)
        {
            return true;
        }

        return false;
    }

    public void StartLoading()
    {
        if (m_Loading) return;

        if (m_ControlPanelAnimator != null)
        {
            m_ControlPanelAnimator.SetBool("Loading", true);
        }

        m_Loading = true;

        SceneTransitionManager.StartTransition();
    }

    public void StopLoading()
    {
        if (!m_Loading) return;

        if (m_ControlPanelAnimator != null)
        {
            m_ControlPanelAnimator.SetBool("Loading", false);
        }

        m_Loading = false;

        SceneTransitionManager.StopTransition();
    }

    public void TurnOn()
    {
        if (m_ControlPanelAnimator != null)
        {
            m_ControlPanelAnimator.SetBool("On", true);
        }
    }

    public void TurnOff()
    {
        if (m_ControlPanelAnimator != null)
        {
            m_ControlPanelAnimator.SetBool("On", false);
        }
    }
}
