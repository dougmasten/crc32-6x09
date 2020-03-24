; crc32-6309.asm
; CRC-32 Library for Hitachi 6309 CPU


;CRC32_VERSION equ CRC32_FORMULAIC
CRC32_VERSION equ CRC32_TABLE_256

;CRC32_POLY    equ CRC32_IEEE
;CRC32_POLY    equ CRC32_C
;CRC32_POLY    equ CRC32_K
;CRC32_POLY    equ CRC32_Q

; Options:
;   CRC32_VERSION   = CRC32_FORMULAIC  ; Formulaic version (Default)
;                   = CRC32_TABLE_256  ; Table-Lookup version (1024 bytes)
;
;   CRC32_POLY      = CRC32_IEEE  ; IEEE (Default)
;                   = CRC32_C     ; Castagnoli
;                   = CRC32_K     ; Koopman
;                   = CRC32_Q     ; Q


CRC32_IEEE    equ $edb88320       ; IEEE 802.3 (Standard used by Ethernet and zip, gzip, etc.)
CRC32_C       equ $82f63b78       ; Castagnoli
CRC32_K       equ $eb31d82e       ; Koopman
CRC32_Q       equ $d5828281       ; Q

CRC32_FORMULAIC equ 0             ; Use formulaic version for space optimization
CRC32_TABLE_256 equ 1             ; Use lookup-table for speed optimization

  IFNDEF CRC32_VERSION
CRC32_VERSION equ CRC32_FORMULAIC
  ENDC

  IFNDEF CRC32_POLY
CRC32_POLY equ CRC32_IEEE   ; default to IEEE 802.3
  ENDC

CRC32_POLY_MSW equ (((CRC32_POLY&$FFFF0000)/$10000)&$FFFF)
CRC32_POLY_LSW equ (CRC32_POLY&$FFFF)


; LWASM assembler options
              opt 6309
              opt qrts


;------------------------------------------------------------------------------
; Function    : crc32
; Input       : Reg U = Pointer to the source data buffer
;             : Reg Y = Number of elements in the source data buffer
; Output      : Reg Q = Returns CRC32 checksum value
; Destroys    : none
; Calls       : crc32_init, crc32_update and crc32_finalize
; Description : Computes the finale CRC-32 checksum for the source data buffer
;------------------------------------------------------------------------------
crc32
              bsr crc32_init           ; Initialize CRC-32 starting value
              bsr crc32_update         ; Calculate CRC-32 value
              ;bra crc32_finalize      ; Finalize CRC-32 value and return


;------------------------------------------------------------------------------
; Function    : crc32_finalize
; Input       : Reg Q = CRC-32 checksum value
; Output      : Reg Q = Finale CRC-32 checksum value
; Destroys    : none
; Calls       : none
; Description : Finalize CRC-32 value
;------------------------------------------------------------------------------
crc32_finalize
               eord #$ffff              ; xor LSW
               exg d,w                  ; exchange MSW and LSW back
               eord #$ffff              ; xor MSW
               rts                      ; return


;------------------------------------------------------------------------------
; Function    : crc32_init
; Input       : none
; Output      : Reg Q = Initial CRC-32 checksum value
; Destroys    : none
; Calls       : none
; Description : Initialize CRC-32 checksum "seed" value
;------------------------------------------------------------------------------
crc32_init
              ldq #$ffffffff           ; Initial value
              rts


;------------------------------------------------------------------------------
; Function    : crc32_update
; Input       : Req Q = Current CRC-32 value
;             : Reg U = Pointer to the source data buffer
;             : Reg Y = Number of elements in the source data buffer
; Output      : Reg Q = Updated CRC-32 value
; Destroys    : none
; Calls       : none
; Description : Update CRC32 checksum with data buffer's CRC32 checksum
;------------------------------------------------------------------------------
; Note: CRC-32's MSW and LSW are switched as an speed optimization. They are
;       switched back at the end in the "crc32_finalize" routine.

  IFEQ CRC32_VERSION-CRC32_FORMULAIC

; Formulaic version
crc32_shift_right MACRO
              lsrw                     ; shift to the right for bit #0
              rord                     ;  "    "   "   "
              bcc a@                   ; branch if no 1's fell off
              eorr x,w                 ; xor polynomial
              eord #CRC32_POLY_LSW     ;  "   "
a@            equ *                    ;
              ENDM

crc32_update
              leay ,y                  ; test if number of elements is zero
              beq ?rts                 ; if yes, then exit

              pshs x,y                 ; save registers
              ldx #CRC32_POLY_MSW      ; preload reg X with polynomial

loop@
              eorb ,u+                 ; xor CRC-32 with byte from buffer
              crc32_shift_right        ; shift right by one bit
              crc32_shift_right        ;  "     "    "   "   "
              crc32_shift_right        ;  "     "    "   "   "
              crc32_shift_right        ;  "     "    "   "   "
              crc32_shift_right        ;  "     "    "   "   "
              crc32_shift_right        ;  "     "    "   "   "
              crc32_shift_right        ;  "     "    "   "   "
              crc32_shift_right        ;  "     "    "   "   "
              leay -1,y                ; decrement buffer counter
              bne loop@                ; (Loop takes 133 clock cycles)

              puls x,y,pc              ; restore registers and exit

  ENDC

  IFEQ CRC32_VERSION-CRC32_TABLE_256

; Table-lookup version
; Algorithm: crc = table[(crc & 0xff) ^ k ] ^ (crc >> 8)
crc32_update
              leay ,y                  ; test if number of elements is zero
              beq ?rts                 ; if yes, then exit
              pshs x,y                 ; save registers

loop@
; i = (crc & 0xff) ^ k
              eorb ,u+                 ; xor CRC32 with source data buffer    (5 cycles)
              ldx #crc32_lookup_table  ; retrieve lookup table address        (3 cycles)
              abx                      ; index x4                             (1 cycle)
              abx                      ;  "    "                              (1 cycle)
              abx                      ;  "    "                              (1 cycle)
              abx                      ;  "    "                              (1 cycle)
;
; crc = crc >> 8
              tfr a,b                  ; shift CRC32 right by 8 bits          (4 cycles)
              tfr f,a                  ;  "     "     "    "  "  "            (4 cycles)
              tfr e,f                  ;  "     "     "    "  "  "            (4 cycles)
              clre                     ;  "     "     "    "  "  "            (2 cycles)
;
; crc = crc ^ table[i]
              eord 2,x                 ; xor CRC32 with lookup table          (7 cycles)
              ldx ,x                   ;  "   "     "     "     "             (5 cycles)
              eorr x,w                 ;  "   "     "     "     "             (4 cycles)
;
              leay -1,y                ;                                      (5 cycles)
              bne loop@                ;                                      (3 cycles)
                                       ;                                      -----------
                                       ;                               TOTAL  (50 cycles)

              puls x,y,pc              ; restore registers and exit

  ENDC


  IFEQ CRC32_VERSION-CRC32_TABLE_256
crc32_lookup_table equ *
    IFEQ CRC32_POLY-CRC32_IEEE
      include crc32ieee-table.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_C
      include crc32c-table.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_K
      include crc32k-table.asm
    ENDC

    IFEQ CRC32_POLY-CRC32_Q
      include crc32q-table.asm
    ENDC

    IFEQ crc32_lookup_table-*
      ERROR "CRC-32 include tables does not support CRC32_POLY value"
    ENDC
  ENDC
