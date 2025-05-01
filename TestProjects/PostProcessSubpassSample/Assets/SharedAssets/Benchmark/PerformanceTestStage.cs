using Cinemachine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.SceneManagement;
using UnityEngine.Serialization;
using UnityEngine.UIElements;

namespace Benchmarking
{
    [Serializable]
    public class PerformanceTestStage
    {
        public bool enabled = true;

        [FormerlySerializedAs("SceneName")]
        public string sceneName;

        // TODO: Remove followings
        public Vector3 cameraPosition;
        public Quaternion cameraRotation;
        public bool useFullTimeline = true;
        // ENDTODO

        private List<FrameData> _frameDatas;
        private FrameData _minFrameData, _maxFrameData, _avgFrameData, _medianFrameData, _lowerQuartileFrameData, _upperQuartileFrameData;

        private int _recordingIndex = 0;

        private Camera _testCamera => PerformanceTest.instance.testCamera;
        private Action _finishedAction;
        private PlayableDirector _playableDirector;
        private float _intermediateCaptureTime;

        private bool _uiInitialized = false;
        private VisualElement
            _visualElementRoot,
            _timingsGraphContainerVE,
            _quartilesVE,
            _quartilesMinMaxRangeVE,
            _quartilesRangeVE,
            _progressContainerVE,
            _progressBarVe;
        private Label
            _testNameLabel,
            _statusLabel,
            _timingsUnitLabel,
            _minLabel,
            _maxLabel,
            _avgLabel,
            _lowerQuartileLabel,
            _medianLabel,
            _upperQuartileLabel,
            _progressLabel;
        private StatsGraphVE _timingsGraphVE;
        private bool _timingVisible = true;
        private Button _cancelButton;

        private TestStageStatus _status = TestStageStatus.Waiting;
        public TestStageStatus status
        {
            get
            {
                return _status;
            }
            private set
            {
                _status = value;
                if (_statusLabel != null)
                    _statusLabel.text = _status.ToString();
            }
        }


        private DataType _displayedDataType => PerformanceTest.displayedDataType;

        private Dictionary<FrameData, VisualElement> _timingLines = new();

        public void RecordTiming(FrameData currentFrameData)
        {
            bool needsRangeUpdate = false;
            _frameDatas.Add(currentFrameData);
            if (_recordingIndex == 0)
            {
                _minFrameData = _maxFrameData = _avgFrameData = currentFrameData;
                needsRangeUpdate = true;
            }
            else
            {
                needsRangeUpdate |= _minFrameData.MinWith(currentFrameData, true);
                needsRangeUpdate |= _maxFrameData.MaxWith(currentFrameData, true);
                _avgFrameData.AverageWith(currentFrameData, _recordingIndex + 1, true);
            }

            // Debug.Log("Current frame: " + currentFrameData.ToString());
            // Debug.Log($"CpuTimerFrequency: {FrameTimingManager.GetCpuTimerFrequency()}, GpuTimerFrequency: {FrameTimingManager.GetGpuTimerFrequency()}");

            _recordingIndex++;

            _avgLabel.Set(_avgFrameData);
            if (needsRangeUpdate)
            {
                _minLabel.Set(_minFrameData);
                _maxLabel.Set(_maxFrameData);

                UpdateRangeAndGraph();
            }
        }

