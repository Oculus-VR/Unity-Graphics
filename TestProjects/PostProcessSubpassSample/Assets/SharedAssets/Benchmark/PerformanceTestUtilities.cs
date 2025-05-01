using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

namespace Benchmarking
{
    public static class PerformanceTestUtilities
    {
        public static void Set(this Label label, FrameData frameData)
        {
            label.text = frameData.GetValueString(PerformanceTest.displayedDataType);
            label.style.color = PerformanceTest.GetColorForFrameData(frameData);
        }
    }
}
