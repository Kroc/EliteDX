; Elite C64 disassembly / Elite : Harmless, cc-by-nc-sa 2018-2019,
; see LICENSE.txt. "Elite" is copyright / trademark David Braben & Ian Bell,
; All Rights Reserved. <github.com/Kroc/elite-harmless>
;===============================================================================

.include        "elite.inc"

.include        "vars_zeropage.asm"
.include        "text/text_docked_fns.asm"
.include        "math.inc"
.include        "math_3d.inc"

; from "text_flight.asm"
.import table_sin:absolute
.import _0ae0:absolute

; from "text_docked.asm"
.import _0e00:absolute
.import _1a27:absolute
.import _1a41:absolute

; from "vars_user.asm"
.import _1d06:absolute
.import _1d07:absolute
.import _1d09:absolute

; from "code_6A00.asm"
.import _6a00:absolute
.import set_cursor_col:absolute
.import set_cursor_row:absolute
.import cursor_down:absolute
.import _6a2f:absolute
.import randomize:absolute
.import _6a9b:absolute
.import _6f82:absolute
.import _70a0:absolute
.import _70ab:absolute
.import _745a:absolute
.import _7481:absolute
.import _76e9:absolute
.import print_flight_token_and_newline:absolute
.import print_flight_token:absolute
.import _7b61:absolute
.import _7b64:absolute
.import _7b6f:absolute
.import _7bd2:absolute
.import _7c24:absolute
.import _7c6b:absolute
.import _7d0c:absolute
.import _7d0e:absolute
.import _805e:absolute
.import wipe_sun:absolute
.import _81ee:absolute
.import set_memory_layout:absolute
.import _829a:absolute
.import _83df:absolute
.import clear_zp_polyobj:absolute
.import get_random_number:absolute
.import _872f:absolute
.import _877e:absolute
.import _87a4:absolute
.import _87a6:absolute
.import _87b1:absolute
.import _87d0:absolute
.import _88e7:absolute
.import txt_docked_token1A:absolute
.import txt_docked_token_mediaCurrent:absolute
.import txt_docked_token_mediaOther:absolute
.import _8c7b:absolute
.import _8c8a:absolute
.import _8cad:absolute
.import key_bomb:absolute
.import key_accelerate:absolute
.import key_escape_pod:absolute
.import key_decelerate:absolute
.import key_docking_off:absolute
.import key_missile_fire:absolute
.import key_jump:absolute
.import key_missile_disarm:absolute
.import joy_down:absolute
.import key_missile_target:absolute
.import key_docking_on:absolute
.import key_ecm:absolute
.import joy_fire:absolute
.import get_input:absolute
.import do_quickjump:absolute
.import _900d:absolute
.import _9204:absolute
.import _923b:absolute

.import table_log:absolute
.import table_logdiv:absolute
.import _9500:absolute
.import _9600:absolute
.import row_to_bitmap_lo:absolute
.import row_to_bitmap_hi:absolute

.import _9978:absolute
.import _99af:absolute
.import _9a2c:absolute
.import _9a86:absolute
.import _9d8e:absolute
.import _9db3:absolute
.import _9dee:absolute
.import _9e27:absolute
.import _a013:absolute
.import _a2a0:absolute
.import move_polyobj_x:absolute
.import _a626:absolute
.import set_page:absolute
.import _a7a6:absolute
.import _a786:absolute
.import _a795:absolute
.import _a7e9:absolute
.import _a80f:absolute
.import _a813:absolute
.import _a839:absolute
.import _a858:absolute
.import _a8e0:absolute
.import _a8e6:absolute
.import draw_line:absolute
.import draw_straight_line:absolute
.import _b0f4:absolute
.import _b11f:absolute
.import wait_for_frame:absolute
.import paint_newline:absolute
.import paint_char:absolute
.import txt_docked_token15:absolute
.import _b410:absolute

; from "hull_data.asm"
.import hull_pointers
.import hull_d042

.segment        "CODE_1D81"

;===============================================================================
; I think this is when the player has docked,
; it checks for potential mission offers
;
_1d81:                                                                  ;$1D81
        jsr _83df
        jsr _379e

        ; now the player is docked, some variables can be reset
        ; -- the cabin temperature is not reset; oversight / bug?
        lda # $00
        sta PLAYER_SPEED        ; bring player's ship to a full stop
        sta PLAYER_TEMP_LASER   ; complete laser cooldown
        sta ZP_66               ; reset hyperspace countdown

        ; set shields to maximum,
        ; restore energy:
        lda # $ff
        sta PLAYER_SHIELD_FRONT
        sta PLAYER_SHIELD_REAR
        sta PLAYER_ENERGY

        ldy # 44                ; wait 44 frames
        jsr wait_frames         ; -- why would this be necessary?

        ; if the galaxy is not using the original Elite seed, then the missions
        ; will not function as they rely on specific planet name / placement
        ;
.ifndef OPTION_CUSTOMSEED
        ;///////////////////////////////////////////////////////////////////////

        ; check eligibility for the Constrictor mission:
        ;-----------------------------------------------------------------------
        ; available on the first galaxy after 256 or more kills. your job is
        ; to hunt down the prototype Constrictor ship starting at Reesdice
        ;
        ; is the mission already underway or complete?
        lda MISSION_FLAGS
        and # missions::constrictor
       .bnz :+                  ; mission is underway/complete, ignore it

        lda PLAYER_KILLS
        beq @skip               ; ignore mission if kills less than 256

        ; is the player in the first galaxy?
        ;
        lda PLAYER_GALAXY       ; if bit 0 is set, shifting right will cause
        lsr                     ; it to fall off the end, leaving zero;
       .bnz @skip               ; if not first galaxy, ignore mission

        ; start the Constrictor mission
        jmp _3dff

        ; is the mission complete? (both bits set)
:       cmp # missions::constrictor                                     ;$1DB5
       .bnz :+

        ; you've docked at a station, set up the 'tip' that will display in
        ; the planet info for where to find the Constrictor next
        jmp _3daf

