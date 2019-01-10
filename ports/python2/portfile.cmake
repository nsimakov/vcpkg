# Patches are from: 
# - https://github.com/python-cmake-buildsystem/python-cmake-buildsystem/tree/master/patches/2.7.13/Windows-MSVC/1900
# - https://github.com/Microsoft/vcpkg/tree/master/ports/python3

if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic AND VCPKG_CRT_LINKAGE STREQUAL static)
    message(STATUS "Warning: Dynamic library with static CRT is not supported. Building static library.")
    set(VCPKG_LIBRARY_LINKAGE static)
endif()

set(PYTHON_VERSION_MAJOR  2)
set(PYTHON_VERSION_MINOR  7)
set(PYTHON_VERSION_PATCH  15)
set(PYTHON_VERSION        ${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}.${PYTHON_VERSION_PATCH})
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/python-${PYTHON_VERSION})

include(vcpkg_common_functions)


vcpkg_download_distfile(
    PYTHON_ARCHIVE
    URLS https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz
    FILENAME Python-${PYTHON_VERSION}.tar.xz
    SHA512 27ea43eb45fc68f3d2469d5f07636e10801dee11635a430ec8ec922ed790bb426b072da94df885e4dfa1ea8b7a24f2f56dd92f9b0f51e162330f161216bd6de6
)

vcpkg_extract_source_archive(${PYTHON_ARCHIVE})

set(_PYTHON_PATCHES "")

if (VCPKG_LIBRARY_LINKAGE STREQUAL static)
    list(APPEND _PYTHON_PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/004-static-library-msvc.patch
        ${CMAKE_CURRENT_LIST_DIR}/006-static-fix-headers.patch
    )
endif()
if (VCPKG_CRT_LINKAGE STREQUAL static)
    list(APPEND _PYTHON_PATCHES ${CMAKE_CURRENT_LIST_DIR}/005-static-crt-msvc.patch)
endif()

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/001-build-msvc.patch
        ${CMAKE_CURRENT_LIST_DIR}/002-build-msvc.patch
        ${CMAKE_CURRENT_LIST_DIR}/003-build-msvc.patch
        ${_PYTHON_PATCHES}
        ${CMAKE_CURRENT_LIST_DIR}/007-fix-build-path.patch
        ${CMAKE_CURRENT_LIST_DIR}/disable-tcl-tk-tix.patch
)

# Get external dependencies
execute_process(
    COMMAND ${SOURCE_PATH}/PCbuild/get_externals.bat
    WORKING_DIRECTORY ${SOURCE_PATH}/PCbuild/get_externals.bat
    )

if (VCPKG_TARGET_ARCHITECTURE MATCHES "x86")
    set(BUILD_ARCH "Win32")
    set(OUT_DIR "win32")
elseif (VCPKG_TARGET_ARCHITECTURE MATCHES "x64")
    set(BUILD_ARCH "x64")
    set(OUT_DIR "amd64")
else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()


vcpkg_build_msbuild(
        PROJECT_PATH ${SOURCE_PATH}/PCBuild/pcbuild.proj
        PLATFORM ${BUILD_ARCH})


file(GLOB HEADERS ${SOURCE_PATH}/Include/*.h)
file(COPY ${HEADERS} ${SOURCE_PATH}/PC/pyconfig.h DESTINATION ${CURRENT_PACKAGES_DIR}/include/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR})

file(COPY ${SOURCE_PATH}/Lib DESTINATION ${CURRENT_PACKAGES_DIR}/share/python${PYTHON_VERSION_MAJOR})

file(COPY ${SOURCE_PATH}/PCBuild/${OUT_DIR}/python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}.lib DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
file(COPY ${SOURCE_PATH}/PCBuild/${OUT_DIR}/python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}_d.lib DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    file(COPY ${SOURCE_PATH}/PCBuild/${OUT_DIR}/python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}.dll DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
    file(COPY ${SOURCE_PATH}/PCBuild/${OUT_DIR}/python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}_d.dll DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
endif()

# Python binary as tool
foreach(FILE python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}.dll python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}_d.dll 
        python.exe python_d.exe
    )
    file(COPY ${SOURCE_PATH}/PCBuild/${OUT_DIR}/${FILE} DESTINATION ${CURRENT_PACKAGES_DIR}/share/python${PYTHON_VERSION_MAJOR})
endforeach()

# Compiled python modules
foreach(FILE
        _bsddb.pdb            _bsddb.pyd            _bsddb_d.pdb            _bsddb_d.pyd            _ctypes.pdb         _ctypes.pyd
        _ctypes_d.pdb         _ctypes_d.pyd         _ctypes_test.pdb        _ctypes_test.pyd        _ctypes_test_d.pdb  _ctypes_test_d.pyd
        _elementtree.pdb      _elementtree.pyd      _elementtree_d.pdb      _elementtree_d.pyd      _hashlib.pdb        _hashlib.pyd
        _hashlib_d.pdb        _hashlib_d.pyd        _msi.pdb                _msi.pyd                _msi_d.pdb          _msi_d.pyd
        _multiprocessing.pdb  _multiprocessing.pyd  _multiprocessing_d.pdb  _multiprocessing_d.pyd  _socket.pdb         _socket.pyd
        _socket_d.pdb         _socket_d.pyd         _sqlite3.pdb            _sqlite3.pyd            _sqlite3_d.pdb      _sqlite3_d.pyd
        _ssl.pdb              _ssl.pyd              _ssl_d.pdb              _ssl_d.pyd              _testcapi.pdb       _testcapi.pyd
        _testcapi_d.pdb       _testcapi_d.pyd       bz2.pdb                 bz2.pyd                 bz2_d.pdb           bz2_d.pyd
        pyexpat.pdb           pyexpat.pyd           pyexpat_d.pdb           pyexpat_d.pyd           select.pdb          select.pyd
        select_d.pdb          select_d.pyd          sqlite3.pdb             sqlite3_d.pdb           unicodedata.pdb     unicodedata.pyd
        unicodedata_d.pdb     unicodedata_d.pyd     w9xpopen.pdb            w9xpopen_d.pdb          winsound.pdb        winsound.pyd
    )
    file(COPY ${SOURCE_PATH}/PCBuild/${OUT_DIR}/${FILE} DESTINATION ${CURRENT_PACKAGES_DIR}/share/python${PYTHON_VERSION_MAJOR}/DLLs)
endforeach()

# Handle copyright
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/python${PYTHON_VERSION_MAJOR})
file(RENAME ${CURRENT_PACKAGES_DIR}/share/python${PYTHON_VERSION_MAJOR}/LICENSE ${CURRENT_PACKAGES_DIR}/share/python${PYTHON_VERSION_MAJOR}/copyright)

vcpkg_copy_pdbs()
