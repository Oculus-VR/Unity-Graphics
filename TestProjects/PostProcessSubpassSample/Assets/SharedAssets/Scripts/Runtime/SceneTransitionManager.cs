using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;
using Benchmarking;
using Cinemachine;

public class SceneTransitionManager : MonoBehaviour
{
    [Tooltip("Enable to debug the transition effect")] //TODO: do we want to remove this? 
    [SerializeField] private bool m_OverrideTransition;
    [SerializeField][Range(0, 1)] private float m_ManualTransition;

    [Tooltip("The amount of time it takes to transition between two scenes")]
    [SerializeField] private float m_TransitionTime;

    private Camera m_MainCamera;
    private Camera m_ScreenCamera;
    private CharacterController m_Player;
    private PlayerManager m_CameraManager;

    private bool m_InitialSceneLoad;

    private static SceneTransitionManager instance;

    [Tooltip("Layers to render when in a location")]
    [SerializeField] private LayerMask locationLayer;
    [Tooltip("Layers to render when in the terminal")]
    [SerializeField] private LayerMask m_TerminalLayer;

    private bool InTerminal = true;

    private bool m_EneableCharacterInFollowingFrame = false;

    private SceneLoader m_Loader;

    private Transform spawnTransform;

    private Vector3 m_PositionAtLock;
    private Quaternion m_RotationAtLock;

    private bool InTransition = false;
    private bool CoolingOff = false; //After teleporting
    private float ElapsedTimeInTransition = 0;

    private Dictionary<string, SceneMetaData> registeredScenes;
    private SceneMetaData screenScene;
    private SceneMetaData currentScene;

    private int m_ScenesLoading;

    private Vector3 m_CameraPosition;
    private Quaternion m_CameraRotation;

    //Used for cinemachine transition
    private MediaSceneLoader m_MediaSceneLoader;

    private int m_TransitionAmountShaderProperty;

    private bool m_ScreenOff;

    void Awake()
    {
        if (PerformanceTest.RunningBenchmark)
        {
            Destroy(gameObject);
            return;
        }

        SetupSingleton();

        SetupReferences();

        SetupInitialState();
    }

    #region Awake
    public void SetupSingleton()
    {
        if (instance != null)
        {
            Destroy(gameObject);
            return;
        }
        instance = this;
        DontDestroyOnLoad(gameObject);
    }

    public void SetupReferences()
    {
        m_Player = GameObject.Find("PlayerCapsule")?.GetComponent<CharacterController>(); //TODO: Don't hardcode string
        if (m_Player == null)
        {
            Debug.Log("Couldn't find character controller");
        }

        m_CameraManager = m_Player.transform.parent.GetComponent<PlayerManager>();

        m_MainCamera = GameObject.FindGameObjectWithTag("MainCamera")?.GetComponent<Camera>();

        if (m_MainCamera == null)
        {
            Debug.Log("Couldn't find Main Camera");
        }

        m_ScreenCamera = GameObject.FindGameObjectWithTag("ScreenCamera").GetComponent<Camera>();
        if (m_ScreenCamera == null)
        {
            Debug.Log("Couldn't find Screen Camera");
        }

        m_ScreenCamera.GetComponent<Camera>().enabled = false;

        m_TransitionAmountShaderProperty = Shader.PropertyToID("_TransitionAmount");
    }

    public void SetupInitialState()
    {
        InTerminal = true;
        m_InitialSceneLoad = true;

        registeredScenes = new Dictionary<string, SceneMetaData>();

        m_ScreenOff = true;

        RenderSettings.defaultReflectionMode = DefaultReflectionMode.Custom;
    }
    #endregion

    void Update()
    {
        if (m_EneableCharacterInFollowingFrame)
        {
            m_Player.GetComponent<StarterAssets.FirstPersonController>().enabled = true;
            m_EneableCharacterInFollowingFrame = false;
        }

        float t = m_OverrideTransition ? m_ManualTransition : ElapsedTimeInTransition / m_TransitionTime;

        if (InTransition)
        {
            ElapsedTimeInTransition += Time.deltaTime;

            if (ElapsedTimeInTransition > m_TransitionTime)
            {
                TriggerTeleport();
            }

            ElapsedTimeInTransition = Mathf.Min(m_TransitionTime, ElapsedTimeInTransition);
        }
        else
        {
            ElapsedTimeInTransition -= Time.deltaTime * 3;

            if (ElapsedTimeInTransition < 0 && CoolingOff)
            {
                CoolingOff = false;
            }

            ElapsedTimeInTransition = Mathf.Max(0, ElapsedTimeInTransition);
        }

        //Update weights of post processing volumes
        if (m_Loader != null && !CoolingOff)
        {
            float tSquared = t * t;
            m_Loader.SetVolumeWeights(1 - tSquared);
        }

        Shader.SetGlobalFloat(m_TransitionAmountShaderProperty, t);
    }

