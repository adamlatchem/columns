;COLUMNS BY A.LATCHEM
;THIS IS THE MAIN FILE THAT ALLOWS ALL THE VARIOUS MODULES TO BE CALLED
;IN THE CORRECT ORDER.  THE VALUES IN THE RGISTERS DO NOT TO BE SAVED BY
;THE GAME ROUTINES IN THE NEXT MODULE.
;
START:          MOV     AH,01                   ;FUNCTION 1
		MOV     CX,0FFFF                ;SET THE CURSOR TO OFF
		INT     010                     ;TURN OFF CURSOR
		MOV     AH,05                   ;FUNCTION 5
		MOV     AL,0                    ;PAGE 0
		INT     010                     ;SET DISPLAY PAGE 0
		CALL    CLEARSCREEN             ;CLEAR THE TEXT SCREEN
		MOV     SI,OFFSET OPENTITLE
		CALL    DRAWSCREEN              ;PUT UP TITLE SCREEN
		CALL    SETUP                   ;SETUP INTTERUPTS
		MOV     AX,0
		CALL    PRINTSCORE              ;ZERO THE SCORE
;
PLAYLOOP:       CALL    PLAY                    ;ASK IF USER WANTS TO PLAY
		JCXZ    EXIT                    ;IF NO THEN EXIT THE PROGRAM
		CALL    SPEEDSET                ;GET THE SPEED
		CALL    CLEARBOARD              ;CLEAR BOARD
		CALL    INITGAME                ;SETUP GAME
		MOV     EXITFLAG B,0            ;CLEAR EXIT FLAG
		CALL    PLAYGAME                ;PLAY THE GAME
		CALL    CLEARBOARD              ;CLEAR BOARD
		JMP     PLAYLOOP                ;LOOP TO START
;
EXIT:           CALL    RESTORE                 ;RESTORE TIMER VECTOR
		IN      AL,061                  ;GET SPEAKER CONTROL
		AND     AL,0FC                  ;SET IT TO OFF
		OUT     061,AL                  ;TURN OFF SPEAKER
		CALL    CLEARSCREEN             ;CLEAR THE GAME SCREEN
		MOV     SI,OFFSET ENDMESSAGE    ;OUTPUT THE ENDING MESSAGE
		CALL    DRAWSCREEN
		MOV     AH,01                   ;SET CURSOR FORMAT
		MOV     CX,00709                ;USE SCAN LINE 7-9
		INT     010                     ;SET CURSOR
		MOV     AH,02                   ;FUNCTION 2
		MOV     BH,0
		MOV     DH,20                   ;CURSOR ATTRIBUTES
		MOV     DL,23
		INT     010                     ;SET CURSOR
		MOV     AH,04C                  ;EXIT PROGRAM
		INT     021                     ;BACK TO DOS
