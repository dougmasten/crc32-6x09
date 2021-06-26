; crc32.asm
; CRC-32 library for the Motorola 6809 and Hitachi 6309 CPU


; Library options

; CPU version
;CRC32_CPU       equ CRC32_CPU_6809              ; Code for Motorola 6809 CPU only (Default)
;CRC32_CPU       equ CRC32_CPU_6309              ; Code for Hitachi 6309 CPU only
;CRC32_CPU       equ CRC32_CPU_BOTH              ; At runtime detects CPU and uses that CPU code

; Method version
;CRC32_VERSION   equ CRC32_FORMULAIC             ; Slowest and smallest size (Default)
;CRC32_VERSION   equ CRC32_FORMULAIC_UNROLLED    ;
;CRC32_VERSION   equ CRC32_TABLE_16              ;
;CRC32_VERSION   equ CRC32_TABLE_32              ;
;CRC32_VERSION   equ CRC32_TABLE_256             ; Fastest and biggest code size

; Polynomial
;CRC32_POLY      equ CRC32_IEEE                  ; IEEE (Default)
;CRC32_POLY      equ CRC32_C                     ; Castagnoli
;CRC32_POLY      equ CRC32_K                     ; Koopman
;CRC32_POLY      equ CRC32_Q                     ; Q


;------------------------------------------------------------------------------
CRC32_ASM_FILE  equ 1  ; flag to mark libary as called from crc32.asm


; Define CPU options
CRC32_CPU_6809  equ 0               ; Motorola 6809
CRC32_CPU_6309  equ 1               ; Hitachi 6309
CRC32_CPU_BOTH  equ 2               ; Include both versions and detect CPU at runtime

CRC32_FORMULAIC equ 0               ; Formulaic version (Space optimization)
CRC32_FORMULAIC_UNROLLED equ 1      ; Unrolled Formulaic version
CRC32_TABLE_16  equ 2               ; 16-entry lookup-table
CRC32_TABLE_32  equ 3               ; 32-entry lookup-table
CRC32_TABLE_256 equ 4               ; 256-entry lookup-table (Speed optimization)

CRC32_IEEE      equ $edb88320       ; IEEE 802.3
CRC32_C         equ $82f63b78       ; Castagnoli
CRC32_K         equ $eb31d82e       ; Koopman
CRC32_Q         equ $d5828281       ; Q

                ifndef CRC32_CPU
CRC32_CPU       equ CRC32_CPU_6809  ; default to M6809 CPU
                endc

                ifndef CRC32_VERSION
CRC32_VERSION   equ CRC32_FORMULAIC ; default to formulaic
                endc

                ifndef CRC32_POLY
CRC32_POLY      equ CRC32_IEEE      ; default to IEEE 802.3
                endc


CRC32_POLY_MSW  equ (((CRC32_POLY&$FFFF0000)/$10000)&$FFFF)
CRC32_POLY_LSW  equ (CRC32_POLY&$FFFF)


; Only include H6309 code
                ifeq CRC32_CPU-CRC32_CPU_6309
                include crc32-6309.asm
crc32           equ crc32_6309
crc32_init      equ crc32_6309_init
crc32_update    equ crc32_6309_update
crc32_finalize  equ crc32_6309_finalize
                endc


; Only include M6809 code
                ifeq CRC32_CPU-CRC32_CPU_6809
                error "TODO! 6809 version not completed yet"
                include crc32-6809.asm
                endc

; Include both M6809 and H6309 code and select version at runtime
                ifeq CRC32_CPU-CRC32_CPU_BOTH
                error "TODO! 6809 version not completed yet"
                include crc32-6309.asm
                include crc32-6809.asm
                endc


; Include lookup tables
                include tables/crc32-tables.asm
