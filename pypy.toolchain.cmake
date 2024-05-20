if (NOT DEFINED CROSS_GNU_TRIPLE)
    message(FATAL_ERROR "This toolchain file is not intended to be used directly")
endif()

# User options
set(TOOLCHAIN_PYTHON_VERSION "3.10" CACHE STRING "Python version to locate")
set(TOOLCHAIN_PYPY_VERSION "7.3.16" CACHE STRING "PyPy version to locate")
option(TOOLCHAIN_NO_FIND_PYTHON "Do not set the FindPython hints" Off)
option(TOOLCHAIN_NO_FIND_PYTHON3 "Do not set the FindPython3 hints" Off)

# Inform CMake about these options (for try_compile etc.)
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
    TOOLCHAIN_PYTHON_VERSION TOOLCHAIN_PYPY_VERSION TOOLCHAIN_NO_FIND_PYTHON TOOLCHAIN_NO_FIND_PYTHON3)

# Internal variables
set(TOOLCHAIN_PYTHON_ROOT "${CMAKE_CURRENT_LIST_DIR}/${CROSS_GNU_TRIPLE}/pypy${TOOLCHAIN_PYTHON_VERSION}-v${TOOLCHAIN_PYPY_VERSION}")
list(APPEND CMAKE_FIND_ROOT_PATH "${TOOLCHAIN_PYTHON_ROOT}")

# Determine the paths and other properties of the Python installation
function(toolchain_locate_python)
    set(_TOOLCHAIN_PYTHON_ROOT_DIR "${TOOLCHAIN_PYTHON_ROOT}/usr/local")
    # Determine the library name and path
    set(lib_version "${TOOLCHAIN_PYTHON_VERSION}")
    if (TOOLCHAIN_PYTHON_VERSION VERSION_LESS "3.9")
        set(lib_version "3")
    endif()
    set(_TOOLCHAIN_PYTHON_LIBRARY "${_TOOLCHAIN_PYTHON_ROOT_DIR}/bin/libpypy${lib_version}-c.so")
    # Determine the include path
    set(inc_dir "include/pypy${TOOLCHAIN_PYTHON_VERSION}")
    if (TOOLCHAIN_PYTHON_VERSION VERSION_LESS "3.8")
        set(inc_dir "include")
    endif()
    set(_TOOLCHAIN_PYTHON_INCLUDE_DIR "${_TOOLCHAIN_PYTHON_ROOT_DIR}/${inc_dir}")
    # Set the extension suffix
    if (NOT TOOLCHAIN_PYPY_VERSION MATCHES "^([0-9]+)\\.([0-9]+)(\\.[0-9]+)?$")
        message(SEND_ERROR "Invalid PyPy version. \${TOOLCHAIN_PYPY_VERSION} should be major.minor or major.minor.patch (e.g. 7.3.16)")
    endif()
    set(abi_version "${CMAKE_MATCH_1}${CMAKE_MATCH_2}")
    if (NOT TOOLCHAIN_PYTHON_VERSION MATCHES "^([0-9]+)\\.([0-9]+)$")
        message(SEND_ERROR "Invalid Python version. \${TOOLCHAIN_PYTHON_VERSION} should be major.minor (e.g. 3.10)")
    endif()
    set(py_version "${CMAKE_MATCH_1}${CMAKE_MATCH_2}")
    set(_TOOLCHAIN_PYTHON_EXTSUFFIX ".pypy${py_version}-pp${abi_version}-${CMAKE_SYSTEM_PROCESSOR}-linux-gnu.so")

    # Set result variables (cached)
    set(TOOLCHAIN_PYTHON_ABI "" CACHE STRING "" FORCE)
    set(TOOLCHAIN_PYTHON_EXTSUFFIX "${_TOOLCHAIN_PYTHON_EXTSUFFIX}" CACHE STRING "" FORCE)
    set(TOOLCHAIN_PYTHON_ROOT_DIR "${_TOOLCHAIN_PYTHON_ROOT_DIR}" CACHE PATH "" FORCE)
    set(TOOLCHAIN_PYTHON_LIBRARY "${_TOOLCHAIN_PYTHON_LIBRARY}" CACHE FILEPATH "" FORCE)
    set(TOOLCHAIN_PYTHON_INCLUDE_DIR "${_TOOLCHAIN_PYTHON_INCLUDE_DIR}" CACHE PATH "" FORCE)
