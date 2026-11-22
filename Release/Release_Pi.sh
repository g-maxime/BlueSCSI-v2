#!/bin/bash

##  Copyright (c) MediaArea.net SARL. All Rights Reserved.
 #
 #  Use of this source code is governed by a BSD-style license that can
 #  be found in the License.html file in the root of the source tree.
 ##

set -e # fail on any error

#-----------------------------------------------------------------------
# Setup

if [ "$(uname -s)" != "Linux" ] ; then
    echo "Error: this script must run on a Linux host"
    exit 1
fi

case "$(uname -m)" in
    x86_64)
        toolchain_host="x86_64"
        ;;
    aarch64|arm64)
        toolchain_host="aarch64"
        ;;
    *)
        echo "Error: unsupported Linux host architecture: $(uname -m)"
        exit 1
        ;;
esac

release_directory="$(realpath -- "$(dirname -- "${BASH_SOURCE[0]}")")"
version="$(sed -n 's/^#define FW_VER_NUM[[:space:]]*"\(.*\)".*/\1/p' "${release_directory}/../src/BlueSCSI_config.h")"

archive=""

toolchain_version="14.2.rel1"
pico_sdk_branch="v2.2.0-UltraSupport-rel2"
pico_extras_branch="sdk-2.2.0"

toolchain_name="arm-gnu-toolchain-${toolchain_version}-${toolchain_host}-arm-none-eabi"
toolchain_url="https://developer.arm.com/-/media/Files/downloads/gnu/${toolchain_version}/binrel/${toolchain_name}.tar.xz"

temp_directory="$(mktemp -d)"
trap 'rm -rf -- "${temp_directory}"' EXIT

#-----------------------------------------------------------------------
# Cleanup
rm -f "${release_directory}/BlueSCSI_${version}_Arm.zip"

#-----------------------------------------------------------------------
# Toolchain and SDK
pushd "${temp_directory}"
    curl -L "${toolchain_url}" -o "${toolchain_name}.tar.xz"
    tar -xJf "${toolchain_name}.tar.xz"

    git clone --depth 1 --branch "${pico_sdk_branch}" --recurse-submodules --shallow-submodules https://github.com/bluescsi/pico-sdk-internal.git pico-sdk-internal
    git clone --depth 1 --branch "${pico_extras_branch}" --recurse-submodules --shallow-submodules https://github.com/raspberrypi/pico-extras.git pico-extras
popd

toolchain_directory="${temp_directory}/${toolchain_name}"
export PATH="${toolchain_directory}/bin:${PATH}"
export PICO_SDK_PATH="${temp_directory}/pico-sdk-internal"
export PICO_EXTRAS_PATH="${temp_directory}/pico-extras"

build_directory="${temp_directory}/build"
package_directory="${temp_directory}/BlueSCSI"

target_names=(Pico Pico_DaynaPORT Pico_Audio_SPDIF Pico_2 Pico_2_DaynaPORT Pico_2_Audio_SPDIF Ultra Ultra_Wide)
target_boards=(pico pico_w pico_w pico2 pico2_w pico2_w bluescsi_ultra bluescsi_ultra_wide)

#-----------------------------------------------------------------------
# Build the Raspberry Pi RP2040/RP2350 firmware targets
for target_index in "${!target_names[@]}" ; do
    target="${target_names[${target_index}]}"
    board="${target_boards[${target_index}]}"

    echo "Building BlueSCSI_${target} (board=${board})"
    cmake -S "${release_directory}/.." -B "${build_directory}/${target}" -DPICO_BOARD="${board}" -DBLUESCSI_TARGET="${target}" -DCMAKE_BUILD_TYPE=Release
    cmake --build "${build_directory}/${target}"
done

#-----------------------------------------------------------------------
# Package
mkdir -p "${package_directory}"

for file in "${build_directory}"/*/BlueSCSI_*.uf2 ; do
    if [ ! -f "${file}" ] ; then
        continue
    fi
    cp -f "${file}" "${package_directory}"
done

"${release_directory}/../utils/create_firmware_zip.sh" "${build_directory}" "${package_directory}"

cp -f "${release_directory}/../LICENSE" "${package_directory}"
cp -f "${release_directory}/../README.adoc" "${package_directory}"
cp -f "${release_directory}/../BUILDING.md" "${package_directory}"

pushd "${temp_directory}"
    zip -9 -r "${release_directory}/BlueSCSI_${version}_Arm.zip" "BlueSCSI"
popd
