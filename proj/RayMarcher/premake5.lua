RayMarcherInclude = path.getabsolute("../../include", os.getcwd())

project "RayMarcher"
	kind "StaticLib"
	staticruntime "off"
	language "C++"
	cppdialect "C++17"
	location ""
	targetdir "../../build/%{cfg.buildcfg}"
	objdir "obj/%{cfg.buildcfg}"
	files { "../../src/**.hpp", "../../src/**.cpp", "../../src/**.glsl", "../../include/**.hpp" }

	flags {
		"MultiProcessorCompile"
	}

	includedirs {
		HawkEyeInclude
	}

	links {
		"HawkEye"
	}
	
	filter "configurations:Debug"
		defines { "DEBUG" }
		symbols "On"

	filter "configurations:Release"
		defines { "RELEASE" }
		optimize "On"

	filter {}
