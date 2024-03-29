#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(local_size_x = 16, local_size_y = 16) in;

layout(binding = 0, rgba8) uniform writeonly image2D resultImage;

layout(set = 1, binding = 0) uniform Camera
{
	vec4 position;
	vec4 ray0;
	vec4 horizontal;
	vec4 vertical;
} camera;


uvec2 pictureSize = (gl_NumWorkGroups * gl_WorkGroupSize).xy;
uvec2 pixelCoords = gl_GlobalInvocationID.xy;

vec3 pixelRay()
{
	ivec2 pix = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = imageSize(resultImage);
	
	if (pix.x >= size.x || pix.y >= size.y)
		return vec3(0);

	vec2 pos = vec2(pix) / vec2(size.x - 1, size.y - 1);

	return normalize(camera.ray0.xyz + pos.x * camera.horizontal.xyz + pos.y * camera.vertical.xyz);
}

void outputColor(vec3 color)
{
	imageStore(resultImage, ivec2(pixelCoords), vec4(color, 1));
}

float distanceFromSphere(vec3 point, vec3 origin, float radius)
{
	return length(point - origin) - radius;
}

float DE(vec3 position)
{
	return distanceFromSphere(position, vec3(0), 10.f);
}

const float EPSILON = .001f;
const int MAX_ITERATIONS =  10;
const float MAX_DISTANCE = 1000.f;

void main()
{
	vec3 ray = pixelRay();

	if (ray == vec3(0))
	{
		return;
	}

	float t = 0.f;
	bool hit = false;
	int steps = MAX_ITERATIONS;

	for (int i = 0; i < MAX_ITERATIONS; ++i)
	{
		float sdf = DE(camera.position.xyz + t * ray);

		if (sdf < EPSILON)
		{
			hit = true;
			steps = i;
			break;
		}

		t += sdf;

		if (t > MAX_DISTANCE)
		{
			break;
		}
	}

	vec3 hitPosition = camera.position.xyz + t * ray;
	vec3 xDir = vec3(EPSILON, 0, 0);
	vec3 yDir = vec3(0, EPSILON, 0);
	vec3 zDir = vec3(0, 0, EPSILON);

	vec3 normal = normalize(
		vec3(DE(hitPosition+xDir)-DE(hitPosition-xDir),
			DE(hitPosition+yDir)-DE(hitPosition-yDir),
			DE(hitPosition+zDir)-DE(hitPosition-zDir)));

	outputColor(normal);
}