:       ; check eligibility for Thargoid Blueprints mission             ;$1DBC
        ;-----------------------------------------------------------------------
        ; once you've met the criteria for this mission (3rd galaxy, have
        ; completed the Constrictor mission, >=1280 kills) you're presented
        ; with a message to fly to Ceerdi. Once there, you're given some
        ; top-secret blueprints which you have to get to Birera
        ;
        ; is the player in the third galaxy?
        lda PLAYER_GALAXY
        cmp # 2
        bne @skip               ; no; ignore mission

        ; player is in the third galaxy; has the player completed the
        ; Constrictor mission already? (and hasn't started blueprints mission)
        lda MISSION_FLAGS
        and # missions::constrictor | missions::blueprints
        cmp # missions::constrictor_complete
        bne :+

        ; has the player at least 1280 kills? (halfway to Deadly)
        lda PLAYER_KILLS
        cmp #> 1280
       .blt @skip               ; no; skip ahead if not enough

        ; 'start' the mission: the player has to fly
        ; to Ceerdi to actually get the blueprints
        jmp mission_blueprints_begin

:       ; has the player started the blueprints mission?                ;$1DD6
        ; (and by association, completed the Constrictor mission)
        cmp # missions::constrictor_complete | missions::blueprints_begin
        bne :+

        ; is the player at Ceerdi?
        ;SPEED: couldn't we use the planet index number
        ;       instead of checking co-ordinates?

        lda PSYSTEM_POS_X
        cmp # 215
        bne @skip

        lda PSYSTEM_POS_Y
        cmp # 84
        bne @skip

        jmp mission_blueprints_ceerdi

:       cmp # %00001010                                                 ;$1DEB
        bne @skip

        ; is the player at Birera?
        ;SPEED: couldn't we use the planet index number
        ;       instead of checking co-ordinates?

        lda PSYSTEM_POS_X
        cmp # 63
        bne @skip

        lda PSYSTEM_POS_Y
        cmp # 72
        bne @skip

        jmp mission_blueprints_birera

.endif  ;///////////////////////////////////////////////////////////////////////

@skip:  ; check for Trumbles™ mission                                   ;$1E00
        ;
.ifndef OPTION_NOTRUMBLES
        ;///////////////////////////////////////////////////////////////////////

        ; at least 6'553.5 cash?
        lda PLAYER_CASH_pt3
        cmp # $c4               ;TODO: not sure how this works out as 6'553.5?
       .blt :+

        ; has the mission already been done?
        lda MISSION_FLAGS
        and # missions::trumbles
        bne :+

        ; initiate Trumbles™ mission
        jmp mission_trumbles

.endif  ;///////////////////////////////////////////////////////////////////////

:       jmp _88e7                                                       ;$1E11

; the unused and incomplete debug code can be removed
; in non-original builds
;
.ifdef  OPTION_ORIGINAL
;///////////////////////////////////////////////////////////////////////////////
debug_for_brk:                                                          ;$1E14
        ;=======================================================================
        ; set a routine to capture use of the `brk` instruction.
        ; not actually used, but present, in original Elite
        ;
.import debug_brk:absolute

        lda #< debug_brk
        sei                     ; disable interrupts
        sta KERNAL_VECTOR_BRK+0
        lda #> debug_brk
        sta KERNAL_VECTOR_BRK+1
        cli                     ; enable interrupts

        rts

;///////////////////////////////////////////////////////////////////////////////
.endif

;===============================================================================
; Trumble™ A.I. data?
;
trumble_steps:                                                          ;$1E21
        ; movement steps; "0, 1, -1, 0"
        .byte   $00, $01, $ff, $00
_1e25:                                                                  ;$1E25
        .byte   $00, $00, $ff, $00

; masks for sprite MSBs?
_1e29:                                                                  ;$1E29
        .byte   %11111011, %00000100
        .byte   %11110111, %00001000
        .byte   %11101111, %00010000
        .byte   %11011111, %00100000
        .byte   %10111111, %01000000
        .byte   %01111111, %10000000

_1e35:
        ;-----------------------------------------------------------------------
        ; move Trumbles™ around the screen
        ;
        lda ZP_A3               ; "move counter"?
        and # %00000111         ; modulo 8 (0-7)
        cmp TRUMBLES_ONSCREEN   ; number of Trumble™ sprites on-screen
       .blt :+

        jmp _1ece

        ; take the counter 0-7 and multiply by 2
        ; for use in a table of 16-bit values later
:       asl                                                             ;$1E41
        tay

.ifdef  OPTION_ORIGINAL
        ;///////////////////////////////////////////////////////////////////////
        ; turn the I/O area on to manage the sprites
        lda # C64_MEM::IO_ONLY
        jsr set_memory_layout
.else   ;///////////////////////////////////////////////////////////////////////
        ; optimisation for changing the memory map,
        ; with thanks to: <http://www.c64os.com/post?p=83>
        inc CPU_CONTROL
.endif  ;///////////////////////////////////////////////////////////////////////

        ; should the Trumbles™ change direction?
        ;
        jsr get_random_number   ; select a random number
        cmp # 235               ; is it > 234 (about 8% probability)
       .blt @move               ; no, just keep moving

        ; pick a direction for the Trumble™
        ;
        ; select an X direction:
        ; 50% chance stay still, 25% go left, 25% go right
        and # %00000011         ; random number modulo 4 (0-3)
        tax                     ; choice 1-4
        lda trumble_steps, x    ; pick a direction, i.e. 0, 1 or -1
        sta TRUMBLES_MOVE_X, y  ; set the Trumble™'s X direction

        lda _1e25, x
        sta VAR_0521, y

        ; select a Y direction:
        ; 50% chance stay still, 25% go up, 25% go down
        jsr get_random_number   ; pick a new random number
        and # %00000011         ; modulo 4 (0-3)
        tax                     ; choice 1-4
        lda trumble_steps, x    ; pick a direction, i.e. 0, 1 or -1
        sta TRUMBLES_MOVE_Y, y  ; set the Trumble™'s Y direction

@move:                                                                  ;$1E6A
        lda _1e29, y
        and VIC_SPRITES_X
        sta VIC_SPRITES_X

        ; move the Trumble™ sprite vertically
        lda VIC_SPRITE2_Y, y
        clc
        adc TRUMBLES_MOVE_Y, y
        sta VIC_SPRITE2_Y, y

        ; move the Trumble™ sprite horizontally
        clc
        lda VIC_SPRITE2_X, y
        adc TRUMBLES_MOVE_X, y
        sta ZP_VAR_T

        lda VAR_0531, y
        adc VAR_0521, y
        bpl :+

        lda # $48               ;=72 / %01001000
        sta ZP_VAR_T

        lda # $01
:       and # %00000001                                                 ;$1E94
        beq _1ea4

        lda ZP_VAR_T
        cmp # $50               ;=80 / %10000000
        lda # $01
        bcc _1ea4

        lda # $00
        sta ZP_VAR_T
_1ea4:                                                                  ;$1EA4
        sta VAR_0531, y
        beq _1eb3

        ; MSBs?
        lda _1e29+1, y
        ora VIC_SPRITES_X
        sei                     ; disable interrupts whilst repositioning
        sta VIC_SPRITES_X
_1eb3:                                                                  ;$1EB3
        lda ZP_VAR_T
        sta VIC_SPRITE2_X, y
        cli                     ; re-enable interrupts

.ifdef  OPTION_ORIGINAL
        ;///////////////////////////////////////////////////////////////////////
        ; turn I/O off, go back to 64K RAM
        lda # C64_MEM::ALL
        jsr set_memory_layout
.else   ;///////////////////////////////////////////////////////////////////////
        ; optimisation for changing the memory map,
        ; with thanks to: <http://www.c64os.com/post?p=83>
        dec CPU_CONTROL
.endif  ;///////////////////////////////////////////////////////////////////////

        jmp _1ece

_1ec1:                                                                  ;$1EC1
;===============================================================================
; main cockpit-view game-play loop perhaps?
; (handles many key presses)
;
.export _1ec1

.import POLYOBJ_00

        lda POLYOBJ_00          ;=$F900?
        sta ZP_GOATSOUP_pt1     ;? randomize?

.ifndef OPTION_NOTRUMBLES
        ;///////////////////////////////////////////////////////////////////////

        ; are there any Trumbles™ on-screen?
        lda TRUMBLES_ONSCREEN   ; number of Trumble™ sprites on-screen
       .bze _1ece               ; =0; don't process Trumbles™

        ; process Trumbles™
        ; (move them about, breed them)
        jmp _1e35

.endif  ;///////////////////////////////////////////////////////////////////////

_1ece:                                                                  ;$1ECE
        ;-----------------------------------------------------------------------
        ldx VAR_048D
        jsr _3c58
        jsr _3c58

        txa
        eor # %10000000         ; flip the sign bit
        tay                     ; put aside
        and # %10000000         ; strip down to just the sign bit
        sta ZP_ROLL_SIGN        ; store as our "direction of roll"

        stx VAR_048D            ; X-dampen?
        eor # %10000000
        sta ZP_6A               ; move count?

        tya
        bpl :+

        ; negate
        eor # %11111111
        clc
        adc # $01

:       lsr                                                             ;$1EEE
        lsr
        cmp # $08
        bcs :+
        lsr

:       sta ZP_ROLL_MAGNITUDE                                           ;$1EF5
        ora ZP_ROLL_SIGN        ; add sign
        sta ZP_ALPHA            ; put aside for use in the matrix math

        ;-----------------------------------------------------------------------

        ldx VAR_048E
        jsr _3c58

        txa
        eor # %10000000
        tay
        and # %10000000
        stx VAR_048E
        sta ZP_95
        eor # %10000000
        sta ZP_PITCH_SIGN
        tya
        bpl _1f15
        eor # %11111111
_1f15:                                                                  ;$1F15
        adc # $04
        lsr
        lsr
        lsr
        lsr
        cmp # $03
        bcs _1f20
        lsr
_1f20:                                                                  ;$1F20
        ; get the player ship's pitch;
        ; stored as separate sign & magnitude
        ;
        sta ZP_PITCH_MAGNITUDE
        ora ZP_PITCH_SIGN
        sta ZP_BETA             ; put aside for the matrix math

        ; accelerate?
        ;-----------------------------------------------------------------------
        lda key_accelerate      ; is accelerate being held?
       .bze :+                  ; if not, continue

        lda PLAYER_SPEED        ; current speed
        cmp # $28               ; are we at maximum speed?
        bcs :+

        inc PLAYER_SPEED        ; increase player's speed

:       ; decelerate?                                                   ;$1F33
        ;-----------------------------------------------------------------------
        lda key_decelerate      ; is decelerate being held?
       .bze :+                  ; if not, continue

        dec PLAYER_SPEED        ; reduce player's speed
       .bnz :+                  ; still above zero?
        inc PLAYER_SPEED        ; if zero, set to 1?

        ; disarm missile?
        ;-----------------------------------------------------------------------
:       lda key_missile_disarm  ; is disarm missile key being pressed?  ;$1F3E
        and PLAYER_MISSILES     ; does the player have any missiles?
       .bze :+                  ; no? skip ahead

        ldy # $57
        jsr _7d0c
        ldy # $06
        jsr _a858

        lda # $00               ; set loaded missile as disarmed ($00)
        sta PLAYER_MISSILE_ARMED

:       lda ZP_MISSILE_TARGET                                           ;$1F55
        bpl :+

        ; target missile?
        ;-----------------------------------------------------------------------
        lda key_missile_target  ; target missile key pressed?
       .bze :+

        ldx PLAYER_MISSILES     ; does the player have any missiles?
       .bze :+

        ; set missile armed flag on
        ; (A = $FF from `key_missile_target`)
        sta PLAYER_MISSILE_ARMED

        ldy # $87
        jsr _b11f

        ; fire missile?
        ;-----------------------------------------------------------------------
:       lda key_missile_fire    ; fire missile key held?                ;$1F6B
       .bze :+                  ; no, skip ahead

        lda ZP_MISSILE_TARGET
        bmi _1fc2
        jsr _36a6

        ; energy bomb?
        ;-----------------------------------------------------------------------
:       lda key_bomb            ; energy bomb key held?                 ;$1F77
       .bze :+

        asl PLAYER_EBOMB        ; does player have an energy bomb?
        beq :+                  ; no? keep going

        ldy # $d0
        sty _a8e0

        ldy # $0d
        jsr _a858               ; handle e-bomb?

        ; turn docking computer off?
        ;-----------------------------------------------------------------------
:       lda key_docking_off     ; docking-computer off pressed?         ;$1F8B
       .bze :+                  ; no? skip ahead

        lda # $00               ; $00 = OFF
        sta DOCKCOM_STATE       ; turn docking computer off

        jsr _923b

        ; activate escape pod?
        ;-----------------------------------------------------------------------
:       lda key_escape_pod      ; escape pod key pressed?               ;$1F98
        and PLAYER_ESCAPEPOD    ; does the player have an escape pod?
       .bze :+                  ; no? keep moving

        lda IS_WITCHSPACE       ; is the player stuck in witchspace?
       .bnz :+                  ; yes...

        jmp eject_escapepod     ; no: eject escpae pod

        ; quick-jump?
        ;-----------------------------------------------------------------------
:       lda key_jump            ; quick-jump key pressed?               ;$1FA8
       .bze :+                  ; no? skip ahead

        jsr do_quickjump        ; handle the quick-jump

        ; activate E.C.M.?
        ;-----------------------------------------------------------------------
:       lda key_ecm             ; E.C.M. key pressed?                   ;$1FB0
        and PLAYER_ECM          ; does the player have an E.C.M.?
        beq _1fc2

        lda ZP_67
        bne _1fc2

        dec VAR_0481
        jsr _b0f4

_1fc2:  ; turn docking computer on?                                     ;$1FC2
        ;-----------------------------------------------------------------------
        lda key_docking_on      ; key for docking computers pressed?
        and PLAYER_DOCKCOM      ; does the player have a docking computer?
       .bze :+                  ; no, skip
        eor joy_down            ; stops ship climbing, but why?
       .bze :+
        sta DOCKCOM_STATE       ; turn docking computer on (A = $FF)

        jsr _9204               ; handle docking computer behaviour?

:       lda # $00                                                       ;$1FD5
        sta ZP_7B
        sta ZP_97

        lda PLAYER_SPEED
        lsr
        ror ZP_97
        lsr
        ror ZP_97
        sta ZP_98

        lda VAR_0487
        bne _202d

        lda joy_fire
        beq _202d

        lda PLAYER_TEMP_LASER
        cmp # $f2
        bcs _202d

        ldx VAR_0486
        lda PLAYER_LASERS, x
        beq _202d

        pha
        and # %01111111
        sta ZP_7B
        sta VAR_0484

        ldy # $00
        pla
        pha
        bmi _2014
        cmp # $32
        bne _2012
        ldy # $0c
_2012:                                                                  ;$2012
        bne _201d
_2014:                                                                  ;$2014
        cmp # $97
        beq _201b
        ldy # $0a

        ; this causes the next instruction to become a meaningless `bit`
        ; instruction, a very handy way of skipping without branching
       .bit
_201b:                                                                  ;$201B
        ldy # $0b
_201d:                                                                  ;$201D
        jsr _a858
        jsr shoot_lasers
        pla
        bpl _2028
        lda # $00
_2028:                                                                  ;$2028
        and # %11111010
        sta VAR_0487
_202d:                                                                  ;$202D
        ldx # $00
_202f:                                                                  ;$202F
.export _202f
        stx ZP_9D

        lda SHIP_SLOTS, x
        bne _2039

        jmp _21fa

        ;-----------------------------------------------------------------------

_2039:                                                                  ;$2039
        sta ZP_A5               ; put ship type aside
        jsr get_polyobj

        ; copy the given PolyObject to the zero page:
        ; ($09..$2D)
        ;
        ldy # .sizeof(PolyObject) - 1
:       lda [ZP_POLYOBJ_ADDR], y                                        ;$2040
        sta ZP_POLYOBJ, y
        dey
        bpl :-

        lda ZP_A5               ; get ship type back
        bmi @skip               ; if sun / planet, skip over

        asl
        tay
        lda hull_pointers - 2, y
        sta ZP_HULL_ADDR_LO
        lda hull_pointers - 1, y
        sta ZP_HULL_ADDR_HI

        lda PLAYER_EBOMB        ; player has energy bomb?
        bpl @skip

.import hull_coreolis_index:direct
.import hull_thargoid_index:direct
.import hull_constrictor_index:direct

        ; space station?
        cpy # hull_coreolis_index *2
        beq @skip

        ; thargoid?
        cpy # hull_thargoid_index *2
        beq @skip

        ; constrictor?
        cpy # hull_constrictor_index *2
        bcs @skip

        lda ZP_POLYOBJ_VISIBILITY
        and # visibility::display
        bne @skip

        asl ZP_POLYOBJ_VISIBILITY
        sec
        ror ZP_POLYOBJ_VISIBILITY

        ldx ZP_A5
        jsr _a7a6

@skip:  jsr _a2a0                                                       ;$2079

        ; copy the zero-page PolyObject back to its storage

        ldy # .sizeof(PolyObject) - 1
:       lda ZP_POLYOBJ, y                                               ;$207E
        sta [ZP_POLYOBJ_ADDR], y
        dey
        bpl :-

        lda ZP_POLYOBJ_VISIBILITY
        and # visibility::exploding | visibility::display
        jsr _87b1
        bne _20e0

        lda ZP_POLYOBJ_XPOS_LO
        ora ZP_POLYOBJ_YPOS_LO
        ora ZP_POLYOBJ_ZPOS_LO
        bmi _20e0

        ldx ZP_A5
        bmi _20e0

        cpx # $02
        beq _20e3

        and # %11000000
        bne _20e0

        cpx # $01
        beq _20e0
        lda VAR_04C2
        and ZP_POLYOBJ_YPOS_HI  ;=$0E
        bpl _2122
        cpx # $05
        beq _20c0

        ldy # Hull::_00         ;=$00: "scoop / debris"?
        lda [ZP_HULL_ADDR], y
        lsr
        lsr
        lsr
        lsr
        beq _2122
        adc # $01
        bne _20c5
_20c0:                                                                  ;$20C0
        jsr get_random_number
        and # %00000111
_20c5:                                                                  ;$20C5
        jsr _6a00               ; count cargo?
        ldy # $4e
        bcs _2110

        ldy VAR_04EF            ; item index?
        adc VAR_CARGO, y
        sta VAR_CARGO, y
        tya
        adc # $d0
        jsr _900d

        asl ZP_POLYOBJ_BEHAVIOUR
        sec
        ror ZP_POLYOBJ_BEHAVIOUR
_20e0:                                                                  ;$20E0
        jmp _2131

        ;-----------------------------------------------------------------------

_20e3:                                                                  ;$20E3
        lda POLYOBJ_01 + PolyObject::behaviour                         ;=$F949
        and # behaviour::angry
        bne _2107

        lda ZP_POLYOBJ_M0x2_HI
        cmp # $d6
        bcc _2107
        jsr _8c7b
        lda ZP_VAR_X2
        cmp # $59
        bcc _2107
        lda ZP_POLYOBJ_M1x0_HI
        and # %01111111
        cmp # $50
        bcc _2107
_2101:                                                                  ;$2101
        jsr _923b
        jmp _1d81

        ;-----------------------------------------------------------------------

_2107:                                                                  ;$2107
        lda PLAYER_SPEED
        cmp # $05
        bcc _211a
        jmp _87d0

        ;-----------------------------------------------------------------------

_2110:                                                                  ;$2110
        jsr _a813

        ; set top-bit of visibility state?
        asl ZP_POLYOBJ_VISIBILITY
        sec
        ror ZP_POLYOBJ_VISIBILITY
        bne _2131
_211a:                                                                  ;$211A
        lda # $01
        sta PLAYER_SPEED
        lda # $05
        bne _212b
_2122:                                                                  ;$2122
        asl ZP_POLYOBJ_VISIBILITY
        sec
        ror ZP_POLYOBJ_VISIBILITY
        lda ZP_POLYOBJ_ENERGY
        sec
        ror
_212b:                                                                  ;$212B
        jsr _7bd2
        jsr _a813
_2131:                                                                  ;$2131
        lda ZP_POLYOBJ_BEHAVIOUR
        bpl _2138
        jsr _b410
_2138:                                                                  ;$2138
        ; are we in the cockpit-view?
        lda ZP_SCREEN
        bne _21ab

        jsr _a626
        jsr _363f
        bcc _21a8

        lda PLAYER_MISSILE_ARMED
        beq _2153

        jsr _a80f
        ldx ZP_9D
        ldy # $27
        jsr _7d0e
_2153:                                                                  ;$2153
        lda ZP_7B
        beq _21a8
        ldx # $0f
        jsr _a7e9
        lda ZP_A5
        cmp # $02
        beq _21a3
        cmp # $1f
        bcc _2170
        lda ZP_7B
        cmp # $17
        bne _21a3
        lsr ZP_7B
        lsr ZP_7B
_2170:                                                                  ;$2170
        lda ZP_POLYOBJ_ENERGY
        sec
        sbc ZP_7B
        bcs _21a1

        asl ZP_POLYOBJ_VISIBILITY
        sec
        ror ZP_POLYOBJ_VISIBILITY

        lda ZP_A5
        cmp # $07
        bne _2192
        lda ZP_7B
        cmp # $32
        bne _2192
        jsr get_random_number
        ldx # $08
        and # %00000011
        jsr _2359
_2192:                                                                  ;$2192
        ldy # $04
        jsr _234c
        ldy # $05
        jsr _234c

        ldx ZP_A5
        jsr _a7a6
_21a1:                                                                  ;$21A1
        sta ZP_POLYOBJ_ENERGY
_21a3:                                                                  ;$21A3
        lda ZP_A5
        jsr _36c5
_21a8:                                                                  ;$21A8
        jsr _9a86
_21ab:                                                                  ;$21AB
        ldy # PolyObject::energy
        lda ZP_POLYOBJ_ENERGY
        sta [ZP_POLYOBJ_ADDR], y

        lda ZP_POLYOBJ_BEHAVIOUR
        bmi _21e2

        lda ZP_POLYOBJ_VISIBILITY
        bpl _21e5               ; bit 7 set?

        and # visibility::display
        beq _21e5

        lda ZP_POLYOBJ_BEHAVIOUR
        and # behaviour::police
        ora PLAYER_LEGAL
        sta PLAYER_LEGAL
        lda VAR_048B
        ora IS_WITCHSPACE
        bne _21e2

        ldy # Hull::bounty      ;=$0A: (bounty lo-byte)
        lda [ZP_HULL_ADDR], y
        beq _21e2

        tax
        iny                     ;=$0B: (bounty hi-byte)
        lda [ZP_HULL_ADDR], y
        tay
        jsr _7481
        lda # $00
        jsr _900d
_21e2:                                                                  ;$21E2
        jmp _829a

        ;-----------------------------------------------------------------------

_21e5:                                                                  ;$21E5
        lda ZP_A5
        bmi _21ee
        jsr _87a4
        bcc _21e2
_21ee:                                                                  ;$21EE
        ldy # PolyObject::visibility
        lda ZP_POLYOBJ_VISIBILITY
        sta [ZP_POLYOBJ_ADDR], y

        ldx ZP_9D
        inx
        jmp _202f

        ;-----------------------------------------------------------------------

_21fa:                                                                  ;$21FA
        lda PLAYER_EBOMB        ; player has energy bomb?
        bpl _2207
        asl PLAYER_EBOMB        ; player has energy bomb?
        bmi _2207
        jsr _2367
_2207:                                                                  ;$2207
        lda ZP_A3               ; move counter?
        and # %00000111
        bne _227a

        ldx PLAYER_ENERGY
        bpl _2224

        ldx PLAYER_SHIELD_REAR
        jsr _7b61
        stx PLAYER_SHIELD_REAR

        ldx PLAYER_SHIELD_FRONT
        jsr _7b61
        stx PLAYER_SHIELD_FRONT
_2224:                                                                  ;$2224
        sec
        lda VAR_04C4            ; energy charge rate?
        adc PLAYER_ENERGY
        bcs _2230
        sta PLAYER_ENERGY
_2230:                                                                  ;$2230
        lda IS_WITCHSPACE
        bne _2277

        lda ZP_A3               ; move counter?
        and # %00011111
        bne _2283

        lda VAR_045F
        bne _2277

        tay
        jsr _2c50
        bne _2277

        ; copy some of the PolyObject data to zeropage:
        ;
        ; the X/Y/Z position of the PolyObject
        ; (these are not addresses, but they are 24-bit)
        ;
        ; $09-$0B:      xpos            .faraddr
        ; $0C-$0E:      ypos            .faraddr
        ; $0F-$11:      zpos            .faraddr
        ;
        ; a 3x3 rotation matrix?
        ;
        ; $12-$13:      m0x0            .word
        ; $14-$15:      m0x1            .word
        ; $16-$17:      m0x2            .word
        ; $18-$19:      m1x0            .word
        ; $1A-$1B:      m1x1            .word
        ; $1C-$1D:      m1x2            .word
        ; $1E-$1F:      m2x0            .word
        ; $20-$21:      m2x1            .word
        ; $22-$23:      m2x2            .word
        ;
        ; a pointer to already processed vertex data
        ;
        ; $24-$25:      vertexData      .addr

        ; number of bytes to copy:
        ; (up to, and including, the `vertexData` property)
        ldx # PolyObject::vertexData + .sizeof(PolyObject::vertexData) - 1

        ;?
:       lda POLYOBJ_00, x       ;=$F900                                 ;$2248
        sta ZP_POLYOBJ, x       ;=$09
        dex
        bpl :-

        inx
        ldy # $09
        jsr _2c2d
        bne _2277

        ldx # $03
        ldy # $0b
        jsr _2c2d
        bne _2277
        ldx # $06
        ldy # $0d
        jsr _2c2d
        bne _2277
        lda # $c0
        jsr _87a6
        bcc _2277

        jsr wipe_sun
        jsr _7c24
_2277:                                                                  ;$2277
        jmp _231c

        ;-----------------------------------------------------------------------

_227a:                                                                  ;$227A
        lda IS_WITCHSPACE
        bne _2277

        lda ZP_A3               ; move counter?
        and # %00011111
_2283:                                                                  ;$2283
        cmp # $0a
        bne _22b5
        lda # $32
        cmp PLAYER_ENERGY
        bcc _2292
        asl
        jsr _900d
_2292:                                                                  ;$2292
        ldy # $ff
        sty VAR_06F3
        iny
        jsr _2c4e
        bne _231c
        jsr _2c5c
        bcs _231c
        sbc # $24
        bcc _22b2
        sta ZP_VAR_R
        jsr _9978
        lda ZP_VAR_Q
        sta VAR_06F3
        bne _231c
_22b2:                                                                  ;$22B2
        jmp _87d0

        ;-----------------------------------------------------------------------

_22b5:                                                                  ;$22B5
        cmp # $0f
        bne _22c2

        lda DOCKCOM_STATE
       .bze _231c

        lda # $7b
        bne _2319
_22c2:                                                                  ;$22C2
        cmp # $14
        bne _231c

        lda # $1e
        sta PLAYER_TEMP_CABIN

        lda VAR_045F
        bne _231c

        ldy # .sizeof(PolyObject)
        jsr _2c50
       .bnz _231c

        jsr _2c5c

        eor # %11111111
        adc # $1e
        sta PLAYER_TEMP_CABIN
        bcs _22b2
        cmp # $e0
        bcc _231c
        cmp # $f0
        bcc _2303

.ifdef  OPTION_ORIGINAL
        ;///////////////////////////////////////////////////////////////////////
        ; turn the I/O area on to manage the sprites
        lda # C64_MEM::IO_ONLY
        jsr set_memory_layout
.else   ;///////////////////////////////////////////////////////////////////////
        ; optimisation for changing the memory map,
        ; with thanks to: <http://www.c64os.com/post?p=83>
        inc CPU_CONTROL
.endif  ;///////////////////////////////////////////////////////////////////////

        lda VIC_SPRITE_ENABLE
        and # %00000011
        sta VIC_SPRITE_ENABLE

.ifdef  OPTION_ORIGINAL
        ;///////////////////////////////////////////////////////////////////////
        ; turn off I/O, go back to 64K RAM
        lda # C64_MEM::ALL
        jsr set_memory_layout
.else   ;///////////////////////////////////////////////////////////////////////
        ; optimisation for changing the memory map,
        ; with thanks to: <http://www.c64os.com/post?p=83>
        dec CPU_CONTROL
.endif  ;///////////////////////////////////////////////////////////////////////

.ifndef OPTION_NOTRUMBLES
        ;///////////////////////////////////////////////////////////////////////
        ; halve the number of Trumbles™
        lsr PLAYER_TRUMBLES_HI
        ror PLAYER_TRUMBLES_LO
.endif  ;///////////////////////////////////////////////////////////////////////

_2303:                                                                  ;$2303
        lda VAR_04C2
        beq _231c

        lda ZP_98
        lsr
        adc PLAYER_FUEL
        cmp # $46
        bcc _2314
        lda # $46
_2314:                                                                  ;$2314
        sta PLAYER_FUEL

        lda # $a0
_2319:                                                                  ;$2319
        jsr _900d
_231c:                                                                  ;$231C
        lda VAR_0484
        beq _2330
        lda VAR_0487
        cmp # $08
        bcs _2330
        jsr _3cfa
        lda # $00
        sta VAR_0484
_2330:                                                                  ;$2330
        lda VAR_0481
        beq _233a

        jsr _7b64
        beq _2342
_233a:                                                                  ;$233A
        lda ZP_67
        beq _2345
        dec ZP_67
        bne _2345
_2342:                                                                  ;$2342
        jsr _a786
_2345:                                                                  ;$2345
        ; are we in the cockpit-view?
        lda ZP_SCREEN
        bne _2366

        jmp _2a32

;===============================================================================

_234c:                                                                  ;$234C
        jsr get_random_number
        bpl _2366

        tya
        tax
        ldy # Hull::_00         ;=$00: "scoop / debris"?
        and [ZP_HULL_ADDR], y
        and # %00001111
_2359:                                                                  ;$2359
        sta ZP_AA
        beq _2366
_235d:                                                                  ;$235D
        lda # $00
        jsr _370a
        dec ZP_AA
        bne _235d
_2366:                                                                  ;$2366
        rts

_2367:                                                                  ;$2367
;===============================================================================
.export _2367

        lda # $c0
        sta _a8e0

        lda # $00
        sta _a8e6

        rts

;===============================================================================
; insert these docked token functions from "text_docked_fns.asm"
;
.txt_docked_token1B                                                     ;$2372
.txt_docked_token1C                                                     ;$2376


_237e:                                                                  ;$237E
        ;=======================================================================
        ; print a message from the message table at `_1a5c` rather than the
        ; standard one (`_0e00`)
        ;
        ; push the current state:
        pha
        tax
       .phy                     ; push Y to stack (via A)
        lda ZP_TEMP_ADDR3_LO
        pha
        lda ZP_TEMP_ADDR3_HI
        pha

        ; switch base-address of the message pool and jump into the print
        ; routine using this new address. note that in this case, X is the
        ; message-index to print
.import _1a5c

        lda # < _1a5c
        sta ZP_TEMP_ADDR3_LO
        lda # > _1a5c
        bne _23a0


print_docked_str:                                                       ;$2390
;===============================================================================
; prints one of the strings from "text_docked.asm"
;
;       A = index of string to print
;
; preserves A, Y & $5B/$5C
; (due to recursion)
;
.export print_docked_str

        pha                     ; preserve A (message index)
        tax                     ; move message index to X

        ; when recursing, $5B/$5C+Y represent the
        ; current position in the message data
       .phy                     ; push Y to stack (via A)
        lda ZP_TEMP_ADDR3_LO
        pha
        lda ZP_TEMP_ADDR3_HI
        pha

        ; load the message table
        lda #< _0e00
        sta ZP_TEMP_ADDR3_LO
        lda #> _0e00
_23a0:                                                                  ;$23A0
        sta ZP_TEMP_ADDR3_HI
        ldy # $00

@skip_str:                                                              ;$23A4
        ;-----------------------------------------------------------------------
        ; skip over the messages until we find the one we want:
        ; -- this is insane!
        ;
.import TXT_DOCKED_XOR:direct

        lda [ZP_TEMP_ADDR3], y
        eor # TXT_DOCKED_XOR    ;=$57 -- descramble token
        bne :+                  ; keep going if not a message terminator ($00)
        dex                     ; message has ended, decrement index
        beq @read_token         ; if we've found our message, exit loop
:       iny                     ; move to next token                    ;$23AD
        bne @skip_str           ; if we haven't crossed the page, keep going
        inc ZP_TEMP_ADDR3_HI    ; move to the next page (256 bytes)
        bne @skip_str           ; and continue

@read_token:                                                            ;$23B4
        ;-----------------------------------------------------------------------
        iny                     ; step over the terminator byte ($00)
        bne :+                  ; did we step over the page boundary?
        inc ZP_TEMP_ADDR3_HI    ; if so, move forward to next page

:       ; read and descramble a token:                                  ;$23B9
        ;
        ; tokens: (descrambled)
        ;     $00 = invalid
        ; $01-$1F = format token, function varies
        ; $20-$40 = print ASCII chars $20-$40 (space, punctuation, numbers)
        ; $41-$5A = print ASCII characters @, A-Z
        ; $5B-$80 = planet description tokens
        ; $81-$D6 = ?
        ; $D7-$FF = some pre-defined character pairs ("text_pairs.asm")
        ;
        lda [ZP_TEMP_ADDR3], y  ; read a token
        eor # TXT_DOCKED_XOR    ;=$57 -- descramble token
        beq @rts                ; has message ended? (token $00)

        jsr print_docked_token
        jmp @read_token

@rts:   ; finished printing, clean up and exit                          ;$23C5
        ;-----------------------------------------------------------------------
        pla
        sta ZP_TEMP_ADDR3_HI
        pla
        sta ZP_TEMP_ADDR3_LO
        pla
        tay
        pla

        rts

print_docked_token:                                                     ;$23CF
        ;=======================================================================
        cmp # ' '               ; tokens less than $20 (space)
       .blt _format_code        ; are format codes

        bit txt_flight_flag     ; if flight string mode is off,
        bpl :+                  ; skip the next bit

       ; save state before we recurse
        tax
       .phy                     ; push Y to stack (via A)
        lda ZP_TEMP_ADDR3_LO
        pha
        lda ZP_TEMP_ADDR3_HI
        pha
        txa

        ; print from the commonly shared 'flight' strings
        jsr print_flight_token

        jmp _2438

:                                                                       ;$23E8
        ;-----------------------------------------------------------------------
        cmp # 'z'+1             ; letters "A" to "Z"?
       .blt _2404               ; print letters, handling auto-casing

        cmp # $81               ; tokens $5B...$80?
       .blt _2441               ; handle planet description tokens

        cmp # $d7               ; tokens $81...$D6 are expansions,
       .blt print_docked_str    ; use the token as a message index

        ; tokens $D7 and above:
        ; (character pairs)

.import txt_docked_pair1
.import txt_docked_pair2

        sbc # $d7               ; re-index as $00...$28
        asl                     ; double, for lookup-table
        pha                     ; (put aside)
        tax                     ; use as index to table
        lda txt_docked_pair1, x ; read 1st character and print it

        jsr _2404

        pla                     ; get the offset again
        tax
        lda txt_docked_pair2, x ; read 2nd character and print it

_2404:  ; print a character                                             ;$2404
        ;-----------------------------------------------------------------------

        ; print the punctuation characters ($20...$40), as is

        cmp # '@'+1
       .blt @print

        ; shall we change the letter case?

        ; check for the upper-case flag: -- note that this will have no effect
        ; if the upper-case mask is not set or if the lower-case mask is set
        ; which takes precedence

        bit txt_ucase_flag      ; check if bit 7 is set
        bmi @ucase              ; if so, skip ahead

        ; check for the lower-case flag: -- this will only have an effect if
        ; the lower-case mask is set to remove bit 5

        bit txt_lcase_flag      ; check if bit 7 is set
        bmi @lcase              ; if so, skip ahead

@ucase: ora txt_ucase_mask      ; upper case (if enabled)               ;$2412

@lcase: and txt_lcase_mask      ; lower-case (if enabled)               ;$2415

@print: jmp print_char                                                  ;$2418


_format_code:                                                           ;$241B
        ;=======================================================================
        ; tokens $00..$1F are format codes, each has a different behaviour:
        ;
        ;    $00 = invalid
        ;    $01 = ?
        ;    $02 = ?
        ;    $03 = ?
        ;    $04 = ?
        ;    $05 = ?
        ;    $06 = ?
        ;    $07 = ?
        ;    $08 = ?
        ;    $09 = ?
        ;    $0A = ?
        ;    $0B = ?
        ;    $0C = ?
        ;    $0D = ?
        ;    $0E = ?
        ;    $0F = ?
        ;    $10 = ?
        ;    $11 = ?
        ;    $12 = ?
        ;    $13 = set lower-case
        ;    $14 = ?
        ;    $15 = ?
        ;    $16 = ?
        ;    $17 = ?
        ;    $18 = ?
        ;    $19 = ?
        ;    $1A = ?
        ;    $1B = ?
        ;    $1C = ?
        ;    $1D = ?
        ;    $1E = ?
        ;    $1F = ?

        ; snapshot current state:
        ; -- these format codes can get recursive
        tax
       .phy                     ; push Y to stack (via A)
        lda ZP_TEMP_ADDR3_LO
        pha
        lda ZP_TEMP_ADDR3_HI
        pha

        ; multiply token by two
        ; (lookup into table)
        txa
        asl
        tax

        ; note that the lookup table is indexed two-bytes early, making an
        ; index of zero land in some code -- this is why token $00 is invalid
        ;
        ; we read an address from the table and rewrite a `jsr` instruction
        ; further down, i.e. the token is a lookup to a routine to call
.import txt_docked_functions

        lda txt_docked_functions - 2, x
        sta @jsr + 1
        lda txt_docked_functions - 1, x
        sta @jsr + 2

        ; convert the token back to its original value
        ; (to be used as a parameter for whatever we jump to)
        txa
        lsr

        ; NOTE: this address gets overwritten by the code above!!
@jsr:   jsr print_char                                                  ;$2435

_2438:  ; restore state and exit                                        ;$2438
        ;-----------------------------------------------------------------------
        pla
        sta ZP_TEMP_ADDR3_HI
        pla
        sta ZP_TEMP_ADDR3_LO
        pla
        tay
        rts

_2441:  ; process msg tokens $5B..$80                                   ;$2441
        ;-----------------------------------------------------------------------
        sta ZP_TEMP_ADDR1_LO    ; put token aside

        ; put aside our current location in the text data
       .phy                     ; push Y to stack (via A)
        lda ZP_TEMP_ADDR3_LO
        pha
        lda ZP_TEMP_ADDR3_HI
        pha

        ; choose planet description template 0-4:

        jsr get_random_number
        tax
        lda # $00               ; select description template 0
        cpx # $33               ; is random number over $33?
        adc # $00               ; select description template 1
        cpx # $66               ; is random number over $66?
        adc # $00               ; select description template 2
        cpx # $99               ; is random number over $99?
        adc # $00               ; select description template 3
        cpx # $cc               ; is random number over $CC? note that if so,
                                ; carry is set, to be added later

.import _3eac

        ; get back the token value and lookup another message index to print
        ; (since these tokens are $5B..$80, we index the table back $5B bytes)
        ldx ZP_TEMP_ADDR1_LO
        adc _3eac - $5B, x

        jsr print_docked_str    ; print the new message

        jmp _2438               ; clean up and exit

;===============================================================================
; insert these docked token functions from "text_docked_fns.asm"
;
.txt_docked_token01_02                                                  ;$246A
.txt_docked_token08                                                     ;$2478
.txt_docked_token09                                                     ;$2483
.txt_docked_token0D                                                     ;$248B
.txt_docked_token06_05                                                  ;$2496
.txt_docked_token0E_0F                                                  ;$24A3
.txt_docked_token11                                                     ;$24B0
.txt_docked_token12                                                     ;$24CE
.txt_docked_token_set_lowercase                                         ;$24ED

is_vowel:                                                               ;$24F3
        ;=======================================================================
        ora # %00100000
        cmp # $61               ; 'A'?
        beq :+
        cmp # $65               ; 'E'?
        beq :+
        cmp # $69               ; 'I'?
        beq :+
        cmp # $6f               ; 'O'?
        beq :+
        cmp # $75               ; 'U'?
        beq :+

        clc
:       rts                                                             ;$250A

.ifdef  OPTION_ORIGINAL
;///////////////////////////////////////////////////////////////////////////////
_250b:  rts                                                             ;$250B
;///////////////////////////////////////////////////////////////////////////////
.endif

;===============================================================================
.segment        "DATA_SAVE"

; file-name?

_25a6:                                                                  ;$25A6
.export _25a6
        .byte   $3a, $30, $2e,$45                       ;":0.E"?

; 85 bytes here get copied by `_88f0` to $0490..$04E4

_25aa:                                                                  ;$25AA
.export _25aa
        .byte   $2e                                     ;"."?

; save data; length might be 97 bytes
;
_25ab:                                                                  ;$25AB
.export _25ab
        .byte   $6a, $61, $6d, $65, $73, $6f, $6e       ;"jameson"?
_25b2:                                                                  ;$25B2
.export _25b2
        .byte   $0d

.proc   _25b3                                                           ;$25B3
;-------------------------------------------------------------------------------

        .byte   $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $10, $0f, $11
        .byte   $00, $03, $1c, $0e, $00, $00, $0a, $00
        .byte   $11, $3a, $07, $09, $08, $00, $00, $00
        .byte   $00, $80

; checksum?

_25fd:                                                                  ;$25FD
        .byte   $00
_25fe:                                                                  ;$25FE
        .byte   $00
_25ff:                                                                  ;$25FF
        .byte   $00
.endproc

.export _25b3
.export _25fd   := _25b3::_25fd
.export _25fe   := _25b3::_25fe
.export _25ff   := _25b3::_25ff

;-------------------------------------------------------------------------------

.segment        "DATA_2600"

;$2600: unreferenced / unused data?

        .byte   $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00, $00, $00, $00, $00
        .byte   $00, $00, $00, $00

        .byte   $3a, $30, $2e  ;":0.E."?
        .byte   $45, $2e

; dummy/default save-data. this gets copied over the 'current'
; save data during game initialisation. length: 97 bytes
;
_2619:                                                                  ;$2619
.export _2619
        ; commander name
        .byte   $4a ,$41, $4d, $45, $53, $4f, $4e, $0d  ;"JAMESON"
        .byte   $00 ,$14, $ad

        ; galaxy seed -- see "elite.inc"
        .word   ELITE_SEED

        .dbyt   0, 1000         ; cash?
        .byte   $46             ; fuel?
        .byte   $00             ; unused?
        .byte   $00             ; number of current galaxy?
        .byte   $0f             ; front laser type
        .byte   $00             ; rear laser type
        .byte   $00             ; left laser type
        .byte   $00             ; right laser type
        .word   $00             ; additional mission data?
        .byte   $16
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $03             ; number of missiles?
        .byte   $00             ; legal status?
        .byte   $10             ; food available?
        .byte   $0f             ; textiles available?
        .byte   $11             ; radioactives available?
        .byte   $00             ; slaves available?
        .byte   $03             ; liquor available?
        .byte   $1c             ; luxuries available?
        .byte   $0e             ; narcotics available?
        .byte   $00             ; computers available?
        .byte   $00             ; machines available?
        .byte   $0a             ; alloys available?
        .byte   $00             ; firearms available?
        .byte   $11             ; furs available?
        .byte   $3a             ; minerals available?
        .byte   $07             ; gold available?
        .byte   $09             ; platinum available?
        .byte   $08             ; gems available?
        .byte   $00             ; alien goods available?
        .byte   $00             ; price factor?
        .word   $00             ; kills?

        .byte   $80
        .byte   $aa
        .byte   $27
        .byte   $03
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
_267e:                                                                  ;$267E
.export _267e
        .byte   $00, $ff, $ff, $aa, $aa, $aa, $55, $55
        .byte   $55, $aa, $aa, $aa, $aa, $aa, $aa, $55
        .byte   $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
        .byte   $aa, $aa, $aa, $aa, $aa, $5a, $aa, $aa
        .byte   $00, $aa, $00, $00, $00, $00

;===============================================================================
; "LINE_DATA" segment goes here in the original game, see "draw_lines.inc"
;
;line_points_x:                                                         ;$26A4
;line_points_y:                                                         ;$27A4
;===============================================================================

.segment        "CODE_28A4"

polyobj_addrs:                                                          ;$28A4
;===============================================================================
; a total of 11 3D-objects ("poly-objects") can be 'in-play' at a time,
; each object has a block of runtime storage to keep track of its current
; state including rotation, speed, shield etc. this is a lookup-table of
; addresses for each poly-object slot
;
.export polyobj_addrs
.export polyobj_addrs_lo = polyobj_addrs
.export polyobj_addrs_hi = polyobj_addrs + 1

.import POLYOBJ_00
        .word   POLYOBJ_00
.import POLYOBJ_01
        .word   POLYOBJ_01
.import POLYOBJ_02
        .word   POLYOBJ_02
.import POLYOBJ_03
        .word   POLYOBJ_03
.import POLYOBJ_04
        .word   POLYOBJ_04
.import POLYOBJ_05
        .word   POLYOBJ_05
.import POLYOBJ_06
        .word   POLYOBJ_06
.import POLYOBJ_07
        .word   POLYOBJ_07
.import POLYOBJ_08
        .word   POLYOBJ_08
.import POLYOBJ_09
        .word   POLYOBJ_09
.import POLYOBJ_10
        .word   POLYOBJ_10

;===============================================================================

; unused / unreferenced?
;$28BA:

        ; single pixel masks?
        .byte   %10000000       ;=$80
        .byte   %01000000       ;=$40
        .byte   %00100000       ;=$20
        .byte   %00010000       ;=$10
        .byte   %00001000       ;=$08
        .byte   %00000100       ;=$04
        .byte   %00000010       ;=$02
        .byte   %00000001       ;=$01
        .byte   %10000000       ;=$80
        .byte   %01000000       ;=$40

; unused / unreferenced?
;$28C4:
        .byte   %11000000       ;=$C0
        .byte   %00110000       ;=$30
        .byte   %00001100       ;=$0C
        .byte   %00000011       ;=$03

_28c8:  ; pixel pairs, in single step (for drawing dust)                ;$28C8
        .byte   %11000000       ;=$C0
        .byte   %11000000       ;=$C0
        .byte   %01100000       ;=$60
        .byte   %00110000       ;=$30
        .byte   %00011000       ;=$18
        .byte   %00001100       ;=$0C
        .byte   %00000110       ;=$06
        .byte   %00000011       ;=$03

_28d0:  ; this looks like masks for multi-colour pixels?                ;$28D0
        .byte   %11000000       ;=$C0
        .byte   %00110000       ;=$30
        .byte   %00001100       ;=$0C
        .byte   %00000011       ;=$03
        .byte   %11000000       ;=$C0

;===============================================================================

_28d5:                                                                  ;$28D5
        ; loads A & F with $0F!

.export _28d5
        lda # $0f
        tax
        rts

_28d9:                                                                  ;$28D9
;===============================================================================
.export _28d9

        jsr print_flight_token

txt_docked_token0B:                                                     ;$28DC
;===============================================================================
.export txt_docked_token0B

        lda # $13
        bne _28e5

_28e0:                                                                  ;$28E0
;===============================================================================
.export _28e0

        lda # 23
        jsr cursor_down

_28e5:                                                                  ;$28E5
;===============================================================================
; called from galactic chart screen;
; draws a line across the screen
;
;       A = Y-position of line
;
.export _28e5

        sta ZP_VAR_Y1                   ; set Y-position of line,
        sta ZP_VAR_Y2                   ; both start and end (straight)

        ; set X to go from 0 to 255
        ldx # $00                       ; begin with zero
        stx ZP_VAR_X1                   ; set line-begin
        dex                             ; roll around to 255
        stx ZP_VAR_X2                   ; set line-end

        ; TODO: could we not use the faster `draw_straight_line`,
        ;       rather than the generic line-drawing routine?
        jmp draw_line

_28f3:                                                                  ;$28F3
;===============================================================================
; for `clip_horz_line`:
;
;      YY = middle-point of line, in viewport px (0-255)
;       A = half-width of line
;
; for `draw_straight_line`:
;
;       Y = Y-pos of line, in viewport px (0-144)
;
.export _28f3
.import clip_horz_line

        jsr clip_horz_line

        ; set parameter for drawing line
        sty ZP_VAR_Y

        ; remove this line from the scanline cache
        lda # $00
        sta VAR_0580, y

        jmp draw_straight_line

;===============================================================================

_2900:                                                                  ;$2900
.export _2900
        .byte   %10000000       ;=$80
        .byte   %11000000       ;=$C0
        .byte   %11100000       ;=$E0
        .byte   %11110000       ;=$F0
        .byte   %11111000       ;=$F8
        .byte   %11111100       ;=$FC
        .byte   %11111110       ;=$FE
_2907:                                                                  ;$2907
.export _2907
        .byte   %11111111       ;=$FF
        .byte   %01111111       ;=$7F
        .byte   %00111111       ;=$3F
        .byte   %00011111       ;=$1F
        .byte   %00001111       ;=$0F
        .byte   %00000111       ;=$07
        .byte   %00000011       ;=$03
        .byte   %00000001       ;=$01

_290f:                                                                  ;$209F
;===============================================================================
        jsr multiplied_now_add
        sta ZP_VAR_YY_HI
        txa
        sta VAR_06C9, y         ; within "dust y-lo" ???

draw_particle:                                                          ;$2918
;===============================================================================
; draw a single dust particle
;
;   ZP_VAR_X = X-distance from middle of screen
;   ZP_VAR_Y = Y-distance from middle of screen
;   ZP_VAR_Z = dust Z-distance;
;
.export draw_particle

        lda ZP_VAR_X
        bpl :+                  ; handle dust to the right

        ; X is negative (left of centre) --
        ; negate the value for the math to follow:
        eor # %01111111         ; flip the sign
        clc                     ; carry must be clear
        adc # $01               ; add 1 to create 2's compliment

        ; flip the sign and put aside for later
:       eor # %10000000                                                 ;$2921
        tax

        ; has the dust particle travelled off
        ; the top/bottom of the screen?
        lda ZP_VAR_Y            ; get particle's Y-distance from centre
        and # %01111111         ; ignore the sign
        ; has the dust particle gone beyond the half-height?
        cmp # ELITE_VIEWPORT_HEIGHT / 2
        ; if yes, don't process
        ; (this is an RTS jump)
       .bge _2976

        ; if the dust Y-distance is positive,
        ; the value doesn't need altering
        lda ZP_VAR_Y
        bpl :+

        ; negate the Y
        eor # %01111111
        adc # $01

        ; put aside the positive-only Y value
:       sta ZP_VAR_T                                                    ;$2934

        ; get the viewport half-height again
        lda # (ELITE_VIEWPORT_HEIGHT / 2) + 1
        sbc ZP_VAR_T

        ; fall through to the routine that does
        ; the actual bitmap manipulation

paint_particle:                                                         ;$293A
;===============================================================================
; paint a dust particle to the bitmap screen
;
;        A = Y-position (px)
;        X = X-position (px)
; ZP_VAR_Z = dust Z-distance
;        Y is preserved
;
.export paint_particle

        sty ZP_TEMP_VAR         ; preserve Y through this ordeal
        tay                     ; get a copy of our Y-coordinate

        ; get a bitmap address for a char row:

        ; reduce the X-position to a multiple of 8,
        ; i.e. a character column
        txa
        and # %11111000

        ; add this to the bitmap address for the given row
        clc
        adc row_to_bitmap_lo, y
        sta ZP_TEMP_ADDR1_LO
        lda row_to_bitmap_hi, y
        adc # $00
        sta ZP_TEMP_ADDR1_HI

        ; get the row within the character cell
        tya
        and # %00000111         ; modulo 8 (0-7)
        tay

        ; get the pixel within that row
        txa
        and # %00000111         ; modulo 8 (0-7)
        tax

        ;; The Z-check makes effectively the same paint operation for Z>=144
        ;; and Z>=80, this seems to be a remnant from a different implementation
        ;; we could instead use this to grow dust in more detail
        ;; using a single-pixel bitmask for far far away dust particles
.ifdef  OPTION_ORIGINAL
        ;///////////////////////////////////////////////////////////////////////
        lda ZP_VAR_Z            ; "pixel distance"
        cmp # 144               ; is the dust-particle >= 144 Z-distance?
       .bge :+                  ; yes, is very far away
.endif  ;///////////////////////////////////////////////////////////////////////

        lda _28c8, x            ; get mask for desired pixel-position
        eor [ZP_TEMP_ADDR1], y
        sta [ZP_TEMP_ADDR1], y

        lda ZP_VAR_Z            ; again get the dust Z-distance
        cmp # 80                ; is the dust-particle >= 80 Z-distance?
       .bge @restore

        dey                     ; move up a pixel-row
        bpl :+                  ; didn't go off the top of the char?

        ldy # $01               ; use row 1 instead of chnaging chars

:       ; draw pixels for very distant dust:                            ;$296D

        lda _28c8, x            ; get mask for desired pixel-position
        eor [ZP_TEMP_ADDR1], y  ; mask the background
        sta [ZP_TEMP_ADDR1], y  ; merge the pixel with the background

@restore:                                                               ;$2974
        ldy ZP_TEMP_VAR         ; restore Y
_2976:                                                                  ;$2976
        rts

;===============================================================================
; BBC code: "BLINE"; ball-line for circle
;
_2977:                                                                  ;$2977
.export _2977
.import line_points_x
.import line_points_y

        txa
        adc ZP_43
        sta ZP_8B

        lda ZP_44
        adc ZP_VAR_T
        sta ZP_8C

        lda ZP_A9
        beq _2998
        inc ZP_A9
_2988:                                                                  ;$2988
        ldy ZP_7E                       ; current line-buffer cursor
        lda # $ff                       ; line terminator
        cmp line_points_y-1, y          ; check the line-buffer Y-coords
        beq _29fa
        sta line_points_y, y            ; line-buffer Y-coords
        inc ZP_7E
        bne _29fa
_2998:                                                                  ;$2998
        lda ZP_85
        sta ZP_VAR_X1
        lda ZP_86
        sta ZP_VAR_Y1
        lda ZP_87
        sta ZP_VAR_X2
        lda ZP_88
        sta ZP_VAR_Y2
        lda ZP_89
        sta ZP_6F
        lda ZP_8A
        sta ZP_70
        lda ZP_8B
        sta ZP_71
        lda ZP_8C
        sta ZP_72
        jsr _a013
        bcs _2988
        lda VAR_06F4
        beq _29d2

        lda ZP_VAR_X1
        ldy ZP_VAR_X2
        sta ZP_VAR_X2
        sty ZP_VAR_X1
        lda ZP_VAR_Y1
        ldy ZP_VAR_Y2
        sta ZP_VAR_Y2
        sty ZP_VAR_Y1
_29d2:                                                                  ;$29D2
        ldy ZP_7E                       ; current line-buffer cursor (1-based)
        lda line_points_y-1, y          ; check current Y-coord
        cmp # $ff                       ; is it the terminator?
        bne _29e6

        ; add X1/Y1 to line-buffer
        ; (Y is the current cursor position)
        lda ZP_VAR_X1
        sta line_points_x, y            ; line-buffer X-coords
        lda ZP_VAR_Y1
        sta line_points_y, y            ; line-buffer Y-coords
        iny                             ; move to the next point in the buffer

_29e6:                                                                  ;$2936
        ; add X2/Y2 to the line-buffer?
        lda ZP_VAR_X2
        sta line_points_x, y            ; line-buffer X-coords
        lda ZP_VAR_Y2
        sta line_points_y, y            ; line-buffer Y-coords
        iny                             ; move to the next point in the buffer
        sty ZP_7E                       ; update line-buffer cursor

        ; draw the current line in X1/Y1/X2/Y2
        ; TODO: do validation of line direction here so as to allow
        ;       removal of validation in the line routine
        jsr draw_line

        lda ZP_A2
        bne _2988
_29fa:                                                                  ;$29FA
        lda ZP_89
        sta ZP_85
        lda ZP_8A
        sta ZP_86
        lda ZP_8B
        sta ZP_87
        lda ZP_8C
        sta ZP_88
        lda ZP_AA
        clc
        adc ZP_AC
        sta ZP_AA

        rts

dust_swap_xy:                                                           ;$2A12
;===============================================================================
.export dust_swap_xy

        ldy DUST_COUNT          ; get number of dust particles

:       ldx DUST_Y, y           ; get dust-particle Y-position          ;$2A15
        lda DUST_X, y           ; get dust-particle X-position
        sta ZP_VAR_Y            ; (put aside X-position)
        sta DUST_Y, y           ; save the Y-value to the X-position
        txa                     ; move the Y-position into A
        sta ZP_VAR_X            ; (put aside Y-value)
        sta DUST_X, y           ; write the X-value to the Y-position
        lda DUST_Z, y           ; get dust z-position
        sta ZP_VAR_Z            ; (put aside Z-position)

        jsr draw_particle

        dey
        bne :-

        rts

;===============================================================================

_2a32:                                                                  ;$2A32
        ldx VAR_0486
        beq _2a40
        dex
        bne _2a3d
        jmp _2b2d

;===============================================================================

_2a3d:                                                                  ;$2A3D
        jmp _37e9

        ;-----------------------------------------------------------------------

_2a40:                                                                  ;$2A40
        ldy DUST_COUNT          ; number of dust particles
_2a43:                                                                  ;$2A43
        jsr _3b30
        lda ZP_VAR_R
        lsr ZP_VAR_P1
        ror
        lsr ZP_VAR_P1
        ror
        ora # %00000001
        sta ZP_VAR_Q
        lda VAR_06E3, y
        sbc ZP_97
        sta VAR_06E3, y
        lda DUST_Z, y
        sta ZP_VAR_Z
        sbc ZP_98
        sta DUST_Z, y
        jsr _3992
        sta ZP_VAR_YY_HI
        lda ZP_VAR_P1
        adc VAR_06C9, y         ; inside `DUST_Y` array
        sta ZP_VAR_YY_LO
        sta ZP_VAR_R
        lda ZP_VAR_Y
        adc ZP_VAR_YY_HI
        sta ZP_VAR_YY_HI
        sta ZP_VAR_S
        lda DUST_X, y
        sta ZP_VAR_X
        jsr _3997
        sta ZP_VAR_XX_HI
        lda ZP_VAR_P1
        adc VAR_06AF, y         ; inside `DUST_X` array
        sta ZP_VAR_XX_LO
        lda ZP_VAR_X
        adc ZP_VAR_XX_HI
        sta ZP_VAR_XX_HI
        eor ZP_6A               ; move count?
        jsr _393c
        jsr multiplied_now_add
        sta ZP_VAR_YY_HI
        stx ZP_VAR_YY_LO
        eor ZP_ROLL_SIGN        ; roll sign?
        jsr _3934
        jsr multiplied_now_add
        sta ZP_VAR_XX_HI
        stx ZP_VAR_XX_LO
        ldx ZP_PITCH_MAGNITUDE
        lda ZP_VAR_YY_HI
        eor ZP_95
        jsr _393e
        sta ZP_VAR_Q
        jsr _3a4c
        asl ZP_VAR_P1
        rol
        sta ZP_VAR_T
        lda # $00
        ror
        ora ZP_VAR_T
        jsr multiplied_now_add
        sta ZP_VAR_XX_HI
        txa
        sta VAR_06AF, y         ; inside `DUST_X` array
        lda ZP_VAR_YY_LO
        sta ZP_VAR_R
        lda ZP_VAR_YY_HI
        sta ZP_VAR_S
        lda # $00
        sta ZP_VAR_P1
        lda ZP_BETA
        eor # %10000000
        jsr _290f
        lda ZP_VAR_XX_HI
        sta ZP_VAR_X
        sta DUST_X, y
        and # %01111111
        cmp # $78
        bcs _2b0a
        lda ZP_VAR_YY_HI
        sta DUST_Y, y
        sta ZP_VAR_Y
        and # %01111111
        cmp # $78
        bcs _2b0a
        lda DUST_Z, y
        cmp # $10
        bcc _2b0a
        sta ZP_VAR_Z
_2b00:                                                                  ;$2B00
        jsr draw_particle
        dey
        beq _2b09
        jmp _2a43

_2b09:                                                                  ;$2B09
        rts

        ;-----------------------------------------------------------------------

_2b0a:                                                                  ;$2B0A
        jsr get_random_number
        ora # %00000100
        sta ZP_VAR_Y
        sta DUST_Y, y

        jsr get_random_number
        ora # %00001000
        sta ZP_VAR_X
        sta DUST_X, y

        jsr get_random_number
        ora # %10010000
        sta DUST_Z, y
        sta ZP_VAR_Z

        lda ZP_VAR_Y
        jmp _2b00

;===============================================================================

_2b2d:                                                                  ;$2B2D
        ldy DUST_COUNT          ; number of dust particles
_2b30:                                                                  ;$2B30
        jsr _3b30
        lda ZP_VAR_R
        lsr ZP_VAR_P1
        ror
        lsr ZP_VAR_P1
        ror
        ora # %00000001
        sta ZP_VAR_Q
        lda DUST_X, y
        sta ZP_VAR_X
        jsr _3997
        sta ZP_VAR_XX_HI
        lda VAR_06AF, y         ; inside `DUST_X` array
        sbc ZP_VAR_P1
        sta ZP_VAR_XX_LO
        lda ZP_VAR_X
        sbc ZP_VAR_XX_HI
        sta ZP_VAR_XX_HI
        jsr _3992
        sta ZP_VAR_YY_HI
        lda VAR_06C9, y         ; inside `DUST_Y` array
        sbc ZP_VAR_P1
        sta ZP_VAR_YY_LO
        sta ZP_VAR_R
        lda ZP_VAR_Y
        sbc ZP_VAR_YY_HI
        sta ZP_VAR_YY_HI
        sta ZP_VAR_S
        lda VAR_06E3, y
        adc ZP_97
        sta VAR_06E3, y
        lda DUST_Z, y
        sta ZP_VAR_Z
        adc ZP_98
        sta DUST_Z, y
        lda ZP_VAR_XX_HI
        eor ZP_ROLL_SIGN        ; roll sign?
        jsr _393c
        jsr multiplied_now_add
        sta ZP_VAR_YY_HI
        stx ZP_VAR_YY_LO
        eor ZP_6A               ; move count?
        jsr _3934
        jsr multiplied_now_add
        sta ZP_VAR_XX_HI
        stx ZP_VAR_XX_LO
        lda ZP_VAR_YY_HI
        eor ZP_95
        ldx ZP_PITCH_MAGNITUDE
        jsr _393e
        sta ZP_VAR_Q
        lda ZP_VAR_XX_HI
        sta ZP_VAR_S
        eor # %10000000
        jsr _3a50
        asl ZP_VAR_P1
        rol
        sta ZP_VAR_T
        lda # $00
        ror
        ora ZP_VAR_T
        jsr multiplied_now_add
        sta ZP_VAR_XX_HI
        txa
        sta VAR_06AF, y         ; inside `DUST_X` array
        lda ZP_VAR_YY_LO
        sta ZP_VAR_R
        lda ZP_VAR_YY_HI
        sta ZP_VAR_S
        lda # $00
        sta ZP_VAR_P1
        lda ZP_BETA
        jsr _290f
        lda ZP_VAR_XX_HI
        sta ZP_VAR_X
        sta DUST_X, y
        lda ZP_VAR_YY_HI
        sta DUST_Y, y
        sta ZP_VAR_Y
        and # %01111111
        cmp # $6e
        bcs _2bf7
        lda DUST_Z, y
        cmp # $a0
        bcs _2bf7
        sta ZP_VAR_Z
_2bed:                                                                  ;$2BED
        jsr draw_particle
        dey
        beq _2bf6
        jmp _2b30

_2bf6:                                                                  ;$2BF6
        rts

        ;-----------------------------------------------------------------------

_2bf7:                                                                  ;$2BF7
        jsr get_random_number
        and # %01111111
        adc # $0a
        sta DUST_Z, y
        sta ZP_VAR_Z
        lsr
        bcs _2c1a
        lsr
        lda # $fc
        ror
        sta ZP_VAR_X
        sta DUST_X, y
        jsr get_random_number
        sta ZP_VAR_Y
        sta DUST_Y, y
        jmp _2bed

        ;-----------------------------------------------------------------------

_2c1a:                                                                  ;$2C1A
        jsr get_random_number
        sta ZP_VAR_X
        sta DUST_X, y
        lsr
        lda # $e6
        ror
        sta ZP_VAR_Y
        sta DUST_Y, y
        bne _2bed
_2c2d:                                                                  ;$2C2D
        lda ZP_POLYOBJ_XPOS_LO, y
        asl
        sta ZP_VALUE_pt2
        lda ZP_POLYOBJ_XPOS_MI, y
        rol
        sta ZP_VALUE_pt3
        lda # $00
        ror
        sta ZP_VALUE_pt4
        jsr _2d69
        sta ZP_POLYOBJ_XPOS_HI, x
_2c43:                                                                  ;$2C43
.export _2c43
        ldy ZP_VALUE_pt2
        sty ZP_POLYOBJ_XPOS_LO, x
        ldy ZP_VALUE_pt3
        sty ZP_POLYOBJ_XPOS_MI, x
        and # %01111111
        rts

;===============================================================================
; examine a poly-object's X/Y/Z position?
;
;       A = a starting value to merge with
;       Y = a multiple of 37 bytes for each poly-object
;
_2c4e:                                                                  ;$2C4E
.export _2c4e
        lda # $00
_2c50:                                                                  ;$2C50
.export _2c50
.import POLYOBJECTS, PolyObject

        ora POLYOBJECTS + PolyObject::xpos + 2, y
        ora POLYOBJECTS + PolyObject::ypos + 2, y
        ora POLYOBJECTS + PolyObject::zpos + 2, y
        and # %01111111         ; strip sign

        rts

;===============================================================================

_2c5c:                                                                  ;$2C5C
        lda POLYOBJ_00 + PolyObject::xpos + 1, y                        ;=$F901
        jsr math_square
        sta ZP_VAR_R

        lda POLYOBJ_00 + PolyObject::ypos + 1, y                        ;=$F904
        jsr math_square
        adc ZP_VAR_R
        bcs _2c7a
        sta ZP_VAR_R

        lda POLYOBJ_00 + PolyObject::zpos + 1, y                        ;=$F907
        jsr math_square
        adc ZP_VAR_R
        bcc _2c7c
_2c7a:                                                                  ;$2C7A
        lda # $ff
_2c7c:                                                                  ;$2C7C
        rts

;===============================================================================

_2c7d:                                                                  ;$2C7D
.import TXT_DOCKED_DOCKED:direct

        lda # TXT_DOCKED_DOCKED
        jsr print_docked_str

        jsr paint_newline
        jmp _2cc7

_2c88:                                                                  ;$2C88
        ldx # $09               ; "Elite" status
        cmp #> 6400             ; 25*256 = 6400 kills
       .bge _2cee

        dex                     ; "Deadly" status
        cmp #> 2560             ; 10*256 = 2560 kills
       .bge _2cee

        dex                     ; "Dangerous" status
        cmp #> 512              ; 2*256 = 512 kills
       .bge _2cee

        dex                     ; "Competent" status or below
        bne _2cee

; display status page
;===============================================================================
status_screen:                                                          ;$2C9B
.export status_screen

        ; switch to page "8"(?)
        lda # $08
        jsr _6a2f
        jsr _70ab

        lda # 7
        jsr set_cursor_col

        lda # $7e               ; txt token -- status line?
        jsr _28d9

        lda # $0f
        ldy ZP_A7
        bne _2c7d
        lda # $e6
        ldy VAR_047F
        ldx SHIP_SLOT2, y
        beq _2cc4
        ldy PLAYER_ENERGY
        cpy # $80
        adc # $01
_2cc4:                                                                  ;$2CC4
        jsr print_flight_token_and_newline
_2cc7:                                                                  ;$2CC7
        lda # $7d
        jsr _6a9b
        lda # $13
        ldy PLAYER_LEGAL
        beq _2cd7
        cpy # $32
        adc # $01
_2cd7:                                                                  ;$2CD7
        jsr print_flight_token_and_newline

        lda # $10
        jsr _6a9b

        lda PLAYER_KILLS
        bne _2c88

        tax
        lda VAR_04E0
        lsr
        lsr
_2cea:                                                                  ;$2CEA
        inx
        lsr
        bne _2cea
_2cee:                                                                  ;$2CEE
        txa

        clc
        adc # $15
        jsr print_flight_token_and_newline

        lda # $12
        jsr _2d61
        lda PLAYER_ESCAPEPOD
        beq _2d04
        lda # $70
        jsr _2d61
_2d04:                                                                  ;$2D04
        lda VAR_04C2
        beq _2d0e
        lda # $6f
        jsr _2d61
_2d0e:                                                                  ;$2D0E
        lda PLAYER_ECM
        beq _2d18
        lda # $6c
        jsr _2d61
_2d18:                                                                  ;$2D18
        lda # $71
        sta ZP_AD
_2d1c:                                                                  ;$2D1C
        tay
        ldx SHIP_SLOTS, y       ; ship slots? NB: "$04c3 - $71"
        beq _2d25
        jsr _2d61
_2d25:                                                                  ;$2D25
        inc ZP_AD
        lda ZP_AD
        cmp # $75
        bcc _2d1c
        ldx # $00
_2d2f:                                                                  ;$2D2F
        stx ZP_AA
        ldy PLAYER_LASERS, x
        beq _2d59
        txa
        clc
        adc # $60
        jsr _6a9b
        lda # $67
        ldx ZP_AA
        ldy PLAYER_LASERS, x
        cpy # $8f
        bne _2d4a
        lda # $68
_2d4a:                                                                  ;$2D4A
        cpy # $97
        bne _2d50
        lda # $75
_2d50:                                                                  ;$2D50
        cpy # $32
        bne _2d56
        lda # $76
_2d56:                                                                  ;$2D56
        jsr _2d61
_2d59:                                                                  ;$2D59
        ldx ZP_AA
        inx
        cpx # $04
        bcc _2d2f
        rts

;===============================================================================

_2d61:                                                                  ;$2D61
        jsr print_flight_token_and_newline
        lda # 6
        jmp set_cursor_col

;===============================================================================

_2d69:                                                                  ;$2D69
.export _2d69

        lda ZP_VALUE_pt4
        sta ZP_VAR_S
        and # %10000000
        sta ZP_VAR_T
        eor ZP_POLYOBJ_XPOS_HI, x
        bmi _2d8d
        lda ZP_VALUE_pt2
        clc
        adc ZP_POLYOBJ_XPOS_LO, x
        sta ZP_VALUE_pt2
        lda ZP_VALUE_pt3
        adc ZP_POLYOBJ_XPOS_MI, x
        sta ZP_VALUE_pt3
        lda ZP_VALUE_pt4
        adc ZP_POLYOBJ_XPOS_HI, x
        and # %01111111
        ora ZP_VAR_T
        sta ZP_VALUE_pt4
        rts

        ;-----------------------------------------------------------------------

_2d8d:                                                                  ;$2D8D
        lda ZP_VAR_S
        and # %01111111
        sta ZP_VAR_S
        lda ZP_POLYOBJ_XPOS_LO, x
        sec
        sbc ZP_VALUE_pt2
        sta ZP_VALUE_pt2
        lda ZP_POLYOBJ_XPOS_MI, x
        sbc ZP_VALUE_pt3
        sta ZP_VALUE_pt3
        lda ZP_POLYOBJ_XPOS_HI, x
        and # %01111111
        sbc ZP_VAR_S
        ora # %10000000
        eor ZP_VAR_T
        sta ZP_VALUE_pt4
        bcs _2dc4
        lda # $01
        sbc ZP_VALUE_pt2
        sta ZP_VALUE_pt2
        lda # $00
        sbc ZP_VALUE_pt3
        sta ZP_VALUE_pt3
        lda # $00
        sbc ZP_VALUE_pt4
        and # %01111111
        ora ZP_VAR_T
        sta ZP_VALUE_pt4
_2dc4:                                                                  ;$2DC4
        rts

;===============================================================================
;
;       X = offset from `ZP_POLYOBJECT` to the desired matrix row;
;           that is, a `MATRIX_ROW_*` constant
;
;       Y = offset from `ZP_POLYOBJECT` to the desired matrix row;
;           that is, a `MATRIX_ROW_*` constant
;
_2dc5:                                                                  ;$2DC5

COL0    = $00           ; column 0 of the matrix row
COL0_LO = $00
COL0_HI = $01
COL1    = $02           ; column 1 of the matrix row
COL1_LO = $02
COL1_HI = $03
COL2    = $04           ; column 2 of the matrix row
COL2_LO = $04
COL2_HI = $05

.export _2dc5
        ; ROW X
        ;-----------------------------------------------------------------------

        lda ZP_POLYOBJ + COL0_HI, x
        and # %01111111         ; extract HI byte without sign
        lsr                     ; divide by 2
        sta ZP_VAR_T

        lda ZP_POLYOBJ + COL0_LO, x
        sec
        sbc ZP_VAR_T
        sta ZP_VAR_R

        lda ZP_POLYOBJ + COL0_HI, x
        sbc # $00
        sta ZP_VAR_S

        ; ROW Y
        ;-----------------------------------------------------------------------

        lda ZP_POLYOBJ + COL0_LO, y
        sta ZP_VAR_P

        lda ZP_POLYOBJ + COL0_HI, y
        and # %10000000         ; extract sign
        sta ZP_VAR_T            ; put sign aside

        lda ZP_POLYOBJ + COL0_HI, y
        and # %01111111         ; extract magnitude
        lsr                     ; divide by 2
        ror ZP_VAR_P
        lsr
        ror ZP_VAR_P
        lsr
        ror ZP_VAR_P
        lsr
        ror ZP_VAR_P
        ora ZP_VAR_T            ; restore sign
        eor ZP_B1               ; rotation sign?
        stx ZP_VAR_Q

        jsr multiplied_now_add
        sta ZP_VALUE_pt2
        stx ZP_VALUE_pt1
        ldx ZP_VAR_Q
        lda ZP_POLYOBJ + COL0_HI, y
        and # %01111111
        lsr
        sta ZP_VAR_T
        lda ZP_POLYOBJ + COL0_LO, y
        sec
        sbc ZP_VAR_T
        sta ZP_VAR_R
        lda ZP_POLYOBJ + COL0_HI, y
        sbc # $00
        sta ZP_VAR_S
        lda ZP_POLYOBJ + COL0_LO, x
        sta ZP_VAR_P
        lda ZP_POLYOBJ + COL0_HI, x
        and # %10000000
        sta ZP_VAR_T
        lda ZP_POLYOBJ + COL0_HI, x
        and # %01111111
        lsr
        ror ZP_VAR_P
        lsr
        ror ZP_VAR_P
        lsr
        ror ZP_VAR_P
        lsr
        ror ZP_VAR_P
        ora ZP_VAR_T
        eor # %10000000
        eor ZP_B1
        stx ZP_VAR_Q
        jsr multiplied_now_add
        sta ZP_POLYOBJ + COL0_HI, y
        stx ZP_POLYOBJ + COL0_LO, y
        ldx ZP_VAR_Q
        lda ZP_VALUE_pt1
        sta ZP_POLYOBJ + COL0_LO, x
        lda ZP_VALUE_pt2
        sta ZP_POLYOBJ + COL0_HI, x

        rts

; convert values to strings:
; TODO: this to be its own segment, we WILL want to replace it
;===============================================================================

; the number to be converted:
; (a 4-byte big-endian buffer is defined for $77..$7A)
.exportzp       ZP_VALUE_OVFLW  := $9c  ; because, why not!?

; working copy of the number:
.exportzp       ZP_VCOPY        := $6b
.exportzp       ZP_VCOPY_pt1    := $6b
.exportzp       ZP_VCOPY_pt2    := $6c
.exportzp       ZP_VCOPY_pt3    := $6d
.exportzp       ZP_VCOPY_pt4    := $6e
.exportzp       ZP_VCOPY_OVFLW  := $6f

.exportzp       ZP_PADDING      := $99
.exportzp       ZP_MAXLEN       := $bb  ; maximum length of string

_max_value:                                                             ;$2E51
        ; maximum value:
        ;
        ; this is the maximum printable value: 100-billion ($17_4876_E800);
        ; note that this lacks the first byte, $17, as that is handled
        ; directly in the code itself
        .byte   $48, $76, $e8, $00

print_tiny_value:                                                       ;$2E55
        ;=======================================================================
        ; print an 8-bit value, given in X, padded to 3 chars
        ;
        ;    X = value to print
        ;
.export print_tiny_value

        ; set the padding to a max. number of digits to 3, i.e. "  0"-"255"
        lda # $03

print_small_value:                                                      ;$2E57
        ;=======================================================================
        ; print an 8-bit value, given in X, with A specifying the number of
        ; characters to pad to
        ;
        ;    X = value to print
        ;    A = width in chars to pad to
        ;
.export print_small_value

        ; strip the hi-byte for what follows; only use X
        ldy # $00

print_medium_value:                                                     ;$2E59
        ;=======================================================================
        ; print a 16-bit value stored in X/Y
        ;
        ;    A = max. no. of expected digits
        ;    X = lo-byte of value
        ;    Y = hi-byte of value
        ;
.export print_medium_value

        sta ZP_PADDING

        ; zero out the upper-bytes of the 32-bit value to print
        lda # $00
        sta ZP_VALUE_pt1
        sta ZP_VALUE_pt2

        ; insert the 16-bit value given
        sty ZP_VALUE_pt3
        stx ZP_VALUE_pt4

print_large_value:                                                      ;$2E65
        ;=======================================================================
        ; print a large value, up to 100-billion
        ;
        ; $77-$7A = numerical value (note: big-endian)
        ;     $99 = max. number of expected digits, i.e. left-pad the number
        ;       c = carry set: use decimal point
        ;
.export print_large_value

        ; set max. text width
        ; i.e. for "100000000000" (100-billion)
        ldx # 11                ; 12 chars
        stx ZP_MAXLEN

        ; keep a copy of the carry-flag
        ; parameter ('use decimal point')
        php
        bcc :+                  ; skip ahead when carry = 0

        ; carry flag is set:
        ; a decimal point will be printed
        dec ZP_MAXLEN           ; one less char available
        dec ZP_PADDING          ; reduce amount of left-padding

:       lda # 11                ; max length of text (12 chars)         ;$2E70
        sec                     ; set carry-flag, see note below
        sta ZP_9F               ; put original max.length of text aside

        ; subtract the max. number of digits from the max. length of text.
        ; since carry is set, this will underflow (sign-bit) if equal
        sbc ZP_PADDING
        sta ZP_PADDING          ; remainder
        inc ZP_PADDING          ; fix use of carry

        ; clear the overflow byte used during calculations with the value.
        ; note that this is also setting Y (the current digit counter) to zero
        ldy # $00
        sty ZP_VALUE_OVFLW

        jmp @_check_curr_digit  ; jump into the main loop
                                ; (below is not a direct follow-on from here)

@_x10:  ; multiply by 10:                                               ;$2E82
        ;-----------------------------------------------------------------------
        ; since you can't 'just' multiply by 10 in binary, we first multiply
        ; by 2 and put that aside, do a multiply by 8 and then add the two
        ; values together

        ; first, multiply by 2
        asl ZP_VALUE_pt4
        rol ZP_VALUE_pt3
        rol ZP_VALUE_pt2
        rol ZP_VALUE_pt1
        rol ZP_VALUE_OVFLW      ; catch any overflow

        ; make a copy of our 2x value
        ldx # 3                 ; numerical value is 4-bytes long (0..3)
:       lda ZP_VALUE, x                                                 ;$2E8E
        sta ZP_VCOPY, x
        dex
        bpl :-

        lda ZP_VALUE_OVFLW      ; copy the overflow value
        sta ZP_VCOPY_OVFLW      ; to the 2x value copy too

        ; multiply again by 2
        ; (i.e. 4x original value)
        asl ZP_VALUE_pt4
        rol ZP_VALUE_pt3
        rol ZP_VALUE_pt2
        rol ZP_VALUE_pt1
        rol ZP_VALUE_OVFLW
        ; multiply again by 2;
        ; (i.e. 8x original value)
        asl ZP_VALUE_pt4
        rol ZP_VALUE_pt3
        rol ZP_VALUE_pt2
        rol ZP_VALUE_pt1
        rol ZP_VALUE_OVFLW
        clc

        ; add our 2x value to our 8x value:

        ldx # 3                 ; numerical value is 4-bytes long (0..3)
:       lda ZP_VALUE, x         ; load x2 byte                          ;$2EB0
        adc ZP_VCOPY, x         ; add to x8 byte
        sta ZP_VALUE, x         ; write the value back
        dex
        bpl :-

        ; add the overflow bytes together
        lda ZP_VCOPY_OVFLW
        adc ZP_VALUE_OVFLW
        sta ZP_VALUE_OVFLW

        ldy # 0                 ; set the current digit counter to 0

@_check_curr_digit:                                                     ;$2EC1
        ;-----------------------------------------------------------------------
        ; subtract the check digit (100-billion) from value as long as
        ; possible, increasing Y each time. when less than 100-billion,
        ; multiply by 10 to check for the next digit
        ;
        ; why 100 billion and the overflow byte is used is beyound me...
        ; 1 billion should be enough, since max<uint32> is < 5 billion
        ;
        ldx # 3                 ; numerical value is 4-bytes long (0..3)

       .clb                     ; clear the borrow before subtracting
:       lda ZP_VALUE, x         ; read a byte from the numerical value  ;$2EC4
        sbc _max_value, x       ; subtract against '100-billion'
        sta ZP_VCOPY, x         ; store the result separately
        dex
        bpl :-

        ; and then the 5th byte separately
        lda ZP_VALUE_OVFLW
        sbc # $17               ; this is the $17 in '$17_4876_E800',
                                ; i.e. 100-billion decimal
        sta ZP_VCOPY_OVFLW

        ; underflow, 100-billion did not fit another time. 
        ; print current digit 'y' and advance to next digit
       .bbw @_print_digit

        ; 100-billion did fit, so 'commit' the subtraction to VALUE
        ldx # 3                  ; numerical value is 4-bytes long (0..3)
:       lda ZP_VCOPY, x                                                 ;$2ED8
        sta ZP_VALUE, x
        dex
        bpl :-

        lda ZP_VCOPY_OVFLW
        sta ZP_VALUE_OVFLW

        iny                     ; increase the current digit
        jmp @_check_curr_digit  ; try to subtract another 100-billion

@_print_digit:                                                          ;$2EE7
        ;-----------------------------------------------------------------------
        ; is there a digit waiting to be printed?
        ; (when we first enter this routine, Y will be zero)
        tya
       .bnz @ascii

        lda ZP_MAXLEN
       .bze @ascii

        dec ZP_PADDING
        bpl @_2f00

        lda # ' '               ; print leading white-space
        bne @print              ; skip over the next bit (always branches)

@ascii: ; convert value 0-9 to ASCII/PETSCII character                  ;$2EF6

        ldy # $00
        sty ZP_MAXLEN

        clc
        adc # '0'               ; re-base as an ASCII/PETSCII numeral

@print: jsr print_char                                                  ;$2EFD

@_2f00:                                                                 ;$2F00
        dec ZP_MAXLEN
        bpl :+
        inc ZP_MAXLEN
:       dec ZP_9F                                                       ;$2F06
        bmi @rts
        bne :+

        ; are we printing a decimal point?
        plp                     ; get the original carry-flag parameter
        bcc :+                  ; carry clear skips printing decimal point

        ; carry set: print the decimal point
        lda # '.'
        jsr print_char

        ; handle the next decimal digit...
:       jmp @_x10                                                       ;$2F14

@rts:   rts                                                             ;$2F17

;===============================================================================
; a block of text-printing related flags and variables

txt_ucase_mask:                                                         ;$2F18
        ; a mask for converting a character A-Z to upper-case.
        ; this byte gets changed to 0 to neuter the effect
        .byte   %00100000

txt_lcase_flag:                                                         ;$2F19
.export txt_lcase_flag

        .byte   %11111111

txt_flight_flag:                                                        ;$2F1A
        .byte   %00000000

txt_buffer_flag:                                                        ;$2F1B
.export txt_buffer_flag

        .byte   %00000000

txt_buffer_index:                                                       ;$2F1C
.export txt_buffer_index

        .byte   $00

txt_ucase_flag:                                                         ;$2F1D
        .byte   %00000000

txt_lcase_mask:                                                         ;$2F1E
        ; this byte is used to lower-case charcters, it's ANDed with the
        ; character value -- therefore its default value $FF does nothing.
        ; this byte is changed to %11011111 to enable lower-casing, which
        ; removes bit 5 ($20) from characters, e.g. $61 "A" > $41 "a"
        .byte   %11111111


print_crlf:                                                             ;$2F1F
;===============================================================================
; 'print' a new-line character. i.e. move to the next row, starting column
;
.export print_crlf

        lda # TXT_NEWLINE

        ; this causes the next instruction to become a meaningless `bit`
        ; instruction, a very handy way of skipping without branching
       .bit

txt_docked_token10:                                                     ;$2F22
;===============================================================================
; print "A"!?
;
.export txt_docked_token10

        lda # 'a'

print_char:                                                             ;$2F24
;===============================================================================
; prints an ASCII character to screen (eventually). note that this routine can
; buffer output to produce effects like text-justification. the actual routine
; that copies pixels to screen is `paint_char`, but this routine is the one
; the text-handling works with
;
;       A = ASCII code
;
.export print_char

; TODO: this to be defined structurally at some point
TXT_BUFFER = $0648              ; $0648..$06A2? -- 3 lines

        ; put X parameter aside,
        ; we need the X register for now
        stx ZP_TEMP_ADDR1_LO

        ; disable the automatic lower-case transformation
        ldx # %11111111
        stx txt_lcase_mask

        ; check for characters that aren't cased

        cmp # '.'
        beq :+

        cmp # ':'
        beq :+

        cmp # $0a               ;?
        beq :+

        cmp # TXT_NEWLINE
        beq :+

        cmp # ' '
        beq :+

        ; X is $FF for all characters, except ".", ":", $0A, $0C & space,
        ; otherwise $00 -- some kind of flag?
        inx

:       stx txt_lcase_flag                                              ;$24F0

        ; get back the original X value
        ldx ZP_TEMP_ADDR1_LO

        ; check 'use buffer' flag
        bit txt_buffer_flag     ; check if bit 7 is set
        bmi _add_to_buffer      ; yes? switch to buffered printing

        ; no buffer, print character as-is
        jmp paint_char


_add_to_buffer:                                                         ;$2F4D
        ;=======================================================================
        ; a flag to ignore line-breaks?
        bit txt_buffer_flag     ; check bit 6
        bvs :+                  ; skip if bit 6 set

        cmp # TXT_NEWLINE       ; new-line character?
        beq _flush_buffer       ; flush buffer

:       ldx txt_buffer_index                                            ;$2F56
        sta TXT_BUFFER, x       ; add the character to the buffer

        ldx ZP_TEMP_ADDR1_LO
        inc txt_buffer_index

        clc
        rts

_flush_buffer:                                                          ;$2F63
        ;=======================================================================
        ; flush the text buffer to screen
        ;

        ; backup X & Y registers:
       .phx                     ; push X to stack (via A)
       .phy                     ; push Y to stack (via A)

_flush_line:                                                            ;$2F67
        ;-----------------------------------------------------------------------
        ldx txt_buffer_index    ; get current buffer index
       .bze _exit               ; if buffer is empty, exit

        ; does the buffer need to be justified?
        ;
        cpx # 31                ; is the buffer <= 30 chars?
       .blt _print_all          ; if so, the buffer is one line, print as-is

        ; there is more than one line to print, ergo all but the last line
        ; must be justified -- insert extra spaces until the text reaches
        ; the full length of the line
        ;
        ; since we must insert spaces evenly between words, a 'space-counter'
        ; is used to ensure that we ignore an increasing number of spaces
        ; so that new spaces are added further and further down the line,
        ; providing even distribution
        ;
        ; for speed optimisation, the space-counter is implemented as
        ; a 'walking bit', a single bit in a byte that is shifted along
        ; at each step. when the bit falls off the end it gets reset
        ;
        ; the space-counter begins at bit 6; this is so that the first
        ; space encountered triggers justification
        ;
        ; note that whatever the value of $08 prior to calling this routine,
        ; shifting it right once will ensure that the 'minus' check below will
        ; always fail, so $08 will be 'reset' to %01000000 for this routine
        ;
        lsr ZP_TEMP_ADDR1_HI

_justify_line:                                                          ;$2F72
        ;-----------------------------------------------------------------------
        lda ZP_TEMP_ADDR1_HI    ; check the space-counter
        bmi :+

        lda # %01000000         ; reset space-counter
        sta ZP_TEMP_ADDR1_HI    ; to its starting position

        ; begin at the end of the line and walk backwards through it:
:       ldy # 29                                                        ;$2F7A

@justify:                                                               ;$2F7C
        ;-----------------------------------------------------------------------
        ; is the justification complete?
        lda TXT_BUFFER + 30     ; check the last char in the line
        cmp # ' '               ; is it a space?
        beq @print_line         ; if so, skip ahead to printing the line

@find_spc:                                                              ;$2F83
        dey                     ; step back through the line-length
        bmi _justify_line       ; catch underflow? max buffer length is 90
        beq _justify_line       ; hit the start of the line? go again

        lda TXT_BUFFER, y       ; read character from buffer
        cmp # ' '               ; is it a space?
        bne @find_spc           ; not a space, keep going

        ; space found:
        asl ZP_TEMP_ADDR1_HI    ; move the space-counter along
        bmi @find_spc           ; if it's hit the end, we ignore this space
                                ; and look for the next one

        ; remember the current position,
        ; i.e. where the space is
        sty ZP_TEMP_ADDR1_LO

        ; insert another space, pushing everything forward
        ; (increase the spacing between two words)
        ldy txt_buffer_index
:       lda TXT_BUFFER, y                                               ;$2F98
        sta TXT_BUFFER+1, y
        dey
        cpy ZP_TEMP_ADDR1_LO
       .bge :-

        ; given the space we added, increase the text-buffer length by 1
        inc txt_buffer_index

:       cmp TXT_BUFFER, y                                               ;$2FA6
        bne @justify
        dey
        bpl :-
        bmi _justify_line

@print_line:                                                            ;$2FB0
        ; a line is already 30-chars long, or has
        ; been justified to the same, print it
        ldx # 30
        jsr _print_chars

        ; move to the next line
        lda # TXT_NEWLINE
        jsr paint_char

        lda txt_buffer_index
        sbc # 30
        sta txt_buffer_index
        tax
        beq _exit
        ldy # $00
        inx

        ; downshift the buffer, moving lines 2+, down to line 1 since the
        ; routine here only works with the start of the buffer

:       lda TXT_BUFFER + 30 + 1, y                                      ;$2FC8
        sta TXT_BUFFER, y
        iny
        dex
       .bnz :-

        ; go back and process the remaining buffer
       .bze _flush_line         ; always branches!

_print_chars:                                                           ;$2FD4
        ;=======================================================================
        ; print X number of characters in the buffer to the screen
        ;
        ;       X = length of string to print from the buffer
        ;
        ldy # $00               ; begin at index 0
:       lda TXT_BUFFER, y       ; read a character from the buffer      ;$2FD6
        jsr paint_char          ; paint it to screen
        iny                     ; move to the next character
        dex                     ; reduce number of remaining characters
        bne :-                  ; keep looping if some remain

_2fe0:  rts                                                             ;$2FE0

_print_all:                                                             ;$2FE1
        ;=======================================================================
        jsr _print_chars

_exit:  stx txt_buffer_index    ; save remaining buffer length          ;$2FE4

        ; restore state
        pla
        tay
        pla
        tax

        ; 'paint' a carriage return, which will move the cursor accordingly
        lda # TXT_NEWLINE
        ; this causes the next instruction to become a meaningless `bit`
        ; instruction, a very handy way of skipping without branching
       .bit

_2fee:                                                                  ;$2FEE
        ;=======================================================================
        ; the BBC code says that char 7 is a beep
.export _2fee

        lda # $07               ; BEEP?
        jmp paint_char

;===============================================================================
; BBC code says this is "update displayed dials"
;
_2ff3:                                                                  ;$2FF3
.export _2ff3

        ; location of the speed bar on the HUD
        ; TODO: this should be defined in the file with the HUD graphics
        dial_speed_addr = ELITE_BITMAP_ADDR + .bmppos(18, 30)

        lda #< dial_speed_addr
        sta ZP_TEMP_ADDR1_LO
        lda #> dial_speed_addr
        sta ZP_TEMP_ADDR1_HI

        jsr _30bb               ; flashing?
        stx ZP_VALUE_pt2
        sta ZP_VALUE_pt1

        lda # 14                ; threshold to change colour?
        sta ZP_TEMP_VAR

        lda PLAYER_SPEED
        jsr hud_drawbar_32

        ;-----------------------------------------------------------------------

        lda # $00
        sta ZP_VAR_R
        sta ZP_VAR_P1

        lda # $08
        sta ZP_VAR_S

        lda ZP_ROLL_MAGNITUDE
        lsr
        lsr
        ora ZP_ROLL_SIGN
        eor # %10000000
        jsr multiplied_now_add
        jsr _3130
        lda ZP_BETA
        ldx ZP_PITCH_MAGNITUDE
        beq _302b
        sbc # $01
_302b:                                                                  ;$302B
        jsr multiplied_now_add
        jsr _3130

        lda ZP_A3               ; move counter?
        and # %00000011
        bne _2fe0

        ldy # $00
        jsr _30bb
        stx ZP_VALUE_pt1
        sta ZP_VALUE_pt2

        ldx # $03               ; 4 energy banks
        stx ZP_TEMP_VAR
_3044:                                                                  ;$3044
        sty ZP_71, x
        dex
        bpl _3044

        ldx # $03
        lda PLAYER_ENERGY
        lsr
        lsr
        sta ZP_VAR_Q
_3052:                                                                  ;$3052
        sec
        sbc # $10
        bcc _3064
        sta ZP_VAR_Q
        lda # $10
        sta ZP_71, x
        lda ZP_VAR_Q
        dex
        bpl _3052
        bmi _3068
_3064:                                                                  ;$3064
        lda ZP_VAR_Q
        sta ZP_71, x
_3068:                                                                  ;$3068
        lda ZP_71, y
        sty ZP_VAR_P1
        jsr hud_drawbar

        ldy ZP_VAR_P1
        iny
        cpy # $04
        bne _3068

        ; location of the fore-shield bar on the HUD
        dial_fore_addr = ELITE_BITMAP_ADDR + .bmppos(18, 6)

        lda #< dial_fore_addr
        sta ZP_TEMP_ADDR1_LO
        lda #> dial_fore_addr
        sta ZP_TEMP_ADDR1_HI
        lda # .color_nybble(LTRED, LTRED)
        sta ZP_VALUE_pt1
        sta ZP_VALUE_pt2

        lda PLAYER_SHIELD_FRONT
        jsr hud_drawbar_128

        lda PLAYER_SHIELD_REAR
        jsr hud_drawbar_128

        lda PLAYER_FUEL
        jsr hud_drawbar_64

        jsr _30bb               ; setup flashing colours
        stx ZP_VALUE_pt2
        sta ZP_VALUE_pt1
        ldx # $0b               ; "threshold to change colour"
        stx ZP_TEMP_VAR

        lda PLAYER_TEMP_CABIN
        jsr hud_drawbar_128

        lda PLAYER_TEMP_LASER
        jsr hud_drawbar_128

        lda # $f0               ; "threshold to change colour"
        sta ZP_TEMP_VAR

        lda VAR_06F3            ; altitude?
        jsr hud_drawbar_128

        jmp _7b6f

;===============================================================================
; decide to flash a dial?
;
_30bb:                                                                  ;$30BB
        ldx # .color_nybble(LTRED, LTRED)

        lda ZP_A3               ; move counter?
        and # %00001000         ; every 8th frame?
        and _1d09               ; is flashing enabled?
       .bze :+

        txa

        ; this causes the next instruction to become a meaningless `bit`
        ; instruction, a very handy way of skipping without branching
       .bit
:       lda # .color_nybble(GREEN, GREEN)                               ;$30C8

        rts

;===============================================================================
; draw a bar on the HUD. e.g. for speed, temperature, shield etc.
;
hud_drawbar_128:                                                        ;$30CB
        ;-----------------------------------------------------------------------
        ; divide value by 8 before drawing the bar:
        ; (accounting for the `lsr`s below)
        ;
        ;       A = value to represent on the bar, 0-127
        ;
        lsr
        lsr

hud_drawbar_64:                                                         ;$3C0D
        ;-----------------------------------------------------------------------
        ; divide value by 4 before drawing the bar:
        ; (accounting for the `lsr` below)
        ;
        ;       A = value to represent on the bar, 0-63
        lsr

hud_drawbar_32:                                                         ;$30CE
        ;-----------------------------------------------------------------------
        ; divide value by 2 before drawing the bar:
        ;
        ;       A = value to represent on the bar, 0-31
        ;
        lsr

hud_drawbar:                                                            ;$30CF
        ;-----------------------------------------------------------------------
        ;
        ;       A = value to represent on the bar, 0-15
        ;
        sta ZP_VAR_Q            ; "bar value 1-15"

        ldx # %11111111         ; mask?
        stx ZP_VAR_R
        cmp ZP_TEMP_VAR         ; "threshold to change colour"
        bcs :+

        lda ZP_VALUE_pt2
        bne :++

:       lda ZP_VALUE_pt1                                                ;$30DD

:       sta ZP_32               ; colour to use                         ;$30DF

        ldy # $02               ; "height offset"
        ldx # $03               ; "height of bar - 1"

_30e5:                                                                  ;$30E5
        lda ZP_VAR_Q            ; get bar value 0-15

        ; subtract 4 if >= 4?
        cmp # $04
       .blt _3109

        sbc # $04
        sta ZP_VAR_Q

        lda ZP_VAR_R            ; mask
_30f1:                                                                  ;$30F1
        and ZP_32
        sta [ZP_TEMP_ADDR1], y
        iny
        sta [ZP_TEMP_ADDR1], y
        iny
        sta [ZP_TEMP_ADDR1], y
        tya
        clc
        adc # $06
        bcc :+
        inc ZP_TEMP_ADDR1_HI

:       tay                                                             ;$3103
        dex
        bmi _next_row
        bpl _30e5
_3109:                                                                  ;$3109
        eor # %00000011
        sta ZP_VAR_Q
        lda ZP_VAR_R

:       asl                                                             ;$310F
        asl
        dec ZP_VAR_Q
        bpl :-
        pha
        lda # $00
        sta ZP_VAR_R
        lda # $63
        sta ZP_VAR_Q
        pla
        jmp _30f1


_next_row:                                                              ;$3122
        ;-----------------------------------------------------------------------
        ; move to the next row in the bitmap:
        ; -- i.e. add 320-px to the bitmap pointer
        ;
        lda ZP_TEMP_ADDR1_LO
        clc
        adc #< 320
        sta ZP_TEMP_ADDR1_LO

        lda ZP_TEMP_ADDR1_HI
        adc #> 320
        sta ZP_TEMP_ADDR1_HI

        rts

;===============================================================================
; ".DIL2 -> roll/pitch indicator takes X.A"
;
_3130:                                                                  ;$3130
        ldy # $01               ; counter Y = 1
        sta ZP_VAR_Q
@_3134:                                                                 ;$3134
        sec
        lda ZP_VAR_Q
        sbc # $04
        bcs @_3149               ; >= 4?

        lda # $ff
        ldx ZP_VAR_Q
        sta ZP_VAR_Q
        lda _28d0, x
        and # %10101010         ; colour mask

        jmp @_314d

@_3149:                                                                 ;$3149
        ; clear the bar
        sta ZP_VAR_Q
        lda # $00
@_314d:                                                                 ;$314D
        ; fill four pixel rows?
        sta [ZP_TEMP_ADDR1], y
        iny
        sta [ZP_TEMP_ADDR1], y
        iny
        sta [ZP_TEMP_ADDR1], y
        iny
        sta [ZP_TEMP_ADDR1], y
        tya

        ; move to the next cell?
        clc
        adc # $05
        tay
        cpy # $1e
        bcc @_3134

        lda ZP_TEMP_ADDR1_LO
        adc # $3f
        sta ZP_TEMP_ADDR1_LO
        lda ZP_TEMP_ADDR1_HI
        adc # $01
        sta ZP_TEMP_ADDR1_HI

        rts

;===============================================================================
; eject escape pod
;
eject_escapepod:                                                        ;$316E

        jsr _83df

        ldx # $0b
        stx ZP_A5

        jsr _3680
        bcs _317f

        ldx # $18
        jsr _3680
_317f:                                                                  ;$317F
        lda # $08
        sta ZP_POLYOBJ_VERTX_LO

        lda # %11000010
        sta ZP_POLYOBJ_PITCH
        lsr
        sta ZP_POLYOBJ_ATTACK
_318a:                                                                  ;$318A
        jsr _a2a0
        jsr _9a86

        dec ZP_POLYOBJ_ATTACK
        bne _318a

        jsr _b410

        lda # $00
        ldx # .sizeof(Cargo)-1

:       sta VAR_CARGO, x        ; empty cargo slot                      ;$319B
        dex
        bpl :-

        sta PLAYER_LEGAL        ; clear legal status
        sta PLAYER_ESCAPEPOD    ; you no longer own an escape pod

        ; some Trumbles™ will slip away
        ; with you, the sneaky things!
.ifndef OPTION_NOTRUMBLES
        ;///////////////////////////////////////////////////////////////////////

        ; does the player have any Trumbles™?
        lda PLAYER_TRUMBLES_LO
        ora PLAYER_TRUMBLES_HI
        beq _31be               ; no Trumbles™; skip

        ; cull the number of Trumbles™
        jsr get_random_number
        and # %00000111         ; select a range of 0-7
        ora # %00000001         ; restrict to 1, 3, 5 or 7
        sta PLAYER_TRUMBLES_LO
        lda # $00
        sta PLAYER_TRUMBLES_HI

.endif  ;///////////////////////////////////////////////////////////////////////

_31be:                                                                  ;$31BE
        lda # $46
        sta PLAYER_FUEL
        jmp _2101

;===============================================================================

_31c6:                                                                  ;$31C6
.export _31c6

        lda # $0e
        jsr print_docked_str

        jsr _6f82
        jsr _70a0
        lda # $00
        sta ZP_AE
_31d5:                                                                  ;$31D5
        jsr txt_docked_token0E
        jsr _76e9

        ldx txt_buffer_index
        lda ZP_POLYOBJ_YPOS_HI, x       ;=$0E?
        cmp # $0d
        bne _31f1
_31e4:                                                                  ;$31E4
        dex
        lda ZP_POLYOBJ_YPOS_HI, x       ;=$0E?
        ora # %00100000
        cmp VAR_0648, x
        beq _31e4
        txa
        bmi _3208
_31f1:                                                                  ;$31F1
        jsr randomize
        inc ZP_AE
        bne _31d5
        jsr _70ab
        jsr _6f82
        ldy # $06
        jsr _a858

        lda # $d7
        jmp print_docked_str

        ;-----------------------------------------------------------------------

_3208:                                                                  ;$3208
        lda ZP_SEED_W1_HI
        sta TSYSTEM_POS_X
        lda ZP_SEED_W0_HI
        sta TSYSTEM_POS_Y
        jsr _70ab
        jsr _6f82
        jsr txt_docked_token0F
        jmp _877e

;===============================================================================

_321e:                                                                  ;$321E
        lda ZP_POLYOBJ_XPOS_LO  ;=$09
        ora ZP_POLYOBJ_YPOS_LO  ;=$0C
        ora ZP_POLYOBJ_ZPOS_LO  ;=$0F
        bne _322b

        lda # $50
        jsr _7bd2
_322b:                                                                  ;$322B
        ldx # $04
        bne _3290
_322f:                                                                  ;$322F
        lda # $00
        jsr _87b1
        beq _3239
        jmp _3365

        ;-----------------------------------------------------------------------

_3239:                                                                  ;$3239
        jsr _3293
        jsr _a813
        lda # $fa
        jmp _7bd2

        ;-----------------------------------------------------------------------

_3244:                                                                  ;$3244
        lda ZP_67
        bne _321e

        lda ZP_POLYOBJ_ATTACK
        asl
        bmi _322f

        lsr
        tax
        lda polyobj_addrs_lo, x
        sta ZP_TEMP_ADDR3_LO
        lda polyobj_addrs_hi, x
        jsr _3581

        lda ZP_POLYOBJ01_XPOS_pt3
        ora ZP_POLYOBJ01_YPOS_pt3
        ora ZP_POLYOBJ01_ZPOS_pt3
        and # %01111111
        ora ZP_POLYOBJ01_XPOS_pt2
        ora ZP_POLYOBJ01_YPOS_pt2
        ora ZP_POLYOBJ01_ZPOS_pt2
        bne _3299

        lda ZP_POLYOBJ_ATTACK
        cmp # attack::active | attack::aggr1    ;=%10000010
        beq _321e

        ldy # $1f
        lda [ZP_TEMP_ADDR3], y
        ; this might be a `ldy # $32`, but I don't see any jump into it
        bit _32a0+1             ;!?
        bne _327d
        ora # %10000000
        sta [ZP_TEMP_ADDR3], y
_327d:                                                                  ;$327D
        lda ZP_POLYOBJ_XPOS_LO  ;=$09
        ora ZP_POLYOBJ_YPOS_LO  ;=$0C
        ora ZP_POLYOBJ_ZPOS_LO  ;=$0F
        bne _328a

        lda # $50
        jsr _7bd2
_328a:                                                                  ;$328A
        lda ZP_POLYOBJ_ATTACK
        and # attack::active ^$FF       ;=%01111111
        lsr
        tax
_3290:                                                                  ;$3290
        jsr _a7a6
_3293:                                                                  ;$3293
        asl ZP_POLYOBJ_VISIBILITY
        sec
        ror ZP_POLYOBJ_VISIBILITY
_3298:                                                                  ;$3298
        rts

        ;-----------------------------------------------------------------------

_3299:                                                                  ;$3299
        jsr get_random_number
        cmp # $10
        bcs _32a7
_32a0:                                                                  ;$32A0
        ldy # $20
        lda [ZP_TEMP_ADDR3], y
        lsr
        bcs _32aa
_32a7:                                                                  ;$32A7
        jmp _336e

_32aa:                                                                  ;$32AA
        jmp _b0f4

;===============================================================================

_32ad:                                                                  ;$32AD
.export _32ad

        lda #< VAR_0403
        sta ZP_B0
        lda #> VAR_0403
        sta ZP_B1
        lda # $16
        sta ZP_AB
        cpx # $01
        beq _3244
        cpx # $02
        bne _32ef

        lda ZP_POLYOBJ_BEHAVIOUR
        and # behaviour::angry
        bne _32da

        lda VAR_0467
        bne _3298
        jsr get_random_number
        cmp # $fd
        bcc _3298
        and # %00000001
        adc # $08
        tax
        bne _32ea
_32da:                                                                  ;$32DA
        jsr get_random_number
        cmp # $f0
        bcc _3298
        lda VAR_046D
        cmp # $04
        bcs _3328
        ldx # $10
_32ea:                                                                  ;$32EA
        lda # $f1
        jmp _370a

        ;-----------------------------------------------------------------------

_32ef:                                                                  ;$32EF
        cpx # $0f
        bne _330f
        jsr get_random_number
        cmp # $c8
        bcc _3328

        ldx # %00000000
        stx ZP_POLYOBJ_ATTACK

        ldx # behaviour::protected | behaviour::angry   ;=%00100100
        stx ZP_POLYOBJ_BEHAVIOUR

        and # %00000011
        adc # $11
        tax
        jsr _32ea

        lda # %00000000
        sta ZP_POLYOBJ_ATTACK
        rts

        ;-----------------------------------------------------------------------

_330f:                                                                  ;$330F
        ldy # Hull::energy      ;=$0E: energy
        lda ZP_POLYOBJ_ENERGY
        cmp [ZP_HULL_ADDR], y
        bcs _3319
        inc ZP_POLYOBJ_ENERGY
_3319:                                                                  ;$3319
        cpx # $1e
        bne _3329

        lda VAR_047A
        bne _3329

        lsr ZP_POLYOBJ_ATTACK
        asl ZP_POLYOBJ_ATTACK
        lsr ZP_POLYOBJ_VERTX_LO
_3328:                                                                  ;$3328
        rts

        ;-----------------------------------------------------------------------

_3329:                                                                  ;$3329
        jsr get_random_number
        lda ZP_POLYOBJ_BEHAVIOUR
        lsr
        bcc _3335
        cpx # $32
        bcs _3328
_3335:                                                                  ;$3335
        lsr
        bcc _3347
        ldx PLAYER_LEGAL
        cpx # $28
        bcc _3347
        lda ZP_POLYOBJ_BEHAVIOUR
        ora # behaviour::angry
        sta ZP_POLYOBJ_BEHAVIOUR
        lsr
        lsr
_3347:                                                                  ;$3347
        lsr
        bcs _3357
        lsr
        lsr
        bcc _3351
        jmp _34bc

        ;-----------------------------------------------------------------------

_3351:                                                                  ;$3351
        jsr _8c7b
        jmp _34ac

        ;-----------------------------------------------------------------------

_3357:                                                                  ;$3357
        lsr
        bcc _3365

        lda VAR_045F
        beq _3365

        lda ZP_POLYOBJ_ATTACK
        and # attack::active | attack::ecm      ;=%10000001
        sta ZP_POLYOBJ_ATTACK
_3365:                                                                  ;$3365
        ldx # $08
_3367:                                                                  ;$3367
        lda ZP_POLYOBJ_XPOS_LO, x
        sta ZP_POLYOBJ01_XPOS_pt1, x
        dex
        bpl _3367
_336e:                                                                  ;$336E
        jsr _8c8a
        ldy # $0a
        jsr _3ab2
        sta ZP_AA
        lda ZP_A5
        cmp # $01
        bne _3381
        jmp _344b

        ;-----------------------------------------------------------------------

_3381:                                                                  ;$3381
        cmp # $0e
        bne _339a
_3385:                                                                  ;$3385
.export _3385

        jsr get_random_number
        cmp # $c8
        bcc _339a
        jsr get_random_number
        ldx # $17
        cmp # $64
        bcs _3397
        ldx # $11
_3397:                                                                  ;$3397
        jmp _32ea

        ;-----------------------------------------------------------------------

_339a:                                                                  ;$339A
        jsr get_random_number
        cmp # $fa
        bcc _33a8
        jsr get_random_number
        ora # %01101000
        sta ZP_POLYOBJ_ROLL
_33a8:                                                                  ;$33A8
        ldy # Hull::energy      ;=$0E: energy
        lda [ZP_HULL_ADDR], y
        lsr
        cmp ZP_POLYOBJ_ENERGY
        bcc _33fd
        lsr
        lsr
        cmp ZP_POLYOBJ_ENERGY
        bcc _33d6
        jsr get_random_number
        cmp # $e6
        bcc _33d6
        ldx ZP_A5
        lda hull_d042 - 1, x
        bpl _33d6
        lda ZP_POLYOBJ_BEHAVIOUR
        and # behaviour::remove    | behaviour::police \
            | behaviour::protected | behaviour::docking ;=%11110000
        sta ZP_POLYOBJ_BEHAVIOUR
        ldy # PolyObject::behaviour
        sta [ZP_POLYOBJ_ADDR], y

        lda # %00000000
        sta ZP_POLYOBJ_ATTACK
        jmp _3706

        ;-----------------------------------------------------------------------

_33d6:                                                                  ;$33D6
        lda ZP_POLYOBJ_VISIBILITY
        and # visibility::missiles
        beq _33fd
        sta ZP_VAR_T

        jsr get_random_number
        and # %00011111
        cmp ZP_VAR_T
        bcs _33fd

        lda ZP_67
        bne _33fd
        dec ZP_POLYOBJ_VISIBILITY       ; reduce number of missiles?
        lda ZP_A5
        cmp # $1d
        bne _33fa

        ldx # %00011110
        lda ZP_POLYOBJ_ATTACK
        jmp _370a

        ;-----------------------------------------------------------------------

_33fa:                                                                  ;$33FA
        jmp _a795

        ;-----------------------------------------------------------------------

_33fd:                                                                  ;$33FD
        lda # $00
        jsr _87b1
        and # %11100000
        bne _3434
        ldx ZP_AA
        cpx # $a0
        bcc _3434

        ldy # Hull::_13         ;=$13: "laser / missile count"?
        lda [ZP_HULL_ADDR], y
        and # %11111000
        beq _3434

        lda ZP_POLYOBJ_VISIBILITY
        ora # visibility::firing
        sta ZP_POLYOBJ_VISIBILITY
        cpx # $a3
        bcc _3434

        lda [ZP_HULL_ADDR], y
        lsr
        jsr _7bd2
        dec ZP_POLYOBJ_VERTX_HI
        lda ZP_67
        bne _3499
        ldy # $01
        jsr _a858
        ldy # $0f
        jmp _a858

        ;-----------------------------------------------------------------------

_3434:                                                                  ;$3434
        lda ZP_POLYOBJ_ZPOS_MI  ;=$10
        cmp # $03
        bcs _3442
        lda ZP_POLYOBJ_XPOS_MI  ;=$0A
        ora ZP_POLYOBJ_YPOS_MI  ;=$0D
        and # %11111110
        beq _3454
_3442:                                                                  ;$3442
        ; randomly generate an attacking ship?
        jsr get_random_number
        ora # attack::active    ;=%10000000
        cmp ZP_POLYOBJ_ATTACK
        bcs _3454
_344b:                                                                  ;$344B
        jsr _35d5
        lda ZP_AA
        eor # %10000000
_3452:                                                                  ;$3452
        sta ZP_AA
_3454:                                                                  ;$3454
        ldy # $10
        jsr _3ab2
        tax
        eor # %10000000
        and # %10000000
        sta ZP_POLYOBJ_PITCH
        txa
        asl
        cmp ZP_B1
        bcc _346c
        lda ZP_B0
        ora ZP_POLYOBJ_PITCH
        sta ZP_POLYOBJ_PITCH
_346c:                                                                  ;$346C
        lda ZP_POLYOBJ_ROLL
        asl
        cmp # $20
        bcs _348d
        ldy # $16
        jsr _3ab2
        tax
        eor ZP_POLYOBJ_PITCH
        and # %10000000
        eor # %10000000
        sta ZP_POLYOBJ_ROLL
        txa
        asl
        cmp ZP_B1
        bcc _348d
        lda ZP_B0
        ora ZP_POLYOBJ_ROLL
        sta ZP_POLYOBJ_ROLL
_348d:                                                                  ;$348D
        lda ZP_AA
        bmi _349a
        cmp ZP_AB
        bcc _349a
        lda #> $0300            ; processed vertex data is stored at $0300+
        sta ZP_POLYOBJ_VERTX_HI
_3499:                                                                  ;$3499
        rts

        ;-----------------------------------------------------------------------

_349a:                                                                  ;$349A
        and # %01111111
        cmp # $12
        bcc _34ab

        lda # $ff
        ldx ZP_A5
        cpx # $01
        bne _34a9

        asl
_34a9:                                                                  ;$34A9
        sta ZP_POLYOBJ_VERTX_HI
_34ab:                                                                  ;$34AB
        rts

        ;-----------------------------------------------------------------------

_34ac:                                                                  ;$34AC
        ldy # $0a
        jsr _3ab2
        cmp # $98
        bcc _34b9
        ldx # $00
        stx ZP_B1
_34b9:                                                                  ;$24B9
        jmp _3452

;===============================================================================

_34bc:                                                                  ;$34BC
.export _34bc

        lda # $06
        sta ZP_B1
        lsr
        sta ZP_B0
        lda # $1d
        sta ZP_AB
        lda VAR_045F
        bne _34cf
_34cc:                                                                  ;$34CC
        jmp _3351

        ;-----------------------------------------------------------------------

_34cf:                                                                  ;$34CF
        jsr _357b
        lda ZP_POLYOBJ01_XPOS_pt3
        ora ZP_POLYOBJ01_YPOS_pt3
        ora ZP_POLYOBJ01_ZPOS_pt3
        and # %01111111
        bne _34cc
        jsr _8cad
        lda ZP_VAR_Q
        sta ZP_VALUE_pt1
        jsr _8c8a
        ldy # $0a
        jsr _35b3
        bmi _3512
        cmp # $23
        bcc _3512
        ldy # $0a
        jsr _3ab2
        cmp # $a2
        bcs _352c
        lda ZP_VALUE_pt1
        cmp # $9d
        bcc _3504
        lda ZP_A5
        bmi _352c
_3504:                                                                  ;$3504
        jsr _35d5
        jsr _34ac
_350a:                                                                  ;$350A
        ldx # $00
        stx ZP_POLYOBJ_VERTX_HI
        inx
        stx ZP_POLYOBJ_VERTX_LO

        rts

        ;-----------------------------------------------------------------------

_3512:                                                                  ;$3512
        jsr _357b
        jsr _35e8
        jsr _35e8
        jsr _8c8a
        jsr _35d5
        jmp _34ac

        ;-----------------------------------------------------------------------

_3524:                                                                  ;$3524
        inc ZP_POLYOBJ_VERTX_HI
        lda # $7f
        sta ZP_POLYOBJ_ROLL
        bne _3571
_352c:                                                                  ;$352C
        ldx # $00
        stx ZP_B1
        stx ZP_POLYOBJ_PITCH
        lda ZP_A5
        bpl _3556
        eor ZP_VAR_X
        eor ZP_VAR_Y
        asl
        lda # $02
        ror
        sta ZP_POLYOBJ_ROLL
        lda ZP_VAR_X
        asl
        cmp # $0c
        bcs _350a
        lda ZP_VAR_Y
        asl
        lda # $02
        ror
        sta ZP_POLYOBJ_PITCH
        lda ZP_VAR_Y
        asl
        cmp # $0c
        bcs _350a
_3556:                                                                  ;$3556
        stx ZP_POLYOBJ_ROLL
        lda ZP_POLYOBJ_M2x0_HI
        sta ZP_VAR_X
        lda ZP_POLYOBJ_M2x1_HI
        sta ZP_VAR_Y
        lda ZP_POLYOBJ_M2x2_HI
        sta ZP_VAR_X2
        ldy # $10
        jsr _35b3
        asl
        cmp # $42
        bcs _3524
        jsr _350a
_3571:                                                                  ;$3571
        lda ZP_3F               ; only use, ever. does not get set!
        bne _357a

        asl ZP_POLYOBJ_BEHAVIOUR
        sec
        ror ZP_POLYOBJ_BEHAVIOUR
_357a:                                                                  ;$357A
        rts

;===============================================================================

_357b:                                                                  ;$357B
        lda #< POLYOBJ_01       ;=$F925
        sta ZP_TEMP_ADDR3_LO
        lda #> POLYOBJ_01       ;=$F925
_3581:  sta ZP_TEMP_ADDR3_HI                                            ;$3581

        ldy # $02
        jsr _358f

        ldy # $05
        jsr _358f

        ldy # $08
_358f:                                                                  ;$358F
        lda [ZP_TEMP_ADDR3], y
        eor # %10000000
        sta ZP_VALUE_pt4

        dey
        lda [ZP_TEMP_ADDR3], y
        sta ZP_VALUE_pt3

        dey
        lda [ZP_TEMP_ADDR3], y
        sta ZP_VALUE_pt2

        sty ZP_VAR_U
        ldx ZP_VAR_U
        jsr _2d69

        ldy ZP_VAR_U
        sta ZP_POLYOBJ01_XPOS_pt3, x
        lda ZP_VALUE_pt3
        sta ZP_POLYOBJ01_XPOS_pt2, x
        lda ZP_VALUE_pt2
        sta ZP_POLYOBJ01_XPOS_pt1, x
        rts

;===============================================================================

_35b3:                                                                  ;$35B3
        ldx POLYOBJ_01 + PolyObject::xpos + 0, y                        ;=$F925
        stx ZP_VAR_Q
        lda ZP_VAR_X
        jsr multiply_signed_into_RS
        ldx POLYOBJ_01 + PolyObject::xpos + 2, y                        ;=$F927
        stx ZP_VAR_Q
        lda ZP_VAR_Y
        jsr multiply_and_add
        sta ZP_VAR_S
        stx ZP_VAR_R
        ldx POLYOBJ_01 + PolyObject::ypos + 1, y                        ;=$F929
        stx ZP_VAR_Q
        lda ZP_VAR_X2
        jmp multiply_and_add

;===============================================================================

_35d5:                                                                  ;$35D5
        lda ZP_VAR_X
        eor # %10000000
        sta ZP_VAR_X
        lda ZP_VAR_Y
        eor # %10000000
        sta ZP_VAR_Y
        lda ZP_VAR_X2
        eor # %10000000
        sta ZP_VAR_X2
        rts

;===============================================================================

_35e8:                                                                  ;$35E8
        jsr _35eb
_35eb:                                                                  ;$35EB
        lda POLYOBJ_01 + PolyObject::m0x0 + 1                           ;=$F92F
        ldx # $00
        jsr _3600
        lda POLYOBJ_01 + PolyObject::m0x1 + 1                           ;=$F931
        ldx # $03
        jsr _3600
        lda POLYOBJ_01 + PolyObject::m0x2 + 1                           ;=$F933
        ldx # $06
_3600:                                                                  ;$3600
        asl
        sta ZP_VAR_R
        lda # $00
        ror
        eor # %10000000
        eor ZP_POLYOBJ01_XPOS_pt3, x
        bmi _3617
        lda ZP_VAR_R
        adc ZP_POLYOBJ01_XPOS_pt1, x
        sta ZP_POLYOBJ01_XPOS_pt1, x
        bcc _3616
        inc ZP_POLYOBJ01_XPOS_pt2, x
_3616:                                                                  ;$3616
        rts

        ;-----------------------------------------------------------------------

_3617:                                                                  ;$3617
        lda ZP_POLYOBJ01_XPOS_pt1, x
        sec
        sbc ZP_VAR_R
        sta ZP_POLYOBJ01_XPOS_pt1, x
        lda ZP_POLYOBJ01_XPOS_pt2, x
        sbc # $00
        sta ZP_POLYOBJ01_XPOS_pt2, x
        bcs _3616
        lda ZP_POLYOBJ01_XPOS_pt1, x
        eor # %11111111
        adc # $01
        sta ZP_POLYOBJ01_XPOS_pt1, x
        lda ZP_POLYOBJ01_XPOS_pt2, x
        eor # %11111111
        adc # $00
        sta ZP_POLYOBJ01_XPOS_pt2, x
        lda ZP_POLYOBJ01_XPOS_pt3, x
        eor # %10000000
        sta ZP_POLYOBJ01_XPOS_pt3, x
        jmp _3616

;===============================================================================

_363f:                                                                  ;$363F
        clc
        lda ZP_POLYOBJ_ZPOS_HI
        bne _367d

        lda ZP_A5
        bmi _367d

        lda ZP_POLYOBJ_VISIBILITY
        and # visibility::display
        ora ZP_POLYOBJ_XPOS_MI
        ora ZP_POLYOBJ_YPOS_MI
        bne _367d

        lda ZP_POLYOBJ_XPOS_LO
        jsr math_square
        sta ZP_VAR_S

        lda ZP_VAR_P1
        sta ZP_VAR_R

        lda ZP_POLYOBJ_YPOS_LO
        jsr math_square

        tax
        lda ZP_VAR_P1
        adc ZP_VAR_R
        sta ZP_VAR_R
        txa
        adc ZP_VAR_S
        bcs _367e
        sta ZP_VAR_S
        ldy # Hull::_0102 + 1   ;=$02: "missile lock area" hi-byte?
        lda [ZP_HULL_ADDR], y
        cmp ZP_VAR_S
        bne _367d
        dey                     ;=$01: "missile lock area" lo-byte?
        lda [ZP_HULL_ADDR], y
        cmp ZP_VAR_R
_367d:                                                                  ;$367D
        rts

        ;-----------------------------------------------------------------------

_367e:                                                                  ;$367E
        clc
        rts

;===============================================================================

_3680:                                                                  ;$3680
        jsr clear_zp_polyobj
        lda # $1c
        sta ZP_POLYOBJ_YPOS_LO
        lsr
        sta ZP_POLYOBJ_ZPOS_LO
        lda # $80
        sta ZP_POLYOBJ_YPOS_HI

        lda ZP_MISSILE_TARGET
        asl
        ora # attack::active
        sta ZP_POLYOBJ_ATTACK

_3695:                                                                  ;$3695
.export _3695

        lda # $60
        sta ZP_POLYOBJ_M0x2_HI
        ora # %10000000
        sta ZP_POLYOBJ_M2x0_HI

        lda PLAYER_SPEED
        rol
        sta ZP_POLYOBJ_VERTX_LO

        txa
        jmp _7c6b

;===============================================================================

_36a6:                                                                  ;$36A6
        ldx # $01
        jsr _3680
        bcc _3701

        ldx ZP_MISSILE_TARGET
        jsr get_polyobj

        lda SHIP_SLOTS, x
        jsr _36c5

        ldy # $b7
        jsr _7d0c

        dec PLAYER_MISSILES

        ldy # $04
        jmp _a858

;===============================================================================
; target / fire missile?

.import hull_coreolis_index:direct

_36c5:                                                                  ;$36C5
        ; firing misisle at space station?
        ; (not a good idea)
        cmp # hull_coreolis_index       ;$02
        ; make the space-station hostile?
        beq _36f8

        ldy # PolyObject::behaviour
        lda [ZP_POLYOBJ_ADDR], y
        and # behaviour::protected
        beq _36d4

        jsr _36f8
_36d4:                                                                  ;$36D4
        ldy # PolyObject::attack
        lda [ZP_POLYOBJ_ADDR], y
        beq _367d

        ora # %10000000
        sta [ZP_POLYOBJ_ADDR], y

        ldy # $1c
        lda # $02
        sta [ZP_POLYOBJ_ADDR], y
        asl
        ldy # $1e
        sta [ZP_POLYOBJ_ADDR], y

        lda ZP_A5
        cmp # $0b
        bcc _36f7

        ldy # PolyObject::behaviour
        lda [ZP_POLYOBJ_ADDR], y
        ora # behaviour::angry
        sta [ZP_POLYOBJ_ADDR], y
_36f7:                                                                  ;$36F7
        rts

        ;-----------------------------------------------------------------------

_36f8:                                                                  ;$36F8
        ; make hostile?
        lda POLYOBJ_01 + PolyObject::behaviour                         ;=$F949
        ora # behaviour::angry
        sta POLYOBJ_01 + PolyObject::behaviour                         ;=$F949
        rts

_3701:                                                                  ;$3701
        lda # $c9
        jmp _900d

;===============================================================================

_3706:                                                                  ;$3706
        ldx # $03
_3708:                                                                  ;$3708
.export _3708

        lda # $fe
_370a:                                                                  ;$370A
        sta ZP_TEMP_VAR
       .phx                     ; push X to stack (via A)
        lda ZP_HULL_ADDR_LO
        pha
        lda ZP_HULL_ADDR_HI
        pha
        lda ZP_POLYOBJ_ADDR_LO
        pha
        lda ZP_POLYOBJ_ADDR_HI
        pha
        ldy # $24
_371c:                                                                  ;$371C
        lda ZP_POLYOBJ_XPOS_LO, y
        sta $0100, y            ; the stack!?
        lda [ZP_POLYOBJ_ADDR], y
        sta ZP_POLYOBJ_XPOS_LO, y
        dey
        bpl _371c
        lda ZP_A5
        cmp # $02
        bne _374d
       .phx                     ; push X to stack (via A)
        lda # $20
        sta ZP_POLYOBJ_VERTX_LO
        ldx # $00
        lda ZP_POLYOBJ_M0x0_HI
        jsr _378c
        ldx # $03
        lda ZP_POLYOBJ_M0x1_HI
        jsr _378c
        ldx # $06
        lda ZP_POLYOBJ_M0x2_HI
        jsr _378c
        pla
        tax
_374d:                                                                  ;$374D
        lda ZP_TEMP_VAR
        sta ZP_POLYOBJ_ATTACK
        lsr ZP_POLYOBJ_ROLL
        asl ZP_POLYOBJ_ROLL
        txa
        cmp # $09
        bcs _3770
        cmp # $04
        bcc _3770
        pha
        jsr get_random_number
        asl
        sta ZP_POLYOBJ_PITCH
        txa
        and # %00001111
        sta ZP_POLYOBJ_VERTX_LO
        lda # $ff
        ror
        sta ZP_POLYOBJ_ROLL
        pla
_3770:                                                                  ;$3770
        jsr _7c6b
        pla
        sta ZP_POLYOBJ_ADDR_HI
        pla
        sta ZP_POLYOBJ_ADDR_LO
        ldx # $24
_377b:                                                                  ;$377B
        lda $0100, x
        sta ZP_POLYOBJ_XPOS_LO, x
        dex
        bpl _377b
        pla
        sta ZP_HULL_ADDR_HI
        pla
        sta ZP_HULL_ADDR_LO
        pla
        tax
        rts

;===============================================================================

_378c:                                                                  ;$378C
        asl
        sta ZP_VAR_R
        lda # $00
        ror
        jmp move_polyobj_x

_3795:                                                                  ;$3795
.export _3795

        jsr _a839
        lda # $04
        jsr _37a5

        rts

;===============================================================================

_379e:                                                                  ;$397E
.export _379e

        ldy # $04
        jsr _a858
        lda # $08
_37a5:                                                                  ;$37A5
        sta ZP_AC

        lda ZP_SCREEN
        pha

        ; switch to cockpit-view?
        lda # $00
        jsr set_page

        pla
        sta ZP_SCREEN

_37b2:                                                                  ;$37B2
.export _37b2

        ldx # $80
        stx ZP_POLYOBJ01_XPOS_pt1

        ldx # $48               ;TODO: half viewport height?
        stx ZP_43

        ldx # $00
        stx ZP_AD
        stx ZP_POLYOBJ01_XPOS_pt2
        stx ZP_44
_37c2:                                                                  ;$37C2
        jsr _37ce
        inc ZP_AD
        ldx ZP_AD
        cpx # $08
        bne _37c2
        rts

;===============================================================================

_37ce:                                                                  ;$37CE
        lda ZP_AD
        and # %00000111
        clc
        adc # $08
        sta ZP_VALUE_pt1
_37d7:                                                                  ;$37D7
        lda # $01
        sta ZP_7E
        jsr _805e
        asl ZP_VALUE_pt1
        bcs _37e8
        lda ZP_VALUE_pt1
        cmp # $a0
        bcc _37d7
_37e8:                                                                  ;$37E8
        rts

;===============================================================================

_37e9:                                                                  ;$37E9
        lda # $00
        cpx # $02
        ror
        sta ZP_B0
        eor # %10000000
        sta ZP_B1
        jsr _38a3
        ldy DUST_COUNT          ; number of dust particles
_37fa:                                                                  ;$37FA
        lda DUST_Z, y
        sta ZP_VAR_Z
        lsr
        lsr
        lsr
        jsr _3b33
        lda ZP_VAR_P1
        sta ZP_BA
        eor ZP_B1
        sta ZP_VAR_S
        lda VAR_06AF, y         ; inside `DUST_X` array
        sta ZP_VAR_P1
        lda DUST_X, y
        sta ZP_VAR_X
        jsr multiplied_now_add
        sta ZP_VAR_S
        stx ZP_VAR_R
        lda DUST_Y, y
        sta ZP_VAR_Y
        eor ZP_PITCH_SIGN
        ldx ZP_PITCH_MAGNITUDE
        jsr _393e
        jsr multiplied_now_add
        stx ZP_VAR_XX_LO
        sta ZP_VAR_XX_HI
        ldx VAR_06C9, y         ; inside `DUST_Y` array
        stx ZP_VAR_R
        ldx ZP_VAR_Y
        stx ZP_VAR_S
        ldx ZP_PITCH_MAGNITUDE
        eor ZP_95
        jsr _393e
        jsr multiplied_now_add
        stx ZP_VAR_YY_LO
        sta ZP_VAR_YY_HI
        ldx ZP_ROLL_MAGNITUDE
        eor ZP_ROLL_SIGN
        jsr _393e
        sta ZP_VAR_Q
        lda ZP_VAR_XX_LO
        sta ZP_VAR_R
        lda ZP_VAR_XX_HI
        sta ZP_VAR_S
        eor # %10000000
        jsr multiply_and_add
        sta ZP_VAR_XX_HI
        txa
        sta VAR_06AF, y         ; inside `DUST_X` array
        lda ZP_VAR_YY_LO
        sta ZP_VAR_R
        lda ZP_VAR_YY_HI
        sta ZP_VAR_S
        jsr multiply_and_add
        sta ZP_VAR_S
        stx ZP_VAR_R
        lda # $00
        sta ZP_VAR_P1
        lda ZP_ALPHA
        jsr _290f
        lda ZP_VAR_XX_HI
        sta DUST_X, y
        sta ZP_VAR_X
        and # %01111111
        eor # %01111111
        cmp ZP_BA
        bcc _38be
        beq _38be
        lda ZP_VAR_YY_HI
        sta DUST_Y, y
        sta ZP_VAR_Y
        and # %01111111
_3895:                                                                  ;$3895
.export _3895

        cmp # $74
        bcs _38d1
_389a:                                                                  ;$389A
        jsr draw_particle
        dey
        beq _38a3
        jmp _37fa

        ;-----------------------------------------------------------------------

_38a3:                                                                  ;$38A3
        lda ZP_ALPHA
        eor ZP_B0
        sta ZP_ALPHA
        lda ZP_ROLL_SIGN        ; roll sign?
        eor ZP_B0
        sta ZP_ROLL_SIGN        ; roll sign?
        eor # %10000000
        sta ZP_6A               ; move count?
        lda ZP_PITCH_SIGN
        eor ZP_B0
        sta ZP_PITCH_SIGN
        eor # %10000000
        sta ZP_95
        rts

        ;-----------------------------------------------------------------------

_38be:                                                                  ;$38BE
        jsr get_random_number
        sta ZP_VAR_Y
        sta DUST_Y, y
        lda # $73
        ora ZP_B0
        sta ZP_VAR_X
        sta DUST_X, y
        bne _38e2
_38d1:                                                                  ;$38D1
        jsr get_random_number
        sta ZP_VAR_X
        sta DUST_X, y
        lda # $6e
        ora ZP_6A               ; move count?
        sta ZP_VAR_Y
        sta DUST_Y, y
_38e2:                                                                  ;$38E2
        jsr get_random_number
        ora # %00001000
        sta ZP_VAR_Z
        sta DUST_Z, y
        bne _389a
_38ee:                                                                  ;$38EE
        sta ZP_VALUE_pt1
        sta ZP_VALUE_pt2
        sta ZP_VALUE_pt3
        sta ZP_VALUE_pt4
        clc
        rts

        ;-----------------------------------------------------------------------

_38f8:                                                                  ;$38F8
.export _38f8

        sta ZP_VAR_R
        and # %01111111
        sta ZP_VALUE_pt3
        lda ZP_VAR_Q
        and # %01111111
        beq _38ee
        sec
        sbc # $01
        sta ZP_VAR_T
        lda ZP_VAR_P2
        lsr ZP_VALUE_pt3
        ror
        sta ZP_VALUE_pt2
        lda ZP_VAR_P1
        ror
        sta ZP_VALUE_pt1
        lda # $00
        ldx # $18
_3919:                                                                  ;$3919
        bcc _391d
        adc ZP_VAR_T
_391d:                                                                  ;$391D
        ror
        ror ZP_VALUE_pt3
        ror ZP_VALUE_pt2
        ror ZP_VALUE_pt1
        dex
        bne _3919
        sta ZP_VAR_T
        lda ZP_VAR_R
        eor ZP_VAR_Q
        and # %10000000
        ora ZP_VAR_T
        sta ZP_VALUE_pt4
        rts

;===============================================================================

_3934:                                                                  ;$3934
        ldx ZP_VAR_XX_LO
        stx ZP_VAR_R
        ldx ZP_VAR_XX_HI
        stx ZP_VAR_S
_393c:                                                                  ;$393C
        ldx ZP_ROLL_MAGNITUDE
_393e:                                                                  ;$393E
        stx ZP_VAR_P1
        tax
        and # %10000000
        sta ZP_VAR_T
        txa
        and # %01111111
        beq _3981
        tax
        dex
        stx ZP_TEMP_VAR
        lda # $00
        lsr ZP_VAR_P1
        bcc _3956
        adc ZP_TEMP_VAR
_3956:                                                                  ;$3956
        ror
        ror ZP_VAR_P1
        bcc _395d
        adc ZP_TEMP_VAR
_395d:                                                                  ;$395D
        ror
        ror ZP_VAR_P1
        bcc _3964
        adc ZP_TEMP_VAR
_3964:                                                                  ;$3964
        ror
        ror ZP_VAR_P1
        bcc _396b
        adc ZP_TEMP_VAR
_396b:                                                                  ;$396B
        ror
        ror ZP_VAR_P1
        bcc _3972
        adc ZP_TEMP_VAR
_3972:                                                                  ;$3972
        ror
        ror ZP_VAR_P1
        lsr
        ror ZP_VAR_P1
        lsr
        ror ZP_VAR_P1
        lsr
        ror ZP_VAR_P1
        ora ZP_VAR_T
        rts

        ;-----------------------------------------------------------------------

_3981:                                                                  ;$3981
        sta ZP_VAR_P2
        sta ZP_VAR_P1
        rts

;===============================================================================
; insert some routines from "math.inc"
;
.math_square                                                            ;$3986

;===============================================================================
_39e0:                                                                  ;$39E0
.export _39e0                   ; calculate ZP_VALUE_pt1 * abs(sin(A))

        and # %00011111
        tax                     ; X = A%31, with 0..31 equiv. 0..pi
        lda table_sin, x
        sta ZP_VAR_Q            ; Q = abs(sin(A))*256
        lda ZP_VALUE_pt1
_39ea:                                                                  ;$39EA
.export _39ea                   ; calculate A=(A*Q)/256 via log-tables

        stx ZP_VAR_P1           ; preserve X
        sta ZP_B6
        tax
        beq _3a1d
        lda table_logdiv, x
        ldx ZP_VAR_Q
        beq _3a20
        clc
        adc table_logdiv, x
        bmi _3a0f
        lda table_log, x
        ldx ZP_B6
        adc table_log, x
        bcc _3a20               ; no overflow: A*Q < 256
        tax
        lda _9500, x
        ldx ZP_VAR_P1           ; restore X
        rts

        ;-----------------------------------------------------------------------

_3a0f:                                                                  ;$3A0F
        lda table_log, x
        ldx ZP_B6
        adc table_log, x
        bcc _3a20               ; no overflow: A*Q < 256
        tax
        lda _9600, x            ; A = X*ZP_B6
_3a1d:                                                                  ;$3A1D
        ldx ZP_VAR_P1           ; restore X
        rts

        ;-----------------------------------------------------------------------

_3a20:                                                                  ;$3A20
        lda # $00           ; A=0 when either A or Q was 0 or A*Q < 256
        ldx ZP_VAR_P1       ; restore X
        rts

;===============================================================================

_3a25:                                                                  ;$3A25
.export _3a25

        stx ZP_VAR_Q
_3a27:                                                                  ;$3A27
.export _3a27

        eor # %11111111
        lsr
        sta ZP_VAR_P2
        lda # $00
        ldx # $10
        ror ZP_VAR_P1
_3a32:                                                                  ;$3A32
        bcs _3a3f
        adc ZP_VAR_Q
        ror
        ror ZP_VAR_P2
        ror ZP_VAR_P1
        dex
        bne _3a32
        rts

        ;-----------------------------------------------------------------------

_3a3f:                                                                  ;$3A3F
        lsr
        ror ZP_VAR_P2
        ror ZP_VAR_P1
        dex
        bne _3a32
        rts

;===============================================================================
; insert `multiply_signed` (and some precedents) from "math_3d.inc"
.multiply_signed                                                        ;$3A48

;===============================================================================

_3ab2:                                                                  ;$3AB2
        ldx ZP_POLYOBJ_XPOS_LO, y
        stx ZP_VAR_Q
        lda ZP_VAR_X
        jsr multiply_signed_into_RS
        ldx ZP_POLYOBJ_XPOS_HI, y
        stx ZP_VAR_Q
        lda ZP_VAR_Y
        jsr multiply_and_add
        sta ZP_VAR_S
        stx ZP_VAR_R
        ldx ZP_POLYOBJ_YPOS_MI, y
        stx ZP_VAR_Q
        lda ZP_VAR_X2

;===============================================================================
; insert the `multiply_and_add` routine from "math.inc"
;
.multiply_and_add                                                       ;$3ACE

;===============================================================================

_3b0d:                                                                  ;$3B0D
.export _3b0d

        stx ZP_VAR_Q
        eor # %10000000
        jsr multiply_and_add
        tax
        and # %10000000
        sta ZP_VAR_T
        txa
        and # %01111111
        ldx # $fe
        stx ZP_TEMP_VAR
_3b20:                                                                  ;$3B20
        asl
        cmp # $60
        bcc _3b27
        sbc # $60
_3b27:                                                                  ;$3B27
        rol ZP_TEMP_VAR
        bcs _3b20
        lda ZP_TEMP_VAR
        ora ZP_VAR_T
        rts

;===============================================================================

_3b30:                                                                  ;$3B30
        lda DUST_Z, y
_3b33:                                                                  ;$3B33
        sta ZP_VAR_Q

        lda PLAYER_SPEED


;===============================================================================
;; unsigned integer division
;; takes A, Q
;; returns A/Q*256 as 16-bit value in P1,R  (A is the same as R on exit)
;===============================================================================
divide_unsigned:                                                                  ;$3B37
.export divide_unsigned

        ; This calculates A / Q by repeatedly shifting A (16bit) left
        ; and subtracting from the hi-byte whenever possible.

        asl
        sta ZP_VAR_P1

        lda # $00
        rol
        cmp ZP_VAR_Q
        bcc _3b43
        sbc ZP_VAR_Q
_3b43:                                                                  ;$3B43
        rol ZP_VAR_P1 ; 1
        rol
        cmp ZP_VAR_Q
        bcc _3b4c
        sbc ZP_VAR_Q
_3b4c:                                                                  ;$3B4C
        rol ZP_VAR_P1 ; 2
        rol
        cmp ZP_VAR_Q
        bcc _3b55
        sbc ZP_VAR_Q
_3b55:                                                                  ;$3B55
        rol ZP_VAR_P1 ; 4
        rol
        cmp ZP_VAR_Q
        bcc _3b5e
        sbc ZP_VAR_Q
_3b5e:                                                                  ;$3B5E
        rol ZP_VAR_P1 ; 8
        rol
        cmp ZP_VAR_Q
        bcc _3b67
        sbc ZP_VAR_Q
_3b67:                                                                  ;$3B67
        rol ZP_VAR_P1 ; 16
        rol
        cmp ZP_VAR_Q
        bcc _3b70
        sbc ZP_VAR_Q
_3b70:                                                                  ;$3B70
        rol ZP_VAR_P1 ; 32
        rol
        cmp ZP_VAR_Q
        bcc _3b79
        sbc ZP_VAR_Q
_3b79:                                                                  ;$3B79
        rol ZP_VAR_P1 ; 64
        rol
        cmp ZP_VAR_Q
        bcc _3b82
        sbc ZP_VAR_Q
_3b82:                                                                  ;$3B82
        rol ZP_VAR_P1 ; 128
        ;; End of P1 = A/Q

        ldx # $00       ;; unneccessary, is cancelled out by the tax below
        sta ZP_B6       ;; A and ZP_B6 are now both the remainder of A/Q
        tax
        beq _3ba6       ;; no remainder: finish.

        ;; calculate (remainder/Q)*256 via the log-tables
        lda table_logdiv, x
        ldx ZP_VAR_Q
        sec
        sbc table_logdiv, x
        bmi _3bae
        ldx ZP_B6
        lda table_log, x
        ldx ZP_VAR_Q
        sbc table_log, x
        bcs _3ba9               ;; carry is set: log(remainder) < log(q)
        tax
        lda _9500, x
_3ba6:                                                                  ;$3BA6
        sta ZP_VAR_R
        rts

        ;-----------------------------------------------------------------------

_3ba9:                                                                  ;$3BA9
        lda # $ff
        sta ZP_VAR_R
        rts

        ;-----------------------------------------------------------------------

_3bae:                                                                  ;$3ABE
        ldx ZP_B6
        lda table_log, x
        ldx ZP_VAR_Q
        sbc table_log, x
        bcs _3ba9
        tax
        lda _9600, x
        sta ZP_VAR_R
        rts

;===============================================================================

_3bc1:                                                                  ;$3BC1
.export _3bc1

        sta ZP_VAR_P3
        lda ZP_POLYOBJ_ZPOS_LO
        ora # %00000001
        sta ZP_VAR_Q
        lda ZP_POLYOBJ_ZPOS_MI
        sta ZP_VAR_R
        lda ZP_POLYOBJ_ZPOS_HI
        sta ZP_VAR_S
        lda ZP_VAR_P1
        ora # %00000001
        sta ZP_VAR_P1
        lda ZP_VAR_P3
        eor ZP_VAR_S
        and # %10000000
        sta ZP_VAR_T
        ldy # $00
        lda ZP_VAR_P3
        and # %01111111
_3be5:                                                                  ;$3BE5
        cmp # $40
        bcs _3bf1
        asl ZP_VAR_P1
        rol ZP_VAR_P2
        rol
        iny
        bne _3be5
_3bf1:                                                                  ;$3BF1
        sta ZP_VAR_P3
        lda ZP_VAR_S
        and # %01111111
_3bf7:                                                                  ;$3BF7
        dey
        asl ZP_VAR_Q
        rol ZP_VAR_R
        rol
        bpl _3bf7
        sta ZP_VAR_Q
        lda # $fe
        sta ZP_VAR_R
        lda ZP_VAR_P3
_3c07:                                                                  ;$3C07
        asl
        bcs _3c17
        cmp ZP_VAR_Q
        bcc _3c10
        sbc ZP_VAR_Q
_3c10:                                                                  ;$3C10
        rol ZP_VAR_R
        bcs _3c07
        jmp _3c20

_3c17:                                                                  ;$3C17
        sbc ZP_VAR_Q
        sec
        rol ZP_VAR_R
        bcs _3c07
        lda ZP_VAR_R
_3c20:                                                                  ;$3C20
        lda # $00
        sta ZP_VALUE_pt2
        sta ZP_VALUE_pt3
        sta ZP_VALUE_pt4
        tya
        bpl _3c49
        lda ZP_VAR_R
_3c2d:                                                                  ;$3C2D
        asl
        rol ZP_VALUE_pt2
        rol ZP_VALUE_pt3
        rol ZP_VALUE_pt4
        iny
        bne _3c2d
        sta ZP_VALUE_pt1
        lda ZP_VALUE_pt4
        ora ZP_VAR_T
        sta ZP_VALUE_pt4
        rts

;===============================================================================

_3c40:                                                                  ;$3C40
        lda ZP_VAR_R
        sta ZP_VALUE_pt1
        lda ZP_VAR_T
        sta ZP_VALUE_pt4
        rts

        ;-----------------------------------------------------------------------

_3c49:                                                                  ;$3C49
        beq _3c40
        lda ZP_VAR_R
_3c4d:                                                                  ;$3C4D
        lsr
        dey
        bne _3c4d
        sta ZP_VALUE_pt1
        lda ZP_VAR_T
        sta ZP_VALUE_pt4
        rts

;===============================================================================
; BBC code says "centre ship indicators"
; roll/pitch dampening? -- slowly reduces X to 1
;
;       X :
;
_3c58:                                                                  ;$3C58
        lda DOCKCOM_STATE       ; is docking computer enabled?
       .bnz :+                  ; yes, skip over the following

        lda _1d06               ; is this the dampening flag?
        bne @rts                ; do not dampen

:       txa                                                             ;$3C62
        bpl :+                  ; >= 0?

        dex                     ; decrease negative number towards zero
        bmi @rts                ; if still negative, finish

:       inx                     ; increase counter                      ;$3C68
       .bnz @rts                ; do nothing 255/256 times

        dex
       .bze :-

@rts:   rts                                                             ;$3C68

;===============================================================================

_3c6f:                                                                  ;$3C6F
.export _3c6f

        sta ZP_VAR_T
        txa
        clc
        adc ZP_VAR_T
        tax
        bcc _3c7a
        ldx # $ff
_3c7a:                                                                  ;$3C7A
        bpl _3c8c
_3c7c:                                                                  ;$3C7C
        lda ZP_VAR_T
        rts

        ;-----------------------------------------------------------------------

_3c7f:                                                                  ;$3C7F
.export _3c7f

        sta ZP_VAR_T
        txa
        sec
        sbc ZP_VAR_T
        tax
        bcs _3c8a
        ldx # $01
_3c8a:                                                                  ;$3C8A
        bpl _3c7c
_3c8c:                                                                  ;$3C8C
        lda _1d07
        bne _3c7c
        ldx # $80
        bmi _3c7c
_3c95:                                                                  ;$3C95
.export _3c95

        lda ZP_VAR_P1
        eor ZP_VAR_Q
        sta ZP_TEMP_VAR
        lda ZP_VAR_Q
        beq _3cc4
        asl
        sta ZP_VAR_Q
        lda ZP_VAR_P1
        asl
        cmp ZP_VAR_Q
        bcs _3cb2
        jsr _3cce
        sec
_3cad:                                                                  ;$3CAD
        ldx ZP_TEMP_VAR
        bmi _3cc7
        rts

        ;-----------------------------------------------------------------------

_3cb2:                                                                  ;$3CB2
        ldx ZP_VAR_Q
        sta ZP_VAR_Q
        stx ZP_VAR_P1
        txa
        jsr _3cce
        sta ZP_VAR_T
        lda # $40
        sbc ZP_VAR_T
        bcs _3cad
_3cc4:                                                                  ;$3CC4
        lda # $3f
        rts

        ;-----------------------------------------------------------------------

_3cc7:                                                                  ;$3CC7
        sta ZP_VAR_T
        lda # $80
        sbc ZP_VAR_T
        rts

        ;-----------------------------------------------------------------------

_3cce:                                                                  ;$3CCE
        jsr _99af
        lda ZP_VAR_R
        lsr
        lsr
        lsr
        tax
        lda _0ae0, x
_3cda:                                                                  ;$3CDA
        rts

;===============================================================================
; pew! pew!
;
shoot_lasers:                                                           ;$3CDB

        ; jitter the laser beam's position a bit:
        ; pick the starting Y-position (Y1)
        ;
        jsr get_random_number
        and # %00000111                 ; clip to 0-7
        adc # $44                       ; offset by 68px
        sta VAR_06F1

        ; pick the starting X-position (X1)
        ;
        jsr get_random_number
        and # %00000111                 ; clip to 0-7
        adc # $7C                       ; offset by 124 (256-8 / 2?)
        sta VAR_06F0

        ; increase laser temperature!
        ;
        lda PLAYER_TEMP_LASER
        adc # $08
        sta PLAYER_TEMP_LASER
        jsr _7b64                       ; handle laser temperature limits?

_3cfa:                                                                  ;$3CFA
        ;=======================================================================
        ; are we in the cockpit-view?
        lda ZP_SCREEN
        bne _3cda                       ; no, exit (`rts` above us)

        lda # 32                        ; X2
        ldy # 224
        jsr @_3d09

        lda # 48                        ; X2
        ldy # 208

@_3d09:                                                                 ;$3D09
        ;-----------------------------------------------------------------------
        ; the horizontal end of the line, which will
        ; be somewhere along the bottom of the viewport
        sta ZP_VAR_X2

        ; set the start point of the line, in the middle
        ; of the screen (slightly randomised, by above)
        lda VAR_06F0
        sta ZP_VAR_X1
        lda VAR_06F1
        sta ZP_VAR_Y1

        ; the bottom of the line is always at
        ; the bottom of the viewport
        lda # ELITE_VIEWPORT_HEIGHT - 1
        sta ZP_VAR_Y2

        ; TODO: skip validation and jump straight to
        ;       the vertical up/down line routine?
        jsr draw_line

        lda VAR_06F0
        sta ZP_VAR_X1
        lda VAR_06F1
        sta ZP_VAR_Y1
        sty ZP_VAR_X2
        lda # ELITE_VIEWPORT_HEIGHT - 1
        sta ZP_VAR_Y2

        ; TODO: skip validation and jump straight to
        ;       the vertical up/down line routine?
        jmp draw_line

;===============================================================================

_3d2f:                                                                  ;$3D2F
.export _3d2f

        lda TSYSTEM_DISTANCE_LO
        ora TSYSTEM_DISTANCE_HI
       .bnz _3d6f

        lda ZP_A7
        bpl _3d6f
        ldy # $00
_3d3d:                                                                  ;$3D3D
        lda _1a27, y
        cmp ZP_VAR_Z
        bne _3d6c
        lda _1a41, y
        and # %01111111
        cmp PLAYER_GALAXY
        bne _3d6c
        lda _1a41, y
        bmi :+

        lda MISSION_FLAGS
        lsr
        bcc _3d6f

        jsr txt_docked_token0E

        lda # $01
        ; this causes the next instruction to become a meaningless `bit`
        ; instruction, a very handy way of skipping without branching
       .bit

:       lda # $b0                                                       ;$3D5F
        jsr print_docked_token

        tya
        jsr _237e

        lda # $b1
        bne _3d7a
_3d6c:                                                                  ;$3D6C
        dey
        bne _3d3d
_3d6f:                                                                  ;$3D6F
        ; copy the last four bytes of the main seed to the "goat soup"
        ; seed, used for generating the planet descriptions
        ldx # $03
:       lda ZP_SEED_W1_LO, x                                            ;3D71
        sta ZP_GOATSOUP, x
        dex
        bpl :-

        lda # $05
_3d7a:  jmp print_docked_str                                            ;$3D7A


mission_blueprints_begin:                                               ;$3D7D
        ;=======================================================================
        ; begin the Thargoid Blueprints mission:
        ;
        lda MISSION_FLAGS
        ora # missions::blueprints_begin
        sta MISSION_FLAGS

        ; display "go to Ceerdi" mission text
.import TXT_DOCKED_0B:direct
        lda # TXT_DOCKED_0B

_3d87:                                                                  ;$3D87
        jsr print_docked_str
_3d8a:                                                                  ;$3D8A
        jmp _88e7


mission_blueprints_ceerdi:                                              ;$3D8D
        ;=======================================================================
        lda MISSION_FLAGS
        and # %11110000
        ora # %00001010
        sta MISSION_FLAGS

        lda # $de
        bne _3d87

mission_blueprints_birera:                                              ;$3D9B
        ;=======================================================================
        lda MISSION_FLAGS
        ora # %00000100
        sta MISSION_FLAGS

        ; give the player the military energy unit?
        lda # 2
        sta VAR_04C4            ; energy charge rate?

        inc PLAYER_KILLS

        lda # $df
        bne _3d87               ; always branches

_3daf:                                                                  ;$3DAF
        ;=======================================================================
        lsr MISSION_FLAGS
        asl MISSION_FLAGS

        ldx # $50
        ldy # $c3
        jsr _7481

        lda # $0f
_3dbe:                                                                  ;$3DBE
        bne _3d87               ; (always branches)

.ifndef OPTION_NOTRUMBLES
;///////////////////////////////////////////////////////////////////////////////

mission_trumbles:                                                       ;$3DC0
        ;=======================================================================
        ; begin Trumbles™ mission
        ;

        ;set the mission bit:
        lda MISSION_FLAGS
        ora # missions::trumbles
        sta MISSION_FLAGS

        ; display the Trumbles™ mission text
.import TXT_DOCKED_TRUMBLES:direct
        lda # TXT_DOCKED_TRUMBLES
        jsr print_docked_str

        jsr _81ee
        bcc _3d8a

        ldy # $c3
        ldx # $50
        jsr _745a

        ;put a Trumble™ in the hold...
        inc PLAYER_TRUMBLES_LO

        ; start the normal docked screen?
        jmp _88e7

;///////////////////////////////////////////////////////////////////////////////
.endif

;===============================================================================

_3dff:                                                                  ;$3DFF
        ; and this is how you set bit 0,
        ; without using registers!
        ;
        lsr MISSION_FLAGS       ; push bit 0 into the bit-bucket
        sec                     ; put a 1 into the carry
        rol MISSION_FLAGS       ; push the carry into bit 0

        jsr txt_docked_incoming_message
        jsr clear_zp_polyobj

        lda # $1f
        sta ZP_A5
        jsr _7c6b

        lda # 1
        jsr set_cursor_col

        sta ZP_POLYOBJ_ZPOS_MI

        ; switch to page "1"(?)
        jsr set_page

        lda # $40
        sta ZP_A3               ; move counter?
_3e01:                                                                  ;$3E01
        ldx # $7f
        stx ZP_POLYOBJ_ROLL
        stx ZP_POLYOBJ_PITCH
        jsr _9a86
        jsr _a2a0
        dec ZP_A3               ; move counter?
        bne _3e01
_3e11:                                                                  ;$3E11
        lsr ZP_POLYOBJ_XPOS_LO
        inc ZP_POLYOBJ_ZPOS_LO
        beq _3e31

        inc ZP_POLYOBJ_ZPOS_LO
        beq _3e31

        ldx ZP_POLYOBJ_YPOS_LO
        inx
        cpx # $50
        bcc _3e24

        ldx # $50
_3e24:                                                                  ;$3E24
        stx ZP_POLYOBJ_YPOS_LO
        jsr _9a86
        jsr _a2a0
        dec ZP_A3               ; move counter?
        jmp _3e11
_3e31:                                                                  ;$3E31
        inc ZP_POLYOBJ_ZPOS_MI
        lda # $0a
        bne _3dbe               ; always branches

;===============================================================================
; insert these docked token functions from "text_docked_fns.asm"
;
.txt_docked_incoming_message                                            ;$3E37
.txt_docked_token16_17_1D                                               ;$3E41
.txt_docked_token18                                                     ;$3E7C

get_polyobj:                                                            ;$3E87
;===============================================================================
; a total of 11 3D-objects ("poly-objects") can be 'in-play' at a time,
; each object has a block of runtime storage to keep track of its current
; state including rotation, speed, shield etc.
;
; given an index for a poly-object 0-10, this routine will
; return an address for the poly-object's variable storage
;
;       X = index
;
; returns address in $59/$5A
;
.export get_polyobj

        txa
        asl                     ; multiply by 2 (for 2-byte table-lookup)
        tay
        lda polyobj_addrs_lo, y
        sta ZP_POLYOBJ_ADDR_LO
        lda polyobj_addrs_hi, y
        sta ZP_POLYOBJ_ADDR_HI

        rts

set_psystem_to_tsystem:                                                 ;$3E95
;===============================================================================
; copy present system co-ordinates to target system co-ordinates,
; i.e. you have arrived at your destination
;
.export set_psystem_to_tsystem

        ldx # 1
:       lda PSYSTEM_POS, x                                              ;$3E97
        sta TSYSTEM_POS, x
        dex
        bpl :-

        rts

wait_frames:                                                            ;$3EA1
;===============================================================================
; wait for a given number of frames to complete
;
;       Y = number of frames to wait
;
.export wait_frames

        jsr wait_for_frame
        dey
        bne wait_frames
        rts

;===============================================================================
; colour of different type of laser cross-hairs?

_3ea8:                                                                  ;$3EA8
.export _3ea8
        .byte   YELLOW, YELLOW, LTGREEN, PURPLE                         ;$3EA8


;$3EAC
