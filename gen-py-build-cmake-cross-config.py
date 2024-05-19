import sys
from pathlib import Path
from platform_config import PlatformConfig, python_arch


python_versions = [f"3.{v}" for v in range(7, 14)]

toolchain_contents = """\
include("${{CMAKE_CURRENT_LIST_DIR}}/{triple}.toolchain.cmake")

# Logic for locating Python
# ------------------------------------------------------------------------------

"""

cross_config_contents = """\
# For more information, see
# https://tttapa.github.io/py-build-cmake/Cross-compilation.html

implementation = 'cp'
version = '{version_nodot}'
abi = '{abi}'
arch = '{arch}'
toolchain_file = '{triple}.python.toolchain.cmake'

[cmake.options]
TOOLCHAIN_PYTHON_VERSION = '{version}'
"""


def get_toolchain_file(cfg: PlatformConfig):
    subs = {"triple": str(cfg)}
    return toolchain_contents.format(**subs)


def get_py_build_cmake_cross_config(version: str, cfg: PlatformConfig):
    version_nodot = version.replace(".", "")
    abi = f"cp{version_nodot}m" if version == "3.7" else f"cp{version_nodot}"
    subs = {
        "abi": abi,
        "version": version,
        "version_nodot": version_nodot,
        "arch": python_arch(cfg),
        "triple": str(cfg),
    }
    return cross_config_contents.format(**subs)


if __name__ == "__main__":
    triple = sys.argv[1]
    outdir = Path(sys.argv[2])
    script_dir = Path(__file__).resolve().parent
    cfg = PlatformConfig.from_string(triple)
    with open(outdir / f"{cfg}.python.toolchain.cmake", "w") as f, \
        open(script_dir / "python.toolchain.cmake", "r") as s:
        f.write(get_toolchain_file(cfg))
        f.write(s.read())
    for version in python_versions:
        fname = f"{cfg}.python{version}.py-build-cmake.cross.toml"
        with open(outdir / fname, "w") as f:
            f.write(get_py_build_cmake_cross_config(version, cfg))
