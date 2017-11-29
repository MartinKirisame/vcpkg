
file(
    COPY
        ${CMAKE_CURRENT_LIST_DIR}/boost-modular.cmake
        ${CMAKE_CURRENT_LIST_DIR}/Jamroot.jam
        ${CMAKE_CURRENT_LIST_DIR}/nothing.bat
        ${CMAKE_CURRENT_LIST_DIR}/user-config.jam
    DESTINATION ${CURRENT_PACKAGES_DIR}/share/boost-modularscripts
)

set(VCPKG_POLICY_EMPTY_PACKAGE enabled)
