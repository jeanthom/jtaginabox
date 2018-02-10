LDFLAGS := $(shell pkg-config --libs libusb-1.0 glib-2.0)
CFLAGS := -Wall -Wextra -Werror $(shell pkg-config --cflags libusb-1.0 glib-2.0) -Iinclude -fPIC -g

OBJS := src/dfu.o src/stlinkloader.o src/flashing.o src/crypto.o src/aes.o

all: libstlinkloader.so

libstlinkloader.so: $(OBJS)
	$(CC) -shared $(LDFLAGS) $(OBJS) -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -f libstlinkloader.so
	rm -f src/*.o
