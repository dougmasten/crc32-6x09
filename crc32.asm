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