# ATK uses DllMain, so atkmm also
if (VCPKG_LIBRARY_LINKAGE STREQUAL static)
    message(STATUS "Warning: Static building not supported. Building dynamic.")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/atkmm-2.25.4)
vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.gnome.org/pub/GNOME/sources/atkmm/2.25/atkmm-2.25.4.tar.xz"
    FILENAME "atkmm-2.25.4.tar.xz"
    SHA512 6a9c23861fd482c641190172323a7ddf510c4d8c8c8e9d56a658f5a5a0d09565e2c5285daef988450e50663c15aa4814cb9c93d13057b58134299b30ba3891ce
)
vcpkg_extract_source_archive(${ARCHIVE})

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES ${CMAKE_CURRENT_LIST_DIR}/fix_properties.patch ${CMAKE_CURRENT_LIST_DIR}/fix_charset.patch
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/msvc_recommended_pragmas.h DESTINATION ${SOURCE_PATH}/MSVC_Net2013)

set(VS_PLATFORM ${VCPKG_TARGET_ARCHITECTURE})
if(${VCPKG_TARGET_ARCHITECTURE} STREQUAL x86)
    set(VS_PLATFORM "Win32")
endif(${VCPKG_TARGET_ARCHITECTURE} STREQUAL x86)
vcpkg_build_msbuild(
    PROJECT_PATH ${SOURCE_PATH}/MSVC_Net2013/atkmm.sln
    TARGET atkmm
    PLATFORM ${VS_PLATFORM}
    # Need this for it to pick up xerces-c port: https://github.com/Microsoft/vcpkg/issues/891
    OPTIONS /p:ForceImportBeforeCppTargets=${VCPKG_ROOT_DIR}/scripts/buildsystems/msbuild/vcpkg.targets
)

# Handle headers
file(COPY ${SOURCE_PATH}/MSVC_Net2013/atkmm/atkmmconfig.h DESTINATION ${CURRENT_PACKAGES_DIR}/include)
file(COPY ${SOURCE_PATH}/atk/atkmm.h DESTINATION ${CURRENT_PACKAGES_DIR}/include)
file(
    COPY
    ${SOURCE_PATH}/atk/atkmm
    DESTINATION ${CURRENT_PACKAGES_DIR}/include
    FILES_MATCHING PATTERN *.h
)

# Handle libraries
file(
    COPY
    ${SOURCE_PATH}/MSVC_Net2013/Release/${VS_PLATFORM}/bin/atkmm.dll
    DESTINATION ${CURRENT_PACKAGES_DIR}/bin
)
file(
    COPY
    ${SOURCE_PATH}/MSVC_Net2013/Release/${VS_PLATFORM}/bin/atkmm.lib
    DESTINATION ${CURRENT_PACKAGES_DIR}/lib
)
file(
    COPY
    ${SOURCE_PATH}/MSVC_Net2013/Debug/${VS_PLATFORM}/bin/atkmm.dll
    DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin
)
file(
    COPY
    ${SOURCE_PATH}/MSVC_Net2013/Debug/${VS_PLATFORM}/bin/atkmm.lib
    DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib
)

vcpkg_copy_pdbs()

# Handle copyright and readme
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/atkmm RENAME copyright)
file(INSTALL ${SOURCE_PATH}/README DESTINATION ${CURRENT_PACKAGES_DIR}/share/atkmm RENAME readme.txt)
