# ATK uses DllMain
if (VCPKG_LIBRARY_LINKAGE STREQUAL static)
    message(STATUS "Warning: Static building not supported. Building dynamic.")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

include(vcpkg_common_functions)
set(ATK_VERSION 2.26.1)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/atk-${ATK_VERSION})
vcpkg_download_distfile(ARCHIVE
    URLS "http://ftp.gnome.org/pub/GNOME/sources/atk/2.26/atk-${ATK_VERSION}.tar.xz"
    FILENAME "atk-${ATK_VERSION}.tar.xz"
    SHA512 9a802f1856f0f608c3b4ef6de27dc8174e103dbb32431a4dcffcac48c685cc48efb087ab73f661d7327341e8074b73bb7877c596f93228283ca5907910d64a6b)

vcpkg_extract_source_archive(${ARCHIVE})
vcpkg_apply_patches(SOURCE_PATH ${SOURCE_PATH}/atk
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/fix-encoding.patch)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DCMAKE_PROGRAM_PATH=${CURRENT_INSTALLED_DIR}/tools/glib
    OPTIONS_DEBUG
        -DATK_SKIP_HEADERS=ON)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

file(COPY ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/atk)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/atk/COPYING ${CURRENT_PACKAGES_DIR}/share/atk/copyright)
