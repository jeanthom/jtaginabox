#!/bin/bash
set -e
docker build -t jtaginabox -f Dockerfile .
docker run --volume=$PWD:/host:z jtaginabox bash -c "chown "`id -u`":"`id -u`" *.AppImage && cp -p *.AppImage /host/"
