#!/bin/bash

##  Copyright (c) MediaArea.net SARL. All Rights Reserved.
 #
 #  Use of this source code is governed by a BSD-style license that can
 #  be found in the License.html file in the root of the source tree.
 ##

set -e # fail on any error

#-----------------------------------------------------------------------
# Setup
release_directory="$(realpath -- "$(dirname -- "${BASH_SOURCE[0]}")")"
version="$(sed -n 's/^#define FW_VER_NUM[[:space:]]*"\(.*\)".*/\1/p' "${release_directory}/../src/BlueSCSI_config.h")"

temp_directory="$(mktemp -d)"
trap 'rm -rf -- "${temp_directory}"' EXIT


#-----------------------------------------------------------------------
# Source archives
pushd "${temp_directory}"
    mkdir BlueSCSI
    cp -r "${release_directory}/.." BlueSCSI

    # Remove what is not wanted
    rm -rf BlueSCSI/.git*

    # Make source archives
    XZ_OPT=-9e tar -cJ --owner=root --group=root -f "BlueSCSI_${version}.tar.xz" BlueSCSI
popd

# Copy the source packages to the source directory
mkdir -p "${release_directory}/source"
cp "${temp_directory}/BlueSCSI_${version}.tar.xz" "${release_directory}/source"
