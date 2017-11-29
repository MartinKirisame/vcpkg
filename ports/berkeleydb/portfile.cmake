if(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
    message(FATAL_ERROR "${PORT} does not currently support UWP")
endif()

include(vcpkg_common_functions)

set(VERSION 6.1.36)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/db-${VERSION}.NC)

vcpkg_download_distfile(ARCHIVE
    URLS "http://download.oracle.com/berkeley-db/db-${VERSION}.NC.zip"
    FILENAME "db-${VERSION}.NC.zip"
    SHA512 288365a7fd13a083ecbda058c79d97141668f2cc1223658d0a5b4bd5e10969797b3c3072260906bae7692ed732ab94390a923379a30c8b9cb01ec8f391295a98
)
vcpkg_extract_source_archive(${ARCHIVE})

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS_DEBUG -DINSTALL_HEADERS=OFF
)

vcpkg_install_cmake()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/berkeleydb RENAME copyright)
