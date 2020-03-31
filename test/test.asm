; test.asm

; CPU version
;CRC32_CPU       equ CRC32_CPU_6809              ; Code for Motorola 6809 CPU only (Default)
CRC32_CPU       equ CRC32_CPU_6309              ; Code for Hitachi 6309 CPU only
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

;CRC32_ZERO_LEN_CHECK equ 0                      ; no length check
;CRC32_ZERO_LEN_CHECK equ 1                      ; include code to check length

        org $2600

; include CRC-32 library
        include ../crc32.asm


; test value
  IFEQ CRC32_POLY-CRC32_IEEE
TEST_CHKSUM      equ $519025e9
  ENDC

  IFEQ CRC32_POLY-CRC32_C
TEST_CHKSUM      equ $190097b3
  ENDC

  IFEQ CRC32_POLY-CRC32_K
TEST_CHKSUM      equ $1ced0906
  ENDC

  IFEQ CRC32_POLY-CRC32_Q
TEST_CHKSUM      equ $147c1e06
  ENDC

TEST_CHKSUM_MSW  equ (((TEST_CHKSUM&$FFFF0000)/$10000)&$FFFF)
TEST_CHKSUM_LSW  equ (TEST_CHKSUM&$FFFF)


; test CRC-32 library
start
        clr $6f           ; select screen for device #
        clr $ff40         ; turn off disk drive motor

        ldu #test_string
        ldy #test_string_len
        jsr crc32

        ldx #error        ; default to bad checksum
        cmpd #TEST_CHKSUM_MSW
        bne bad_checksum
        cmpw #TEST_CHKSUM_LSW
        bne bad_checksum
        ldx #ok           ; checksum is correct
bad_checksum

; print string
print
        lda ,x+
        beq halt
        jsr [$a002]       ; print char
        bra print

halt    bra halt


ok      fcn "OK: CRC-32 CHECKSUM IS CORRECT."
error   fcn "ERROR: CRC-32 CHECKSUM IS INCORRECT!"


test_string
        fcc "The quick brown fox jumps over the lazy dog."
test_string_len equ *-test_string


; autoexec
        org $176
        jmp start
