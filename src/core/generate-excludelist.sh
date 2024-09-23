#!/bin/bash

# Copyright 2018 Alexander Gottwald (https://github.com/ago1024)
# Copyright 2018 TheAssassin (https://github.com/TheAssassin)
#
# Dual-licensed under the terms of the GPLv3 and LGPL v3 licenses as part of
# linuxdeployqt (https://github.com/probonopd/linuxdeployqt).
#
# Changed to use C++ standard library containers instead of Qt ones.

set -e

filename=excludelist.h

tempfile=$(mktemp -t linuxdeploy-excludelist.h-XXXXXX)

log_prefix="-- [$(basename $0)]"

echo "$log_prefix downloading excludelist from GitHub"
url="https://gist.githubusercontent.com/root-kidik/d2c487591bb8b8e5c93726c3d8675544/raw/fbcf46d1d1925dea5e31ea87a8f6279b59fb4b0e/exclude-list"
blacklisted='ld-linux.so.2",
"ld-linux-x86-64.so.2",
"libanl.so.1",
"libBrokenLocale.so.1",
"libcidn.so.1",
"libc.so.6",
"libdl.so.2",
"libm.so.6",
"libmvec.so.1",
"libnss_compat.so.2",
"libnss_dns.so.2",
"libnss_files.so.2",
"libnss_hesiod.so.2",
"libnss_nisplus.so.2",
"libnss_nis.so.2",
"libpthread.so.0",
"libresolv.so.2",
"librt.so.1",
"libthread_db.so.1",
"libutil.so.1'

# sanity check
if [ "$blacklisted" == "" ]; then
    exit 1;
fi

# make sure to clean up tempfile in case of errors and on exit
_cleanup() {
    [ -f "$tempfile" ] && rm "$tempfile"
}
trap _cleanup EXIT

# overwrite existing source file
cat > "$tempfile" <<\EOF
/*
 * List of libraries to exclude for different reasons.
 *
 * Automatically generated from
 * https://raw.githubusercontent.com/probonopd/AppImages/master/excludelist
 *
 * This file shall be committed by the developers occassionally,
 * otherwise systems without access to the internet won't be able to build
 * fully working versions of linuxdeployqt.
 *
 * See https://github.com/probonopd/linuxdeployqt/issues/274 for more
 * information.
 */

#include <string>
#include <vector>

static const std::vector<std::string> generatedExcludelist = {
EOF

# create array
for item in ${blacklisted[@]:0:${#blacklisted[@]}-1}; do
    echo -e '    "'"$item"'",' >> "$tempfile"
done
echo -e '    "'"${blacklisted[$((${#blacklisted[@]}-1))]}"'"' >> "$tempfile"

echo "};" >> "$tempfile"

# avoid overwriting if the contents have not changed
# this prevents CMake having to recompile half of linuxdeploy even if nothing changed
if [ "$(sha256sum $filename | awk '{print $1}')" != "$(sha256sum $tempfile | awk '{print $1}')" ]; then
    echo "$log_prefix changes detected, updating $filename"
    cp "$tempfile" "$filename"
else
    echo "$log_prefix no changes detected, not touching $filename"
fi