    private void TriggerTeleport()
    {
        InTransition = false;

        if (m_Loader != null)
        {
            m_Loader.SetVolumeWeights(1);
        }

        if (m_MediaSceneLoader) //check this some other way
        {
            CinemachineTeleport();
        }
        else
        {
            Teleport();
        }

        m_Loader = null;
        CoolingOff = true;
    }

    /// <summary>
    /// This function is called per camera by the render pipeline.
    /// We use it to set up light and render settings (skybox etc) for the different scenes as they are displayed
    /// </summary>
    void OnBeginCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        bool isMainCamera = camera.CompareTag("MainCamera");

        if (!isMainCamera && screenScene == null)
        {
            //If no screen scene is loaded, no setup needs to be done for it
            return;
        }

        //Toggle main light
        if (camera.cameraType == CameraType.SceneView)
        {
            ToggleMainLight(currentScene, true);
            ToggleMainLight(screenScene, false);
        }
        else
        {
            ToggleMainLight(currentScene, isMainCamera);
            ToggleMainLight(screenScene, !isMainCamera);
        }

        //Setup render settings
        SceneMetaData sceneToRender = isMainCamera || camera.cameraType == CameraType.SceneView ? currentScene : screenScene;
        RenderSettings.fog = sceneToRender.FogEnabled;
        RenderSettings.skybox = sceneToRender.skybox;
        if (sceneToRender.reflection != null)
        {
            RenderSettings.customReflectionTexture = sceneToRender.reflection;
        }

