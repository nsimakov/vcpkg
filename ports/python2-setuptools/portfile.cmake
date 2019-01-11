include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO pypa/setuptools
    REF v40.6.3
    SHA512 6dbe826eca37e8121e2b6f61045b2923a4c5b3e93e5f985d8990f03c9046a01d2f2fbe70f45a1b3106a2a9c755edbfb0953fdf25909bea0a45db9c179bcd1a90
)

# find python
#find_library(_VCPKG_BIN python27.lib)
set(PYTHON2 ${VCPKG_ROOT_DIR}/installed/x86-windows/share/python2/python.exe)
message(STATUS "PYTHON2: ${PYTHON2}")
set(ENV{PYTHONPATH} "${CURRENT_PACKAGES_DIR}/share/python2/python27.zip;${CURRENT_PACKAGES_DIR}/share/python2/DLLs;${CURRENT_PACKAGES_DIR}/share/python2/Lib;${CURRENT_PACKAGES_DIR}/share/python2/lib/plat-win;${CURRENT_PACKAGES_DIR}/share/python2/lib/lib-tk;${CURRENT_PACKAGES_DIR}/share/python2;${CURRENT_PACKAGES_DIR}/share/python2/Lib/site-packages;")

message(STATUS "Running: ${PYTHON2} bootstrap.py")
execute_process(
    COMMAND ${PYTHON2} -c "import sys;print(sys.path)"
    WORKING_DIRECTORY ${SOURCE_PATH}
    )
# bootstrap
message(STATUS "Running: ${PYTHON2} bootstrap.py")
execute_process(
    COMMAND ${PYTHON2} bootstrap.py
    WORKING_DIRECTORY ${SOURCE_PATH}
    OUTPUT_FILE ${CURRENT_BUILDTREES_DIR}/bootstrap_py_out.txt
    ERROR_FILE ${CURRENT_BUILDTREES_DIR}/bootstrap_py_err.txt
    )
# build
message(STATUS "Running: ${PYTHON2} setup.py build")
execute_process(
    COMMAND ${PYTHON2} setup.py build
    WORKING_DIRECTORY ${SOURCE_PATH}
    OUTPUT_FILE ${CURRENT_BUILDTREES_DIR}/setup_py_build_out.txt
    ERROR_FILE ${CURRENT_BUILDTREES_DIR}/setup_py_build_err.txt
    )
# install
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/python2/DLLs")
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/python2/Lib/site-packages")
# setup.py install like prefix in native format
file(TO_NATIVE_PATH "${CURRENT_PACKAGES_DIR}/share/python2" _PACKAGE_PREFEX)
execute_process(
    COMMAND ${PYTHON2} setup.py install --prefix=${_PACKAGE_PREFEX}
    WORKING_DIRECTORY ${SOURCE_PATH}
    OUTPUT_FILE ${CURRENT_BUILDTREES_DIR}/setup_py_install_out.txt
    ERROR_FILE ${CURRENT_BUILDTREES_DIR}/setup_py_install_err.txt
)
# license
file(INSTALL
    ${SOURCE_PATH}/LICENSE
    DESTINATION ${CURRENT_PACKAGES_DIR}/share/python2-setuptools
    RENAME copyright
)
# fake include file
file(WRITE ${CURRENT_PACKAGES_DIR}/include/python2_setup_tools.h "//this is fake header")
# remove empty folders
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/share/python2/DLLs)
