;
;SUBROUTINES FOR USE IN COLS
;
;CLEARSCREEN - CLEARS PAGE 0 OF THE SCREEN MEMORY ANS SETS YOU TO
;              PAGE 0, IT ALSO GETS THE VIDEO MODE AND PUTS THIS VALUE
;              INTO VIDEOMODE
; TIMER      - THIS IS THE ROUTINE CALLED 18.2 TIMES A SECOND BY THE TIMER
;              INTERRUPT
; PLAY       - ASKS IF THE USER WANTS TO PLAY AGAIN AND SETS CX=0 IF THE 
;              ANSWER IS NOT YES
; INITGAME   - THIS SETS UP ALL THE VARIABLES FOR THE INITIAL GAME AND GETS
;              THE SPEED
; PLAYGAME   - THIS IS THE MAIN GAME LOOP
; CLEARBOARD - CLEARS THE PART OF THE SCREEN THAT THE BLOCKS GO ON
; NEWBLOCK   - THIS RESETS THE BLOCK POINTER TO THE TOP OF THE SCREEN AND
;              PUTS NEW BLOCKS IN THE CURRENT BLOCK POINTERS
; MOVELEFT   - CHECKS TO SEE IF THE BLOCKS CAN MOVE LEFT AND MOVES THEM IF
;              THEY CAN
; MOVERIGHT  - SEE ABOVE
; TESTBLOCK  - TESTS TO SEE IF THE BLOCKS CAN GO LEFT OR RIGHT CH<>32 FOR NO 
;              LEFT CL <> 32 FOR NO RIGHT
; WIPEBLOCKS - THIS CLEARS THE CURRENTLY DISPLAYED BLOCKS FROM THE SCREEN
; SPEEDSET   - THIS SETS THE SPEED VARIABLE UP
; RAND       - CREATES A NUMBER THAT DECIDES WHAT BLOCKS TO USE FROM A
;            - PROBABILITY TABLE
; COLUMNS    - THIS REPLACES ANY VALID COLUMNS WITH SPACES
; COMPACT    - THIS GETS RID OF SPACES
; PRINTSCORE - PUTS THE SCORE ON THE SCREEN
;
COLUMNS:        PUSH    DS
		PUSH    AX                      ;SAVE VARIOUS REGISTERS
		PUSH    BX
		PUSH    DX
		PUSH    DI
		PUSH    CS
		POP     DS
		PUSH    CX
COLSTART:       MOV     COLSFLAG B,0            ;SET FLAG TO 0
		MOV     DX,SCORE W              ;GET SCORE IN DX
		MOV     SI,1000                 ;GET START OFFSET FOR SCREEN              
		MOV     ES,VIDEOADDR W          ;OFSET TO OF SCREEN SEGMENT
		SUB     BX,BX                    ;OFFSET IN LINE
		JMP     COLLOOP1
COLLOOP0:       ADD     BX,2                    ;POINT TO NEXT CHARACTER
		CMP     BX,44                   ;HAVE WE GONE TOO FAR?
		JB      COLLOOP1
		SUB     BX,BX                   ;YES THEN POINT TO NEXT
		ADD     SI,160                  ;LINE
		CMP     SI,3080                 ;CHECK FOR LAST LINE
		JB      COLLOOP1                ;NO MORE TO CHECK
		JMP     COLSEXIT
COLLOOP1:       CMP     B[ES:SI+BX],32          ;DOES LOCATION HOLD A SPACE ?
		JE      COLLOOP0                ;YES THEN LOOP
		MOV     AL,B[ES:SI+BX]          ;ELSE GET BLOCK TYPE
		CMP     AL,219                  ;IS IT 8 POINTS?
		JB      COLTRYNEXT1             ;WE PUT THE SCORE FOR THIS
		MOV     AH,8                    ;BLOCK INTO AH
		JMP     CHECKALONG
COLTRYNEXT1:    CMP     AL,178                  ;IS IT 4 POINTS?
		JB      COLTRYNEXT2
		MOV     AH,4
		JMP     CHECKALONG
COLTRYNEXT2:    CMP     AL,177                  ;IS IT A 2 POINTER?
		JB      COLTRYNEXT3
		MOV     AH,2
		JMP     CHECKALONG
