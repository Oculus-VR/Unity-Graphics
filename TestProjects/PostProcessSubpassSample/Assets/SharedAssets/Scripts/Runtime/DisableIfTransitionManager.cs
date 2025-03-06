using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DisableIfTransitionManager : MonoBehaviour
{
    void Start()
    {
        if (SceneTransitionManager.IsAvailable())
        {
            Destroy(gameObject);
        }
    }
}
