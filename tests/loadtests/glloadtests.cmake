
function( create_gl_target target sources KTX_GL_CONTEXT_PROFILE KTX_GL_CONTEXT_MAJOR_VERSION KTX_GL_CONTEXT_MINOR_VERSION )

    add_executable( ${target}
        ${EXE_FLAG}
        $<TARGET_OBJECTS:appfwSDL>
        $<TARGET_OBJECTS:GLAppSDL>
        $<TARGET_OBJECTS:objUtil>
        ${sources}
        ${LOAD_TEST_COMMON_RESOURCE_FILES}
    )

    target_include_directories(
        ${target}
    PRIVATE
        $<TARGET_PROPERTY:appfwSDL,INTERFACE_INCLUDE_DIRECTORIES>
        $<TARGET_PROPERTY:GLAppSDL,INTERFACE_INCLUDE_DIRECTORIES>
        $<TARGET_PROPERTY:ktx,INTERFACE_INCLUDE_DIRECTORIES>
        $<TARGET_PROPERTY:objUtil,INTERFACE_INCLUDE_DIRECTORIES>
    )

    if(OPENGL_FOUND)
        target_include_directories(
            ${target}
        PRIVATE
            ${OPENGL_INCLUDE_DIR}
        )
    endif()

    target_link_libraries(
        ${target}
        ktx
        ${KTX_ZLIB_LIBRARIES}
    )

    if(OPENGL_FOUND AND NOT EMSCRIPTEN)
        target_link_libraries(
            ${target}
            ${OPENGL_LIBRARIES}
        )
    endif()

    if(SDL2_FOUND)
        target_link_libraries(
            ${target}
            ${SDL2_LIBRARIES}
        )
    endif()

    if(APPLE)
        if(IOS)
            set( INFO_PLIST "${PROJECT_SOURCE_DIR}/tests/loadtests/glloadtests/resources/ios/Info.plist" )
            set( KTX_RESOURCES
                ${PROJECT_SOURCE_DIR}/icons/ios/CommonIcons.xcassets
                glloadtests/resources/ios/LaunchImages.xcassets
                glloadtests/resources/ios/LaunchScreen.storyboard
            )
            target_sources( ${target} PRIVATE ${KTX_RESOURCES} )
            target_link_libraries(
                ${target}
                ${AudioToolbox_LIBRARY}
                ${AVFoundation_LIBRARY}
                ${CoreAudio_LIBRARY}
                ${CoreBluetooth_LIBRARY}
                ${CoreGraphics_LIBRARY}
                ${CoreMotion_LIBRARY}
                ${Foundation_LIBRARY}
                ${GameController_LIBRARY}
                ${Metal_LIBRARY}
                ${OpenGLES_LIBRARY}
                ${QuartzCore_LIBRARY}
                ${UIKit_LIBRARY}
            )
        else()
            set( KTX_RESOURCES ${KTX_ICON} )
            set( INFO_PLIST "${PROJECT_SOURCE_DIR}/tests/loadtests/glloadtests/resources/mac/Info.plist" )
        endif()
    elseif(EMSCRIPTEN)
        set_target_properties(
            ${target}
        PROPERTIES
            COMPILE_FLAGS "-Wpedantic -s DISABLE_EXCEPTION_CATCHING=0 -s USE_SDL=2 -s USE_WEBGL2=1 -O0 -g"
            # LINK_FLAGS "--source-map-base ./ --preload-file testimages --exclude-file testimages/genref --exclude-file testimages/*.pgm --exclude-file testimages/*.ppm --exclude-file testimages/*.pam --exclude-file testimages/*.pspimage -s ALLOW_MEMORY_GROWTH=1 -s DISABLE_EXCEPTION_CATCHING=0 -s USE_SDL=2 -s USE_WEBGL2=1 -g4"
            LINK_FLAGS "-s ALLOW_MEMORY_GROWTH=1 -s DISABLE_EXCEPTION_CATCHING=0 -s USE_SDL=2 -s USE_WEBGL2=1 -g"
        )
    elseif(WIN32)
        target_sources(
            ${target}
        PRIVATE
            glloadtests/resources/win/glloadtests.rc
            glloadtests/resources/win/resource.h
        )
        target_link_libraries(
            ${target}
            "${CMAKE_SOURCE_DIR}/other_lib/win/Release-x64/glew32.lib"
        )
        ensure_runtime_dependencies_windows(${target})
    endif()

    target_link_libraries( ${target} ${LOAD_TEST_COMMON_LIBS} )

    target_compile_definitions(
        ${target}
    PRIVATE
        $<TARGET_PROPERTY:ktx,INTERFACE_COMPILE_DEFINITIONS>
        GL_CONTEXT_PROFILE=${KTX_GL_CONTEXT_PROFILE}
        GL_CONTEXT_MAJOR_VERSION=${KTX_GL_CONTEXT_MAJOR_VERSION}
        GL_CONTEXT_MINOR_VERSION=${KTX_GL_CONTEXT_MINOR_VERSION}
    )

    if(APPLE)
        set(PRODUCT_NAME "${target}")
        set(EXECUTABLE_NAME ${PRODUCT_NAME})
        set(PRODUCT_BUNDLE_IDENTIFIER "org.khronos.ktx.${PRODUCT_NAME}")
        configure_file( ${INFO_PLIST} ${target}/Info.plist )
        set_target_properties( ${target} PROPERTIES
            MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_BINARY_DIR}/${target}/Info.plist"
            MACOSX_BUNDLE_ICON_FILE "ktx_app.icns"
            # Because libassimp is built with bitcode disabled. It's not important unless
            # submitting to the App Store and currently bitcode is optional.
            XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
            XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH "YES"
            XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "ktx_app"
            XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2" # iPhone and iPad
        )
        unset(PRODUCT_NAME)
        unset(EXECUTABLE_NAME)
        unset(PRODUCT_BUNDLE_IDENTIFIER)
        if(KTX_RESOURCES)
            set_target_properties( ${target} PROPERTIES RESOURCE "${KTX_RESOURCES}" )
        endif()

        if(NOT IOS)
            add_custom_command( TARGET ${target} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ktx> "$<TARGET_BUNDLE_CONTENT_DIR:vkloadtests>/Frameworks/$<TARGET_FILE_NAME:ktx>"
                COMMAND ${CMAKE_COMMAND} -E copy "${PROJECT_SOURCE_DIR}/other_lib/mac/$<CONFIG>/libSDL2.dylib" "$<TARGET_BUNDLE_CONTENT_DIR:vkloadtests>/Frameworks/libSDL2.dylib"
                COMMENT "Copy libraries/frameworks to build destination"
            )
        endif()

        ## TODO: fix install. it is broken for some reason.
        # install(TARGETS ${target}
        #     BUNDLE DESTINATION .
        #     RESOURCE DESTINATION "Resources"
        # )

    elseif(EMSCRIPTEN)
        set_target_properties(${target} PROPERTIES SUFFIX ".html")
    endif()