        public void InstantiateVisualElement(VisualTreeAsset referenceVisuaTree, VisualElement parent = null)
        {
            if (referenceVisuaTree == null)
                return;

            _visualElementRoot = referenceVisuaTree.Instantiate();
            _testNameLabel = _visualElementRoot.Q<Label>(name: "TestName");
            _statusLabel = _visualElementRoot.Q<Label>(name: "Status");

            _timingsUnitLabel = _visualElementRoot.Q<Label>(name: "UnitText");
            _minLabel = _visualElementRoot.Q<Label>(name: "MinText");
            _maxLabel = _visualElementRoot.Q<Label>(name: "MaxText");
            _avgLabel = _visualElementRoot.Q<Label>(name: "AvgText");
            _lowerQuartileLabel = _visualElementRoot.Q<Label>(name: "LowerQuartileText");
            _medianLabel = _visualElementRoot.Q<Label>(name: "MedianText");
            _upperQuartileLabel = _visualElementRoot.Q<Label>(name: "UpperQuartileText");

            _timingsGraphContainerVE = _visualElementRoot.Q(name: "TimingsGraph");
            _timingsGraphContainerVE.style.backgroundImage = null;
            _timingsGraphVE = new StatsGraphVE();
            _timingsGraphContainerVE.Add(_timingsGraphVE);

            if (!PerformanceTest.instance.liveRefreshGraph)
            {
                _timingsGraphVE.style.display = DisplayStyle.None;
                _timingVisible = false;
            }

            _quartilesVE = _visualElementRoot.Q(name: "Quartiles");
            _quartilesMinMaxRangeVE = _visualElementRoot.Q(name: "MinMaxRange");
            _quartilesRangeVE = _visualElementRoot.Q(name: "QuartilesRange");

            _progressContainerVE = _visualElementRoot.Q(name: "ProgressContainer");
            _progressBarVe = _visualElementRoot.Q(name: "ProgressBar");
            _progressLabel = _visualElementRoot.Q<Label>(name: "ProgressLabel");
            _progressContainerVE.style.opacity = 0f;

            _cancelButton = _visualElementRoot.Q<Button>(name: "CancelButton");
            _cancelButton.clicked += Cancel;
            _cancelButton.text = "Skip";

            var refLine = _visualElementRoot.Q(name: "StatLine");
            refLine.parent.Remove(refLine);

            var offset = 100f / (PerformanceTest.timingThresholds.Count + 2);
            var lengthValue = new Length(offset, LengthUnit.Percent);
            foreach (var kvp in PerformanceTest.timingThresholds)
            {
                var ve = new VisualElement();
                ve.style.backgroundColor = kvp.Value;
                ve.style.bottom = lengthValue;
                ve.AddToClassList("StatLine");
                _timingsGraphContainerVE.Add(ve);
                lengthValue.value += offset;

                _timingLines.Add(kvp.Key, ve);
            }

            _testNameLabel.text = sceneName;

            if (parent != null)
            {
                parent.Add(_visualElementRoot);
            }

            _uiInitialized = true;

            status = TestStageStatus.Waiting;
        }

        public void CalculateValues(bool recalculateRange = false)
        {
            if (recalculateRange)
            {
                _minFrameData = FrameData.MinMultiple(_frameDatas);
                _maxFrameData = FrameData.MaxMultiple(_frameDatas);
            }

            var orderedData = new List<FrameData>(_frameDatas).OrderBy(v => v.frameTime).ToArray();
            var lowerQuartileIndexF = _frameDatas.Count * 0.25f;
            var medianIndexF = _frameDatas.Count * 0.5f;
            var upperQuartileIndexF = _frameDatas.Count * 0.75f;

            var lowerQuartileIndexI = (int)lowerQuartileIndexF;
            lowerQuartileIndexF -= lowerQuartileIndexI;

            var medianIndexI = (int)medianIndexF;
            medianIndexF -= medianIndexI;

            var upperQuartileIndexI = (int)upperQuartileIndexF;
            upperQuartileIndexF -= upperQuartileIndexI;

            int lastIndex = orderedData.Length - 1;
            // Debug.Log($"lowerQuartileIndexI: {lowerQuartileIndexI} , orderedData.Length: {orderedData.Length}");
            _lowerQuartileFrameData = FrameData.Lerp(orderedData[lowerQuartileIndexI], orderedData[Mathf.Min(lowerQuartileIndexI + 1, lastIndex)], lowerQuartileIndexF);
            _medianFrameData = FrameData.Lerp(orderedData[medianIndexI], orderedData[Mathf.Min(medianIndexI + 1, lastIndex)], medianIndexF);
            _upperQuartileFrameData = FrameData.Lerp(orderedData[upperQuartileIndexI], orderedData[Mathf.Min(upperQuartileIndexI + 1, lastIndex)], upperQuartileIndexF);

            float tmpFPS = _lowerQuartileFrameData.fps;
            _lowerQuartileFrameData.SetFPSOverride(_upperQuartileFrameData.fps);
            _upperQuartileFrameData.SetFPSOverride(tmpFPS);
        }

