#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(local_size_x = 16, local_size_y = 16) in;

layout(binding = 0, rgba8) uniform writeonly image2D resultImage;

uvec2 pictureSize = (gl_NumWorkGroups * gl_WorkGroupSize).xy;
uvec2 pixelCoords = gl_GlobalInvocationID.xy;

void outputColor(vec3 color)
{
	imageStore(resultImage, ivec2(pixelCoords), vec4(color, 1));
}

void main()
{
	vec3 resultColor = vec3(1, 0, 0);
	outputColor(resultColor);
}
