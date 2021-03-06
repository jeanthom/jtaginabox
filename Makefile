VALA_OBJS=src/JTAGInABox.o src/JTAGInABoxWindow.o src/Homepage.o src/Flashing.o src/UrJTAG.o src/STLink.o
VALA_VAPI=$(VALA_OBJS:o=vapi)
VALAC=valac

MODULES=glib-2.0 gio-2.0 gtk+-3.0 vte-2.91 libusb-1.0
LDFLAGS=-Llibstlinkloader -lstlinkloader $(shell pkg-config --libs --cflags $(MODULES)) #-Wl,-Rlibstlinkloader
VALAFLAGS=--vapidir=libstlinkloader --pkg libusb-1.0 --pkg glib-2.0 --pkg gtk+-3.0 --pkg vte-2.91 --pkg stlinkloader --Xcc="-Ilibstlinkloader/include/" --target-glib=2.38 --gresources=res/resources.xml --target-glib=2.40


ARCH=$(shell uname -m)

all: jtaginabox

libstlinkloader/libstlinkloader.so:
	cd libstlinkloader && $(MAKE) libstlinkloader.so

libstlinkloader/libstlinkloader.dylib:
	cd libstlinkloader && $(MAKE) libstlinkloader.dylib

%.vapi: %.vala
	$(VALAC) --fast-vapi=$@ $<

%.o: %.vala $(VALA_VAPI)
	$(eval TMP_VAPI:=$(filter-out $(<:vala=vapi), $(VALA_VAPI)))
	$(VALAC) $(VALAFLAGS) --compile $(TMP_VAPI:%=--use-fast-vapi=%) $<
	mv $(@:src/%o=%vala.o) $@

res/resources.c: res/resources.xml
	glib-compile-resources --sourcedir=res res/resources.xml --target=res/resources.c --generate-source

jtaginabox: $(VALA_OBJS) libstlinkloader/libstlinkloader.so res/resources.c
	$(CC) -g res/resources.c $(VALA_OBJS) $(LDFLAGS) -o $@
	strip -s jtaginabox

jtaginabox-mac: $(VALA_OBJS) libstlinkloader/libstlinkloader.dylib res/resources.c res/Info.plist \
urjtag-mac dirtyjtag.bin
	$(CC) -g res/resources.c $(VALA_OBJS) $(LDFLAGS) -o jtaginabox
	mkdir -p JTAGinabox.app
	mkdir -p JTAGinabox.app/Contents/MacOS
	cp jtaginabox JTAGinabox.app/Contents/MacOS/jtaginabox-bin
	cp libstlinkloader/libstlinkloader.dylib JTAGinabox.app/Contents/MacOS/
	cp res/Info.plist JTAGinabox.app/Contents/Info.plist
	install_name_tool -id "@executable_path/libstlinkloader.dylib" JTAGinabox.app/Contents/MacOS/libstlinkloader.dylib
	install_name_tool -change libstlinkloader.dylib "@executable_path/libstlinkloader.dylib" JTAGinabox.app/Contents/MacOS/jtaginabox-bin
	cp urjtag/urjtag/src/apps/jtag/.libs/jtag JTAGinabox.app/Contents/MacOS/
	cp urjtag/urjtag/src/.libs/liburjtag.0.dylib JTAGinabox.app/Contents/MacOS/
	install_name_tool -id "@executable_path/liburjtag.0.dylib" JTAGinabox.app/Contents/MacOS/liburjtag.0.dylib
	install_name_tool -change "/usr/local/lib/liburjtag.0.dylib" "@executable_path/liburjtag.0.dylib" JTAGinabox.app/Contents/MacOS/jtag
	cp res/jtaginabox.sh JTAGInABox.app/Contents/MacOS/jtaginabox

.PHONY: urjtag
urjtag:
	cd urjtag/urjtag/ && ./autogen.sh && make

.PHONY: urjtag-mac
urjtag-mac:
	YACC=$(YACC) cd urjtag/urjtag/ && ./autogen.sh && ./configure --with-readline=no --enable-python=no --disable-debug --disable-dependency-tracking --disable-silent-rules --prefix=/usr/local && make

.PHONY: appimage
appimage: jtaginabox libstlinkloader/libstlinkloader.so res/runtime-$(ARCH) urjtag dirtyjtag.bin
	: > JTAGInABox-$(ARCH).AppImage # Erase AppImage file if existing
	mkdir -p JTAGInABox.AppDir/usr/bin/
	mkdir -p JTAGInABox.AppDir/usr/lib/
	cp jtaginabox JTAGInABox.AppDir/usr/bin/
	cp libstlinkloader/libstlinkloader.so JTAGInABox.AppDir/usr/lib/
	cp urjtag/urjtag/src/apps/jtag/.libs/jtag JTAGInABox.AppDir/usr/bin/
	cp urjtag/urjtag/src/.libs/liburjtag.so.0.0.0 JTAGInABox.AppDir/usr/lib/
	ln -f JTAGInABox.AppDir/usr/lib/liburjtag.so.0.0.0 JTAGInABox.AppDir/usr/lib/liburjtag.so
	ln -f JTAGInABox.AppDir/usr/lib/liburjtag.so.0.0.0 JTAGInABox.AppDir/usr/lib/liburjtag.so.0
	bash -c "res/appimagelibdep.sh jtaginabox | xargs -I library cp library JTAGInABox.AppDir/usr/lib/"
	@echo "Current AppDir tree :"
	@tree JTAGInABox.AppDir
	mksquashfs JTAGInABox.AppDir JTAGInABox.squashfs -root-owned -noappend
	cat res/runtime-$(ARCH) >> JTAGInABox-$(ARCH).AppImage
	cat JTAGInABox.squashfs >> JTAGInABox-$(ARCH).AppImage
	chmod a+x JTAGInABox-$(ARCH).AppImage

dirtyjtag.bin:
	cd DirtyJTAG && $(MAKE) PLATFORM=stlinkv2dfu
	cp DirtyJTAG/src/dirtyjtag.stlinkv2dfu.bin dirtyjtag.bin

.PHONY: clean
clean:
	rm -f res/resources.c
	rm -f src/*.o
	rm -f jtaginabox
	rm -f libstlinkloader.so
	rm -f *.AppImage
	rm -f JTAGInABox.AppDir/usr/bin/*
	rm -f JTAGInABox.AppDir/usr/lib/*
	rm -f dirtyjtag.bin
	rm -rf JTAGInABox.app
	cd libstlinkloader/ && $(MAKE) clean
	cd urjtag/urjtag/ && $(MAKE) clean
	cd DirtyJTAG/ && $(MAKE) clean