        public void Start()
        {
            Start(null);
        }

        public void Start(Action finishedAction)
        {
            if (finishedAction != null)
                _finishedAction = finishedAction;

            // Debug.Log("Called start for : " + sceneName);

            PerformanceTest.instance.StartCoroutine(ProcessTest());
        }
        public void SetFinishedAction(Action finishedAction) { _finishedAction = finishedAction; }

        IEnumerator ProcessTest()
        {
            if (status == TestStageStatus.Waiting)
            {
                yield return LoadAndInit();
                yield return new WaitForSeconds(PerformanceTest.instance._waitTime);
                yield return RunTest();
                yield return End();
            }

            if (_finishedAction != null)
            {
                // Debug.Log("Invoking Finish action");
                _finishedAction.Invoke();
            }
        }

        IEnumerator LoadAndInit()
        {
            status = TestStageStatus.Warming;
            _cancelButton.text = "Stop";

            // Debug.Log($"Start test {sceneName}");

            _testCamera.transform.position = cameraPosition;
            _testCamera.transform.rotation = cameraRotation;

            // Debug.Log($"Load Scene {sceneName}");

            SceneManager.sceneLoaded += SceneLoadCallback;
            SceneManager.LoadSceneAsync(sceneName, LoadSceneMode.Single);

            // Wait for scene to be loaded
            yield return new WaitUntil(HasSceneLoaded);

            yield return null;
            PerformanceTest.instance.RefreshEventSystem();

            DisableCamerasInScene();

            var directors = Resources.FindObjectsOfTypeAll<PlayableDirector>();

            // Debug.Log($"Found {directors.Length} playable director(s) in the scene {SceneManager.GetActiveScene().name}");

            if (directors.Length > 1 && directors.Any(d => (d.gameObject.name == "CinematicTimeline") || d.gameObject.CompareTag("BenchmarkTimeline")))
                _playableDirector = directors.First(d => (d.gameObject.name == "CinematicTimeline") || d.gameObject.CompareTag("BenchmarkTimeline"));
            else if (directors.Length > 0)
                _playableDirector = directors[0];

            if (_playableDirector != null)
            {
                _playableDirector.gameObject.SetActive(true);
                var playable = _playableDirector.playableAsset;
                if (playable.outputs.Any(o => o.outputTargetType == typeof(CinemachineBrain)))
                {
                    var cinemachineTrack = playable.outputs.Single(o => o.outputTargetType == typeof(CinemachineBrain)).sourceObject;
                    _playableDirector.SetGenericBinding(cinemachineTrack, _testCamera.GetComponent<CinemachineBrain>());
                }

                var duration = (float)_playableDirector.duration;
                _intermediateCaptureTime = duration / (PerformanceTest.instance._framesToCapture + 1);

                _playableDirector.Play();
                _playableDirector.extrapolationMode = DirectorWrapMode.None;

                // Debug.Log($"Will use timeline: {_playableDirector.name} of duration: {_playableDirector.duration}");
            }

            // Init
            var initialListSize = PerformanceTest.instance._framesToCapture;
            if (_playableDirector != null && useFullTimeline)
                initialListSize = (int)_playableDirector.duration * 120;
            _recordingIndex = 0;

            _frameDatas = new List<FrameData>();
            _maxFrameData
                = _avgFrameData
                = _medianFrameData
                = _upperQuartileFrameData
                = _lowerQuartileFrameData
                = new FrameData(0f);
            _minFrameData = new FrameData(Mathf.Infinity);
        }

