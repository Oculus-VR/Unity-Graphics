#if UNITY_EDITOR && ENABLE_VR && ENABLE_XR_MODULE

using System;
using System.Collections.Generic;
using UnityEngine.XR;

	namespace UnityEngine.Rendering.Universal
	{

		public static class DebugOculusMotionVectorSettings
		{
			public static bool enableDebugMotionVectors;

			public static RenderTexture motionVectorRenderTarget;
        	public static RenderTextureDescriptor motionVectorRenderTargetDesc;
            public static RenderTexture depthRenderTarget;
            public static RenderTextureDescriptor depthRenderTargetDesc;
		}

}

#endif