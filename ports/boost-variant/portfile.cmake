# Automatically generated by boost-modularscripts/generate-ports.ps1

include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/variant
    REF boost-1.65.1
    SHA512 fe586a5ce624088d1e05c0b4f6b486206c4f2169c4f4cfb4a77a5dbc27d5aa6bec35682d08f7694fa946a2671e25060271699a98bd563ddd0fae08848570344f
    HEAD_REF master
)

include(${CURRENT_INSTALLED_DIR}/share/boost-modularscripts/boost-modular.cmake)

boost_modular(
    SOURCE_PATH ${SOURCE_PATH}
    
)
