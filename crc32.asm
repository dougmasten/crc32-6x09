; crc32.asm
; CRC-32 library for the Motorola 6809 and Hitachi 6309 CPU


CRC32_CPU       equ CRC32_CPU_6309
#CRC32_CPU       equ CRC32_CPU_6809
#CRC32_CPU       equ CRC32_CPU_BOTH


; Define CPU options
CRC32_CPU_6809  equ 0
CRC32_CPU_6309  equ 1
CRC32_CPU_BOTH  equ 2


  IFNDEF CRC32_CPU
CRC32_CPU       equ CRC32_CPU_6809
  ENDC

; Only include H6309 code
  IFEQ CRC32_CPU-CRC32_CPU_6309
                include crc32-6309.asm
crc32           equ crc32_6309
crc32_init      equ crc32_6309_init
crc32_update    equ crc32_6309_update
crc32_finalize  equ crc32_6309_finalize
  ENDC

; Only include M6809 code
  IFEQ CRC32_CPU-CRC32_CPU_6809
                ERROR "TODO! 6809 version not completed yet"
                include crc32-6809.asm
  ENDC

; Include both M6809 and H6309 code and select version at runtime
  IFEQ CRC32_CPU-CRC32_CPU_BOTH
                ERROR "TODO! 6809 version not completed yet"
                include crc32-6309.asm
                include crc32-6809.asm
  ENDC

; Include tables
  IFEQ CRC32_VERSION-CRC32_TABLE_16
crc32_lookup_table
    IFEQ CRC32_POLY-CRC32_IEEE
              fqb $00000000,$1db71064,$3b6e20c8,$26d930ac
              fqb $76dc4190,$6b6b51f4,$4db26158,$5005713c
              fqb $edb88320,$f00f9344,$d6d6a3e8,$cb61b38c
              fqb $9b64c2b0,$86d3d2d4,$a00ae278,$bdbdf21c
    ENDC
  ENDC

  IFEQ CRC32_VERSION-CRC32_TABLE_32
crc32_lookup_table
    IFEQ CRC32_POLY-CRC32_IEEE
; 1st table
              fqb $00000000,$77073096,$ee0e612c,$990951ba
              fqb $076dc419,$706af48f,$e963a535,$9e6495a3
              fqb $0edb8832,$79dcb8a4,$e0d5e91e,$97d2d988
              fqb $09b64c2b,$7eb17cbd,$e7b82d07,$90bf1d91
; 2nd table
              fqb $00000000,$1db71064,$3b6e20c8,$26d930ac
              fqb $76dc4190,$6b6b51f4,$4db26158,$5005713c
              fqb $edb88320,$f00f9344,$d6d6a3e8,$cb61b38c
              fqb $9b64c2b0,$86d3d2d4,$a00ae278,$bdbdf21c
    ENDC
  ENDC

  IFEQ CRC32_VERSION-CRC32_TABLE_256
crc32_lookup_table
    IFEQ CRC32_POLY-CRC32_IEEE
      include tables/crc32ieee-table.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_C
      include tables/crc32c-table.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_K
      include tables/crc32k-table.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_Q
      include tables/crc32q-table.asm
    ENDC
  ENDC

  IFDEF crc32_lookup_table
    IFEQ crc32_lookup_table-*
      ERROR "CRC32_POLY value not support"
    ENDC
  ENDC
