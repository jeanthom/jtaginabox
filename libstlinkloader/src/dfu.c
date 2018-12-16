#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <libusb.h>

#include "defines.h"
#include "types.h"
#include "crypto.h"
#include "dfu.h"

static int dfu_status(struct stlinkloadercontext *context,
		      struct DFUStatus *status);
static uint16_t checksum(const unsigned char *firmware,
			 size_t len);

int current_mode(struct stlinkloadercontext *context) {
  unsigned char data[16];
  int rw_bytes, res;
  
  memset(data, 0, sizeof(data));

  data[0] = 0xF5;

  /* Write */
  res = libusb_bulk_transfer(context->usb_dev_handle,
			     EP_OUT,
			     data,
			     sizeof(data),
			     &rw_bytes,
			     USB_TIMEOUT);
  if (res) {
    return -1;
  }

  /* Read */
  libusb_bulk_transfer(context->usb_dev_handle,
		       EP_IN,
		       data,
		       2,
		       &rw_bytes,
		       USB_TIMEOUT);
  if (res) {
    return -1;
  }

  return data[0] << 8 | data[1];
}

int dfu_download(struct stlinkloadercontext *context,
		 unsigned char *data,
		 size_t data_len,
		 uint16_t wBlockNum) {
  unsigned char download_request[16];
  struct DFUStatus status;
  int rw_bytes, res;

  memset(download_request, 0, sizeof(download_request));

  download_request[0] = 0xF3;
  download_request[1] = DFU_DNLOAD;
  *(uint16_t*)(download_request+2) = wBlockNum; /* wValue */
  *(uint16_t*)(download_request+4) = checksum(data, data_len); /* wIndex */
  *(uint16_t*)(download_request+6) = data_len; /* wLength */

  if (wBlockNum >= 2) {
   my_encrypt(context->firmware_key, data, data_len);
  }

  res = libusb_bulk_transfer(context->usb_dev_handle,
			     EP_OUT,
			     download_request,
			     sizeof(download_request),
			     &rw_bytes,
			     USB_TIMEOUT);
  if (res || rw_bytes != sizeof(download_request)) {
    return -1;
  }
  
  res = libusb_bulk_transfer(context->usb_dev_handle,
			     EP_OUT,
			     data,
			     data_len,
			     &rw_bytes,
			     USB_TIMEOUT);
  if (res || rw_bytes != (int)data_len) {
    return -1;
  }

  if (dfu_status(context, &status)) {
    return -1;
  }

  if (status.bState != dfuDNBUSY) {
    return -2;
  }

  if (status.bStatus != OK) {
    return -3;
  }

  usleep(status.bwPollTimeout * 1000);

  if (dfu_status(context, &status)) {
    return -1;
  }

  if (status.bState != dfuDNLOAD_IDLE) {
    return -3;
  }

  return 0;
}

static int dfu_status(struct stlinkloadercontext *context,
		      struct DFUStatus *status) {
  unsigned char data[16];
  int rw_bytes, res;

  memset(data, 0, sizeof(data));

  data[0] = 0xF3;
  data[1] = DFU_GETSTATUS;
  data[6] = 0x06; /* wLength */

  res = libusb_bulk_transfer(context->usb_dev_handle,
			     EP_OUT,
			     data,
			     16,
			     &rw_bytes,
			     USB_TIMEOUT);
  if (res || rw_bytes != 16) {
    return -1;
  }
  res = libusb_bulk_transfer(context->usb_dev_handle,
			     EP_IN,
			     data,
			     6,
			     &rw_bytes,
			     USB_TIMEOUT);
  if (res || rw_bytes != 6) {
    return -1;
  }

  status->bStatus = data[0];
  status->bwPollTimeout = data[1] | data[2] << 8 | data[3] << 16;
  status->bState = data[4];
  status->iString = data[5];
  
  return 0;
}

static uint16_t checksum(const unsigned char *firmware,
			 size_t len) {
  unsigned int i;
  int ret = 0;

  for (i = 0; i < len; i++) {
    ret += firmware[i];
  }

  return (uint16_t)ret & 0xFFFF;
}
