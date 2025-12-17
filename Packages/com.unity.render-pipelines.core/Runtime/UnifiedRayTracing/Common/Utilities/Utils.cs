
namespace UnityEngine.Rendering.UnifiedRayTracing
{
    internal static class Utils
    {
        public static void Destroy(UnityEngine.Object obj)
        {
            if (obj != null)
            {
#if UNITY_EDITOR
                if (Application.isPlaying && !UnityEditor.EditorApplication.isPaused)
                    UnityEngine.Object.Destroy(obj);
                else
                    UnityEngine.Object.DestroyImmediate(obj);
#else
                UnityEngine.Object.Destroy(obj);
#endif
            }
        }
    }
}

