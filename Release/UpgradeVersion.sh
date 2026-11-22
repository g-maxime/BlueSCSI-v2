#!/bin/bash

##  Copyright (c) MediaArea.net SARL. All Rights Reserved.
 #
 #  Use of this source code is governed by a BSD-style license that can
 #  be found in the License.html file in the root of the source tree.
 ##

set -e # fail on any error

if [[ "${#}" -lt 1 ]] ; then
    echo "Usage: ${0} version [dev|rel]"
    exit 1
fi

#-----------------------------------------------------------------------
# Setup
release_directory="$(realpath -- "$(dirname -- "${BASH_SOURCE[0]}")")"

version_new="${1}"
suffix="${2:-dev}"

#-----------------------------------------------------------------------
# Update the firmware version
sed -i "s/\(#define FW_VER_NUM[[:space:]]*\"\)[^\"]*\"/\1${version_new}\"/" "${release_directory}/../src/BlueSCSI_config.h"
sed -i "s/\(#define FW_VER_SUFFIX[[:space:]]*\"\)[^\"]*\"/\1${suffix}\"/" "${release_directory}/../src/BlueSCSI_config.h"