COLTRYNEXT3:    MOV     AH,1                    ;MUST BE 1 POINT?
CHECKALONG:     PUSH    BX                      ;SAVE OFFSET
		SUB     CX,CX                   ;SET BLOCKS COUNTED=0   
CHALOOP1:       ADD     BX,2                    ;GET POINTER TO NEXT BLOCK
		CMP     BX,44
		JE      NOMORETOCHECKA          ;HAVE WE GOT TO THE END OF LINE
		CMP     B[ES:SI+BX],AL          ;IS IT THE SAME BLOCK?
		JNE     NOMORETOCHECKA          ;NO THEN EXIT LOOP
		INC     CX                      ;ADD 1 TO THE COUNT
		JMP     CHALOOP1                ;AND LOOP
NOMORETOCHECKA: POP     BX                      ;GET OLD OFFSET
		PUSH    BX                      ;OF INITAL BLOCK POSITION
		PUSH    AX                      ;SAVE SCORE AND BLOCK TYPE
		MOV     AL,AH                   ;MAKE SCORE A WORD
		CBW
		CMP     CX,2                    ;WAS IT THREE OR MORE
		JNE     CHECKDOWN               ;NO THEN CHECK DOWNWARDS
BLANKALONG:     MOV     B[ES:SI+BX],32          ;PUT A SPACE
		ADD     BX,2                    ;OFFSET TO NECT CHARACTER
		ADD     DX,AX                   ;ADD SCORE
		DEC     CX                      ;SUBTRACT COUNT
		CMP     CX,0FFFF
		JNE     BLANKALONG              ;LOOP UNTIL -1
		MOV     COLSFLAG B,1
CHECKDOWN:      POP     AX                      ;RESTORE AX AND BX
		POP     BX
		PUSH    SI                      ;SAVE OFFSET
		SUB     CX,CX                   ;SET BLOCKS COUNTED=0   
CHDLOOP1:       ADD     SI,160                  ;GET POINTER TO NEXT BLOCK
		CMP     SI,3080
		JNB     NOMORETOCHECKD          ;HAVE WE GOT TO THE END OF LINE
		CMP     B[ES:SI+BX],AL          ;IS IT THE SAME BLOCK?
		JNE     NOMORETOCHECKD          ;NO THEN EXIT LOOP
		INC     CX                      ;ADD 1 TO THE COUNT
		JMP     CHDLOOP1                ;AND LOOP
NOMORETOCHECKD: POP     SI
		PUSH    SI                      ;GET OLD OFFSET
		MOV     AL,AH                   ;MAKE SCORE A WORD
		CBW
		CMP     CX,2                    ;WAS IT THREE OR MORE
		JAE     BLANKDOWN               ;YES THEN KILL THEM
		POP     SI
		JMP     COLLOOP0
BLANKDOWN:      MOV     B[ES:SI+BX],32          ;PUT A SPACE
		ADD     SI,160                  ;OFFSET TO NECT CHARACTER
		ADD     DX,AX                   ;ADD SCORE
		DEC     CX                      ;SUBTRACT COUNT
		CMP     CX,0FFFF
		JNE     BLANKDOWN               ;LOOP UNTIL -1
		MOV     COLSFLAG B,1
		POP     SI
		JMP     COLLOOP0                ;JUMP TO LOOP
COLSEXIT:       PUSH    CS
		MOV     DS,VIDEOADDR W          ;GET RID OF ANY SPACES
		CALL    COMPACT
		POP     DS
		MOV     SCORE W,DX
		CMP     COLSFLAG B,0
		JE      COLSEXIT2
		JMP     COLSTART
COLSEXIT2:      POP     CX                      ;RESTORE REGISTERS
		POP     DI
		POP     DX
		POP     BX
		POP     AX
		POP     DS
		RET
;
COMPACT:        MOV     AH,0                    ;RESET FLAG
		MOV     SI,1000                 ;POINT TO START OF SCREEN
		MOV     BX,0                    ;OFFSET IN LINE
