#!/bin/sh
set -e

# Copyright (c) 2010, Pierre-Olivier Latour
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * The name of Pierre-Olivier Latour may not be used to endorse or
#       promote products derived from this software without specific prior
#       written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Retrieve iOS SDK to use
SDK=$1
if [ "${SDK}" == "" ]
then
  echo "Please specify an iOS SDK version number from the following possibilities:"
  xcodebuild -showsdks | grep "iphoneos"
  exit 1
fi

# Project versions to use to build libEtPan (changing this may break the build)
export OPENSSL_VERSION="1.0.0a"
export CYRUS_SASL_VERSION="2.1.23"
export LIBETPAN_VERSION="1.0"

# Project version to use to build zlib (changing this may break the build)
export ZLIB_VERSION="1.2.5"

# Project versions to use to build libssh2 (changing this may break the build)
export GNUPG_VERSION="1.4.10"
export LIBGPG_ERROR_VERSION="1.9"
export LIBGCRYPT_VERSION="1.4.6"
export LIBSSH2_VERSION="1.2.7"

# Platforms to build for (changing this may break the build)
PLATFORMS="iPhoneSimulator iPhoneOS"

# Build projects
DEVELOPER=`xcode-select --print-path`
TOPDIR=`pwd`
for PLATFORM in ${PLATFORMS}
do
  ROOTDIR="${TOPDIR}/${PLATFORM}-${SDK}"
  if [ "${PLATFORM}" == "iPhoneOS" ]
  then
    ARCH="armv6"
  else
    ARCH="i386"
  fi
  rm -rf "${ROOTDIR}"
  mkdir -p "${ROOTDIR}"
  
  export DEVELOPER="${DEVELOPER}"
  export ROOTDIR="${ROOTDIR}"
  export PLATFORM="${PLATFORM}"
  export SDK="${SDK}"
  export ARCH="${ARCH}"
  
  # Build OpenSSL
  ./build-openssl.sh > "${ROOTDIR}-OpenSSL.log"
  
  # Build Cyrus SASL
  ./build-cyrus-sasl.sh > "${ROOTDIR}-Cyrus-SASL.log"
  
  # Build libEtPan
  ./build-libetpan.sh > "${ROOTDIR}-libEtPan.log"
  
  # Build zlib
  ./build-zlib.sh > "${ROOTDIR}-zlib.log"
  
  # Build GnuPG
  ./build-GnuPG.sh > "${ROOTDIR}-GnuPG.log"
  
  # Build libgpg-error
  ./build-libgpg-error.sh > "${ROOTDIR}-libgpg-error.log"
  
  # Build libgcrypt
  ./build-libgcrypt.sh > "${ROOTDIR}-libgcrypt.log"
  
  # Build libssh2
  ./build-libssh2.sh > "${ROOTDIR}-libssh2.log"
  
done

# Create archive if necessary
if [ "$2" == "--create-archive" ]
then
  DIRECTORY="Binaries"
  DATE=`date -u "+%Y-%m-%d-%H%M%S"`
  ARCHIVE="ios-libraries-${DATE}.zip"
  MANIFEST="SDK ${SDK}\nOpenSSL ${OPENSSL_VERSION}\nCyrus SASL ${CYRUS_SASL_VERSION}\nlibEtPan ${LIBETPAN_VERSION}\nzlib ${ZLIB_VERSION}\nGnuPG ${GNUPG_VERSION}\nlibgpg-error ${LIBGPG_ERROR_VERSION}\nlibgcrypt ${LIBGCRYPT_VERSION}\nlibssh2 ${LIBSSH2_VERSION}"
  SUMMARY="SDK ${SDK} + OpenSSL ${OPENSSL_VERSION} + Cyrus SASL ${CYRUS_SASL_VERSION} + libEtPan ${LIBETPAN_VERSION} + zlib ${ZLIB_VERSION} + GnuPG ${GNUPG_VERSION} + libgpg-error ${LIBGPG_ERROR_VERSION} + libgcrypt ${LIBGCRYPT_VERSION} + libssh2 ${LIBSSH2_VERSION}"
  
  # Build archive
  mkdir -p "${DIRECTORY}"
  echo "${MANIFEST}" > "${DIRECTORY}/Manifest.txt"
  for PLATFORM in ${PLATFORMS}; do
    mv "${PLATFORM}-${SDK}" "${DIRECTORY}"
  done
  ditto -c -k --keepParent "${DIRECTORY}" "${ARCHIVE}"
  rm -rf "${DIRECTORY}"
  
  # Upload to Google Code
  if [ "$3" != "" ]
  then
    ./googlecode_upload.pl --file "${ARCHIVE}" --summary "${SUMMARY}" --labels "Type-Archive" --project "libetpan-iphone" --user "$3"
  fi
fi