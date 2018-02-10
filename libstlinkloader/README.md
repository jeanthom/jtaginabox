# libstlinkloader

[stlink-tool](https://github.com/jeanthom/stlink-tool) but as a C library with Vala VAPI.

## Example

```c
#include <stdio.h>
#include <stdlib.h>
#include <libstlinkloader.h>

int main(void) {
	struct stlinkloadercontext *ctx;
	
	ctx = stlinkloader_init();
	if (ctx == NULL) {
		return EXIT_FAILURE;
	}
	
	if (stlinkloader_is_correct_mode(ctx) != 1) {
		/* The dongle can't be reprogrammed in this mode */
		printf("Please unplug and replug your ST-Link\n");
		return EXIT_SUCCESS;
	}
	
	stlinkloader_read_infos(ctx);
	
	stlinkloader_flash(ctx, "/tmp/myfirmware.bin", 0x08004000, 1024);
	
	stlinkloader_free(ctx);

	return EXIT_SUCCESS;
}
```
