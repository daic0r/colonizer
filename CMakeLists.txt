cmake_minimum_required(VERSION 3.21)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

project(Colonizer)

add_executable(${PROJECT_NAME}  
Colonizer.cpp
main.cpp
)

find_library(iceengine iceengine)
find_library(crossguid crossguid)
find_library(uuid uuid)
find_library(profiler profiler)

if (NOT iceengine)
	message(FATAL_ERROR "iceengine not found")
endif()

if (NOT crossguid)
	message(FATAL_ERROR "Crossguid not found")
endif()

if (NOT uuid)
	message(FATAL_ERROR "uuid not found")
endif()

if (NOT profiler)
	message(FATAL_ERROR "profiler not found")
endif()

target_compile_options(${PROJECT_NAME} PRIVATE -O0 -Wno-non-template-friend -Wno-volatile)
target_link_options(${PROJECT_NAME} PRIVATE -Wl,--no-as-needed)
#target_link_options(${PROJECT_NAME} PRIVATE -pg)
target_link_directories(${PROJECT_NAME} PRIVATE /usr/local/lib PRIVATE /usr/lib)
target_include_directories(${PROJECT_NAME} PUBLIC ../iceengine/headers PUBLIC ../iceengine/external/inc PUBLIC ,,/iceengine/external/inc/SDL2 PUBLIC .)
target_link_libraries(${PROJECT_NAME} iceengine crossguid uuid profiler)
