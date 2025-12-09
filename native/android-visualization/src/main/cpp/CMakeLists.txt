cmake_minimum_required(VERSION 3.18.1)
project(visualizationcore)

# 预留 native/core 接入；当前仅构建占位 JNI。
add_library(visualizationcore SHARED visualization_jni.cpp)

target_include_directories(visualizationcore
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/../../../core/include
)

find_library(log-lib log)

target_link_libraries(visualizationcore ${log-lib})
