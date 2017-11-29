include(vcpkg_common_functions)

set(CAIROMM_VERSION 1.15.5)
set(CAIROMM_HASH c8b28b0cf87ec977b01ac47db76ee3d72151ec8f27c16b0331d6f10b4668b95140beb5bd2251d732703826f32fec42b5d1d9719ca23c1aa41240d655c0e311f6)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/cairomm-${CAIROMM_VERSION})

vcpkg_download_distfile(ARCHIVE
    URLS "https://www.cairographics.org/releases/cairomm-${CAIROMM_VERSION}.tar.gz"
    FILENAME "cairomm-${CAIROMM_VERSION}.tar.gz"
    SHA512 ${CAIROMM_HASH}
)
vcpkg_extract_source_archive(${ARCHIVE})

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})
file(COPY ${CMAKE_CURRENT_LIST_DIR}/cmake DESTINATION ${SOURCE_PATH}/build)

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES "${CMAKE_CURRENT_LIST_DIR}/0001-fix-build.patch")

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

file(COPY ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/cairomm)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/cairomm/COPYING ${CURRENT_PACKAGES_DIR}/share/cairomm/copyright)
