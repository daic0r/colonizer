cmake_minimum_required(VERSION 3.21)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

#if (WIN32)
#	if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
#		set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDebug")
#	elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
#		set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")
#	endif()
#endif()

project(Colonizer)

add_executable(${PROJECT_NAME}  
Colonizer.cpp
main.cpp
)

#[[
set(CMAKE_VERBOSE_MAKEFILE ON)
]]

if (UNIX)
   if (CMAKE_BUILD_TYPE STREQUAL "Debug")
      set(ICEENGINE_LIB_NAME "iceengined")
   else()
      set(ICEENGINE_LIB_NAME "iceengine")
   endif()
   message(STATUS "ICEENGINE_LIB_NAME = ${ICEENGINE_LIB_NAME}")
   find_library(iceengine ${ICEENGINE_LIB_NAME})
elseif (WIN32)
	find_library(iceengine $<$<CONFIG:Debug>:iceengined> $<$<CONFIG:Release>:iceengine> HINTS "C:/Program Files (x86)/libiceengine/lib")
endif()

find_library(crossguid crossguid)
find_library(uuid uuid)
find_library(profiler profiler)

if (NOT iceengine)
	message(FATAL_ERROR "iceengine not found")
endif()

find_package(SDL2 REQUIRED)
find_package(nlohmann_json REQUIRED)
find_package(glm REQUIRED)
	
if (UNIX)
	find_library(uuid uuid)
	find_library(profiler profiler)

	if (NOT uuid)
		message(FATAL_ERROR "uuid not found")
	endif()

if (NOT profiler)
	message(FATAL_ERROR "profiler not found")
endif()
#elseif (WIN32)
#	find_library(SDL2_main NAMES SDL2main HINTS ../iceengine/external/windows/lib NO_DEFAULT_PATH)
#	find_library(SDL2_maindbg NAMES SDL2maind HINTS ../iceengine/external/windows/lib NO_DEFAULT_PATH)
endif()



if (UNIX)
	target_link_options(${PROJECT_NAME} PRIVATE -Wl,--no-as-needed)
	target_compile_options(${PROJECT_NAME} PRIVATE -O0 -Wno-non-template-friend -Wno-volatile)
   target_include_directories(${PROJECT_NAME} PRIVATE /usr/local/include/iceengine PRIVATE .)
	target_link_directories(${PROJECT_NAME} PRIVATE /usr/local/lib PRIVATE /usr/lib)
	target_link_libraries(${PROJECT_NAME} ${iceengine} ${crossguid} ${uuid} ${profiler})
elseif (WIN32)
	target_include_directories(${PROJECT_NAME} PUBLIC "C:/Program Files (x86)/libiceengine/include/headers" PUBLIC .) # PUBLIC ../iceengine/external/inc PUBLIC .)
	target_link_libraries(${PROJECT_NAME} ${iceengine} nlohmann_json::nlohmann_json glm::glm SDL2::SDL2) # $<$<CONFIG:Debug>:${crossguiddbg}> $<$<CONFIG:Release>:${crossguid}>)
endif()


#set_property(TARGET ${PROJECT_NAME} PROPERTY 
#   MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
