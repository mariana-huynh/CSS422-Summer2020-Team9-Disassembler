*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
Start
    LEA      Values,A6
    MOVE.L   PrintPointer,A1

;Test
;    CMP.B    #40,D6
;    BGT      Quit
;    MOVE.B   (A6,D6),(A1)+
;    JSR      PrintLine
;    JSR      Test

Quit
    MOVE.B   #9,D0
    TRAP     #15

Print
    MOVE.B   #$00,(A1)               *Terminator for trap 14 - "hey! stop printing!"
    MOVE.L   PrintPointer,A1
    MOVE.B   #14,D0
    TRAP     #15
    RTS

PrintLine
    MOVE.B   #$00,(A1)               *Terminator for trap 13 - "hey! stop printing!"
    ADD.B    #1,D6
    MOVE.B   D6,D0
    BRA      TestWaited

TestWaited
    SUB.B    #30,D0
    CMP.B    #0,D0
    BEQ      WaitMore
    BLT      GoAheadAndPrint
    BGT      TestWaited

WaitMore
    LEA      WaitForMore,A1
    MOVE.B   #14,D0
    TRAP     #15
    MOVE.B   #5,D0
    TRAP     #15
    BRA      GoAheadAndPrint

GoAheadAndPrint
    MOVE.L   PrintPointer,A1
    MOVE.B   #13,D0
    TRAP     #15
    RTS

** Address
PrintAddr
    MOVE.L   A4,D6
    MOVE.B   0(A6),(A1)+             *68K always has address of 00XXXXXX, so we print 2 zeros
    MOVE.B   0(A6),(A1)+

    JSR      RightTwenty             *3rd digit
    MOVE.B   (A6,D6),(A1)+           *Move ascii to print
    MOVE.L   A4,D6                   *Re-set the address

    LSL.L    #8,D6                   *4th digit
    LSL.L    #4,D6
    JSR      RightTwentyEight
    MOVE.B   (A6,D6),(A1)+           *Move ascii to print
    MOVE.L   A4,D6                   *Re-set the address

    LSL.L    #8,D6                   *5th digit
    LSL.L    #8,D6
    JSR      RightTwentyEight
    MOVE.B   (A6,D6),(A1)+           *Move ascii to print
    MOVE.L   A4,D6                   *Re-set the address

    LSL.L    #8,D6                   *6th digit
    LSL.L    #8,D6
    LSL.L    #4,D6
    JSR      RightTwentyEight
    MOVE.B   (A6,D6),(A1)+           *Move ascii to print
    MOVE.L   A4,D6                   *Re-set the address

    LSL.L    #8,D6                   *7th digit
    LSL.L    #8,D6
    LSL.L    #8,D6
    JSR      RightTwentyEight
    MOVE.B   (A6,D6),(A1)+           *Move ascii to print
    MOVE.L   A4,D6                   *Re-set the address

    LSL.L    #8,D6                   *8th digit
    LSL.L    #8,D6
    LSL.L    #8,D6
    LSL.L    #4,D6
    JSR      RightTwentyEight
    MOVE.B   (A6,D6),(A1)+           *Move ascii to print

    JSR      PrintTab                *Add tab
    CLR.L    D6
    RTS

PrintImmediateData
	MOVE.B	41(A6),(A1)+		 *#
	JSR		PrintLong
	RTS

PrintByteOrWord
	JSR 	Print
	MOVE.W	(A4)+,D1
	MOVE.B	#16,D2
	MOVE.B  #15,D0
	TRAP 	#15
	RTS

PrintLong
	JSR		Print
	MOVE.W	(A4)+,D1
	MOVE.B	#16,D2
	MOVE.B  #15,D0
	TRAP 	#15
	RTS

RightTwentyEight
    LSR.L    #8,D6
    JSR      RightTwenty
    RTS

RightTwenty
    LSR.L    #8,D6
    LSR.L    #8,D6
    LSR.L    #4,D6
    RTS

** General
NotFound
    MOVE.B   30(A6),(A1)+        *U
    MOVE.B   23(A6),(A1)+        *N
    MOVE.B   20(A6),(A1)+        *K
    MOVE.B   24(A6),(A1)+        *O
    MOVE.B   32(A6),(A1)+        *W
    MOVE.B   23(A6),(A1)+        *N
    RTS

PrintDataReg
    MOVE.B   13(A6),(A1)+        *D
    JSR      PrintRegNum
    RTS

PrintAddrReg
    MOVE.B   10(A6),(A1)+        *A
    JSR      PrintRegNum
    RTS

PrintIndirAddrReg
	MOVE.B  39(A6),(A1)+		 *(
	JSR		PrintAddrReg		 *Ax
	MOVE.B	40(A6),(A1)+		 *)
	RTS

PrintPostIncAddrReg
	JSR		PrintIndirAddrReg	 *(Ax)
	MOVE.B	42(A6),(A1)+		 *+
	RTS

PrintPreDeincAddrReg
	MOVE.B	43(A6),(A1)+		 *-
	JSR		PrintIndirAddrReg	 *(Ax)

PrintRegNum
    MOVE.B   (A6,D5),(A1)+
    RTS

** OPCodes
PrintAdd
    MOVE.B   10(A6),(A1)+        *A
    MOVE.B   13(A6),(A1)+        *D
    MOVE.B   13(A6),(A1)+        *D
    RTS

PrintAddA
    JSR      PrintAdd            *ADD
    MOVE.B   10(A6),(A1)+        *A
    RTS

PrintAddQ
    JSR      PrintAdd            *ADD
    MOVE.B   26(A6),(A1)+        *Q
    RTS

