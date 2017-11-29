include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/numeric
    REF boost-1.65.1
    SHA512 Running command:    CertUtil.exe -hashfile "D:\src\vcpkg\ports\boost-modularscripts\downloads\numeric-1.65.1.tar.gz" SHA512  failed
    HEAD_REF master
)

include(${CURRENT_INSTALLED_DIR}/share/boost-modularscripts/boost-modular.cmake)

boost_modular(
    SOURCE_PATH ${SOURCE_PATH}
    
)
