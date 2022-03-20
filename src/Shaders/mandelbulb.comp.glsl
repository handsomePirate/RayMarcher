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
const float FRACTAL_POWER = 8;

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

vec3 move(vec3 position, vec3 dir)
{
	return position - dir;
}

vec3 scale(vec3 position, float s)
{
	return position / s;
}

float plane(vec3 position, vec3 origin, vec3 normal)
{
	return dot(position - origin, normal);
}

float mandelbulb(vec3 position, out vec4 color)
{
	vec3 w = position;
    float m = dot(w, w);

    vec4 trap = vec4(abs(w), m);
    float dz = 1.0;

    for (int i = 0; i < FRACTAL_ITERATIONS; i++) {
        // trigonometric version

        // dz = 8*z^7*dz
        dz = 8.0 * pow(m, 3.5) * dz + 1.0;

        // z = z^8+z
        float r = length(w);
        float b = FRACTAL_POWER * acos(w.y / r);
        float a = FRACTAL_POWER * atan(w.x, w.z);
        w = position + pow(r, 8.f) * vec3(sin(b) * sin(a), cos(b), sin(b) * cos(a));

        trap = min(trap, vec4(abs(w), m));

        m = dot(w, w);
        if (m > 256.0) break;
    }

    color = vec4(m, trap.yzw);

    // distance estimation (through the Hubbard-Douady potential)
    return 0.25 * log(m) * sqrt(m) / dz;
}

float smoothUnion(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

const float PI = 3.14159265f;

struct Hit
{
	float dist;
	vec4 color;
};

// Estimate distance to the fractal surface.
Hit DE(vec3 position)
{
	vec3 originalPosition = position;
	Hit res;
	position = scale(move(position, vec3(0, 0, -25.f)), 7.f);
	position += vec3(0.f, mix(-1.f, 1.f, (cos(time.seconds) + 1) * .5f), 0.f);
	res.dist = mandelbulb(position, res.color);
	res.dist = smoothUnion(res.dist, plane(originalPosition, vec3(0, 12, 0), vec3(0, -1, 0)), 2.5f);
	return res;
}

// Specify ray march constants.
const float EPSILON = .001f;
const int MAX_ITERATIONS =  256;
const float MAX_DISTANCE = 10000.f;

// Estimate surface normal.
vec3 surfaceNormal(vec3 surfacePoint)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773;
    return normalize(e.xyy * DE(surfacePoint + e.xyy * EPSILON).dist + e.yyx * DE(surfacePoint + e.yyx * EPSILON).dist +
                     e.yxy * DE(surfacePoint + e.yxy * EPSILON).dist + e.xxx * DE(surfacePoint + e.xxx * EPSILON).dist);
}

const int SHADOW_ITERATIONS = 64;
float shadow(vec3 origin, vec3 direction, float k)
{
    float res = 1.f;
    float t = 0.f;
    for (int i = 0; i < SHADOW_ITERATIONS; i++)
	{
        float h = DE(origin + direction * t).dist;
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
	vec3 hitColor;

	// Ray march.
	for (int i = 0; i < MAX_ITERATIONS; i++)
	{
		vec3 position = camera.position.xyz + t * ray;
		
		// Estimate scene distance.
		Hit h = DE(position);
		t += h.dist;

		// Test for surface proximity.
		if (h.dist < EPSILON * t * .25f)
		{
			hit = true;
			steps = i;
			hitColor = h.color.rgb;
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
