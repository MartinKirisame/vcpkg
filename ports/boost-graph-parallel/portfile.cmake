# Automatically generated by boost-modularscripts/generate-ports.ps1

include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/graph_parallel
    REF boost-1.65.1
    SHA512 e98413faa68213f64619e28a6da80962a4df70f0241418a2a12da9c6d9072ad6517162f9ad886f100253c44a065f303dfbf9febb416b018f9422b16881d91f56
    HEAD_REF master
)

include(${CURRENT_INSTALLED_DIR}/share/boost-modularscripts/boost-modular.cmake)

boost_modular(
    SOURCE_PATH ${SOURCE_PATH}
    
)
