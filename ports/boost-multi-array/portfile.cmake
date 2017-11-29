# Automatically generated by boost-modularscripts/generate-ports.ps1

include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/multi_array
    REF boost-1.65.1
    SHA512 04998daec5b6635cfb53c865619629be859738543d86b2067435eb9219a4f37bfe4d857183c74beea5238b2e32be6290ad8fb2f9770299eafbdb5cc76140c7c8
    HEAD_REF master
)

include(${CURRENT_INSTALLED_DIR}/share/boost-modularscripts/boost-modular.cmake)

boost_modular(
    SOURCE_PATH ${SOURCE_PATH}
    
)