        private bool sceneLoaded = false;
        private bool HasSceneLoaded()
        {
            return sceneLoaded;
        }

        void SceneLoadCallback(Scene scene, LoadSceneMode loadSceneMode)
        {
            // Debug.Log($"Scene {scene.name} has loaded.");

            SceneManager.SetActiveScene(scene);
            sceneLoaded = true;
            SceneManager.sceneLoaded -= SceneLoadCallback;
        }

        IEnumerator RunTest()
        {
            if (status != TestStageStatus.Warming)
                yield break;

            // Debug.Log("Start running test.");

            status = TestStageStatus.Running;
            _progressContainerVE.style.opacity = 1f;
            _progressLabel.text = "0";
            _progressBarVe.style.width = 0;

            bool noIntermediateTime = useFullTimeline && _playableDirector != null;

            if (_playableDirector != null)
            {
                _playableDirector.time = 0f;
                _playableDirector.Play();
            }

            while (
                status != TestStageStatus.Stopped &&
                (
                    _recordingIndex < _frameDatas.Count ||
                    (
                        useFullTimeline && _playableDirector != null &&
                        _playableDirector.state != PlayState.Paused
                    )
                )
            )
            {
                FrameData currentFrameData = FrameData.GetCurrentFrameData();
                currentFrameData.CaptureFrameTimings();
                currentFrameData.timeLineTime = _playableDirector.time;

                PerformanceTest.instance.SetCurrentTiming(currentFrameData);
                RecordTiming(currentFrameData);
                UpdateGraph();

                int timerLineAdvancement = (int)(100 * _playableDirector.time / _playableDirector.duration);

                _progressLabel.text = timerLineAdvancement.ToString();
                _progressBarVe.style.width = P(timerLineAdvancement);

                if (noIntermediateTime)
                    yield return null;
                else
                    yield return new WaitForSeconds(_intermediateCaptureTime);
            }
        }

        IEnumerator End()
        {
            _cancelButton.style.opacity = 0;
            _cancelButton.clicked -= Cancel;

            if (status == TestStageStatus.Running)
                status = TestStageStatus.Finished;
            else if (status != TestStageStatus.Stopped)
                yield break;

            _progressContainerVE.style.opacity = 0f;
            // Debug.Log($"Test {sceneName} finished and captured {_frameDatas.Count} frames timings");
            CalculateValues();
            _lowerQuartileLabel.Set(_lowerQuartileFrameData);
            _upperQuartileLabel.Set(_upperQuartileFrameData);
            _medianLabel.Set(_medianFrameData);

            float maxScale = 100f / _maxFrameData.GetValue(_displayedDataType);

            _quartilesMinMaxRangeVE.style.top = P(0);
            _quartilesMinMaxRangeVE.style.bottom = P(_minFrameData.GetValue(_displayedDataType) * maxScale);
            _quartilesRangeVE.style.top = P(100f - _upperQuartileFrameData.GetValue(_displayedDataType) * maxScale);
            _quartilesRangeVE.style.bottom = P(_lowerQuartileFrameData.GetValue(_displayedDataType) * maxScale);

            if (!_timingVisible)
            {
                _timingsGraphVE.style.display = DisplayStyle.Flex;
                _timingVisible = true;
                UpdateGraph();
            }

            WriteCSV();

            yield return null;
        }

        void Cancel()
        {
            if (status == TestStageStatus.Waiting || status == TestStageStatus.Warming)
            {
                status = TestStageStatus.Skipped;
            }
            else
            {
                status = TestStageStatus.Stopped;
                // _progressContainerVE.style.opacity = 0f;
            }

            _cancelButton.style.opacity = 0;
            _cancelButton.clicked -= Cancel;
        }

