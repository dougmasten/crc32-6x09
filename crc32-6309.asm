; crc32-6309.asm
; CRC-32 Library for Hitachi 6309 CPU


;CRC32_VERSION equ CRC32_FORMULAIC
;CRC32_VERSION equ CRC32_TABLE_16
;CRC32_VERSION equ CRC32_TABLE_32
;CRC32_VERSION equ CRC32_TABLE_256

;CRC32_POLY    equ CRC32_IEEE
;CRC32_POLY    equ CRC32_C
;CRC32_POLY    equ CRC32_K
;CRC32_POLY    equ CRC32_Q

; Options:
;   CRC32_VERSION   = CRC32_FORMULAIC  ; Slowest and smallest size (Default)
;                   = CRC32_TABLE_16   ;
;                   = CRC32_TABLE_32   ;
;                   = CRC32_TABLE_256  ; Fastest and biggest size
;
;   CRC32_POLY      = CRC32_IEEE       ; IEEE (Default)
;                   = CRC32_C          ; Castagnoli
;                   = CRC32_K          ; Koopman
;                   = CRC32_Q          ; Q

; Stats:
;   Version           Type              Code Len     Clock cycles (per byte)
;   ---------------   ---------------   ----------   -----------------------
;   CRC32_FORMULAIC   Formula           142 bytes    133
;   CRC32_TABLE_16    16-entry Table    182 bytes    117
;   CRC32_TABLE_32    32-entry Table    213 bytes    87
;   CRC32_TABLE_256   256-entry Table   1082 bytes   50


CRC32_IEEE    equ $edb88320       ; IEEE 802.3
CRC32_C       equ $82f63b78       ; Castagnoli
CRC32_K       equ $eb31d82e       ; Koopman
CRC32_Q       equ $d5828281       ; Q

CRC32_FORMULAIC equ 0             ; Formulaic version (Space optimization)
CRC32_TABLE_16  equ 1             ; 16-entry lookup-table
CRC32_TABLE_32  equ 2             ; 32-entry lookup-table
CRC32_TABLE_256 equ 3             ; 256-entry lookup-table (Speed optimization)

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
; Function    : crc32_6309
; Input       : Reg U = Pointer to the source data buffer
;             : Reg Y = Number of elements in the source data buffer
; Output      : Reg Q = Returns CRC32 checksum value
; Destroys    : none
; Calls       : crc32_init, crc32_update and crc32_finalize
; Description : Computes the finale CRC-32 checksum for the source data buffer
;------------------------------------------------------------------------------
crc32_6309
              bsr crc32_6309_init      ; Initialize CRC-32 starting value
              bsr crc32_6309_update    ; Calculate CRC-32 value
              ;bra crc32_finalize      ; Finalize CRC-32 value and return


;------------------------------------------------------------------------------
; Function    : crc32_6309_finalize
; Input       : Reg Q = CRC-32 checksum value
; Output      : Reg Q = Finale CRC-32 checksum value
; Destroys    : none
; Calls       : none
; Description : Finalize CRC-32 value
;------------------------------------------------------------------------------
crc32_6309_finalize
              eord #$ffff              ; xor LSW
              exg d,w                  ; exchange MSW and LSW back
              eord #$ffff              ; xor MSW
              rts                      ; return


;------------------------------------------------------------------------------
; Function    : crc32_6309_init
; Input       : none
; Output      : Reg Q = Initial CRC-32 checksum value
; Destroys    : none
; Calls       : none
; Description : Initialize CRC-32 checksum "seed" value
;------------------------------------------------------------------------------
crc32_6309_init
              ldq #$ffffffff           ; Initial value
              rts


;------------------------------------------------------------------------------
; Function    : crc32_6309_update
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
crc32_6309_shift_right MACRO
              lsrw                     ; shift to the right for bit #0        (2 cycles)
              rord                     ;  "    "   "   "                      (2 cycles)
              bcc a@                   ; branch if no 1's fell off            (3 cycles)
              eorr x,w                 ; xor polynomial                       (4 cycles)
              eord #CRC32_POLY_LSW     ;  "   "                               (4 cycles)
a@            equ *                    ;
              ENDM

