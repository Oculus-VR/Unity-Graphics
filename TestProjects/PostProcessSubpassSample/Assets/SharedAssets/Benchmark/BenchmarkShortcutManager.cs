using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;

namespace Benchmarking
{
    public class BenchmarkShortcutManager : MonoBehaviour
    {
        private static BenchmarkShortcutManager s_instance;
        public static BenchmarkShortcutManager instance
        {
            get
            {
                if (s_instance == null)
                    GetOrCreate();

                return s_instance;
            }
        }

        [RuntimeInitializeOnLoadMethod]
        private static void GetOrCreate()
        {
            s_instance = FindObjectOfType<BenchmarkShortcutManager>();
            if (s_instance == null)
            {
                var go = new GameObject("Benchmark Shortcut Manager");
                s_instance = go.AddComponent<BenchmarkShortcutManager>();
            }

            DontDestroyOnLoad(s_instance.gameObject);
        }

        private void Awake()
        {
            if (s_instance != null)
            {
                Destroy(gameObject);
                return;
            }

            s_instance = this;
            DontDestroyOnLoad(s_instance.gameObject);

#if ENABLE_INPUT_SYSTEM
            var action = new InputAction();
            action.AddCompositeBinding("ButtonWithOneModifier")
                .With("Button", "<Keyboard>/B")
                .With("Modifier", "<Keyboard>/leftShift")
                .With("Modifier", "<Keyboard>/rightShift");
            action.performed += ctx => StartBenchmark();
            action.Enable();

            UnityEngine.InputSystem.EnhancedTouch.EnhancedTouchSupport.Enable();
#endif
        }


#if ENABLE_INPUT_SYSTEM
        // TODO: make this an action ?
        public void Update()
        {
            if (SystemInfo.deviceType != DeviceType.Handheld)
                return;

            if (UnityEngine.InputSystem.EnhancedTouch.Touch.activeFingers.Count > 3)
                StartBenchmark();
        }
#endif

#if !ENABLE_INPUT_SYSTEM
        void Update()
        {
            if (SystemInfo.deviceType == DeviceType.Handheld)
            {
                if (Input.touchCount > 3)
                    StartBenchmark();
            }
            else
            {
                if (Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift))
                    if (Input.GetKeyDown(KeyCode.B) && !PerformanceTest.RunningBenchmark)
                        StartBenchmark();
            }
        }
#endif

        private bool availableToStart = true;
        void StartBenchmark()
        {
            if (!PerformanceTest.RunningBenchmark && availableToStart)
            {
                StartCoroutine(WaitingTime());
                SceneManager.LoadScene("BenchmarkScene");
            }
        }

        IEnumerator WaitingTime()
        {
            availableToStart = false;
            yield return new WaitForSeconds(5);
            availableToStart = true;
        }
    }
}