        private void DisableCamerasInScene()
        {
            foreach (var camera in UnityEngine.Object.FindObjectsOfType<Camera>())
            {
                // Debug.Log("Found camera: " + camera.gameObject.name);
                if (camera.gameObject != _testCamera.gameObject)
                {
                    camera.enabled = false;
                }
            }
        }

        public void RefreshDisplayedData()
        {
            if
            (
                !_uiInitialized ||
                status == TestStageStatus.Waiting ||
                status == TestStageStatus.Skipped ||
                status == TestStageStatus.Warming
            )
                return;

            _timingsUnitLabel.text = (PerformanceTest.displayedDataType == DataType.FPS) ? "" : "ms";

            _minLabel.Set(_minFrameData);
            _maxLabel.Set(_maxFrameData);
            _avgLabel.Set(_avgFrameData);
            _lowerQuartileLabel.Set(_lowerQuartileFrameData);
            _upperQuartileLabel.Set(_upperQuartileFrameData);
            _medianLabel.Set(_medianFrameData);
            UpdateRangeAndGraph();
        }

        private void UpdateGraph()
        {
            if (!_timingVisible || _timingsGraphVE.isDirty || !_uiInitialized || _frameDatas == null || _frameDatas.Count < 2)
                return;

            _timingsGraphVE.SetData(_frameDatas.Select(v => v.GetValue(_displayedDataType) / _maxFrameData.GetValue(_displayedDataType)).ToList(), true);
        }

        private void UpdateRangeAndGraph()
        {
            float maxScale = 100f / _maxFrameData.GetValue(_displayedDataType);

            float min = _minFrameData.GetValue(_displayedDataType);
            float max = _maxFrameData.GetValue(_displayedDataType);

            _quartilesMinMaxRangeVE.style.top = P(0);
            _quartilesMinMaxRangeVE.style.bottom = P(_minFrameData.GetValue(_displayedDataType) * maxScale);

            float v;
            foreach (var kvp in _timingLines)
            {
                v = kvp.Key.GetValue(_displayedDataType) / max;
                if (v < 1f)
                {
                    kvp.Value.style.bottom = P(100 * v);
                    kvp.Value.style.display = DisplayStyle.Flex;
                }
                else
                {
                    kvp.Value.style.display = DisplayStyle.None;
                }
            }

            UpdateGraph();
        }

        public static Length P(float percentage, bool isNormalizedValue = false)
        {
            return new Length(isNormalizedValue ? percentage * 100f : percentage, LengthUnit.Percent);
        }

        public void WriteCSV()
        {
            PerformanceTest.CSVWrinteLine();
            PerformanceTest.CSVWrinteLine("Scene", sceneName);
            PerformanceTest.CSVWrinteLine();
            PerformanceTest.CSVWrinteLine("", "Frame Time", "FPS", "CPU time", "CPU Render Thread Time", "GPU Time");
            _minFrameData.WriteCSV("Minimum");
            _maxFrameData.WriteCSV("Maximum");
            _avgFrameData.WriteCSV("Average");
            _lowerQuartileFrameData.WriteCSV("Lower Quartile");
            _medianFrameData.WriteCSV("Median");
            _upperQuartileFrameData.WriteCSV("Upper Quartile");

            PerformanceTest.CSVWrinteLine();

            PerformanceTest.CSVWrinteLine("Captured frames", _frameDatas.Count().ToString());
            PerformanceTest.CSVWrinteLine("", "Frame Time", "FPS", "CPU time", "CPU Render Thread Time", "GPU Time");
            for (int i = 0; i < _frameDatas.Count(); i++)
                _frameDatas[i].WriteCSV(writeTimeLineTime: true);
        }
    }

    public enum TestStageStatus
    {
        Waiting,
        Warming,
        Running,
        Finished,
        Stopped,
        Skipped
    }
}
