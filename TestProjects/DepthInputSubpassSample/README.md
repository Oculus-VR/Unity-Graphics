# Depth Input Subpass Sample
This sample project shows how to use depth input with shader graph and HLSL.

# Transparent material using depth input
![alt text](ShaderGraphWater.jpg)
Navigate to Assets/Scenes/ShaderGraphWater

This scene provide an example shader graph using depth input. For example, when rendering water or smoke, the shader can calculate the attenuation more correctly if knowing the depth of the volume.

# Ambident occlusion using depth input
![alt text](AOSample.jpg)
Navigate to Assets/Scenes/AmbientOcclusion_HLSL.

This scene provides an exmple of using depth input in HLSL. The scene renders a bounding box around the target object (sphere). With depth input, it can calculate the world position previously rendered in each pixel. Then it uses SDF to calculate the distance between the world position and the target object. With the distance info, an approximate ambident occlusion is rendered based on the distance between the world position and the object.