COMPACTLOOP:    CMP     B[SI+BX+160],32         ;IS THERE A SPACE BELOW LINE?
		JNE     NEXTBLOCK               ;NO THEN JUMP
		MOV     AL,B[SI+BX]             ;ASSUMES DS=VIDEOADDR
		CMP     AL,32                   ;WAS AL A SPACE ANYWAY
		JE      NEXTBLOCK               ;YES THEN DON'T MOVE
		MOV     B[SI+BX+160],AL         ;MOVE BLOCK DOWN
		MOV     B[SI+BX],32             ;ERASE OLD POSITION
		MOV     AH,1                    ;SET FLAG
NEXTBLOCK:      ADD     BX,2
		CMP     BX,44                   ;HAVE WE DONE THIS ROW
		JNE     COMPACTLOOP             ;NO THEN LOOP
		SUB     BX,BX                   ;BX=0
		ADD     SI,160                  ;YES THEN UPDATE REGS
		CMP     SI,2920                 ;END OF SCREEN?
		JB      COMPACTLOOP             ;NO THEN LOOP
		CMP     AH,0                    ;ANY DONE?
		JNE     COMPACT                 ;YES THEN LOOP AGAIN
		RET                             ;NO THEN RETURN
;
CLEARBOARD:     MOV     DI,1000
		MOV     DS,VIDEOADDR W          ;GET VIDEO SEGMENT
		MOV     AH,13                   ;13 SCREEN LINES
CLBLOOP1:       MOV     AL,22                   ;PUT WORD COUNT IN AX
CLBLOOP2:       MOV     W[DI],0E20               ;CLEAR SCREEN
		ADD     DI,2
		DEC     AL                      ;ADJUST COUNTERS
		JA      CLBLOOP2                ;JUMP IF NOT END OF LINE
		ADD     DI,116                  ;SET TO START OF NEXT LINE
		DEC     AH
		JA      CLBLOOP1                ;DO REST OF LINES
		PUSH    CS
		POP     DS
		RET
;
INITGAME:
		CALL    NEWBLOCK
		MOV     SCORE W,00000
		MOV     CLKC W,0
		RET
;
NEWBLOCK:       PUSH    DS
		PUSH    CS
		POP     DS                      ;MAKE SURE DS IS CORRECT
		CMP     BLOCKPOSY B,0           ;IS Y ALREADY SETUP
		JE      TAFOLKS                 ;CAN'T USE ANY MORE BLOCKS
STILLOKAY:      MOV     BLOCKPOSX B,11          ;SET BLOCK POSITION
		MOV     BLOCKPOSY B,0
		CALL    RAND                    ;GET A BLOCK
		CMP     CBLOCK1 B,AL            ;MAKE SURE IT IS NOT THE
		JNE     OKAYSTOREIT             ;SAME AS THE LAST ONE
		ADD     AL,1                    ;CHECK THE MIDDLE BLOCK IS
		CMP     AL,179                  ;DIFFERENT
		JB      OKAYSTOREIT
		CMP     AL,220
		JE      RESTARTBLOCK1
		MOV     AL,219
		JMP     OKAYSTOREIT
RESTARTBLOCK1:  MOV     AL,176
OKAYSTOREIT:    MOV     CBLOCK1 B,AL            ;SAVE FIRST NEW BLOCK
		MOV     AH,AL
		CALL    RAND                    ;GET A NEW BLOCK
		CMP     AL,AH                   ;IS IT THE SAME AS THE LAST ONE?
		JNE     OKAY                    ;NO THEN THAT IS OKAY
		ADD     AL,1                    
		CMP     AL,179                  ;MAKE IT DIFFERENT
		JB      OKAY
		CMP     AL,220
		JE      RESTARTBLOCK
		MOV     AL,219
		JMP     OKAY
RESTARTBLOCK:   MOV     AL,176
OKAY:           MOV     CBLOCK2 B,AL            ;176=° 177=± 178=² 219=Û
		CALL    RAND
		MOV     CBLOCK3 B,AL
		POP     DS
		RET
TAFOLKS:        CMP     BLOCKPOSX B,11
		JNE     STILLOKAY               ;THIS CHECKS IF WANT TO EXIT
		MOV     EXITFLAG B,1            ;SETS EXIT FLAG SO NO MORE
		POP     DS
		RET                             ;BLOCKS ADDED.
