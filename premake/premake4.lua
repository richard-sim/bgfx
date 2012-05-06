--
-- Copyright 2010-2011 Branimir Karadzic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

solution "bgfx"
	configurations {
		"Debug",
		"Release",
	}

	platforms {
		"x32",
		"x64",
		"Xbox360",
	}

	language "C++"

newoption {
	trigger = "gcc",
	value = "GCC",
	description = "Choose GCC flavor",
	allowed = {
		{ "mingw", "MinGW" },
		{ "nacl", "Google Native Client" },
	}
}

-- Avoid error when invoking premake4 --help.
if (_ACTION == nil) then return end

ROOT_DIR = (path.getabsolute("..") .. "/")
BUILD_DIR = (ROOT_DIR .. ".build/")
THIRD_PARTY_DIR = (ROOT_DIR .. "3rdparty/")

local XEDK = os.getenv("XEDK")
if not XEDK then XEDK = "<you must install XBOX SDK>" end

location (BUILD_DIR .. "projects/" .. _ACTION)

if _ACTION == "gmake" then

	flags {
		"ExtraWarnings",
	}

	if "linux" ~= os.get() and nil == _OPTIONS["gcc"] then
		print("GCC flavor must be specified!")
		os.exit(1)
	end

	if "mingw" == _OPTIONS["gcc"] then
		premake.gcc.cc = "$(MINGW)/bin/mingw32-gcc"
		premake.gcc.cxx = "$(MINGW)/bin/mingw32-g++"
		premake.gcc.ar = "$(MINGW)/bin/ar"
	end

	if "nacl" == _OPTIONS["gcc"] then

		if not os.getenv("NACL") then 
			print("Set NACL enviroment variables.")
		end

		premake.gcc.cc = "$(NACL)/bin/x86_64-nacl-gcc"
		premake.gcc.cxx = "$(NACL)/bin/x86_64-nacl-g++"
		premake.gcc.ar = "$(NACL)/bin/x86_64-nacl-ar"
		location (BUILD_DIR .. "projects/" .. _ACTION .. "-nacl")
	end
end

flags {
	"StaticRuntime",
	"NoMinimalRebuild",
	"NoPCH",
	"NativeWChar",
	"NoRTTI",
	"NoExceptions",
	"NoEditAndContinue",
	"Symbols",
}

includedirs {
	ROOT_DIR .. "../bx/include",
}

configuration "Debug"
	targetsuffix "Debug"

configuration "Release"
	flags {
		"OptimizeSpeed",
	}
	targetsuffix "Release"

configuration { "vs*" }
	defines {
		"_HAS_EXCEPTIONS=0",
		"_HAS_ITERATOR_DEBUGGING=0",
		"_SCL_SECURE=0",
		"_CRT_SECURE_NO_WARNINGS",
		"_CRT_SECURE_NO_DEPRECATE",
		"__STDC_LIMIT_MACROS",
		"__STDC_FORMAT_MACROS",
		"__STDC_CONSTANT_MACROS",
	}

configuration { "x32", "vs*" }
	defines { "WIN32" }
	targetdir (BUILD_DIR .. "win32_" .. _ACTION .. "/bin")
	objdir (BUILD_DIR .. "win32_" .. _ACTION .. "/obj")
	includedirs { THIRD_PARTY_DIR .. "compiler/msvc" }

configuration { "x64", "vs*" }
	defines { "WIN32" }
	targetdir (BUILD_DIR .. "win64_" .. _ACTION .. "/bin")
	objdir (BUILD_DIR .. "win64_" .. _ACTION .. "/obj")
	includedirs { THIRD_PARTY_DIR .. "compiler/msvc" }

configuration { "x32", "mingw" }
	defines { "WIN32" }
	targetdir (BUILD_DIR .. "win32_mingw" .. "/bin")
	objdir (BUILD_DIR .. "win32_mingw" .. "/obj")
	includedirs { THIRD_PARTY_DIR .. "compiler/mingw" }

configuration { "x64", "mingw" }
	defines { "WIN32" }
	targetdir (BUILD_DIR .. "win64_mingw" .. "/bin")
	objdir (BUILD_DIR .. "win64_mingw" .. "/obj")
	includedirs { THIRD_PARTY_DIR .. "compiler/mingw" }

configuration { "nacl" }
	defines { "_BSD_SOURCE=1", "_POSIX_C_SOURCE=199506", "_XOPEN_SOURCE=600" }
	links {
		"ppapi",
		"ppapi_gles2",
	}
	includedirs { THIRD_PARTY_DIR .. "compiler/nacl" }
	buildoptions {
		"-std=c++0x",
		"-U__STRICT_ANSI__",
		"-pthread",
		"-fno-stack-protector",
		"-fdiagnostics-show-option",
		"-Wunused-value",
		"-fdata-sections",
		"-ffunction-sections",
		"-mfpmath=sse", -- force SSE to get 32-bit and 64-bit builds deterministic.
		"-msse2",
--		"-fmerge-all-constants",
	}
	linkoptions {
		"-Wl,--gc-sections",
	}

configuration { "x32", "nacl" }
	targetdir (BUILD_DIR .. "nacl-x86" .. "/bin")
	objdir (BUILD_DIR .. "nacl-x86" .. "/obj")
	libdirs { THIRD_PARTY_DIR .. "lib/nacl-x86" }
	linkoptions {
		"-melf32_nacl",
	}