crc32_6309_update
              leay ,y                  ; test if number of elements is zero
              beq ?rts                 ; if yes, then exit

              pshs x,y                 ; save registers
              ldx #CRC32_POLY_MSW      ; preload reg X with polynomial

loop@
              eorb ,u+                 ; xor CRC-32 with byte from buffer     (5 cycles)
              crc32_6309_shift_right   ; shift right by one bit               (15 cycles)
              crc32_6309_shift_right   ;  "     "    "   "   "                (15 cycles)
              crc32_6309_shift_right   ;  "     "    "   "   "                (15 cycles)
              crc32_6309_shift_right   ;  "     "    "   "   "                (15 cycles)
              crc32_6309_shift_right   ;  "     "    "   "   "                (15 cycles)
              crc32_6309_shift_right   ;  "     "    "   "   "                (15 cycles)
              crc32_6309_shift_right   ;  "     "    "   "   "                (15 cycles)
              crc32_6309_shift_right   ;  "     "    "   "   "                (15 cycles)
              leay -1,y                ; decrement buffer counter             (5 cycles)
              bne loop@                ; loop until done                      (3 cycles)
                                       ;                                      -----------
                                       ;                                TOTAL (133 cycles)

              puls x,y,pc              ; restore registers and exit

  ENDC


;------------------------------------------------------------------------------
  IFEQ CRC32_VERSION-CRC32_TABLE_16

; Table-Lookup 16-entry version
; Algorithm:
;     i = (crc ^ data) & $0f
;     crc = table[i] ^ (crc >> 4)
;     i = (crc ^ (data >> 4)) & $0f
;     crc = table[i] ^ (crc >> 4)
crc32_6309_update
              leay ,y                  ; test if number of elements is zero
              beq ?rts                 ; if yes, then exit
              pshs x,y                 ; save registers

loop@
              stb a@                   ; save Reg B (SMC)
              eorb ,u
              andb #$0f
              ldx #crc32_lookup_table
              lslb                     ; index x4
              lslb                     ;  "    "
              abx                      ;  "    "
              ldb #0                   ; restore reg B (SMC)
a@            equ *-1                  ; ** Self-Modified Code **
;
; (crc >> 4)
              lsrw                     ; shift CRC32 right by 4 bits   (2 cycles)
              rord                     ;  "     "   "     "    "       (2 cycles)
              lsrw                     ;  "     "   "     "    "       (2 cycles)
              rord                     ;  "     "   "     "    "       (2 cycles)
              lsrw                     ;  "     "   "     "    "       (2 cycles)
              rord                     ;  "     "   "     "    "       (2 cycles)
              lsrw                     ;  "     "   "     "    "       (2 cycles)
              rord                     ;  "     "   "     "    "       (2 cycles)
;
; crc = table[i] ^ (crc >> 4)
              eord 2,x
              ldx ,x
              eorr x,w
;
              stb b@                   ; save Reg B (SMC)
              ldb ,u+
              lsrb
              lsrb
              lsrb
              lsrb
              eorb b@
              andb #$0f
              ldx #crc32_lookup_table
              lslb                     ; index x4
              lslb                     ;  "    "
              abx                      ;  "    "
              ldb #0                   ; restore Reg B (SMC)
b@            equ *-1                  ; ** Self-Modified Code **
;
; (crc >> 4)
              lsrw                     ; shift CRC32 right by 4 bits   (2 cycles)
              rord                     ;  "     "   "     "    "       (2 cycles)
              lsrw                     ;  "     "   "     "    "       (2 cycles)
              rord                     ;  "     "   "     "    "       (2 cycles)
              lsrw                     ;  "     "   "     "    "       (2 cycles)
              rord                     ;  "     "   "     "    "       (2 cycles)
              lsrw                     ;  "     "   "     "    "       (2 cycles)
              rord                     ;  "     "   "     "    "       (2 cycles)
;
; crc = table[i] ^ (crc >> 4)
              eord 2,x                 ;                                (7 cycles)
              ldx ,x                   ;                                (5 cycles)
              eorr x,w                 ;                                (4 cycles)
;
              leay -1,y                ;                                (5 cycles)
              bne loop@                ;                                (3 cycles)
                                       ;                                ------------
                                       ;                         TOTAL  (117 cycles)