;
TOGGLEMUSIC:    CALL    SPEAKEROFF              ;TURN OFF SPEAKER
		SUB     MUSICFLAG B,1
		JAE     NOINPUT
		MOV     MUSICFLAG B,1
		JMP     NOINPUT
;
PLAYGAME:       CALL    DRAWBLOCKS              ;DRAW CURRENT 3 BLOCKS
		PUSH    CS
		POP     DS
		MOV     AH,0B
		INT     021                     ;CHECK KEYBOARD STATUS
		CMP     AL,0FF
		JNE     NOINPUT                 ;JUMP IF NO CHARACTER
		MOV     AH,08                   ;GET CHARACTER
		INT     021
		AND     AL,0DF
		CMP     AL,'Z'                  ;IS IT A Z
		JE      MOVELEFT
		CMP     AL,'X'                  ;IS IT A X
		JE      MOVERIGHT
		CMP     AL,'C'                  ;IS IT A C
		JE      ROTATE
		CMP     AL,'E'
		JE      SETEXITFLAG     
		CMP     AL,'M'
		JE      TOGGLEMUSIC
NOINPUT:        MOV     AX,SCORE W
		CMP     AX,OLDSCORE W
		JNE     YPRINTSCORE             ;DO WE NEED TO CHANGE SCORE
TESTFLAG:       CMP     EXITFLAG B,1
		JNE     PLAYGAME
		RET
;
YPRINTSCORE:    CALL    PRINTSCORE
		JMP     NOINPUT
;
SETEXITFLAG:    MOV     EXITFLAG B,1
		JMP     TESTFLAG
;
ROTATE:         PUSH    CS
		POP     DS
		MOV     AH,CBLOCK1 B
		MOV     AL,CBLOCK2 B
		MOV     BH,CBLOCK3 B
		MOV     CBLOCK2 B,AH
		MOV     CBLOCK3 B,AL
		MOV     CBLOCK1 B,BH
		JMP     PLAYGAME
;
MOVELEFT:       CALL    TESTBLOCK               ;CAN WE MOVE L OR R
		CMP     CH,32                   ;CH=32 IF WE CAN GO L
		JNE     MLNOWIPE                ;WE CAN'T GO THERE
		CALL    WIPEBLOCKS              ;CLEAR BLOCKS
		DEC     BLOCKPOSX B             ;TAKE ONE OFF X POSITION
MLNOWIPE:       JMP     PLAYGAME                ;PLAY GAME
;
MOVERIGHT:      CALL    TESTBLOCK               ;CAN WE MOVE LEFT OR RIGHT
		CMP     CL,32                   ;IF CL=32 WE CAN GO R
		JNE     MRNOWIPE                ;JUMP OUT IF WE CAN'T GO RIGHT
		CALL    WIPEBLOCKS              ;WIPE BLOCKS
		INC     BLOCKPOSX B             ;ADD ONE TO X POSITION
MRNOWIPE:       JMP     PLAYGAME                ;PLAY THE GAME
;
WIPEBLOCKS:     PUSH    DS                      ;SAVE DS
		MOV     DI,840                  ;OFFSET TO START OF BOARD
		MOV     AL,BLOCKPOSY B          ;GET NUMBER OF LINES DOWN
		MOV     AH,0                    ;MAKE WORD
		IMUL    AX,160                  ;OFFSET
		ADD     DI,AX                   ;ADD OFFSET
		MOV     AH,0
		MOV     AL,BLOCKPOSX B          ;GET X POSITION
		SAL     AL,1                    ;CREATE OFFSET
		ADD     DI,AX                   ;ADD OFFSET
		MOV     DS,VIDEOADDR W          ;GET VIDEO ADAPTER BASE
		CMP     DI,998
		JB      NOWIPEBLK0              ;DO WE NEED TO DO 0?
		MOV     B[DI],32                ;WIPE BLOCK 0
		MOV     B[DI+1],07              
NOWIPEBLK0:     MOV     B[DI+160],32            ;WIPE BLOCK 1
		MOV     B[DI+161],07
		MOV     B[DI+320],32            ;WIPE BLOCK 2
		MOV     B[DI+321],07
		MOV     B[DI+480],32            ;WIPE BLOCK 3
		MOV     B[DI+481],07            
EXWIPE:         POP     DS                      ;RESTORE DS
		RET
