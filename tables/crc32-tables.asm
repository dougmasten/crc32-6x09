; crc32-tables.asm


  IFEQ CRC32_VERSION-CRC32_TABLE_16
crc32_lookup_table
    IFEQ CRC32_POLY-CRC32_IEEE
      include crc32ieee-table16.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_C
      include crc32c-table16.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_K
      include crc32k-table16.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_Q
      include crc32q-table16.asm
    ENDC
  ENDC


  IFEQ CRC32_VERSION-CRC32_TABLE_32
crc32_lookup_table
    IFEQ CRC32_POLY-CRC32_IEEE
      include crc32ieee-table32.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_C
      include crc32c-table32.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_K
      include crc32k-table32.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_Q
      include crc32q-table32.asm
    ENDC

  ENDC


  IFEQ CRC32_VERSION-CRC32_TABLE_256
crc32_lookup_table
    IFEQ CRC32_POLY-CRC32_IEEE
      include crc32ieee-table256.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_C
      include crc32c-table256.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_K
      include crc32k-table256.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_Q
      include tables/crc32q-table256.asm
    ENDC
  ENDC

  IFDEF crc32_lookup_table
    IFEQ crc32_lookup_table-*
      ERROR "CRC32_POLY value not support"
    ENDC
  ENDC
