# Building JTAG in a box on a Mac

Building JTAG in a box on a Mac is a fairly difficult exercise, but somehow doable.

## Dependencies

```
brew install vala vte3 gettext libusb bison gcc readline
```

Make sure `/usr/local/opt/gettext/bin` is in your $PATH, otherwise autopoint won't work.

## Instructions

```
make jtaginabox-mac YACC=/usr/local/Cellar/bison/3.2/bin/yacc
```
