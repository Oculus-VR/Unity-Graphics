using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PerfSceneManager : MonoBehaviour
{
    public List<GameObject> kyleRobots;
    public List<GameObject> controllerRays;
    public List<GameObject> particleSystems;
    public OVRManager manager;
    public OVRCameraRig cameraRig;
    public GameObject perfUISettings;
    public GameObject headlockedOnBackground;

    private bool robotAnimationsEnabled = true;
    private bool fixedHeadLock = true;
    private bool updateHeadPosition = true;
    private bool perfUIEnabled = true;
    private bool particlesEnabled = true;

    // Start is called before the first frame update
    void Start()
    {
        perfUISettings.SetActive(perfUIEnabled);
        foreach (var r in controllerRays)
        {
            r.SetActive(perfUIEnabled);
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (OVRInput.GetDown(OVRInput.RawButton.B, OVRInput.Controller.RTouch))
        {
            ToggleHeadLock();
            headlockedOnBackground.SetActive(fixedHeadLock);
        }

        if (OVRInput.GetDown(OVRInput.RawButton.X, OVRInput.Controller.LTouch))
        {
            updateHeadPosition = !updateHeadPosition;
            cameraRig.enabled = updateHeadPosition;
        }

        if (OVRInput.GetDown(OVRInput.RawButton.Start, OVRInput.Controller.LTouch))
        {
            perfUIEnabled = !perfUIEnabled;
            perfUISettings.SetActive(perfUIEnabled);
            foreach (var r in controllerRays)
            {
                r.SetActive(perfUIEnabled);
            }
        }
    }

    public void ToggleRobotAnimation()
    {
        robotAnimationsEnabled = !robotAnimationsEnabled;
        foreach (var g in kyleRobots)
        {
            var botAnimatior = g.GetComponent<Animator>();
            botAnimatior.enabled = robotAnimationsEnabled;
        }
    }

    public void ToggleHeadLock()
    {
        fixedHeadLock = !fixedHeadLock;
        manager.usePositionTracking = fixedHeadLock;
        manager.useRotationTracking = fixedHeadLock;
    }

    public void ToggleParticles()
    {
        particlesEnabled = !particlesEnabled;
        foreach (var p in particleSystems)
        {
            p.SetActive(particlesEnabled);
        }
    }
}
