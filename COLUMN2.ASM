;THIS CONTAINS THE RANDOM NUMBER GENERATION ROUTINES AND ALSO THE INTERRUPT
;DRIVEN MUSIC ROUTINES.  IT ALSO UPDATES THE Y POSITION OF THE BLOCKS IF IT 
;IS NECEESARY.  BECUASE IT IS AN INTERRUPT DRIVEN ROUTINE, THE REGISTER
;VALUES MUST BE SAVED.
;
TIMER:          PUSH    AX                      ;SAVE AX
		PUSH    DS                      ;SAVE DATA SEGMENT PAGE
		PUSH    CS
		POP     DS                      ;PUT CS INTO DS
		INC     CLKC W                  ;ADD 1 TO VALUE
		MOV     AX,CLKC W               ;GET CLKC IN AX
		OR      AL,AH                   ;CALCULATE RND SEED
		MOV     RND W,AX
		INC     SPEEDCOUNT B
		MOV     AL,SPEED B              ;THIS PART CHECKS IF IT IS
		CMP     SPEEDCOUNT B,AL         ;TIME TO CHANGE THE BLOCK
		JB      T_OUT                   ;POSITION.  IF IT IS THEN
		INC     BLOCKPOSY B             ;ADD 1 TO THE Y BLOCK POSITION
		MOV     SPEEDCOUNT B,0          ;RESET SPEED COUNT
T_OUT:          CMP     MUSICFLAG B,1           ;CHECK IF THE MUSIC
		JE      MUSIC                   ;IS ON OR OFF, AND JUMP IF ON
NOMUSIC:        POP     DS                      ;RESTORE DS
		POP     AX                      ;RESTORE AX
		IRET                            ;RETURN TO OLD VECTOR
;
MUSIC:          DEC     MUSICWAIT  W            ;DECREMENT THE MUSIC COUNTER
		JNE     NOMUSIC                 ;A NOTE IS BEING PLAYED
		PUSH    SI                      ;SAVE SI
		PUSH    BX                      ;SAVE BX
NOTESTUFF:      MOV     SI,MUSICDATA            ;GET OFFSET TO DATA
		MOV     BX,MUSICCOUNT  W        ;POSITION IN DATA
		MOV     AX,W[DS:SI+BX]    ;GET NOTE AND LENGTH
		CMP     AX,0FFFF                ;SIGNIFIES END
		JE      RESTARTMUSIC
		ADD     MUSICCOUNT W,2          ;UPDATE POINTER
		MOV     BL,AH                   ;SAVE NOTE
		SUB     BH,BH                   ;CLEAR BH
		CBW                             ;MAKE AX A WORD
		MOV     MUSICWAIT W,AX          ;SAVE LENGTH
		MOV     AX,BX                   ;GET NOTE
		CALL    SPEAKEROFF              ;TURN SPEAKER OFF
		ADD     AX,AX                   ;MULTIPLY BY 2
		JE      MUSIC_END               ;IF 0 IT IS A REST
		SUB     AX,2                    ;OFFSET TO NOTE DATA
		MOV     SI,NOTEDATA
		ADD     SI,AX
PLAYNOTE:       MOV     AL,0B6                  ;PLAYS NOTE POINTED TO BY SI
		OUT     043,AL
		MOV     AL,B[DS:SI]             ;LOW FREQUENCY
		OUT     042,AL
		MOV     AL,B[DS:SI+1]           ;HIGH FREQUENCY
		OUT     042,AL
		IN      AL,061
		OR      AL,3
		OUT     061,AL                  ;TURN SPEAKER ON
MUSIC_END:      POP     BX                      ;RESTORE BX
		POP     SI                      ;RESTORE SOURCE INDEX
		JMP     NOMUSIC
;
SPEAKEROFF:     PUSH    AX
		IN      AL,061                  ;TURNS OFF SPEAKER
		AND     AL,0FC
		OUT     061,AL
		POP     AX
		RET
;
RESTARTMUSIC:   MOV     MUSICCOUNT W,0
		CALL    SPEAKEROFF
		JMP     NOTESTUFF
;
MUSICWAIT       DW      1
MUSICFLAG       DB      1
