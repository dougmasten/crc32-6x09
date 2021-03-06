; crc32-6309.asm
; CRC-32 Library for Hitachi 6309 CPU

; Stats:
;   Version                    Type              Code Len     Clock cycles (per byte)
;   ------------------------   ---------------   ----------   -----------------------
;   CRC32_FORMULAIC            Formula           61 bytes     200
;   CRC32_FORMULAIC_UNROLLED   Formula           142 bytes    133
;   CRC32_TABLE_16             16-entry Table    182 bytes    117
;   CRC32_TABLE_32             32-entry Table    213 bytes    87
;   CRC32_TABLE_256            256-entry Table   1082 bytes   50


; make sure library is called from crc32.asm instead of directly
              ifndef CRC32_ASM_FILE
              error "Use include crc32.asm"
              endc


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
              ;bra crc32_6309_finalize ; Finalize CRC-32 value and return


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
crc32_6309_ret
              rts


;------------------------------------------------------------------------------
; Function    : crc32_6309_update
; Input       : Req Q = Current CRC-32 value
;             : Reg U = Pointer to the source data buffer
;             : Reg Y = Number of elements in the source data buffer
; Output      : Reg Q = Updated CRC-32 value
; Destroys    : Reg V
; Calls       : none
; Description : Update CRC32 checksum with data buffer's CRC32 checksum
;------------------------------------------------------------------------------
; Note: CRC-32's MSW and LSW are switched as an speed optimization. They are
;       switched back at the end in the "crc32_finalize" routine.
crc32_6309_update
              ifndef CRC32_DISABLE_LEN_CHECK
              leay ,y                  ; test if number of elements is zero
              beq crc32_6309_ret       ; if yes, then exit
              endc

              ifndef CRC32_DISABLE_SAVE_REGS
              pshs x,y                 ; save registers
              endc

;------------------------------------------------------------------------------
              ifeq CRC32_VERSION-CRC32_FORMULAIC

; Formulaic version
              ldx #CRC32_POLY_MSW      ; preload reg V with polynomial
              tfr x,v                  ;  "       "  "  "    "

loop_a@
              eorb ,u+                 ; xor CRC-32 with byte from buffer     (5 cycles)
              ldx #8                   ; Initialize loop counter              (3 cycles)
;
loop_b@
              lsrw                     ; shift to the right for bit #0        (2 cycles)
              rord                     ;  "    "   "   "                      (2 cycles)
              bcc a@                   ; branch if no 1's fell off            (3 cycles)
              eorr v,w                 ; xor polynomial                       (4 cycles)
              eord #CRC32_POLY_LSW     ;  "   "                               (4 cycles)
a@
              leax -1,x                ;                                      (5 cycles)
              bne loop_b@              ;                                      (3 cycles)
;
              leay -1,y                ; decrement buffer counter             (5 cycles)
              bne loop_a@              ; loop until done                      (3 cycles)
                                       ;                                      -----------
                                       ;                                TOTAL (200 cycles)
              endc


;------------------------------------------------------------------------------
              ifeq CRC32_VERSION-CRC32_FORMULAIC_UNROLLED

; Unrolled Formulaic version
crc32_6309_shift_right macro
              lsrw                     ; shift to the right for bit #0        (2 cycles)
              rord                     ;  "    "   "   "                      (2 cycles)
              bcc a@                   ; branch if no 1's fell off            (3 cycles)
              eorr x,w                 ; xor polynomial                       (4 cycles)
              eord #CRC32_POLY_LSW     ;  "   "                               (4 cycles)
a@            equ *                    ;
              endm

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
              endc


;------------------------------------------------------------------------------
              ifeq CRC32_VERSION-CRC32_TABLE_16

; Table-Lookup 16-entry version
; Algorithm:
;     i = (crc ^ data) & $0f
;     crc = table[i] ^ (crc >> 4)
;     i = (crc ^ (data >> 4)) & $0f
;     crc = table[i] ^ (crc >> 4)
loop@
              stb a@                   ; save Reg B (SMC)              (4 cycles)
              eorb ,u                  ;                               (4 cycles)
              andb #$0f                ;                               (2 cycles)
              ldx #crc32_lookup_table  ;                               (3 cycles)
              lslb                     ; index x4                      (1 cycle)
              lslb                     ;  "    "                       (1 cycle)
              abx                      ;  "    "                       (1 cycle)
              ldb #0                   ; restore reg B (SMC)           (2 cycles)
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
              eord 2,x                 ;                               (7 cycles)
              ldx ,x                   ;                               (5 cycles)
              eorr x,w                 ;                               (4 cycles)