;
PRINTSCORE:     PUSH    CS
		POP     DS
		MOV     ES,VIDEOADDR W
		MOV     DI,2986                 ;OFFSET ON SCREEN
		MOV     W OLDSCORE,AX           ;SACE SCORE
		MOV     SI,SCORE_MESSAGE
		MOV     DX,0
		DIV     W BY1000
		ADD     AX,030                  ;MAKE RESULT ASCII
		MOV     B[SI],AL
		INC     SI
		MOV     AX,DX
		MOV     DX,0
		DIV     W BY100
		ADD     AX,030                  ;MAKE ASCII RESULT
		MOV     B[SI],AL
		INC     SI
		MOV     AX,DX
		MOV     DX,0
		DIV     W BY10
		ADD     AX,030                  ;MAKE RSULT ASCII
		MOV     B[SI],AL
		INC     SI
		ADD     DL,030                  ;USE REMAINDER AS UNITS
		MOV     B[SI],DL
		SUB     SI,3                    ;POINT TO START OF STRING
		CLD
		MOVSB
		MOV     B[ES:DI],12
		INC     DI
		MOVSB
		MOV     B[ES:DI],12
		INC     DI
		MOVSB   
		MOV     B[ES:DI],12
		INC     DI
		MOVSB
		MOV     B[ES:DI],12
		RET
;
TESTBLOCK:      PUSH    CS
		POP     DS
		MOV     CH,SLEFT B              ;GETS FLAGS SET BY
		MOV     CL,SRIGHT B             ;DRAWBLOCKS
		RET
;
DRAWBLOCKS:     MOV     DI,840                  ;OFFSET TO START OF BOARD
		MOV     AL,BLOCKPOSY B          ;GET NUMBER OF LINES DOWN
		SUB     AH,AH                   ;MAKE WORD
		IMUL    AX,160                  ;OFFSET
		ADD     DI,AX                   ;ADD OFFSET
		SUB     AH,AH
		MOV     AL,BLOCKPOSX B          ;GET X POSITION
		SAL     AL,1                    ;CREATE OFFSET
		ADD     DI,AX                   ;ADD OFFSET
		MOV     AH,CBLOCK1 B
		MOV     AL,CBLOCK2 B
		MOV     BH,CBLOCK3 B
		MOV     DS,VIDEOADDR W          ;GET VIDEO ADAPTER BASE
		CMP     DI,990                  ;ARE WE FAR ENOUGH DOWN FOR
		JB      NOWIPEBLK               ;THERE TO BE A BLOCK TO WIPE
		MOV     B[DI],32
		MOV     B[DI+1],07              ;WIPE OLD BLOCK
NOWIPEBLK:      MOV     B[DI+160],AH            ;PUT BLOCK 1
		MOV     B[DI+161],09
		MOV     B[DI+320],AL            ;PUT BLOCK 2
		MOV     B[DI+321],09
		MOV     B[DI+480],BH            ;PUT BLOCK 3    
		MOV     B[DI+481],09
		MOV     AL,B[DI+478]            ;IS THERE SPACE NEXT TO BLOCK
		MOV     AH,B[DI+482]            ;IS THERE SPACE RIGHT
		CMP     B[DI+640],32            ;IS THERE SPACE TO FILL?
		JNE     NOPLACEBLOCK            ;NO THEN JUMP
		PUSH    CS
		POP     DS
		MOV     SRIGHT B,AH
		MOV     SLEFT B,AL
EXDRAW:         RET
NOPLACEBLOCK:   CALL    COLUMNS                 ;DO SCORES
		CALL    NEWBLOCK                ;GET NEW BLOCKS
		RET
;
SPEEDSET:       MOV     AH,02
		SUB     BH,BH
		MOV     DH,8
		MOV     DL,21
		INT     010                     ;SET CURSOR
		MOV     AH,09
		MOV     DX,SPEED_MESSAGE
		INT     021                     ;DISPLAY MESSAGE
GETSPEED:       MOV     AH,08
		INT     021
		SUB     AL,031
		JB      GETSPEED                ;IS IT ABOVE -1
		CMP     AL,9                    ;AND BELOW 9
		JA      GETSPEED
		MOV     SPEED B,AL
		RET