;
              puls x,y,pc              ; restore registers and exit


crc32_lookup_table

    IFEQ CRC32_POLY-CRC32_IEEE
              fqb $00000000,$1db71064,$3b6e20c8,$26d930ac
              fqb $76dc4190,$6b6b51f4,$4db26158,$5005713c
              fqb $edb88320,$f00f9344,$d6d6a3e8,$cb61b38c
              fqb $9b64c2b0,$86d3d2d4,$a00ae278,$bdbdf21c
    ENDC

    IFEQ crc32_lookup_table-*
      ERROR "CRC32_POLY value is not support"
    ENDC

  ENDC


;------------------------------------------------------------------------------
  IFEQ CRC32_VERSION-CRC32_TABLE_32

; Table-Lookup 32-entry (2 x 16-entry) version
; Algorithm:
;     n = crc ^ data
;     crc = table[n & $0f] ^ table[16 + ((n >> 4) & $0f)] ^ (crc >> 8)
;     https://lentz.com.au/blog/calculating-crc-with-a-tiny-32-entry-lookup-table
crc32_6309_update
              leay ,y                  ; test if number of elements is zero
              beq ?rts                 ; if yes, then exit
              pshs x,y                 ; save registers

loop@
;
; n = crc ^ data
              eorb ,u+                 ; n = crc ^ data                       (5 cycles)
              stb a@                   ; save n                               (4 cycles)
;
; table[n & $0f]
              ldx #crc32_lookup_table  ; point to table                       (3 cycles)
              andb #$0f                ; mask lower nibble                    (2 cycles)
              lslb                     ; index x4                             (1 cycle)
              lslb                     ;  "    "                              (1 cycle)
              abx                      ;  "    "                              (1 cycle)
;
; crc = crc >> 8
              tfr a,b                  ; shift CRC32 right by 8 bits          (4 cycles)
              tfr f,a                  ;  "     "     "    "  "  "            (4 cycles)
              tfr e,f                  ;  "     "     "    "  "  "            (4 cycles)
              clre                     ;  "     "     "    "  "  "            (2 cycles)
;
; crc = crc ^ table[n & $0f]
              eord 2,x                 ; xor CRC32 with lookup table          (7 cycles)
              ldx ,x                   ;  "   "     "     "     "             (5 cycles)
              eorr x,w                 ;  "   "     "     "     "             (4 cycles)
              stb b@                   ; save crc                             (4 cycles)
;
; table[16 + ((n >> 4) & $0f)]
              ldx #crc32_lookup_table+(16*4)  ;                               (3 cycles)
              ldb #0                   ; retrieve n                           (2 cycles)
a@            equ *-1                  ; ** Self-Modified Code **
              andb #$f0                ; mask upper nibble                    (2 cycles)
              lsrb                     ; index x4                             (1 cycle)
              lsrb                     ;  "    "                              (1 cycle)
              abx                      ;  "    "                              (1 cycle)
              ldb #0                   ;                                      (2 cycles)
b@            equ *-1                  ; ** Self-Modified Code **
;
; crc = crc ^ table[16 + ((n >> 4) & $0f)]
              eord 2,x                 ; xor CRC32 with lookup table          (7 cycles)
              ldx ,x                   ;  "   "     "     "     "             (5 cycles)
              eorr x,w                 ;  "   "     "     "     "             (4 cycles)
;
; loop
              leay -1,y                ;                                      (5 cycles)
              bne loop@                ; loop until done                      (3 cycles)
                                       ;                                      ----------
                                       ;                                TOTAL (87 cycles)
;
              puls x,y,pc              ; restore registers and exit


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

    IFEQ crc32_lookup_table-*
      ERROR "CRC32_POLY value is not support"
    ENDC

  ENDC


;------------------------------------------------------------------------------
  IFEQ CRC32_VERSION-CRC32_TABLE_256

; Table-lookup 256-entry version
; Algorithm: crc = table[(crc & 0xff) ^ k ] ^ (crc >> 8)
crc32_6309_update
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
;
              puls x,y,pc              ; restore registers and exit


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

    IFEQ crc32_lookup_table-*
      ERROR "CRC32_POLY value not support"
    ENDC

  ENDC

CRC32_6309_CODE_LEN equ *-crc32_6309
