workspace "RayMarcher"
	architecture "x64"
	configurations { "Debug", "Release" }
	startproject "RayMarcher"
	location ""
	
	flags
	{
		"MultiProcessorCompile"
	}
	
include "../dependencies.lua"
	
include "../proj/RayMarcher"