;
PLAY:           MOV     AH,02
		SUB     BH,BH
		MOV     DH,8
		MOV     DL,21
		INT     010                     ;SET CURSOR
		MOV     AH,09
		MOV     DX,PLAY_MESSAGE
		INT     021                     ;DISPLAY MESSAGE
		MOV     AH,08
		INT     021
		AND     AL,0DF
N:              CMP     AL,'N'                  ;IF USER PRESSES N THEN
		JNE     PLAYYES                 ;SET CX=0 I.E. EXIT
		MOV     CX,0
		JMP     PLAYEXIT                ;EXIT
PLAYYES:        MOV     CX,0FFFF                ;SET CX=FFFF I.E. PLAY
PLAYEXIT:       RET
;
CLEARSCREEN:    MOV     AH,0F
		INT     010                     ;GET VIDEO MODE
		MOV     VIDEOMODE B,AL          ;STORE MODE IN VARIABLE
		SUB     DI,DI
		MOV     BX,01000
		CMP     AL,07   
		JE      MONOCHROME              ;IF MONOCHROME THEN JUMP
		MOV     AX,0720
		MOV     VIDEOADDR W,0B800       ;SET SEGMENT FOR VIDEO
		MOV     DS,0B800
		JMP     CLLOOP
MONOCHROME:     MOV     AX,020
		MOV     VIDEOADDR W,0B000       ;SET UP VIDEO ADDRESS
		MOV     DS,0B000
CLLOOP:         MOV     [DI],AX                 ;CLEAR ATTRIBUTE AND CHARACTER
		CMP     DI,BX
		INC     DI
		INC     DI
		JB      CLLOOP                  ;JUMP, CORRECT NUMBER OF TIMES
		RET                             ;RETURN
;
SETUP:          MOV     AL,01C
		MOV     AH,035
		INT     021                     ;GET OLD INT 1CH HANDLER
		PUSH    ES                      ;GET OLD INT 1CH VECTOR
		POP     AX
		MOV     OLDINTH W,AX            ;SAVE ADDRESS IN OLDINT
		MOV     OLDINTL W,BX
		MOV     AL,01C                  ;START NEW CALL
		MOV     AH,025
		PUSH    CS
		POP     DS
		MOV     DX,TIMER                ;SET CODE SEGMENT
		INT     021                     ;SET NEW VECTOR
		RET
;
RESTORE:        MOV     DX,OLDINTL W            ;LOAD OFFSET OF OLD INT 1CH
		MOV     AX,OLDINTH W            ;LOAD SEGMENT OF OLD INT 1CH
		PUSH    AX
		POP     DS                      ;PUT SEGMENT IN DS
		MOV     AH,025
		MOV     AL,01C
		INT     021                     ;RESTORE INTERRUPT HANDLER
		RET                             ;RETURN
;
RAND:           MOV     BX,RND W                ;GET SEED FOR NUMBER
		AND     BH,0F0                  ;CLEAR BOTTOM 4 BITS    
		MOV     AL,176                  ;SET TO ° AS DEFAULT
		CLC
		MOV     CX,1
		RCR     BL,1                    ;1 PT BLOCK  °
		JC      RANDEXIT1
		MOV     CX,2
		MOV     AL,177
		RCR     BL,1                    ;2 PT BLOCK  ±
		JC      RANDEXIT1
		MOV     CX,4
		MOV     AL,178
		RCR     BL,1                    ;4 PT BLOCK  ²
		JC      RANDEXIT1
		MOV     CX,8
		MOV     AL,219
		RCR     BL,1                    ;8 PT BLOCK Û
		JC      RANDEXIT1
		MOV     AL,176                  ;ELSE 1PT BLOCK
RANDEXIT1:      XOR     RND W,CX
		RET
;
; DS:SI POINTS TO SCREEN TO DRAW
DRAWSCREEN:     PUSH    CS
		POP     DS
		MOV     DI,678                  ;OFFSET TO SCREEN
		MOV     ES,VIDEOADDR W
		SUB     BX,BX                   ;SET BX AND DX TO 0
		SUB     DX,DX
		MOV     CH,0E                   ;THIS IS THE COLOR USED
