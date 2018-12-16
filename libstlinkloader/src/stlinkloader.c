#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <libusb.h>

#include "defines.h"
#include "types.h"
#include "crypto.h"
#include "dfu.h"

struct stlinkloadercontext* stlinkloader_init(void) {
  struct stlinkloadercontext *context;
  int res;

  context = malloc(sizeof(struct stlinkloadercontext));
  if (context == NULL) {
    return NULL;
  }

  res = libusb_init(&(context->usb_context));
  if (res != 0) {
    free(context);
    return NULL;
  }

  context->usb_dev_handle = libusb_open_device_with_vid_pid(context->usb_context,
							    STLINK_VID,
							    STLINK_PID);
  if (context->usb_dev_handle == NULL) {
    libusb_exit(context->usb_context);
    free(context);
    return NULL;
  }
  
  return context;
}

void stlinkloader_free(struct stlinkloadercontext *context) {
  libusb_close(context->usb_dev_handle);
  libusb_exit(context->usb_context);
  free(context);
}

int stlinkloader_read_infos(struct stlinkloadercontext *context) {
  unsigned char data[20];
  int res, rw_bytes;

  memset(data, 0, sizeof(data));

  data[0] = 0xF1;
  data[1] = 0x80;

  /* Write */
  res = libusb_bulk_transfer(context->usb_dev_handle,
			     EP_OUT,
			     data,
			     16,
			     &rw_bytes,
			     USB_TIMEOUT);
  if (res) {
    return -1;
  }

  /* Read */
  res = libusb_bulk_transfer(context->usb_dev_handle,
		       EP_IN,
		       data,
		       6,
		       &rw_bytes,
		       USB_TIMEOUT);
  if (res) {
    return -1;
  }

  context->stlink_version = data[0] >> 4;
  context->jtag_version = (data[0] & 0x0F) << 2 | (data[1] & 0xC0) >> 6;
  context->swim_version = data[1] & 0x3F;
  context->loader_version = data[5] << 8 | data[4];

  memset(data, 0, sizeof(data));

  data[0] = 0xF3;
  data[1] = 0x08;

  /* Write */
  res = libusb_bulk_transfer(context->usb_dev_handle,
			     EP_OUT,
			     data,
			     16,
			     &rw_bytes,
			     USB_TIMEOUT);
  if (res) {
    return -1;
  }

  /* Read */
  libusb_bulk_transfer(context->usb_dev_handle,
		       EP_IN,
		       data,
		       20,
		       &rw_bytes,
		       USB_TIMEOUT);
  if (res) {
    return -1;
  }

  memcpy(context->id, data+8, 12);

  /* Firmware encryption key generation */
  memcpy(context->firmware_key, data, 4);
  memcpy(context->firmware_key+4, data+8, 12);
  my_encrypt((unsigned char*)"I am key, wawawa", context->firmware_key, 16);

  return 0;
}

int stlinkloader_is_correct_mode(struct stlinkloadercontext *context) {
  int res;

  res = current_mode(context);

  if (res == 1) {
    return 1;
  } else if (res >= 0) {
    return 0;
  } else {
    return -1;
  }
}

uint8_t* stlinkloader_get_id(struct stlinkloadercontext *context, int *id_length) {
  if (id_length != NULL) {
    *id_length = 12;
  }
  
  return context->id;
}

uint8_t stlinkloader_get_stlink_version(struct stlinkloadercontext *context) {
  return context->stlink_version;
}

uint8_t stlinkloader_get_jtag_version(struct stlinkloadercontext *context) {
  return context->jtag_version;
}

uint8_t stlinkloader_get_swim_version(struct stlinkloadercontext *context) {
  return context->swim_version;
}
