; Elite C64 disassembly / Elite : Harmless, cc-by-nc-sa 2018-2020,
; see LICENSE.txt. "Elite" is copyright / trademark David Braben & Ian Bell,
; All Rights Reserved. <github.com/Kroc/elite-harmless>
;===============================================================================
; $12: mamba
;-------------------------------------------------------------------------------
hull_index           .set hull_index + 1
hull_mamba_index       := hull_index

.segment        "HULL_TABLE"                                            ;$D000..
;===============================================================================
        .addr   hull_mamba                                              ;$D022/3

.segment        "HULL_D042"                                             ;$D042..
;===============================================================================
        .byte   $8c                                                     ;$D053

.segment        "HULL_D063"                                             ;$D063..
;===============================================================================
        .byte   $80                                                     ;$D074

.segment        "HULL_D084"                                             ;$D084..
;===============================================================================
        .byte   $00                                                     ;$D095

.segment        "HULL_DATA"                                             ;$D0A5..
;===============================================================================
.proc   hull_mamba                                                      ;$DF8D
        ;-----------------------------------------------------------------------
        .byte                            $01, $24, $13                  ;$DF8D
        .byte   $aa, $1a, $61, $00, $22, $96, $1c, $96                  ;$DF90
        .byte   $00, $14, $19, $5a, $1e, $00, $01, $02
        .byte   $12, $00, $00, $40, $1f, $10, $32, $40                  ;$DFA0
        .byte   $08, $20, $ff, $20, $44, $20, $08, $20
        .byte   $be, $21, $44, $20, $08, $20, $3e, $31                  ;$DFB0
        .byte   $44, $40, $08, $20, $7f, $30, $44, $04
        .byte   $04, $10, $8e, $11, $11, $04, $04, $10                  ;$DFC0
        .byte   $0e, $11, $11, $08, $03, $1c, $0d, $11
        .byte   $11, $08, $03, $1c, $8d, $11, $11, $14                  ;$DFD0
        .byte   $04, $10, $d4, $00, $00, $14, $04, $10
        .byte   $54, $00, $00, $18, $07, $14, $f4, $00                  ;$DFE0
        .byte   $00, $10, $07, $14, $f0, $00, $00, $10
        .byte   $07, $14, $70, $00, $00, $18, $07, $14                  ;$DFF0
        .byte   $74, $00, $00, $08, $04, $20, $ad, $44
        .byte   $44, $08, $04, $20, $2d, $44, $44, $08                  ;$E000
        .byte   $04, $20, $6e, $44, $44, $08, $04, $20
        .byte   $ee, $44, $44, $20, $04, $20, $a7, $44                  ;$E010
        .byte   $44, $20, $04, $20, $27, $44, $44, $24
        .byte   $04, $20, $67, $44, $44, $24, $04, $20                  ;$E020
        .byte   $e7, $44, $44, $26, $00, $20, $a5, $44
        .byte   $44, $26, $00, $20, $25, $44, $44, $1f                  ;$E030
        .byte   $20, $00, $04, $1f, $30, $00, $10, $1f
        .byte   $40, $04, $10, $1e, $42, $04, $08, $1e                  ;$E040
        .byte   $41, $08, $0c, $1e, $43, $0c, $10, $0e
        .byte   $11, $14, $18, $0c, $11, $18, $1c, $0d                  ;$E050
        .byte   $11, $1c, $20, $0c, $11, $14, $20, $14
        .byte   $00, $24, $2c, $10, $00, $24, $30, $10                  ;$E060
        .byte   $00, $28, $34, $14, $00, $28, $38, $0e
        .byte   $00, $34, $38, $0e, $00, $2c, $30, $0d                  ;$E070
        .byte   $44, $3c, $40, $0e, $44, $44, $48, $0c
        .byte   $44, $3c, $48, $0c, $44, $40, $44, $07                  ;$E080
        .byte   $44, $50, $54, $05, $44, $50, $60, $05
        .byte   $44, $54, $60, $07, $44, $4c, $58, $05                  ;$E090
        .byte   $44, $4c, $5c, $05, $44, $58, $5c, $1e
        .byte   $21, $00, $08, $1e, $31, $00, $0c, $5e                  ;$E0A0
        .byte   $00, $18, $02, $1e, $00, $18, $02, $9e
        .byte   $20, $40, $10, $1e, $20, $40, $10, $3e                  ;$E0B0
        .byte   $00, $00, $7f

.endproc