endfunction( create_gl_target target )


set( ES1_SOURCES
    glloadtests/gles1/ES1LoadTests.cpp
    glloadtests/gles1/DrawTexture.cpp
    glloadtests/gles1/DrawTexture.h
    glloadtests/gles1/TexturedCube.cpp
    glloadtests/gles1/TexturedCube.h
)

set( GL3_SOURCES
    glloadtests/shader-based/BasisuTest.cpp
    glloadtests/shader-based/BasisuTest.h
    glloadtests/shader-based/DrawTexture.cpp
    glloadtests/shader-based/DrawTexture.h
    glloadtests/shader-based/GL3LoadTests.cpp
    glloadtests/shader-based/GL3LoadTestSample.cpp
    glloadtests/shader-based/GL3LoadTestSample.h
    glloadtests/shader-based/mygl.h
    glloadtests/shader-based/shaders.cpp
    glloadtests/shader-based/TextureArray.cpp
    glloadtests/shader-based/TextureArray.h
    glloadtests/shader-based/TextureCubemap.cpp
    glloadtests/shader-based/TextureCubemap.h
    glloadtests/shader-based/TexturedCube.cpp
    glloadtests/shader-based/TexturedCube.h
    glloadtests/utils/GLMeshLoader.hpp
    glloadtests/utils/GLTextureTranscoder.hpp
)

if(IOS)
    # OpenGL ES 1.0
    create_gl_target( es1loadtests "${ES1_SOURCES}" SDL_GL_CONTEXT_PROFILE_ES 1 0 )
endif()

if(IOS OR EMSCRIPTEN)
    # OpenGL ES 3.0
    create_gl_target( es3loadtests "${GL3_SOURCES}" SDL_GL_CONTEXT_PROFILE_ES 3 0 )
endif()

if( (APPLE AND NOT IOS) OR LINUX OR WIN32 )
    # OpenGL 3.3
    create_gl_target( gl3loadtests "${GL3_SOURCES}" SDL_GL_CONTEXT_PROFILE_CORE 3 3 )
endif()