PrintAnd
    MOVE.B   10(A6),(A1)+        *A
    MOVE.B   23(A6),(A1)+        *N
    MOVE.B   13(A6),(A1)+        *D
    RTS

PrintASL
    MOVE.B   10(A6),(A1)+        *A
    MOVE.B   28(A6),(A1)+        *S
    MOVE.B   21(A6),(A1)+        *L
    RTS

PrintASR
    MOVE.B   10(A6),(A1)+        *A
    MOVE.B   28(A6),(A1)+        *S
    MOVE.B   27(A6),(A1)+        *R
    RTS

PrintBEQ
    MOVE.B   11(A6),(A1)+        *B
    MOVE.B   14(A6),(A1)+        *E
    MOVE.B   26(A6),(A1)+        *Q
    RTS

PrintBGT
    MOVE.B   11(A6),(A1)+        *B
    MOVE.B   16(A6),(A1)+        *G
    MOVE.B   29(A6),(A1)+        *T
    RTS

PrintBLE
    MOVE.B   11(A6),(A1)+        *B
    MOVE.B   21(A6),(A1)+        *L
    MOVE.B   14(A6),(A1)+        *E
    RTS

PrintBRA
    MOVE.B   11(A6),(A1)+        *B
    MOVE.B   27(A6),(A1)+        *R
    MOVE.B   10(A6),(A1)+        *A
    RTS

PrintDivu
	MOVE.B	 13(A6),(A1)+		 *D
	MOVE.B   18(A6),(A1)+		 *I
	MOVE.B	 31(A6),(A1)+		 *V
	MOVE.B	 30(A6),(A1)+		 *U
	RTS

PrintJSR
    MOVE.B   19(A6),(A1)+        *J
    MOVE.B   28(A6),(A1)+        *S
    MOVE.B   27(A6),(A1)+        *R
    RTS

PrintLEA
    MOVE.B   21(A6),(A1)+        *L
    MOVE.B   14(A6),(A1)+        *E
    MOVE.B   10(A6),(A1)+        *A
    RTS

PrintLSL
    MOVE.B   21(A6),(A1)+        *L
    MOVE.B   28(A6),(A1)+        *S
    MOVE.B   21(A6),(A1)+        *L
    RTS

PrintLSR
    MOVE.B   21(A6),(A1)+        *L
    MOVE.B   28(A6),(A1)+        *S
    MOVE.B   27(A6),(A1)+        *R
    RTS

PrintMove
    MOVE.B   22(A6),(A1)+        *M
    MOVE.B   24(A6),(A1)+        *O
    MOVE.B   31(A6),(A1)+        *V
    MOVE.B   14(A6),(A1)+        *E
    RTS

PrintMoveA
    JSR      PrintMove           *MOVE
    MOVE.B   10(A6),(A1)+        *A
    RTS

PrintMoveQ
    JSR      PrintMove           *MOVE
    MOVE.B   26(A6),(A1)+        *Q
    RTS

PrintMoveM
    JSR      PrintMove           *MOVE
    MOVE.B   22(A6),(A1)+        *M
    RTS

PrintMuls
	MOVE.B	22(A6),(A1)+		 *M
	MOVE.B	30(A6),(A1)+		 *U
	MOVE.B	21(A6),(A1)+		 *L
	MOVE.B	28(A6),(A1)+		 *S
	RTS

PrintNOP
    MOVE.B   23(A6),(A1)+        *N
    MOVE.B   24(A6),(A1)+        *O
    MOVE.B   25(A6),(A1)+        *P
    RTS

PrintNot
    MOVE.B   23(A6),(A1)+         *N
    MOVE.B   24(A6),(A1)+         *O
    MOVE.B   29(A6),(A1)+         *T
    RTS

PrintOr
    MOVE.B   24(A6),(A1)+        *O
    MOVE.B   27(A6),(A1)+        *R
    RTS

PrintROL
    MOVE.B   27(A6),(A1)+        *R
    MOVE.B   24(A6),(A1)+        *O
    MOVE.B   21(A6),(A1)+        *L
    RTS

PrintROR
    MOVE.B   27(A6),(A1)+        *R
    MOVE.B   24(A6),(A1)+        *O
    MOVE.B   27(A6),(A1)+        *R
    RTS

PrintRTS
    MOVE.B   27(A6),(A1)+        *R
    MOVE.B   29(A6),(A1)+        *T
    MOVE.B   28(A6),(A1)+        *S
    RTS

PrintSub
    MOVE.B   28(A6),(A1)+        *S
    MOVE.B   30(A6),(A1)+        *U
    MOVE.B   11(A6),(A1)+        *B
    RTS

** Sizes
LengthB                          *Prints .B
    MOVE.B   36(A6),(A1)+        *.
    MOVE.B   11(A6),(A1)+        *B
    RTS

LengthW                          *Prints .W
    MOVE.B   36(A6),(A1)+        *.
    MOVE.B   32(A6),(A1)+        *W
    RTS

LengthL                          *Prints .L
    MOVE.B   36(A6),(A1)+        *.
    MOVE.B   21(A6),(A1)+        *L
    RTS

** Other
PrintTab
    JSR      PrintSpace
    JSR      PrintSpace
    JSR      PrintSpace
    JSR      PrintSpace
    RTS

PrintSpace
    MOVE.B   44(A6),(A1)+
    RTS


    SIMHALT             ; halt simulator

* Put variables and constants here
CR              EQU    $0D
LF              EQU    $0A
WaitForMore     DC.B   'Max number of lines on screen. Press any key to continue dissassembling', CR, LF, 0
Values          DC.B   '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','.',',','$','(',')','#','+','-',' '
*                       0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38  39  40  41  42  43  44
PrintPointer    DC.L   $3500


    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