configuration { "x64", "nacl" }
	targetdir (BUILD_DIR .. "nacl-x64" .. "/bin")
	objdir (BUILD_DIR .. "nacl-x64" .. "/obj")
	libdirs { THIRD_PARTY_DIR .. "lib/nacl-x64" }
	linkoptions {
		"-melf64_nacl",
	}

configuration { "x32", "linux" }
	targetdir (BUILD_DIR .. "linux32" .. "/bin")
	objdir (BUILD_DIR .. "linux32" .. "/obj")

configuration { "x64", "linux" }
	targetdir (BUILD_DIR .. "linux64" .. "/bin")
	objdir (BUILD_DIR .. "linux64" .. "/obj")

configuration { "Xbox360" }
	defines { "_XBOX", "NOMINMAX" }
	targetdir (BUILD_DIR .. "xbox360" .. "/bin")
	objdir (BUILD_DIR .. "xbox360" .. "/obj")
	includedirs { THIRD_PARTY_DIR .. "compiler/msvc" }

configuration {} -- reset configuration

project "bgfx"
	uuid "f4c51860-ebf4-11e0-9572-0800200c9a66"
	kind "StaticLib"

	includedirs {
		"../include",
		ROOT_DIR .. "../bx/include",
		THIRD_PARTY_DIR .. "glew-1.5.4/include",
	}

	files {
		"../include/**.h",
		"../src/**.cpp",
		"../src/**.h",
	}

project "shaderc"
	uuid "f3cd2e90-52a4-11e1-b86c-0800200c9a66"
	kind "ConsoleApp"

	local GLSL_OPTIMIZER = (THIRD_PARTY_DIR .. "glsl-optimizer/")

	configuration { "vs*" }
		includedirs { GLSL_OPTIMIZER .. "src/glsl/msvc" }

	configuration {}

	includedirs {
		ROOT_DIR .. "../bx/include",

		THIRD_PARTY_DIR .. "fcpp",

		GLSL_OPTIMIZER .. "include",
		GLSL_OPTIMIZER .. "include/c99",
		GLSL_OPTIMIZER .. "src/mesa",
		GLSL_OPTIMIZER .. "src/mapi",
		GLSL_OPTIMIZER .. "src/glsl",
	}

	files {
		ROOT_DIR .. "tools/shaderc.cpp",
		THIRD_PARTY_DIR .. "fcpp/**.h",
		THIRD_PARTY_DIR .. "fcpp/cpp1.c",
		THIRD_PARTY_DIR .. "fcpp/cpp2.c",
		THIRD_PARTY_DIR .. "fcpp/cpp3.c",
		THIRD_PARTY_DIR .. "fcpp/cpp4.c",
		THIRD_PARTY_DIR .. "fcpp/cpp5.c",
		THIRD_PARTY_DIR .. "fcpp/cpp6.c",
		THIRD_PARTY_DIR .. "fcpp/cpp6.c",

		GLSL_OPTIMIZER .. "src/mesa/**.c",
		GLSL_OPTIMIZER .. "src/glsl/**.cpp",
		GLSL_OPTIMIZER .. "src/mesa/**.h",
		GLSL_OPTIMIZER .. "src/glsl/**.c",
		GLSL_OPTIMIZER .. "src/glsl/**.cpp",
		GLSL_OPTIMIZER .. "src/glsl/**.h",
	}

	excludes {
		GLSL_OPTIMIZER .. "src/glsl/glcpp/glcpp.c",
		GLSL_OPTIMIZER .. "src/glsl/glcpp/tests/**",
		GLSL_OPTIMIZER .. "src/glsl/main.cpp",
		GLSL_OPTIMIZER .. "src/glsl/builtin_stubs.cpp",
	}

	links {
		"d3dx9",
	}

project "ddsdump"
	uuid "838801ee-7bc3-11e1-9f19-eae7d36e7d26"
	kind "ConsoleApp"

	includedirs {
		ROOT_DIR .. "../bx/include",
		ROOT_DIR .. "include",
		ROOT_DIR .. "src",
	}

	files {
		ROOT_DIR .. "src/dds.*",
		ROOT_DIR .. "tools/ddsdump.cpp",
	}

	links {
		"bgfx",
	}

project "makedisttex"
	uuid "b0561b30-91bb-11e1-b06e-023ad46e7d26"
	kind "ConsoleApp"

	includedirs {
		ROOT_DIR .. "../bx/include",
		THIRD_PARTY_DIR .. "edtaa3",
		THIRD_PARTY_DIR .. "stb_image",
	}

	files {
		THIRD_PARTY_DIR .. "edtaa3/**",
		ROOT_DIR .. "tools/makedisttex.cpp",
	}

project "helloworld"
	uuid "ff2c8450-ebf4-11e0-9572-0800200c9a66"
	kind "WindowedApp"

	includedirs {
		ROOT_DIR .. "include",
	}

	files {
		ROOT_DIR .. "examples/common/**.cpp",
		ROOT_DIR .. "examples/common/**.h",
		ROOT_DIR .. "examples/helloworld/**.cpp",
		ROOT_DIR .. "examples/helloworld/**.h",
	}

	links {
		"bgfx",
	}

	configuration { "nacl" }
		targetextension ".nexe"

	configuration { "nacl", "Release" }
		postbuildcommands {
			"@echo Stripping symbols.",
			"@$(NACL)/bin/x86_64-nacl-strip -s \"$(TARGET)\""
		}