endfunction()

if (NOT TOOLCHAIN_NO_FIND_PYTHON OR NOT TOOLCHAIN_NO_FIND_PYTHON3)
    # Determine Python location and properties if not already cached
    if (NOT DEFINED TOOLCHAIN_PYTHON_ABI
     OR NOT DEFINED TOOLCHAIN_PYTHON_EXTSUFFIX
     OR NOT DEFINED TOOLCHAIN_PYTHON_ROOT_DIR
     OR NOT DEFINED TOOLCHAIN_PYTHON_LIBRARY
     OR NOT DEFINED TOOLCHAIN_PYTHON_INCLUDE_DIR
     OR NOT TOOLCHAIN_PYTHON_VERSION STREQUAL "${_TOOLCHAIN_PYTHON_VERSION_PREVIOUS}"
     OR NOT TOOLCHAIN_PYPY_VERSION STREQUAL "${_TOOLCHAIN_PYPY_VERSION_PREVIOUS}")
        toolchain_locate_python()
        set(_TOOLCHAIN_PYTHON_VERSION_PREVIOUS "${TOOLCHAIN_PYTHON_VERSION}" CACHE INTERNAL "")
        set(_TOOLCHAIN_PYPY_VERSION_PREVIOUS "${TOOLCHAIN_PYPY_VERSION}" CACHE INTERNAL "")
    endif()
    # Set FindPython hints and artifacts
    if (NOT TOOLCHAIN_NO_FIND_PYTHON)
        set(Python_ROOT_DIR ${TOOLCHAIN_PYTHON_ROOT_DIR} CACHE PATH "" FORCE)
        set(Python_LIBRARY ${TOOLCHAIN_PYTHON_LIBRARY} CACHE FILEPATH "" FORCE)
        set(Python_INCLUDE_DIR ${TOOLCHAIN_PYTHON_INCLUDE_DIR} CACHE PATH "" FORCE)
        set(Python_INTERPRETER_ID "PyPy" CACHE STRING "" FORCE)
    endif()
    # Set FindPytho3 hints and artifacts
    if (NOT TOOLCHAIN_NO_FIND_PYTHON3)
        set(Python3_ROOT_DIR ${TOOLCHAIN_PYTHON_ROOT_DIR} CACHE PATH "" FORCE)
        set(Python3_LIBRARY ${TOOLCHAIN_PYTHON_LIBRARY} CACHE FILEPATH "" FORCE)
        set(Python3_INCLUDE_DIR ${TOOLCHAIN_PYTHON_INCLUDE_DIR} CACHE PATH "" FORCE)
        set(Python3_INTERPRETER_ID "PyPy" CACHE STRING "" FORCE)
    endif()
    # Set pybind11 hints
    get_filename_component(PYTHON_MODULE_DEBUG_POSTFIX ${TOOLCHAIN_PYTHON_EXTSUFFIX} NAME_WE)
    get_filename_component(PYTHON_MODULE_EXTENSION ${TOOLCHAIN_PYTHON_EXTSUFFIX} EXT)
    if (TOOLCHAIN_PYTHON_ABI MATCHES "d")
        set(PYTHON_IS_DEBUG TRUE)
    else()
        set(PYTHON_IS_DEBUG FALSE)
    endif()
    set(PYTHON_MODULE_DEBUG_POSTFIX ${PYTHON_MODULE_DEBUG_POSTFIX} CACHE INTERNAL "")
    set(PYTHON_MODULE_EXTENSION ${PYTHON_MODULE_EXTENSION} CACHE INTERNAL "")
    set(PYTHON_IS_DEBUG ${PYTHON_IS_DEBUG} CACHE INTERNAL "")
    # Set nanobind hints
    set(NB_SUFFIX ${TOOLCHAIN_PYTHON_EXTSUFFIX})
    get_filename_component(TOOLCHAIN_PYTHON_EXTSUFFIX_EXT ${TOOLCHAIN_PYTHON_EXTSUFFIX} LAST_EXT)
    set(NB_SUFFIX_S ".abi3${TOOLCHAIN_PYTHON_EXTSUFFIX_EXT}")
    set(NB_SUFFIX ${NB_SUFFIX} CACHE INTERNAL "")
    set(NB_SUFFIX_S ${NB_SUFFIX_S} CACHE INTERNAL "")
endif()
