include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/beast
    REF caf144388778ecb59ff011d10c2afc38b62e5b1a
    SHA512 8f093730b73ea6ce6946c1b5e7d0a7aede7f52b7a19ef06ba8bb7fa32a9a0ec91d22482605d248918f78ececfd7669a60c7243eaa9f5b698affb74dbec040507
    HEAD_REF develop
)

file(COPY ${SOURCE_PATH}/include/boost DESTINATION ${CURRENT_PACKAGES_DIR}/include)

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE_1_0.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/boost-beast RENAME copyright)