LOOPY:          MOV     AL,40
		ADD     DI,160                  ;POINT TO NEXT LINE
		CMP     DI,3080                 ;IS THIS THE LAST LINE
		JNB     SCREENEND
LOOPX:          MOV     DL,BL
		MOV     BL,DH
		MOV     CL,B[DS:SI+BX]
		MOV     BL,DL
		MOV     W[ES:DI+BX],CX          ;PUT CHARACTER AND COLOR IN
		ADD     BX,2                    ;TO THE SCREEN MEMORY
		INC     DH
		DEC     AL                      ;IS IT THE END OF THE LINE
		JNZ     LOOPX
		SUB     BX,BX
		SUB     DX,DX
		ADD     SI,40
		JMP     LOOPY                   ;NEXT LINE      
SCREENEND:      RET
;
;HERE IS ALL THE DATA REQUIRED BY THIS PROGRAM
;
COLSFLAG        DB      0                       ;USED BY COLUMNS
MUSICCOUNT      DW      0                       ;POINT TO MUSIC POSITION
RND             DW      0                       ;USED TO MAKE A RANDOM NUM
SPEED           DB      0                       ;SPEED OF GAME
SPEEDCOUNT      DB      0                       ;SPEED COUNTER
SLEFT           DB      0                       ;FLAG <> 32 IF NO SPACE LEFT
SRIGHT          DB      0                       ;FLAG <> 32 IN NO SPACE RIGHT
OLDINTH         DW      0                       ;HOLDS OLD INT 1CH ADDRESS
OLDINTL         DW      0
VIDEOMODE       DB      0                       ;HOLDS THE VIDEO MODE
VIDEOADDR       DW      0                       ;HOLDS SEGMENT OF VIDEO
BLOCKPOSX       DB      0                       ;X,Y POSITION OF BOTTOM BLOCK
BLOCKPOSY       DB      0
EXITFLAG        DB      0                       ;HOLDS 1 WHEN PROGRAM EXITS
CBLOCK1         DB      0                       ;HOLDS THE CURRENT THREE BLOCKS
CBLOCK2         DB      0                       ;BLOCK 1 = °
CBLOCK3         DB      0                       ;BLOCK 2 = ±
						;BLOCK 3 = ²
SCORE           DW      0                       ;SCORE
OLDSCORE        DW      0                       ;OLD SCORE FOR UPDATE TEST
CLKC            DW      0                       ;CLOCKED COUNTER EVERY 1/18.2s
MUSICDATA:      DB      8,27,4,32,4,27,4,25,4,27,4,24,4,20,4,24,4,27,4,32,4,27
		DB      4,25,4,27,4,24,4,20,4,24,4,27,8,32,4,31,4,29,8,27,8
		DB      25,1,25,1,27,1,25,1,27,4,25,8,24,8,0,8,24,4,22,4,15,4
		DB      19,4,22,8,25,4,24,4,22,4,24,4,20,4,24,4,27,8,32,8,24
		DB      4,22,4,15,4,19,4,22,8,25,4,24,4,22,4,24,4,20,4,24,4
		DB      27,8,32,8,27,4,29,4,27,4,29,4,32,4,29,4,27,4,29,4,32
		DB      4,27,4,25,4,27,4,32,4,27,4,25,4,27,4,32,4,25,4,24,4
		DB      25,4,34,4,24,4,22,4,24,4,32,16,22,8,0,8,22,4,24,4,22
		DB      4,20,4,22,4,24,4,26,4,27,4,24,4,26,4,24,4,22,4,24,4
		DB      26,4,27,4,29,4,26,4,27,4,26,4,24,4,26,4,27,4,29,4,31
		DB      4,27,4,29,4,27,4,26,4,27,4,29,4,31,4,32,4,29,4,31,4
		DB      27,4,31,4,34,4,29,4,26,4,29,4,32,4,31,4,27,4,31,4,34
		DB      4,29,4,26,4,29,4,32,4,31,4,32,4,34,4,27,8,29,8,26,16
		DB      27,8,0,8,22,4,27,4,22,4,20,4,22,4,19,4,15,4,19,4,22
		DB      4,27,4,22,4,20,4,22,4,19,4,15,4,19,4,22,8,27,4,26,4
		DB      24,8,22,8,20,1,20,1,22,1,20,1,22,4,20,8,19,8,0,8,31
		DB      4,29,4,22,4,26,4,29,8,32,4,31,4,29,4,31,4,27,4,31,4
		DB      34,4,27,4,31,4,29,4,27,4,26,4,22,4,26,4,29,8,32,4,31
		DB      4,29,4,31,4,27,4,31,4,34,4,27,4,34,4,26,4,34,4,24,4
		DB      20,4,24,4,27,16,32,4,0,4,32,4,31,4,32,4,26,4,32,4,24
		DB      4,32,4,22,4,19,4,22,4,26,16,31,4,0,4,31,4,29,4,31,4
		DB      24,4,31,4,22,4,31,4,20,4,17,4,20,4,24,16,29,4,0,4,29
		DB      4,27,4,29,4,22,4,29,4,20,4,29,4,19,4,22,4,20,4,24,4
		DB      22,4,26,4,24,4,27,4,26,4,29,4,27,4,31,4,29,4,32,4,31
		DB      4,34,8,32,4,31,4,29,8,34,8,27,16,31,1,29,1,31,1,29,1
		DB      31,8,29,4,27,16,27,8,0,0FF,0FF
