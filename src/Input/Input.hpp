#pragma once
#include "../Camera/Camera.hpp"

#include <HawkEye/HawkEyeAPI.hpp>
#include <EverViewport/WindowAPI.hpp>

void UpdateCamera(HawkEye::Pipeline& pipeline, Camera& camera);
void HandleInput(HawkEye::Pipeline& pipeline, EverViewport::Window& window, Camera& camera, float timeDelta);
