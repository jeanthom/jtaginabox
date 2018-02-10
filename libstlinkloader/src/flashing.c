#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h> 
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <libusb.h>
#include <stlinkloader.h>

#include "defines.h"
#include "types.h"
#include "dfu.h"

static int set_address(struct stlinkloadercontext *context,
		       uint32_t address) {
  unsigned char set_address_command[5];
  int res;

  set_address_command[0] = SET_ADDRESS_POINTER_COMMAND;
  set_address_command[1] = address & 0xFF;
  set_address_command[2] = (address >> 8) & 0xFF;
  set_address_command[3] = (address >> 16) & 0xFF;
  set_address_command[4] = (address >> 24) & 0xFF;

  res = dfu_download(context,
		     set_address_command,
		     sizeof(set_address_command), 0);
  return res;
}

static int erase(struct stlinkloadercontext *context,
		 uint32_t address) {
  unsigned char erase_command[5];
  int res;

  erase_command[0] = ERASE_COMMAND;
  erase_command[1] = address & 0xFF;
  erase_command[2] = (address >> 8) & 0xFF;
  erase_command[3] = (address >> 16) & 0xFF;
  erase_command[4] = (address >> 24) & 0xFF;

  res = dfu_download(context,
		     erase_command,
		     sizeof(erase_command), 0);
  
  return res;
}

int stlinkloader_flash(struct stlinkloadercontext *context,
		       const char *filename,
		       unsigned int base_offset,
		       unsigned int chunk_size,
		       progress_func progress_callback,
		       gpointer user_data) {
  unsigned char *firmware, firmware_chunk[chunk_size];
  unsigned int cur_chunk_size, flashed_bytes, file_size;
  int fd, res;
  struct stat firmware_stat;

  fd = open(filename, O_RDONLY);
  if (fd == -1) {
    return -1;
  }
  
  fstat(fd, &firmware_stat);

  file_size = firmware_stat.st_size;

  firmware = mmap(NULL, file_size, PROT_WRITE, MAP_PRIVATE, fd, 0);
  if (firmware == MAP_FAILED) {
    close(fd);
    return -1;
  }

  flashed_bytes = 0;

  while (flashed_bytes < file_size) {
    if ((flashed_bytes+chunk_size) > file_size) {
      cur_chunk_size = file_size - flashed_bytes;
    } else {
      cur_chunk_size = chunk_size;
    }

    res = erase(context, base_offset+flashed_bytes);
    if (res) {
      munmap(firmware, file_size);
      close(fd);
      return -2;
    }
    
    res = set_address(context, base_offset+flashed_bytes);
    if (res) {
      munmap(firmware, file_size);
      close(fd);
      return -3;
    }

    memcpy(firmware_chunk, firmware+flashed_bytes, cur_chunk_size);
    memset(firmware_chunk+cur_chunk_size, 0, chunk_size-cur_chunk_size);
    res = dfu_download(context, firmware_chunk, cur_chunk_size, 2);
    if (res) {
      munmap(firmware, file_size);
      close(fd);
      return res;
    }

    flashed_bytes += cur_chunk_size;

    progress_callback((double)flashed_bytes/(double)file_size, user_data);
  }

  munmap(firmware, file_size);
  close(fd);

  return 0;
}
