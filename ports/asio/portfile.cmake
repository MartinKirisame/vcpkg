#header-only library
include(vcpkg_common_functions)


vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO chriskohlhoff/asio
    REF asio-1-11-0
    SHA512 ab4a811ec9e4dbb3b64d22b645d33c36b7b3143144b98bccf32e6375137dabeb18a5dc5eff017aef80286633e7b9916bd3074bc3ed71c22be0d915797366ccde
    HEAD_REF master
)

# Handle copyright
file(COPY ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/asio)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/asio/COPYING ${CURRENT_PACKAGES_DIR}/share/asio/copyright)

# Copy the asio header files
file(INSTALL ${SOURCE_PATH}/include DESTINATION ${CURRENT_PACKAGES_DIR} FILES_MATCHING PATTERN "*.hpp" PATTERN "*.ipp")
