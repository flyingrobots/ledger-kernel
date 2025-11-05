#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <blake3.h>

int main(void) {
  blake3_hasher hasher;
  blake3_hasher_init(&hasher);
  uint8_t buf[8192];
  size_t n;
  while ((n = fread(buf, 1, sizeof buf, stdin)) > 0) {
    blake3_hasher_update(&hasher, buf, n);
  }
  uint8_t out[32];
  blake3_hasher_finalize(&hasher, out, 32);
  for (int i=0; i<32; i++) printf("%02x", out[i]);
  printf("\n");
  return 0;
}

