# Automatically generated by boost-modularscripts/generate-ports.ps1

include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/icl
    REF boost-1.65.1
    SHA512 5c766a4c5817d37b4c292b18134d4cccab0c78b759cb0b48b78432b232f247d591a4747e53c1cda4f87cd80b61b275d038b417b3b87a855b5a083635faa1950e
    HEAD_REF master
)

include(${CURRENT_INSTALLED_DIR}/share/boost-modularscripts/boost-modular.cmake)

boost_modular(
    SOURCE_PATH ${SOURCE_PATH}
    
)
