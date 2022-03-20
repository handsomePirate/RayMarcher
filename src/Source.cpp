#include "Logger/Logger.hpp"
#include "Filesystem/Filesystem.hpp"
#include "Input/Input.hpp"
#include "Camera/Camera.hpp"

#include <HawkEye/HawkEyeAPI.hpp>
#include <SoftwareCore/DefaultLogger.hpp>
#include <SoftwareCore/Input.hpp>

#include <EverViewport/WindowAPI.hpp>

#include <thread>

static HawkEye::Pipeline pipeline;

static int windowWidth = 720;
static int windowHeight = 480;

static Camera camera(windowWidth / float(windowHeight));

int main(int argc, char* argv[])
{
	Core::Singleton<RMFilesystem>::GetInstance().Init(argv[0]);
	InitLogger("log.txt");

	const std::string pathToBackend = RMFS.GetAbsolutePath("../../src/BackendConfig.yaml");
	const std::string pathToFrontend = RMFS.GetAbsolutePath("../../src/FrontendConfig.yaml");

	HawkEye::HRendererData rendererData = HawkEye::Initialize(pathToBackend.c_str());

	EverViewport::WindowCallbacks windowCallbacks{};
	windowCallbacks.renderFunction = []()
	{
		if (pipeline.Configured())
		{
			pipeline.DrawFrame();
		}
	};
	windowCallbacks.resizeFunction = [](int width, int height)
	{
		windowWidth = width;
		windowHeight = height;
		camera.SetAspect(windowWidth / float(windowHeight));
		camera.UpdateViewProjectionMatrices();
		UpdateCamera(pipeline, camera);
		if (pipeline.Configured())
		{
			pipeline.Resize(width, height);
		}
	};
	EverViewport::Window window(64, 64, windowWidth, windowHeight, "Ray Marcher", windowCallbacks);

	pipeline.Configure(rendererData, pathToFrontend.c_str(), windowWidth, windowHeight,
		window.GetWindowHandle(), window.GetProgramConnection());

	camera.SetPosition(0, 0, -40);

	const float targetTimeDelta = 1 / 60.f * 1000.f;
	float timeDelta = 1.f;
	auto before = std::chrono::high_resolution_clock::now();
	while (!window.ShouldClose())
	{
		auto now = std::chrono::high_resolution_clock::now();
		timeDelta = std::chrono::duration<float, std::milli>(now - before).count();
		before = std::chrono::high_resolution_clock::now();

		// Stabilizing frame rate.
		if (timeDelta < targetTimeDelta)
		{
			std::this_thread::sleep_for(std::chrono::milliseconds(int(targetTimeDelta - timeDelta)));
		}

		HandleInput(pipeline, window, camera, timeDelta);

		window.PollMessages();
		pipeline.DrawFrame();
	}

	pipeline.Shutdown();
	HawkEye::Shutdown();

	return 0;
}