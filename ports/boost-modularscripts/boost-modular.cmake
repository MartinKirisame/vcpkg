
function(boost_modular)
    cmake_parse_arguments(_bm "" "SOURCE_PATH" "OPTIONS;OPTIONS_RELEASE;OPTIONS_DEBUG;DEPENDENCIES" ${ARGN})

    if(NOT DEFINED _bm_SOURCE_PATH)
        message(FATAL_ERROR "SOURCE_PATH is a required argument to boost_modular.")
    endif()

    set(BOOST_BUILDTREE "${CURRENT_BUILDTREES_DIR}/../boost/src/boost_1_65_1")

    if(EXISTS "${_bm_SOURCE_PATH}/build" AND NOT PORT STREQUAL "boost-metaparse")
        set(_bm_DIR ${CURRENT_INSTALLED_DIR}/share/boost-modularscripts)

        if(EXISTS "${_bm_SOURCE_PATH}/Jamfile.v2")
            file(REMOVE_RECURSE "${_bm_SOURCE_PATH}/Jamfile.v2")
        endif()

        configure_file(${_bm_DIR}/Jamroot.jam ${_bm_SOURCE_PATH}/Jamroot.jam @ONLY)

        # boost thread superfluously builds has_atomic_flag_lockfree on windows.
        if(EXISTS "${_bm_SOURCE_PATH}/build/Jamfile.v2")
            file(READ ${_bm_SOURCE_PATH}/build/Jamfile.v2 _contents)
            string(REPLACE
                "\n\nexe has_atomic_flag_lockfree"
                "\n\nexplicit has_atomic_flag_lockfree ;\nexe has_atomic_flag_lockfree"
                _contents
                "${_contents}"
            )
            string(REPLACE "\nimport ../../config/checks/config : requires ;" "\n# import ../../config/checks/config : requires ;" _contents "${_contents}")
            string(REGEX REPLACE
                "\.\./\.\./([^/ ]+)/build//(boost_[^/ ]+)"
                "/boost/\\1//\\2"
                _contents
                "${_contents}"
            )
            string(REGEX REPLACE " /boost//([^/ ]+) " " /boost/\\1//boost_\\1 " _contents "${_contents}")
            file(WRITE ${_bm_SOURCE_PATH}/build/Jamfile.v2 "${_contents}")
        endif()

        if(EXISTS "${_bm_SOURCE_PATH}/build/log-architecture.jam")
            file(READ ${_bm_SOURCE_PATH}/build/log-architecture.jam _contents)
            string(REPLACE
                "\nproject.load [ path.join [ path.make $(here:D) ] ../../config/checks/architecture ] ;"
                "\n# project.load [ path.join [ path.make $(here:D) ] ../../config/checks/architecture ] ;"
                _contents "${_contents}")
            file(WRITE ${_bm_SOURCE_PATH}/build/log-architecture.jam "${_contents}")
        endif()

        #####################
        # Cleanup previous builds
        ######################
        file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
        if(EXISTS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
            # It is possible for a file in this folder to be locked due to antivirus or vctip
            execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 1)
            file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
            if(EXISTS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
                message(FATAL_ERROR "Unable to remove directory: ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel\n  Files are likely in use.")
            endif()
        endif()

        file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
        if(EXISTS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
            # It is possible for a file in this folder to be locked due to antivirus or vctip
            execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 1)
            file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
            if(EXISTS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
                message(FATAL_ERROR "Unable to remove directory: ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg\n  Files are likely in use.")
            endif()
        endif()

        if(EXISTS ${CURRENT_PACKAGES_DIR}/debug)
            message(FATAL_ERROR "Error: directory exists: ${CURRENT_PACKAGES_DIR}/debug\n  The previous package was not fully cleared. This is an internal error.")
        endif()
        file(MAKE_DIRECTORY
            ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
            ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
        )

        ######################
        # Generate configuration
        ######################
        set(B2_OPTIONS
            -j$ENV{NUMBER_OF_PROCESSORS}
            --debug-configuration
            --debug-building
            --debug-generators
            --ignore-site-config
            --hash
            -q

            threading=multi
            ${_bm_OPTIONS}
        )

        if(PORT STREQUAL "boost-locale")
            list(APPEND B2_OPTIONS
                boost.locale.iconv=off
                boost.locale.posix=off
                /boost/locale//boost_locale
            )
            if("icu" IN_LIST FEATURES)
                list(APPEND B2_OPTIONS boost.locale.icu=on)
            else()
                list(APPEND B2_OPTIONS boost.locale.icu=off)
            endif()
        endif()

        if(PORT STREQUAL "boost-python")
            # Find Python. Can't use find_package here, but we already know where everything is
            file(GLOB PYTHON_INCLUDE_PATH "${CURRENT_INSTALLED_DIR}/include/python[0-9.]*")
            set(PYTHONLIBS_RELEASE "${CURRENT_INSTALLED_DIR}/lib")
            set(PYTHONLIBS_DEBUG "${CURRENT_INSTALLED_DIR}/debug/lib")
            string(REGEX REPLACE ".*python([0-9\.]+)$" "\\1" PYTHON_VERSION ${PYTHON_INCLUDE_PATH})
        endif()

        # Add build type specific options
        if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
            list(APPEND B2_OPTIONS runtime-link=shared)
        else()
            list(APPEND B2_OPTIONS runtime-link=static)
        endif()

        if (VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
            list(APPEND B2_OPTIONS link=shared)
        else()
            list(APPEND B2_OPTIONS link=static)
        endif()

        if(VCPKG_TARGET_ARCHITECTURE MATCHES "x64")
            list(APPEND B2_OPTIONS address-model=64 architecture=x86)
        elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
            list(APPEND B2_OPTIONS address-model=32 architecture=arm)
        else()
            list(APPEND B2_OPTIONS address-model=32 architecture=x86)
        endif()


        file(TO_CMAKE_PATH "${_bm_DIR}/nothing.bat" NOTHING_BAT)

        configure_file(${_bm_DIR}/user-config.jam ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/user-config.jam @ONLY)
        configure_file(${_bm_DIR}/user-config.jam ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/user-config.jam @ONLY)

        if(VCPKG_PLATFORM_TOOLSET MATCHES "v141")
            list(APPEND B2_OPTIONS toolset=msvc-14.1)
        elseif(VCPKG_PLATFORM_TOOLSET MATCHES "v140")
            list(APPEND B2_OPTIONS toolset=msvc-14.0)
        else()
            message(FATAL_ERROR "Unsupported value for VCPKG_PLATFORM_TOOLSET: '${VCPKG_PLATFORM_TOOLSET}'")
        endif()

        ######################
        # Perform build + Package
        ######################
        set(B2_EXE "${CURRENT_BUILDTREES_DIR}/../boost/src/boost_1_65_1/b2.exe")

        message(STATUS "Building ${TARGET_TRIPLET}-rel")
        set(ENV{BOOST_BUILD_PATH} "${BOOST_BUILDTREE}")
        set(ENV{BOOST_BUILD_USER_CONFIG} "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/user-config.jam")
        vcpkg_execute_required_process_repeat(
            COUNT 2
            COMMAND "${B2_EXE}"
                --stagedir=${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/stage
                --build-dir=${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
                ${B2_OPTIONS}
                ${_bm_OPTIONS_RELEASE}
                variant=release
                debug-symbols=on
            WORKING_DIRECTORY ${_bm_SOURCE_PATH}
            LOGNAME build-${TARGET_TRIPLET}-rel
        )
        message(STATUS "Building ${TARGET_TRIPLET}-rel done")

        message(STATUS "Building ${TARGET_TRIPLET}-dbg")
        set(ENV{BOOST_BUILD_PATH} "${BOOST_BUILDTREE}")
        set(ENV{BOOST_BUILD_USER_CONFIG} "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/user-config.jam")
        vcpkg_execute_required_process_repeat(
            COUNT 2
            COMMAND "${B2_EXE}"
                --stagedir=${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/stage
                --build-dir=${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
                ${B2_OPTIONS}
                ${_bm_OPTIONS_DEBUG}
                variant=debug
            WORKING_DIRECTORY ${_bm_SOURCE_PATH}
            LOGNAME build-${TARGET_TRIPLET}-dbg
        )
        message(STATUS "Building ${TARGET_TRIPLET}-dbg done")

        message(STATUS "Packaging ${TARGET_TRIPLET}-rel")
        file(GLOB REL_LIBS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/boost/build/*/*.lib)
        file(COPY ${REL_LIBS}
            DESTINATION ${CURRENT_PACKAGES_DIR}/lib
            FILES_MATCHING PATTERN "*.lib")
        if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
            file(GLOB REL_DLLS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/boost/build/*/*.dll)
            file(COPY ${REL_DLLS}
                DESTINATION ${CURRENT_PACKAGES_DIR}/bin
                FILES_MATCHING PATTERN "*.dll")
        endif()
        message(STATUS "Packaging ${TARGET_TRIPLET}-rel done")

        message(STATUS "Packaging ${TARGET_TRIPLET}-dbg")
        file(GLOB DBG_LIBS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/boost/build/*/*.lib)
        file(COPY ${DBG_LIBS}
            DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib
            FILES_MATCHING PATTERN "*.lib")
        if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
            file(GLOB DBG_DLLS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/boost/build/*/*.dll)
            file(COPY ${DBG_DLLS}
                DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin
                FILES_MATCHING PATTERN "*.dll")
        endif()
        message(STATUS "Packaging ${TARGET_TRIPLET}-dbg done")

        file(GLOB INSTALLED_LIBS ${CURRENT_PACKAGES_DIR}/debug/lib/*.lib ${CURRENT_PACKAGES_DIR}/lib/*.lib)
        foreach(LIB ${INSTALLED_LIBS})
            get_filename_component(OLD_FILENAME ${LIB} NAME)
            get_filename_component(DIRECTORY_OF_LIB_FILE ${LIB} DIRECTORY)
            string(REPLACE "libboost_" "boost_" NEW_FILENAME ${OLD_FILENAME})
            string(REPLACE "-s-" "-" NEW_FILENAME ${NEW_FILENAME}) # For Release libs
            string(REPLACE "-vc141-" "-vc140-" NEW_FILENAME ${NEW_FILENAME}) # To merge VS2017 and VS2015 binaries
            string(REPLACE "-sgd-" "-gd-" NEW_FILENAME ${NEW_FILENAME}) # For Debug libs
            string(REPLACE "-sgyd-" "-gyd-" NEW_FILENAME ${NEW_FILENAME}) # For Debug libs
            string(REPLACE "_python3-" "_python-" NEW_FILENAME ${NEW_FILENAME})
            if ("${DIRECTORY_OF_LIB_FILE}/${NEW_FILENAME}" STREQUAL "${DIRECTORY_OF_LIB_FILE}/${OLD_FILENAME}")
                # nothing to do
            elseif (EXISTS ${DIRECTORY_OF_LIB_FILE}/${NEW_FILENAME})
                file(REMOVE ${DIRECTORY_OF_LIB_FILE}/${OLD_FILENAME})
            else()
                file(RENAME ${DIRECTORY_OF_LIB_FILE}/${OLD_FILENAME} ${DIRECTORY_OF_LIB_FILE}/${NEW_FILENAME})
            endif()
        endforeach()
    endif()

    message(STATUS "Packaging headers")

    file(
        COPY ${_bm_SOURCE_PATH}/include/boost
        DESTINATION ${CURRENT_PACKAGES_DIR}/include
    )

    if(PORT STREQUAL "boost-config")
        file(APPEND ${CURRENT_PACKAGES_DIR}/include/boost/config/user.hpp
            "\n#ifndef BOOST_ALL_NO_LIB\n#define BOOST_ALL_NO_LIB\n#endif\n"
        )
        file(APPEND ${CURRENT_PACKAGES_DIR}/include/boost/config/user.hpp
            "\n#undef BOOST_ALL_DYN_LINK\n"
        )

        if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
            file(APPEND ${CURRENT_PACKAGES_DIR}/include/boost/config/user.hpp
                "\n#define BOOST_ALL_DYN_LINK\n"
            )
        endif()
    endif()

    message(STATUS "Packaging headers done")

    if(PORT STREQUAL "boost-exception")
        set(VCPKG_LIBRARY_LINKAGE static)
        file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/debug/bin)
    endif()

    file(INSTALL ${BOOST_BUILDTREE}/LICENSE_1_0.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
endfunction()