;OFF,OFF IS END OF MUSIC
;THE NOTE DATA IS STORED WITH LOW THEN HIGH BYTE FOR COUNTER
NOTEDATA:       DB      162,35,163,33,191,30,244,29,72,28,176,26,51,25,199,23
		DB      113,22,47,21,254,19,173,18,209,17,209,16,223,15,250
		DB      14,24,14,88,13,153,12,227,11,56,11,151,10,255,9,111,9
		DB      232,8,104,8,239,7,125,7,17,7,172,6,76,6,241,5,156,5
		DB      75,5,255,4,183,4,116,4,52,4,247,3,182,3,137,3,86,3,38
		DB      3,248,2,206,2,165,2,127,2,91,2,218
;
OPENTITLE       DB      'ÚÄ COLUMNS ÄÄÄÄÄÄÄÄÄÄÄÄ¿ÚÄÄÄÄÄÄÄ V1.3 Ä¿'
		DB      '³                      ³³    (C)1993   ³'
		DB      '³                      ³³ By A.Latchem ³'
		DB      '³                      ³³              ³'
		DB      '³                      ³³  Z - LEFT    ³'
		DB      '³                      ³³  X - RIGHT   ³'
		DB      '³                      ³³  C - ROTATE  ³'
		DB      '³                      ³³  E - End     ³'
		DB      '³                      ³³  M - Music   ³'
		DB      '³                      ³³              ³'
		DB      '³                      ³³ ° - 1  ² - 4 ³'
		DB      '³   ²         ±        ³³ ± - 2  Û - 8 ³'
		DB      '³ ²²°         ±²       ³ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´'
		DB      '³²²±²°  °    °²²°      ³³ Score :      ³'
		DB      'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
ENDMESSAGE      DB      'ÚÄ COLUMNS ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ V1.3 ÄÄ¿'
		DB      '³                                      ³'
		DB      '³         Thank-you for playing        ³'
		DB      '³                                      ³'
		DB      '³     ÉÍ¸ ÉÍ» Ò   Ò Ò É»É» É» Ò ÉÍµ    ³'
		DB      '³     º   º º º   º º ºÈ¼º ºÈ»º ÈÍ»    ³'
		DB      '³     ÈÍ¾ ÈÍ¼ ÈÍ¾ ÈÍ¼ Ð  Ð Ð È¼ ÆÍ¼    ³'
		DB      '³    ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ   ³'
		DB      '³                                      ³'
		DB      '³     ±±            By          ²²     ³'
		DB      '³     ±±                        ²²     ³'
		DB      '³ ÛÛ                                °° ³'
		DB      '³ ÛÛ        A.Latchem - 1993        °° ³'
		DB      '³                                      ³'
		DB      'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'
;
PLAY_MESSAGE:   DB      'Want To Play [Y/N]?$'
SPEED_MESSAGE:  DB      ' 1-fast ... 9-slow $'
SCORE_MESSAGE:  DB      '0000'
BY1000          DW      1000
BY100           DW      100
BY10            DW      10
