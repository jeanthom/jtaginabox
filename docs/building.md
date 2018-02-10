# Building JTAG in a box yourself
    
Assuming you have Docker on your computer :

```
git clone https://github.com/jeanthom/jtaginabox
cd jtaginabox
git submodule update --init --recursive
./build.sh
```

This is the recommended way of building JTAG in a box. After initial Docker configuration (Ubuntu container setup and package installation), the build time is around a minute and a half.

The build scripts does the following :

 * Compiling `libstlinkloader`
 * Compiling JTAG in a box executable
 * Compiling UrJTAG
 * Compiling DirtyJTAG
 * Bundle everything into an AppImage

The Dockerfile uses Ubuntu 16.04 LTS.

## AppImage bundling inside Docker

For those who have taken a look at my Makefile, they probably noticed that the whole AppImage bundling was done manually. You way wonder why... Well, AppImage uses a squashfs to store everything (which will be mounted by the runtime when the user will execute your AppImage). The official `appimagetool` uses FUSE to mount a squashfs image. The problem is that on Docker you can't run FUSE properly (or at least without tweaks). The solution here is to use mksquashfs and create our AppImage manually.

However this causes an issue on Fedora : mksquashfs is only available to a root user. Meh.
