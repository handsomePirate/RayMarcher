#include "Input.hpp"

#include <SoftwareCore/Input.hpp>
#include <SoftwareCore/DefaultLogger.hpp>

void UpdateCamera(HawkEye::Pipeline& pipeline, Camera& camera)
{
	camera.UpdateViewProjectionMatrices();
	if (pipeline.Configured())
	{
		Eigen::Matrix4f viewProjectionMatrix = camera.GetProjectionMatrix() * camera.GetViewMatrix();

		Eigen::Matrix4f inverseViewProjectionMatrix = viewProjectionMatrix.inverse();

		Eigen::Vector3f cameraPosition = camera.GetPosition();
		Eigen::Vector4f eye = Eigen::Vector4f(cameraPosition.x(), cameraPosition.y(), cameraPosition.z(), 1.f);

		Eigen::Vector4f ray00 = inverseViewProjectionMatrix * Eigen::Vector4f(-1, -1, 0, 1);
		ray00 /= ray00.w();
		ray00 -= eye;

		Eigen::Vector4f ray10 = inverseViewProjectionMatrix * Eigen::Vector4f(1, -1, 0, 1);
		ray10 /= ray10.w();
		ray10 -= eye;

		Eigen::Vector4f ray01 = inverseViewProjectionMatrix * Eigen::Vector4f(-1, 1, 0, 1);
		ray01 /= ray01.w();
		ray01 -= eye;

		struct ShaderCamera
		{
			Eigen::Vector4f position;
			Eigen::Vector4f ray0;
			Eigen::Vector4f horizontal;
			Eigen::Vector4f vertical;
		};

		ShaderCamera shaderCamera = {
			eye, ray00, ray10 - ray00, ray01 - ray00
		};

		pipeline.SetUniform("rayMarch", "camera", shaderCamera);
	}
}

void HandleInput(HawkEye::Pipeline& pipeline, EverViewport::Window& window, Camera& camera, float timeDelta)
{
	static bool lastEsc = false;

	bool nowEsc = CoreInput.IsKeyPressed(Core::Input::Keys::Escape);
	if (nowEsc && !lastEsc)
	{
		window.Close();
	}

	lastEsc = nowEsc;

	static uint16_t lastMouseX = 0;
	static uint16_t lastMouseY = 0;

	bool forward = CoreInput.IsKeyPressed(Core::Input::Keys::W) || CoreInput.IsKeyPressed(Core::Input::Keys::Up);
	bool back = CoreInput.IsKeyPressed(Core::Input::Keys::S) || CoreInput.IsKeyPressed(Core::Input::Keys::Down);
	bool left = CoreInput.IsKeyPressed(Core::Input::Keys::A) || CoreInput.IsKeyPressed(Core::Input::Keys::Left);
	bool right = CoreInput.IsKeyPressed(Core::Input::Keys::D) || CoreInput.IsKeyPressed(Core::Input::Keys::Right);

	bool up = CoreInput.IsKeyPressed(Core::Input::Keys::R);
	bool down = CoreInput.IsKeyPressed(Core::Input::Keys::F);

	bool shift = CoreInput.IsKeyPressed(Core::Input::Keys::Shift);

	if (forward || back || left || right || up || down)
	{
		//const float moveSensitivity = shift ? 120.f : 50.f;
		const float moveSensitivity = .002f;
		const float forwardDelta =
			((forward ? moveSensitivity : -moveSensitivity) +
				(back ? -moveSensitivity : moveSensitivity))
			* timeDelta;
		const float rightDelta =
			((right ? moveSensitivity : -moveSensitivity) +
				(left ? -moveSensitivity : moveSensitivity))
			* timeDelta;
		const float upDelta =
			((up ? -moveSensitivity : moveSensitivity) +
				(down ? moveSensitivity : -moveSensitivity))
			* timeDelta;

		camera.TranslateLocal({ rightDelta, upDelta, forwardDelta });
	}

	uint16_t mouseX = CoreInput.GetMouseX();
	uint16_t mouseY = CoreInput.GetMouseY();
	const bool isMousePressedLeft = CoreInput.IsMouseButtonPressed(Core::Input::MouseButtons::Left);
	const float mouseSensitivity = 0.001f;

	if (isMousePressedLeft)
	{
		const int deltaX = int(lastMouseX) - int(mouseX);
		const int deltaY = int(lastMouseY) - int(mouseY);
		static int maxD = 0;

		const float xMove = mouseSensitivity * deltaX;
		const float yMove = mouseSensitivity * deltaY;

		camera.Rotate({ 0, 1, 0 }, -xMove);
		camera.RotateLocal({ 1, 0, 0 }, yMove);
	}

	UpdateCamera(pipeline, camera);

	lastMouseX = mouseX;
	lastMouseY = mouseY;
}
