#!/bin/bash

blacklist="libasound.so.2 libcom_err.so.2 libcrypt.so.1 libc.so.6 libdl.so.2 libdrm.so.2 libexpat.so.1 libfontconfig.so.1 libgcc_s.so.1 libgdk_pixbuf-2.0.so.0 libgio-2.0.so.0 libglib-2.0.so.0 libGL.so.1 libgobject-2.0.so.0 libgpg-error.so.0 libICE.so.6 libkeyutils.so.1 libm.so.6 libnsl.so.1 libnss3.so libnssutil3.so libp11-kit.so.0 libpangoft2-1.0.so.0 libpangocairo-1.0.so.0 libpango-1.0.so.0 libpthread.so.0 libresolv.so.2 librt.so.1 libSM.so.6 libstdc++.so.6 libusb-1.0.so.0 libuuid.so.1 libX11.so.6 libxcb.so.1 libz.so.1"
blacklist_regex=`echo $blacklist | tr " " "|" | sed 's/\./\\\\./g'`

if [ $# -lt 1 ]
then
    echo "Usage: $0 path/to/executable"
else
    ldd $1 | grep -o '\W/[^ ]*' | grep -vE $blacklist_regex | tr " " "\n"
fi