        if (!isMainCamera && camera.cameraType == CameraType.Game)
        {
            camera.GetComponent<OffsetCamera>().UpdateWithOffset();
        }
    }

    private void ToggleMainLight(SceneMetaData scene, bool value)
    {
        if (scene != null && scene.mainLight != null)
        {
            scene.mainLight.SetActive(value);
        }
    }

    public static void CinemachineTeleport()
    {
        instance.InTerminal = !instance.InTerminal;
        instance.UpdateCullingMasks();

        Transform flythroughRoot = instance.m_MediaSceneLoader.transform;

        if (!instance.InTerminal)
        {
            flythroughRoot.position = instance.m_ScreenCamera.GetComponent<OffsetCamera>().GetOffset();
            instance.m_MediaSceneLoader.GetTerminalSceneLoader().SetCurrentVolume(instance.m_Loader.GetDestinationVolume());
            instance.screenScene.TerminalLoader.SetActive(true);
        }
        else
        {
            flythroughRoot.position = Vector3.zero;
            instance.m_Loader = instance.m_MediaSceneLoader.GetTerminalSceneLoader();
        }

        (instance.screenScene, instance.currentScene) = (instance.currentScene, instance.screenScene);
    }

    public static void Teleport()
    {
        if (!instance.currentScene || !instance.screenScene)
        {
            Debug.LogError("Can't teleport without two scenes enabled");
            return;
        }

        instance.InTerminal = !instance.InTerminal;
        instance.UpdateCullingMasks();

        //Swap Camera positions
        Transform playerTransform = instance.m_Player.transform;

        //Disable character controller while manipulating positions
        StarterAssets.FirstPersonController controller = playerTransform.GetComponent<StarterAssets.FirstPersonController>();
        controller.enabled = false;

        bool newPositionLocked = instance.screenScene.CameraLockTransform != null;
        bool comingFromLockedPosition = instance.currentScene.CameraLockTransform != null;

        if (newPositionLocked)
        {
            //Cache transform player before moving
            instance.m_PositionAtLock = playerTransform.position;
            instance.m_RotationAtLock = playerTransform.rotation;

            //Set position, parent and rotation to new locked location
            Transform cameraLockTransform = instance.screenScene.CameraLockTransform;

            playerTransform.parent.parent = cameraLockTransform;

            playerTransform.position = cameraLockTransform.position;
            playerTransform.rotation = cameraLockTransform.rotation;

            //Disable the player to prevent them from moving
            instance.m_Player.enabled = false;

            instance.m_MainCamera.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing = false; //TODO: this is hardcoded for the cockpit. Should probably be in the metadata

            DisableScene(instance.currentScene);
        }
        else
        {
            //Find the offset between the player camera and feet positions
            Vector3 playerCameraOffset = instance.m_MainCamera.transform.position - instance.m_Player.transform.position;

            //Position the player at the screen camera position
            playerTransform.position = instance.m_ScreenCamera.transform.position - playerCameraOffset;

            //Toggle the offset of the screen camera to put it where the player used to be
            OffsetCamera oc = instance.m_ScreenCamera.GetComponent<OffsetCamera>();
            oc.ToggleOffset();

            //Reset transform if teleporting from a locked position
            if (comingFromLockedPosition)
            {

                Transform playerParent = playerTransform.parent;

                playerParent.rotation = Quaternion.identity;
                playerParent.parent = null;
                DontDestroyOnLoad(playerParent);
                playerTransform.rotation = instance.m_RotationAtLock;
                playerTransform.position = instance.m_PositionAtLock;
                instance.m_Player.enabled = true;

                EnableScene(instance.screenScene);
            }

            instance.m_MainCamera.GetComponent<UniversalAdditionalCameraData>().renderPostProcessing = true; //see same line in the locked transform case
        }

        instance.m_CameraManager.FlythroughDirector = instance.screenScene.FlythroughDirector;

        instance.m_MainCamera.GetComponent<CinemachineBrain>().m_WorldUpOverride =
            instance.screenScene.WorldUpTransform;

        //Enable or disable post based on what the new scene needs
        UniversalAdditionalCameraData mainCameraData = instance.m_MainCamera.GetComponent<UniversalAdditionalCameraData>();

        mainCameraData.renderPostProcessing = instance.screenScene.PostProcessingEnabled;
        mainCameraData.SetRenderer(instance.screenScene.RendererIndex);

        //Reenable controller after teleporting
        instance.m_EneableCharacterInFollowingFrame = true;

        SceneManager.SetActiveScene(instance.screenScene.Scene);

        //This is weird
        RenderSettings.defaultReflectionMode = DefaultReflectionMode.Custom;



        //Swap references to screen and current scene
        (instance.screenScene, instance.currentScene) = (instance.currentScene, instance.screenScene);

        //Setup terminal loader so player can get back and reset the timeline director
        instance.SetTerminalLoaderAndDirector(instance.screenScene, false);
        instance.SetTerminalLoaderAndDirector(instance.currentScene, true);
    }

    private void UpdateCullingMasks()
    {
        if (instance.InTerminal)
        {
            //Add to mask
            instance.m_MainCamera.cullingMask |= instance.m_TerminalLayer;
            instance.m_ScreenCamera.cullingMask |= instance.locationLayer;

            //Remove from mask
            instance.m_MainCamera.cullingMask ^= instance.locationLayer;
            instance.m_ScreenCamera.cullingMask ^= instance.m_TerminalLayer;
        }
        else
        {
            //Add to mask
            instance.m_MainCamera.cullingMask ^= instance.m_TerminalLayer;
            instance.m_ScreenCamera.cullingMask ^= instance.locationLayer;

            //Remove from mask
            instance.m_MainCamera.cullingMask |= instance.locationLayer;
            instance.m_ScreenCamera.cullingMask |= instance.m_TerminalLayer;
        }
    }

    private void SetTerminalLoaderAndDirector(SceneMetaData scene, bool isActive)
    {
        if (scene.TerminalLoader != null)
        {
            scene.TerminalLoader.SetActive(isActive);
        }
        if (scene.SequenceDirector != null)
        {
            scene.SequenceDirector.time = 0;
            scene.SequenceDirector.enabled = isActive;
            if (isActive)
            {
                scene.SequenceDirector.Play();
            }

        }
    }

    #region On Enable/Disable

    private void OnEnable()
    {
        RenderPipelineManager.beginCameraRendering += OnBeginCameraRendering;
        SceneManager.sceneLoaded += OnSceneLoaded;
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;
        SceneManager.sceneLoaded -= OnSceneLoaded;
    }

    #endregion

    #region Scene Loading

    /// <summary>
    /// This function is called by the metadata script to notify of its existence
    /// </summary>
    public static void RegisterScene(string name, SceneMetaData metaData)
    {
        instance.registeredScenes.Add(name, metaData);

        if (instance.currentScene == null) //First loaded scene get's assigned to current
        {
            instance.currentScene = metaData;
        }
    }

    public static void NotifySceneLoading()
    {
        instance.m_ScenesLoading++;
        instance.m_Player.GetComponent<StarterAssets.FirstPersonController>().enabled = false;
    }

    void OnSceneLoaded(Scene scene, LoadSceneMode mode)
    {
        instance.m_ScenesLoading--;
        if (instance.m_ScenesLoading == 0) instance.m_Player.GetComponent<StarterAssets.FirstPersonController>().enabled = true;
    }

    /// <summary>
    /// This function is called by the scene loader when the player enters its trigger
    /// </summary>
    public static void EnableScene(SceneLoader sceneLoader)
    {
        if (!IsAvailable()) return;

        SceneMetaData sceneMetaData = instance.registeredScenes[sceneLoader.SceneName];

        if (sceneMetaData == null)
        {
            throw new Exception("Trying to enable unregistered scene");
        }

        Debug.Log("Enabling this scene: " + sceneMetaData.Scene.name);

        instance.m_Loader = sceneLoader;
        instance.m_InitialSceneLoad = false;
        instance.screenScene = sceneMetaData;
        instance.currentScene.TerminalLoader = sceneLoader.ControllPanel;

        LightProbes.TetrahedralizeAsync();

        //Enable game objects
        sceneMetaData.Root.SetActive(true);

        //Reset any director that needs to play
        if (sceneMetaData.SequenceDirector != null)
        {
            sceneMetaData.SequenceDirector.time = 0;
            sceneMetaData.SequenceDirector.Play();
        }

        //Set the offset of the screen camera 
        if (sceneMetaData.SpawnTransform != null)
        {
            instance.m_ScreenCamera.GetComponent<OffsetCamera>().SetOffset(
                sceneMetaData.SpawnTransform.position - instance.m_Loader.ReferencePoint.position);
        }

        //Switch on the screens
        if (sceneLoader.screen != null)
        {
            sceneLoader.screen.TurnScreenOn();
        }

        //Set the renderer index
        int index = sceneMetaData.RendererIndex > 1 ? sceneMetaData.RendererIndex : 1;
        instance.m_ScreenCamera.GetComponent<UniversalAdditionalCameraData>().SetRenderer(index);

        instance.m_ScreenCamera.GetComponent<Camera>().enabled = true;
        instance.m_ScreenOff = false;
    }

    public static void EnableScene(SceneMetaData sceneMetaData)
    {
        sceneMetaData.Root.SetActive(true);
        instance.m_ScreenCamera.GetComponent<Camera>().enabled = true;
    }


    public static void DisableScene(SceneLoader sceneLoader)
    {
        if (!IsAvailable()) return;
        SceneMetaData sceneMetaData = instance.registeredScenes[sceneLoader.SceneName];
        if (sceneMetaData == instance.currentScene)
        {
            Debug.Log("Trying to disable current scene");
            return;
        }

        Debug.Log("Disabling this scene: " + sceneMetaData.Scene.name);

        LightProbes.TetrahedralizeAsync();

        //Turn off the screen and disable the root object in the scene once screen is completely shut off
        if (sceneLoader.screen != null)
        {
            sceneLoader.screen.TurnScreenOff(() =>
            {
                if (instance.m_ScreenOff)
                {
                    sceneMetaData.Root.SetActive(false);
                    instance.m_ScreenCamera.GetComponent<Camera>().enabled = false;

                }
            });
        }

        instance.m_ScreenOff = true;
    }

    public static void DisableScene(SceneMetaData sceneMetaData)
    {
        sceneMetaData.Root.SetActive(false);
        instance.m_ScreenCamera.GetComponent<Camera>().enabled = false;
    }

    public static void DisableLoadedScene()
    {
        if (instance.m_Loader == null) return;
        DisableScene(instance.m_Loader);
    }

    public static void StartTransition()
    {
        instance.InTransition = true;
    }

    public static void StartTransition(MediaSceneLoader mediaSceneLoader)
    {
        if (!IsAvailable()) return;

        instance.m_MediaSceneLoader = mediaSceneLoader;
        if (!instance.InTerminal)
        {
            instance.m_Loader = instance.currentScene.TerminalLoader.GetComponentInChildren<SceneLoader>();
        }
        StartTransition();
    }

    public static void StopTransition()
    {
        instance.InTransition = false;
    }

    public static bool DissolveNeeded()
    {
        return instance != null && instance.ElapsedTimeInTransition > 0.001f;
    }

    #endregion

    #region Getters

    public static bool IsLoaded(string sceneName)
    {
        return instance.registeredScenes.ContainsKey(sceneName);
    }

    public static RenderTexture GetScreenRT()
    {
        return instance.m_ScreenCamera.activeTexture;
    }

    public static bool HasNotLoadedScene()
    {
        return instance.m_InitialSceneLoad;
    }

    public static bool IsAvailable()
    {
        return instance != null;
    }

    public static GameObject GetMainCamera()
    {
        return instance.m_MainCamera.gameObject;
    }

    public static SceneMetaData GetCurrentSceneData()
    {
        return instance.currentScene;
    }

    public static bool IsInTerminal()
    {
        return instance.InTerminal;
    }

    #endregion
}
