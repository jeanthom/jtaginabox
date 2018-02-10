#include <stdlib.h>
#include <arpa/inet.h>
#include <string.h>

#include "aes.h"
#include "crypto.h"

static void convert_to_big_endian(unsigned char *array, unsigned int length);

void encrypt(unsigned char *key, unsigned char *data, unsigned int length) {
  struct AES_ctx ctx;
  unsigned char key_be[16];
  size_t i;

  memcpy(key_be, key, 16);
  convert_to_big_endian(key_be, 16);

  AES_init_ctx(&ctx, key_be);

  convert_to_big_endian(data, length);

  for (i = 0; i < length; i += 16) {
    AES_ECB_encrypt(&ctx, data+i);
  }
  convert_to_big_endian(data, length);
}

static void convert_to_big_endian(unsigned char *array, unsigned int length) {
  unsigned int i;

  for (i = 0; i < length; i += 4) {
    *(uint32_t*)(array+i) = htonl(*(uint32_t*)(array+i));
  }
}
