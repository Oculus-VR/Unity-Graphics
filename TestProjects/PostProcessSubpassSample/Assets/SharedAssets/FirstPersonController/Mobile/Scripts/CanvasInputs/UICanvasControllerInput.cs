using UnityEngine;

namespace StarterAssets
{
    public class UICanvasControllerInput : MonoBehaviour
    {

        [Header("Output")]
        public StarterAssetsInputs starterAssetsInputs;

        public PlayerManager CameraManager;

        public void VirtualMoveInput(Vector2 virtualMoveDirection)
        {
            if (CameraManager != null)
            {
                CameraManager.NotifyPlayerMoved();
            }

            starterAssetsInputs.MoveInput(virtualMoveDirection);
        }

        public void VirtualLookInput(Vector2 virtualLookDirection)
        {
            if (CameraManager != null)
            {
                CameraManager.NotifyPlayerMoved();
            }

            starterAssetsInputs.LookInput(virtualLookDirection);
        }

        public void VirtualJumpInput(bool virtualJumpState)
        {
            starterAssetsInputs.JumpInput(virtualJumpState);
        }

        public void VirtualSprintInput(bool virtualSprintState)
        {
            starterAssetsInputs.SprintInput(virtualSprintState);
        }

    }

}
