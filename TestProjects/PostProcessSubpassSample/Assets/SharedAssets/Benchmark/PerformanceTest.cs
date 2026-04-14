using Cinemachine;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;
using UnityEngine.Serialization;
using UnityEngine.UIElements;

namespace Benchmarking
{
    public enum DataType
    {
        FrameTime,
        FPS,

        CPUTime,
        CPURenderTime,
        GPUTime,

        Count,
    }

    public class PerformanceTest : MonoBehaviour
    {
        private static PerformanceTest _instance;
        public static PerformanceTest instance
        {
            get
            {
                if (_instance == null)
                    _instance = FindAnyObjectByType<PerformanceTest>();

                return _instance;
            }
        }

        public bool _autoStart = true;
        [FormerlySerializedAs("m_Stages")]
        public List<PerformanceTestStage> _stages;

        [SerializeField]
        public float _waitTime = 5f;
        // TODO: Remove _framesToCapture
        [SerializeField]
        public int _framesToCapture = 500;

        [SerializeField]
        [FormerlySerializedAs("m_TestDataVisualTreeReference")]
        private VisualTreeAsset _testDataVisualTreeReference;

        [SerializeField]
        private int _currentTimingRefreshCount = 10;
        private int _currentTimingRefreshCounter = 11;
        private FrameData _maxCurrentTiming = new FrameData(0);

        [SerializeField]
        private bool _liveRefreshGraph = true;

        [SerializeField] private GameObject _cameraPrefab;

        [SerializeField]
        private EventSystem _eventSystem;
        public void RefreshEventSystem()
        {
            EventSystem.SetUITookitEventSystemOverride(_eventSystem);
        }

        public bool liveRefreshGraph => _liveRefreshGraph;

        private int _currentStageIndex;
        private PerformanceTestStage _currentStage => _stages[_currentStageIndex];



        private Camera _testCamera;
        public Camera testCamera
        {
            get
            {
                if (_testCamera == null)
                    CreateCamera();

                return _testCamera;
            }
        }

        private UIDocument _UIDocument;
        private TextElement _currentDataTypeLabel, _currentTimingLabel, _currentTimingUnitLabel;
        private Button _changeDataButtonNext, _changeDataButtonPrev, _closeButton;

        private static DataType _displayedDataType = DataType.FrameTime;
        public static DataType displayedDataType => _displayedDataType;

        private int _previousSleepTimeout;
        private int _previousTargetFrameRate = -1;
        private int _previousVSyncCount = 0;

        public void SetCurrentTiming(FrameData currentFrameData)
        {
            _maxCurrentTiming.MaxWith(currentFrameData);
            if (_currentTimingRefreshCounter > _currentTimingRefreshCount)
            {
                _currentTimingLabel.text = _maxCurrentTiming.GetValueString(_displayedDataType);
                _currentTimingLabel.style.color = GetColorForFrameData(_maxCurrentTiming);

                _currentTimingRefreshCounter = 0;
                _maxCurrentTiming = new FrameData(0);
            }
            _currentTimingRefreshCounter++;
        }

        public static bool RunningBenchmark =>
            _instance != null;

        const float
            k_frameLineMul = 1000f,
            k_cpuLineMul = 400f,
            k_cpuRenderLineMul = 200f,
            k_gpuLineMul = 400f;

        private static Dictionary<int, Color> k_fpsThresholds = new()
        {
            {  30, Color.red },
            {  45, Color.yellow },
            {  60, Color.green },
            {  90, Color.cyan },
            { 120, Color.blue }
        };
        private static Color s_worstColor = Color.red;

        private static Dictionary<FrameData, Color> s_timingThresholds;
        public static Dictionary<FrameData, Color> timingThresholds
        {
            get
            {
                if (s_timingThresholds == null)
                {
                    s_timingThresholds = new Dictionary<FrameData, Color>();
                    foreach (var kvp in k_fpsThresholds)
                    {

                        s_timingThresholds.Add(new FrameData()
                        {
                            frameTime = k_frameLineMul / kvp.Key,
                            cpuTime = k_cpuLineMul / kvp.Key,
                            cpuRenderTime = k_cpuRenderLineMul / kvp.Key,
                            gpuTime = k_gpuLineMul / kvp.Key,
                        }, kvp.Value);
                    }
                    s_worstColor = s_timingThresholds.First().Value;
                }
                return s_timingThresholds;
            }
        }

        public static Color GetColorForFrameData(FrameData frameData)
        {
            Color c = s_worstColor;
            if (_displayedDataType == DataType.FPS)
            {
                foreach (var kvp in s_timingThresholds)
                    if (frameData.fps < kvp.Key.fps)
                        return c;
                    else
                        c = kvp.Value;
            }
            else
            {
                foreach (var kvp in s_timingThresholds)
                    if (frameData.frameTime < kvp.Key.frameTime)
                        c = kvp.Value;
            }
            return c;
        }

        private void Awake()
        {
            //Destroy if assigned
            if (_instance != null)
            {
                Destroy(this);
                return;
            }

            _instance = this;
            DontDestroyOnLoad(this);

            var playerManager = FindObjectOfType<PlayerManager>();
            if (playerManager != null)
            {
                playerManager.gameObject.SetActive(false);
            }

            UnityEngine.Cursor.lockState = CursorLockMode.None;
        }

