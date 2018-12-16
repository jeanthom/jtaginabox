#!/bin/bash
make jtaginabox-mac
mkdir -p JTAGinabox.app
mkdir -p JTAGinabox.app/Contents/MacOS
cp jtaginabox JTAGinabox.app/Contents/MacOS/
cp libstlinkloader/libstlinkloader.dylib JTAGinabox.app/Contents/MacOS/
cp res/Info.plist JTAGinabox.app/Contents/Info.plist
install_name_tool -id "@executable_path/libstlinkloader.dylib" JTAGinabox.app/Contents/MacOS/libstlinkloader.dylib
install_name_tool -change libstlinkloader.dylib "@executable_path/libstlinkloader.dylib" JTAGinabox.app/Contents/MacOS/jtaginabox