;
              stb b@                   ; save Reg B (SMC)
              ldb ,u+                  ;
              lsrb                     ;                               (1 cycle)
              lsrb                     ;                               (1 cycle)
              lsrb                     ;                               (1 cycle)
              lsrb                     ;                               (1 cycle)
              eorb b@                  ;                               (4 cycles)
              andb #$0f                ;                               (2 cycles)
              ldx #crc32_lookup_table  ;                               (3 cycles)
              lslb                     ; index x4                      (1 cycle)
              lslb                     ;  "    "                       (1 cycle)
              abx                      ;  "    "                       (1 cycle)
              ldb #0                   ; restore Reg B (SMC)           (2 cycles
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
              eord 2,x                 ;                               (7 cycles)
              ldx ,x                   ;                               (5 cycles)
              eorr x,w                 ;                               (4 cycles)
;
              leay -1,y                ;                               (5 cycles)
              bne loop@                ;                               (3 cycles)
                                       ;                               ------------
                                       ;                        TOTAL  (117 cycles)
;
              endc


;------------------------------------------------------------------------------
              ifeq CRC32_VERSION-CRC32_TABLE_32

; Table-Lookup 32-entry (2 x 16-entry) version
; Algorithm:
;     i = crc ^ data
;     crc = table[i & $0f] ^ table[16 + ((i >> 4) & $0f)] ^ (crc >> 8)
;     https://lentz.com.au/blog/calculating-crc-with-a-tiny-32-entry-lookup-table
loop@
;
; i = crc ^ data
              eorb ,u+                 ; n = crc ^ data                       (5 cycles)
              stb a@                   ; save n                               (4 cycles)
;
; table[i & $0f]
              ldx #crc32_lookup_table  ; point to first table                 (3 cycles)
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
; crc = crc ^ table[i & $0f]
              eord 2,x                 ; xor CRC32 with lookup table          (7 cycles)
              ldx ,x                   ;  "   "     "     "     "             (5 cycles)
              eorr x,w                 ;  "   "     "     "     "             (4 cycles)
              stb b@                   ; save crc                             (4 cycles)
;
; table[16 + ((i >> 4) & $0f)]
              ldx #crc32_lookup_table+(16*4)  ; point to second table         (3 cycles)
              ldb #0                   ; retrieve n                           (2 cycles)
a@            equ *-1                  ; ** Self-Modified Code **
              andb #$f0                ; mask upper nibble                    (2 cycles)
              lsrb                     ; index x4                             (1 cycle)
              lsrb                     ;  "    "                              (1 cycle)
              abx                      ;  "    "                              (1 cycle)
              ldb #0                   ;                                      (2 cycles)
b@            equ *-1                  ; ** Self-Modified Code **
;
; crc = crc ^ table[16 + ((i >> 4) & $0f)]
              eord 2,x                 ; xor CRC32 with lookup table          (7 cycles)
              ldx ,x                   ;  "   "     "     "     "             (5 cycles)
              eorr x,w                 ;  "   "     "     "     "             (4 cycles)
;
              leay -1,y                ;                                      (5 cycles)
              bne loop@                ; loop until done                      (3 cycles)
                                       ;                                      ----------
                                       ;                                TOTAL (87 cycles)
;
              endc


;------------------------------------------------------------------------------
              ifeq CRC32_VERSION-CRC32_TABLE_256

; Table-lookup 256-entry version
; Algorithm: crc = table[(crc & 0xff) ^ k ] ^ (crc >> 8)
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
              leay -1,y                ; decrement counter                    (5 cycles)
              bne loop@                ; loop until done                      (3 cycles)
                                       ;                                      -----------
                                       ;                               TOTAL  (50 cycles)
;
              endc

              ifndef CRC32_DISABLE_SAVE_REGS
              puls x,y,pc              ; restore registers and exit
              else
              rts
              endc
