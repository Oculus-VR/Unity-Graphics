using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PerformanceManager : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        OVRManager.foveatedRenderingLevel = OVRManager.FoveatedRenderingLevel.Medium;
    }

    // Update is called once per frame
    void Update()
    {

    }
}
