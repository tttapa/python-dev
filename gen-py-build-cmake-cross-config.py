import sys
from pathlib import Path
from platform_config import PlatformConfig, python_arch


python_versions = [
    "3.7",
    "3.8",
    "3.9",
    "3.10",
    "3.11",
    "3.12",
    "3.13",
]
pypy_versions = {
    "3.10": "7.3",  # "7.3.16"
    "3.9": "7.3",  # "7.3.16"
    "3.8": "7.3",  # "7.3.11"
    "3.7": "7.3",  # "7.3.9"
}

toolchain_contents = """\
include("${{CMAKE_CURRENT_LIST_DIR}}/{triple}.toolchain.cmake")

# Logic for locating Python
# ------------------------------------------------------------------------------

"""

cross_config_contents = """\
# For more information, see
# https://tttapa.github.io/py-build-cmake/Cross-compilation.html

implementation = '{implementation}'
version = '{version_nodot}'
abi = '{abi}'
arch = '{arch}'
toolchain_file = '{triple}.{python}.toolchain.cmake'

[cmake.options]
TOOLCHAIN_PYTHON_VERSION = '{version}'
"""


def get_toolchain_file(cfg: PlatformConfig):
    subs = {"triple": str(cfg)}
    return toolchain_contents.format(**subs)


def get_pbc_cross_config(version: str, cfg: PlatformConfig):
    version_nodot = version.replace(".", "")
    abi = f"cp{version_nodot}m" if version == "3.7" else f"cp{version_nodot}"
    subs = {
        "implementation": "cp",
        "abi": abi,
        "version": version,
        "version_nodot": version_nodot,
        "arch": python_arch(cfg),
        "triple": str(cfg),
        "python": "python",
    }
    return cross_config_contents.format(**subs)


def get_pbc_cross_config_pypy(version: str, pypy_version: str, cfg: PlatformConfig):
    version_nodot = version.replace(".", "")
    pypy_version_majmin = ".".join(pypy_version.split(".", 2)[:2])
    pypy_version_majmin_nodot = "".join(pypy_version.split(".", 2)[:2])
    subs = {
        "implementation": "pp",
        "abi": f"pypy{version_nodot}_pp{pypy_version_majmin_nodot}",
        "version": version,
        "version_nodot": version_nodot,
        "arch": python_arch(cfg),
        "triple": str(cfg),
        "python": "pypy",
    }
    toolchain_pypy_v = f"TOOLCHAIN_PYPY_VERSION = '{pypy_version_majmin}'\n"
    return cross_config_contents.format(**subs) + toolchain_pypy_v


if __name__ == "__main__":
    triple = sys.argv[1]
    outdir = Path(sys.argv[2])
    script_dir = Path(__file__).resolve().parent
    cfg = PlatformConfig.from_string(triple)
    with (
        open(outdir / f"{cfg}.python.toolchain.cmake", "w") as f,
        open(script_dir / "python.toolchain.cmake", "r") as s,
    ):
        f.write(get_toolchain_file(cfg))
        f.write(s.read())
    for version in python_versions:
        fname = f"{cfg}.python{version}.py-build-cmake.cross.toml"
        with open(outdir / fname, "w") as f:
            f.write(get_pbc_cross_config(version, cfg))
    pypy_supported = triple.startswith(("aarch64-", "x86_64-"))
    if pypy_supported:
        for version, pypy_version in pypy_versions.items():
            fname = f"{cfg}.pypy{version}-v{pypy_version}.py-build-cmake.cross.toml"
            with open(outdir / fname, "w") as f:
                f.write(get_pbc_cross_config_pypy(version, pypy_version, cfg))
        with (
            open(outdir / f"{cfg}.pypy.toolchain.cmake", "w") as f,
            open(script_dir / "pypy.toolchain.cmake", "r") as s,
        ):
            f.write(get_toolchain_file(cfg))
            f.write(s.read())
