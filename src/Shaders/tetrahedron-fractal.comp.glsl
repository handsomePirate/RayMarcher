#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(local_size_x = 16, local_size_y = 16) in;

layout(binding = 0, rgba8) uniform writeonly image2D resultImage;

// Get camera parameters.
layout(set = 1, binding = 0) uniform Camera
{
	vec4 position;
	vec4 ray0;
	vec4 horizontal;
	vec4 vertical;
} camera;

layout(set = 1, binding = 1) uniform Time
{
	float seconds;
} time;

// Retrieve pixel coordinates.
ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);

// Determine the ray to be cast from the pixel to the scene.
vec3 pixelRay()
{
	ivec2 size = imageSize(resultImage);
	
	if (pixelCoords.x >= size.x || pixelCoords.y >= size.y)
		return vec3(0);

	vec2 pos = vec2(pixelCoords) / vec2(size.x - 1, size.y - 1);

	return normalize(camera.ray0.xyz + pos.x * camera.horizontal.xyz + pos.y * camera.vertical.xyz);
}

// Output the RGB to the appropriate pixel spot.
void outputColor(vec3 color)
{
	imageStore(resultImage, pixelCoords, vec4(color, 1));
}

// Specify fractal constants.
const int FRACTAL_ITERATIONS = 32;
const float FRACTAL_SCALE = 2.f;
const vec3 FRACTAL_OFFSET = vec3(10.f);

vec3 rotateX(vec3 p, float rad)
{
    return vec3(p.x, p.y * cos(rad) - p.z * sin(rad), p.y * sin(rad) + p.z * cos(rad));
}

vec3 rotateY(vec3 p, float rad)
{
    return vec3(p.x * cos(rad) + p.z * sin(rad), p.y, -p.x * sin(rad) + p.z * cos(rad));
}

vec3 rotateZ(vec3 p, float rad)
{
    return vec3(p.x * cos(rad) - p.y * sin(rad), p.x * sin(rad) + p.y * cos(rad), p.z);
}

float plane(vec3 position, vec3 origin, vec3 normal)
{
	return dot(position - origin, normal);
}

float recursiveTetrahedron(vec3 position)
{
	vec4 z = vec4(position, 1.0);
    for (int i = 0; i < FRACTAL_ITERATIONS; i++)
	{
        if (z.x + z.y < 0.f) z.xy = -z.yx;
        if (z.x + z.z < 0.f) z.xz = -z.zx;
        if (z.y + z.z < 0.f) z.zy = -z.yz;
        z *= FRACTAL_SCALE;
        z.xyz -= FRACTAL_OFFSET * (FRACTAL_SCALE - 1.f);
    }
    return (length(z.xyz) - 1.5f) / z.w;
}

float smoothUnion(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

const float PI = 3.14159265f;

// Estimate distance to the fractal surface.
float DE(vec3 position)
{
	vec3 originalPosition = position;
	position = rotateY(rotateZ(position, time.seconds * .25f), time.seconds * .125f);
    return smoothUnion(recursiveTetrahedron(position), plane(originalPosition, vec3(0, 12, 0), vec3(0, -1, 0)), 2.5f);
}

// Specify ray march constants.
const float EPSILON = .001f;
const int MAX_ITERATIONS =  256;
const float MAX_DISTANCE = 10000.f;

// Estimate surface normal.
vec3 surfaceNormal(vec3 surfacePoint)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773;
    return normalize(e.xyy * DE(surfacePoint + e.xyy * EPSILON) + e.yyx * DE(surfacePoint + e.yyx * EPSILON) +
                     e.yxy * DE(surfacePoint + e.yxy * EPSILON) + e.xxx * DE(surfacePoint + e.xxx * EPSILON));
}

const int SHADOW_ITERATIONS = 64;
float shadow(vec3 origin, vec3 direction, float k)
{
    float res = 1.f;
    float t = 0.f;
    for (int i = 0; i < SHADOW_ITERATIONS; i++)
	{
        float h = DE(origin + direction * t);
        res = min(res, k * h / t);
        if (res < .001f) break;
        t += clamp(h, .01f, .2f);
    }
    return clamp(res, .3f, 1.f);
}

void main()
{
	// Determine ray to be cast into the scene.
	vec3 ray = pixelRay();

	// Terminate the pixel is not in the image.
	if (ray == vec3(0))
	{
		return;
	}

	float t = 0.f;
	int steps = MAX_ITERATIONS;
	bool hit = false;

	// Ray march.
	for (int i = 0; i < MAX_ITERATIONS; i++)
	{
		vec3 position = camera.position.xyz + t * ray;
		
		// Estimate scene distance.
		float sdf = DE(position);
		t += sdf;

		// Test for surface proximity.
		if (sdf < EPSILON * t)
		{
			hit = true;
			steps = i;
			break;
		}

		// Test for escaped ray.
		if (t > MAX_DISTANCE)
		{
			break;
		}
	}

	// Determine the surface position that has been hit by the ray.
	vec3 hitPosition = camera.position.xyz + t * ray;
	// Determine the normal of the surface point.
	vec3 hitNormal = surfaceNormal(hitPosition);

	vec3 lightPosition = vec3(10.f, 10.f, 5.f);
	float shadowMult = 1.f;//shadow(hitPosition + hitNormal * EPSILON, camera.position.xyz, 20.f);

	// Output color.
	vec3 resultColor = shadowMult * (1.f - vec3(steps / float(MAX_ITERATIONS)));
	outputColor(resultColor);
}
