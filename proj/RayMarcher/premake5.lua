project "RayMarcher"
	kind "ConsoleApp"
	staticruntime "off"
	language "C++"
	cppdialect "C++17"
	location ""
	targetdir "../../build/%{cfg.buildcfg}"
	objdir "obj/%{cfg.buildcfg}"
	files { 
		"../../src/**.hpp",
		"../../src/**.cpp",
		"../../src/**.glsl",
		"../../src/**.yaml"
	}

	flags {
		"MultiProcessorCompile"
	}

	includedirs {
		HawkEyeInclude,
		SoftwareCoreInclude,
		EverViewportInclude
	}

	links {
		"HawkEye",
		"SoftwareCore",
		"EverViewport"
	}
	
	filter "configurations:Debug"
		defines { "DEBUG" }
		symbols "On"

	filter "configurations:Release"
		defines { "RELEASE" }
		optimize "On"

	filter {}
