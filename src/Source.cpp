#include "Logger/Logger.hpp"
#include "Filesystem/Filesystem.hpp"

#include <HawkEye/HawkEyeAPI.hpp>
#include <SoftwareCore/DefaultLogger.hpp>

#include <EverViewport/WindowAPI.hpp>

static HawkEye::Pipeline pipeline;

int main(int argc, char* argv[])
{
	Core::Singleton<RMFilesystem>::GetInstance().Init(argv[0]);
	InitLogger("log.txt");

	const std::string pathToBackend = RMFS.GetAbsolutePath("../../src/BackendConfig.yaml");
	const std::string pathToFrontend = RMFS.GetAbsolutePath("../../src/FrontendConfig.yaml");

	HawkEye::HRendererData rendererData = HawkEye::Initialize(pathToBackend.c_str());
	
	int windowWidth = 720;
	int windowHeight = 480;

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
		if (pipeline.Configured())
		{
			pipeline.Resize(width, height);
		}
	};
	EverViewport::Window window(64, 64, windowWidth, windowHeight, "Ray Marcher", windowCallbacks);

	pipeline.Configure(rendererData, pathToFrontend.c_str(), windowWidth, windowHeight,
		window.GetWindowHandle(), window.GetProgramConnection());

	while (!window.ShouldClose())
	{
		window.PollMessages();
		pipeline.DrawFrame();
	}

	pipeline.Shutdown();
	HawkEye::Shutdown();

	return 0;
}