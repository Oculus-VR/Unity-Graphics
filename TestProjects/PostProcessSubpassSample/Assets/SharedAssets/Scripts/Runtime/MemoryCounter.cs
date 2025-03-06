using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.UI;

[RequireComponent(typeof(Text))]
public class MemoryCounter : MonoBehaviour
{
    private Text m_GuiText;

    void Start()
    {
        m_GuiText = GetComponent<Text>();
    }
    void Update()
    {
        Debug.Log("Mono used size" + Profiler.GetMonoUsedSizeLong() / 1000000 + "Bytes");
        //m_GuiText.text = "" + megabytes;
    }
}