        void Start()
        {
            Time.maximumDeltaTime = 120;
            Application.runInBackground = true;

            QualitySettings.vSyncCount = 0;

            _UIDocument = GetComponent<UIDocument>();
            var rootVE = _UIDocument.rootVisualElement;
            _currentDataTypeLabel = rootVE.Q<TextElement>(name: "DataTypeLabel");
            _currentTimingLabel = rootVE.Q<TextElement>(name: "CurrentTiming");
            _currentTimingUnitLabel = rootVE.Q<TextElement>(name: "CurrentTimingUnit");
            _changeDataButtonNext = rootVE.Q<Button>(name: "ChangeDataButtonNext");
            _changeDataButtonNext.clicked += LoopDisplayedDataNext;
            _changeDataButtonPrev = rootVE.Q<Button>(name: "ChangeDataButtonPrev");
            _changeDataButtonPrev.clicked += LoopDisplayedDataPrevious;
            SetDisplayedData(_displayedDataType);
            _closeButton = rootVE.Q<Button>(name: "CloseButton");
            _closeButton.style.opacity = 0;

            var testList = rootVE.Q<VisualElement>(name: "TestsList");

            var cleanedUpStages = _stages.Where(s => SceneExists(s.sceneName) && s.enabled).ToList();

            for (int i = 0; i < cleanedUpStages.Count; i++)
            {
                var stage = cleanedUpStages[i];

                stage.InstantiateVisualElement(_testDataVisualTreeReference, testList);

                if (i < cleanedUpStages.Count - 1)
                    stage.SetFinishedAction(cleanedUpStages[i + 1].Start);
                else
                    stage.SetFinishedAction(FinalizeTests);
            }
            testList.MarkDirtyRepaint();

            _previousSleepTimeout = Screen.sleepTimeout;
            Screen.sleepTimeout = SleepTimeout.NeverSleep;

            _previousVSyncCount = QualitySettings.vSyncCount;
            QualitySettings.vSyncCount = 0;

            _previousTargetFrameRate = Application.targetFrameRate;
            Application.targetFrameRate = (int)Screen.currentResolution.refreshRateRatio.value * 8;

            cleanedUpStages[0].Start();
        }

        static bool SceneExists(string sceneName)
        {
            for (int i = 0; i < SceneManager.sceneCountInBuildSettings; i++)
            {
                string scenePath = SceneUtility.GetScenePathByBuildIndex(i);
                if (scenePath.Contains(sceneName))
                {
                    return true;
                }
            }
            return false;
        }

        private void CreateCamera()
        {
            GameObject go = Instantiate(_cameraPrefab);
            _testCamera = go.GetComponent<Camera>();
            //GameObject go = new GameObject("TestCamera");
            //_testCamera = go.AddComponent<Camera>();
            //var additionalData = go.AddComponent<UniversalAdditionalCameraData>();
            //additionalData.renderPostProcessing = true;

            //additionalData.antialiasing = AntialiasingMode.TemporalAntiAliasing;
            //additionalData.sett

            DontDestroyOnLoad(go);

            //go.AddComponent<CinemachineBrain>();
        }

        private void FinalizeTests()
        {
            Debug.Log(_sb.ToString());
            GUIUtility.systemCopyBuffer = _sb.ToString();

            _closeButton.style.opacity = 1f;
            _closeButton.clicked += CloseBenchmark;
        }

        private void SetDisplayedData(DataType dataType)
        {
            _displayedDataType = dataType;

            _currentDataTypeLabel.text = dataType.ToString();
            _currentTimingUnitLabel.text = (dataType == DataType.FPS) ? "" : "ms";

            foreach (var stage in _stages)
                stage.RefreshDisplayedData();
        }

        private void LoopDisplayedDataNext() { LoopDisplayedData(1); }
        private void LoopDisplayedDataPrevious() { LoopDisplayedData(-1); }

        private void LoopDisplayedData(int offset = 1)
        {
            int max = FrameTimingManager.IsFeatureEnabled() ? (int)DataType.Count - 1 : (int)DataType.FPS;

            int newValue = (int)_displayedDataType + offset;
            if (newValue < 0)
                newValue = max;
            else if (newValue > max)
                newValue = 0;

            SetDisplayedData((DataType)newValue);
        }

        private void CloseBenchmark()
        {
            UnityEngine.Object.Destroy(this.gameObject);

            var playerManager = FindObjectOfType<PlayerManager>();
            if (playerManager != null)
            {
                playerManager.gameObject.SetActive(true);
            }

            UnityEngine.Cursor.lockState = CursorLockMode.Locked;

            Screen.sleepTimeout = _previousSleepTimeout;
            QualitySettings.vSyncCount = _previousVSyncCount;
            Application.targetFrameRate = _previousTargetFrameRate;

            SceneManager.LoadScene(0);
        }

        private StringBuilder _sb = new StringBuilder("URP Template Performance Test");
        public static void CSVWrinteLine(params string[] values)
        {
            instance._sb.AppendLine();
            for (int i = 0; i < values.Length; i++)
            {
                instance._sb.Append((values[i] == null) ? "" : values[i]);
                if (i < values.Length - 1)
                    instance._sb.Append(",");
            }
        }
    }
}
