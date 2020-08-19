*-----------------------------------------------------------
* Title      : Team 9 Disassembler
* Written by : Mariana Huynh, Hanny Long, Alex Van Matre
* Date       : 07/20/20
* Description: Disassmbles a program that is loaded into
*              memory
*-----------------------------------------------------------
              ORG    $1000
START:                                           ; first instruction of program
    LEA      Values,A6
    JSR      Print
    MOVE.L   PrintPointer,A1
    MOVE.B   #0,PrintLines
    JSR      PrintSpace

* Put program code here

* I/O
             MOVEA.L #0, A1                      ; Clear A1
             LEA IntroMsg, A1
             MOVE.B #14, D0                      ; print contents of A1
             TRAP #15

* Get start address
GetStartAddr
             LEA     AskStartAddr,A1             ; load asking for start address message
             MOVE.B  #14,D0
             TRAP    #15                         ; print to screen

             MOVEA.L #0,A1                       ; Clear A1
             LEA     StartAddr,A1                ; Move variable StartAddr for storing

             MOVE.B  #2,D0                       ; trap task 2: takes in input from keyboard and stores into A1
             TRAP    #15

             CMP     #8,D1                       ; check if input is 8 chars long
             BNE     InvalidAddrHandler

             CLR     D2                          ; clear toggle for if validated start/end address

             BRA     AsciiToHex                  ; convert input to hex

* Get end address
GetEndAddr
             LEA     AskEndAddr,A1               ; load asking for end address message
             MOVE.B  #14,D0
             TRAP    #15

             MOVEA.L #0,A1                       ; Clear A1
             LEA     EndAddr,A1                  ; move variable EndAddr for storing

             MOVE.B  #2,D0                       ; trap task 2: takes in input from keyboard and stores into A1
             TRAP    #15

             CMP     #8,D1                       ; Check if the given value was 8 characters long, if not it needs to be given again
             BNE     InvalidAddrHandler

             BRA     AsciiToHex                  ; convert input to hex

* Convert from ASCII to hex
AsciiToHex
             MOVE.L  #0,D3                       ; initialize D3 to 0
             MOVE.L  #8,D4                       ; initialize D4 to 8, for number of iterations in for_loop1
             MOVE.L  #0,D5                       ; initialize D5 to 0, for storing result of converted input to hex

ConvertForLoop
             CMP.B   D3,D4                       ; for number of iterations
             BEQ     SaveStart                   ; if equal to each other, move on to validate start address
             ADDQ.L  #1,D3                       ; D3++

             ASL.L    #4,D5                      ; shift to the left 4 bits (1 hex character)
             MOVE.B  (A1)+,D1                    ; read one char into D1

             CMP.B   #$30,D1                     ; check the char, "A-F", "0-9", "a-f"
             BLT     InvalidAddrHandler          ; D1 < 0x30
             CMP.B   #$39,D1
             BLE     ConvertNum                  ; 0x30 (0) <= D1 <= 0x39 (9)  <-- see ASCII chart
             CMP.B   #$41,D1
             BLT     InvalidAddrHandler          ; 0x39 < D1 < 0x41

             CMP.B   #$46,D1
             BLE     ConvertUppercase            ; 0x41 (A) <= D1 <= 0x46 (F)
             CMP.B   #$61,D1
             BLT     InvalidAddrHandler          ; 0x47 < D1 < 0x61
             CMP.B   #$66,D1
             BLE     ConvertLowercase            ; 0x66 (f) < D1

ConvertNum
             SUB.L   #$30,D1                     ; convert char (0-9) to number
             ADD.L   D1,D5
             BRA     ConvertForLoop              ; go back and do next character

ConvertLowercase
             SUB.L   #$57,D1                     ; convert char (a-f) to number
             ADD.L   D1,D5
             BRA     ConvertForLoop              ; go back and do next character

ConvertUppercase
             SUB.L   #$37,D1                     ; convert char (A-F) to number
             ADD.L   D1,D5
             BRA     ConvertForLoop              ; go back and do next character

* Save start and end (and validate end) addresses
SaveStart
             CMP         #1,D2
             BEQ         ValidateEnd             ; if D2 = 1, already validated start address
             ADDI        #1,D2                   ; if initially 0, add 1 to toggle to ValidateEnd

             JSR         PutStartToMemory        ; move converted starting address from D3 to defined memory location
             CLR         D5
             BRA         GetEndAddr              ; ask user for new end address

ValidateEnd
             CMP.L       StartAddr,D5            ; check if starting address is less than or equal to ending address
             BLE         InvalidEndHandler       ; if yes, = error (start must be less than end)

             CLR.W       D2
             JSR         PutEndToMemory          ; move ending address in D3 to defined memory location
             CLR.W       D5

             BRA         LoadAddr

PutStartToMemory
             MOVE.L      D5,StartAddr
             RTS

PutEndToMemory
             MOVE.L      D5,EndAddr
             RTS

LoadAddr
             CLR.L       D2
             MOVE.L      StartAddr,A2
             MOVE.L      EndAddr,A3
             JSR         ReadNextLoopStart

* Invalid input handlers
InvalidAddrHandler
             CMP         #1,D2				     ; if toggle at D2 = 1 then end address error
             BEQ         InvalidEndHandler
             BRA         InvalidStartHandler	 ; else starting address error

InvalidStartHandler
             MOVEA.L     #0,A1                   ; clear A1
             JSR         DispInvalidStartError
             CLR         D5
             BRA         GetStartAddr            ; ask for starting address again

InvalidEndHandler
             MOVEA.L     #0,A1                   ; clear A1
             JSR         DispInvalidEndError
             CLR         D5
             BRA         GetEndAddr

DispInvalidStartError
             LEA         InvalidStartMessage,A1  ; load error message
             MOVE.B      #13,D0                  ; print contents of A1
             TRAP        #15
             RTS

DispInvalidEndError
             LEA         InvalidEndMessage,A1    ; load error message
             MOVE.B      #13,D0                  ; print contents of A1
             TRAP        #15
             RTS

* Opcode Parsing
ReadNextLoopStart
             MOVE.L      A2,A4

ReadNextLoop
             CMPA.L      A3,A4
             BGE         AskExitOrRestart

             ;MOVE.B	     -(A4),A4

             JSR         PrintLine

             JSR         PrintAddr

             JSR         DecodingMachineCode
             ;MOVE.W      (A4)+,D7                   ; read one word at a time and store in D7
             JMP         ReadNextLoop

AskExitOrRestart
             LEA         AskRestartOrExitMsg,A1 ; ask user to restart or exit program
             MOVE.B      #14,D0
             TRAP        #15

             MOVE.B      #4,D0                  ; trap task #4: get user input (digit)
             TRAP        #15

             CMP.B       #1,D1                  ; if user inputs 1, restart program
             BEQ         ClearEverything
             CMP.B       #0,D1                  ; if 0, terminate program
             BNE         AskExitOrRestart       ; if not 0 nor 1, prompt again
             BRA         quit

ClearEverything
* Clear data registers
             CLR.L       D0
             CLR.L       D1
             CLR.L       D2
             CLR.L       D3
             CLR.L       D4
             CLR.L       D5
             CLR.L       D6
             CLR.L       D7

* Clear address registers
             MOVEA.L     #0, A0
             MOVEA.L     #0, A1
             MOVEA.L     #0, A2
             MOVEA.L     #0, A3
             MOVEA.L     #0, A4
             MOVEA.L     #0, A5
             MOVEA.L     #0, A6
             MOVEA.L     #0, A7

* Clear memory locations that variables used
             CLR.L       StartAddr
             CLR.L       EndAddr

             BRA         START

quit
             MOVE.B      #9, D0
             TRAP        #15

*-----------------------------------------------------------
* Title      : Opcode decoding
* Written by :
* Date       :
* Description: decoding opcode from machine code by looking at the bit and narrowing down the possibility
*-----------------------------------------------------------
*******     ASSUME (A4) IS ALREADY is the MACHINE CODE                  ********
*******     NOTE: MACHINE CODE ARE WORD SIZE                            ********
*******     The code narrow down the opcode posibility by               ********
*******     looking at the bit and branch                               ********
*******     Using D3,D4 for loop and,D5 result                          ********
*******     Using D0, D1 to hold temperary data                         ********
*******     POSTCONDITION: (A4) will hold 0 after RTS from this SR      ********
*******                    except for if the opcode is NOP or RTS       ********
;Ctrl+F "Print" to see where all the print is
;If nothing work BUG is in GetNextD4bit subroutine or InvalidOpcode subroutine, both is at the bottom of the file

DecodingMachineCode
            CLR     D2
			MOVE.W  (A4)+,D2        ; create copy of data in A4 to fix restart

            CMPI.W  #20081,D2    ; NOP if equal
            BEQ     PrintNOP       ; Call Output PrintNOP subroutine
            ;RTS                    ; Return to get more input

            CMPI.W  #20085,D2    ; RTS if equal
            BEQ     PrintRTS       ; Call Output PrintRTS subroutine
            ;RTS                    ; Return to get more input

            MOVE.L  #4,D4          ; get the next 4 bit from (A4) in to D5
            JSR     GetNextD4bit   ; D5 hold the first 4 bit of (A4)

    ; cmp to see whice opcode the frist 4 bit match with
            CMP.L   #14,D5
            BEQ     LSL_ASL_Opcode

            CMP.L   #13,D5
            BEQ     ADD_Opcode

            CMP.L   #12,D5
            BEQ     MULS_W_AND_Opcode

            CMP.L   #9,D5
            BEQ     SUB_Opcode

            CMP.L   #8,D5
            BEQ     DIVU_W_Opcode

            CMP.L   #6,D5
            BEQ     Bcc_Opcode

            CMP.L   #4,D5
            BEQ     NeedMoreBit

            CMP.L   #3,D5
            BEQ     MOVE_W_Opcode

            CMP.L   #2,D5
            BEQ     MOVE_L_Opcode

            CMP.L   #1,D5
            BEQ     MOVE_B_Opcode

            JMP     InvalidOpcode  ; Call Output NotFound subroutine, since it did not match with any first 4 bit of the opcode


*************************************************                LSL_ASL_Opcode                  *************************************************
; first four bit is (1110 #### #### ####)
LSL_ASL_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 11-9) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which is count or register it is

            MOVE.L  D5,D0          ; D0 will hold the count or register
       ; D0 will hold the count or register (position 11-9)

            MOVE.L  #1,D4          ; get the next 1 bit from (A4)(position 8) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 1 bit of (A4), which tell us the direction

            CMP.L   #1,D5          ; D5 should be 1 since we are shifting left
            BNE     InvalidOpcode  ; if D5 doesn't equal 1 it is not a valid machine code

            MOVE.L  #2,D4          ; get the next 2 bit from (A4)(position 7-6) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 2 bit of (A4), which tell us the size

            CMP.L   #3,D5          ; if size is 3 then it is a memory shift
            JMP     MemShift

            MOVE.L  D5,D1          ; D1 will hold the size
       ; D1 will hold the size (position 7-6)

            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us immediate shift count or register shift count

            CMP.L   #0,D5          ; D5 is 3 bit from (A4)(position 5-3), if 0 mean it is a ASL by count
            BEQ     ASL_Count_Opcode

            CMP.L   #1,D5           ; D5 is 3 bit from (A4)(position 5-3), if 1 mean it is a LSL by count
            BEQ     LSL_Count_Opcode

            CMP.L   #4,D5           ; D5 is 3 bit from (A4)(position 5-3), if 4 mean it is a ASL by Register
            BEQ     ASL_Register_Opcode

            CMP.L   #5,D5           ; D5 is 3 bit from (A4)(position 5-3), if 5 mean it is a LSL by Register
            BEQ     LSL_Register_Opcode

            JMP     InvalidOpcode       ; if it is not invalid because position 5-3 did not match any posibility

ASL_Count_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register

            JSR     ASL_Output_Size    ;output ASL and size from D1

            JSR     CheckCount     ; change D0 to 8 if D0 equal to 0

			MOVE.B	D5,D7
			MOVE.B	D0,D5

			MOVE.B	41(A6),(A1)+		 *#
			JSR		PrintRegNum

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintDataReg

            RTS                    ; Return to get more input

ASL_Output_Size    ; subroutine for outputting size from D1
            CMP.L   #0,D1           ; if D1 is 0 it is byte size
            BEQ     ASL_Output_Byte

            CMP.L   #1,D1           ; if D1 is 1 it is word size
            BEQ     ASL_Output_Word

            CMP.L   #2,D1           ; if D1 is 2 it is long size
            BEQ     ASL_Output_Long

            JMP     InvalidOpcode    ; if it is not 0,1,2 it is not a valid size

ASL_Output_Byte
			JSR 	PrintASL
			JSR		LengthB
			JSR     PrintSpace
            RTS                     ; return from subroutine

ASL_Output_Word
			JSR 	PrintASL
			JSR		LengthW
			JSR     PrintSpace
            RTS                     ; return from subroutine

ASL_Output_Long
			JSR 	PrintASL
			JSR		LengthL
			JSR     PrintSpace
            RTS                     ; return from subroutine


LSL_Count_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register

            JSR     LSL_Output_Size    ;output LSL and size from D1

            JSR     CheckCount     ; change D0 to 8 if D0 equal to 0

			MOVE.B	D5,D7
			MOVE.B	D0,D5

			MOVE.B	41(A6),(A1)+		 *#
			JSR		PrintRegNum

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintDataReg

            RTS                    ; Return to get more input

LSL_Output_Size    ; subroutine for outputting size from D1
            CMP.L   #0,D1           ; if D1 is 0 it is byte size
            BEQ     LSL_Output_Byte

            CMP.L   #1,D1           ; if D1 is 1 it is word size
            BEQ     LSL_Output_Word

            CMP.L   #2,D1           ; if D1 is 2 it is long size
            BEQ     LSL_Output_Long

            JMP     InvalidOpcode    ; if it is not 0,1,2 it is not a valid size

LSL_Output_Byte
			JSR 	PrintLSL
			JSR		LengthB
			JSR     PrintSpace
            RTS                     ; return from subroutine

LSL_Output_Word
			JSR 	PrintLSL
			JSR		LengthW
			JSR     PrintSpace
            RTS                     ; return from subroutine

LSL_Output_Long
			JSR 	PrintLSL
			JSR		LengthL
			JSR     PrintSpace
            RTS                     ; return from subroutine

CheckCount  ; Subroutine for change D0 to 8 if D0 equal to 0
            CMP.L   #0,D0
            BEQ     D0_to_8
            RTS                     ; return from subroutine

D0_to_8     MOVE.L  #8,D0
            RTS                     ; return from subroutine

ASL_Register_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register

            JSR     ASL_Output_Size    ;output ASL and size from D1

			MOVE.B	D5,D7
			MOVE.B	D0,D5
            JSR		PrintDataReg

			MOVE.B	D7,D5
            JSR		PrintDataReg

            RTS                    ; Return to get more input


LSL_Register_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register

            JSR     LSL_Output_Size    ;output ASL and size from D1

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			JSR		PrintDataReg

            RTS                    ; Return to get more input

MemShift    ; D0 will hold the count or register (position 11-9)
            CMP.L   #1,D0
            BEQ     LSL_MemShift
            CMP.L   #0,D0
            BEQ     ASL_MemShift
            JMP     InvalidOpcode  ; for memory shift (position 11-9)need to be 0 or 1

LSL_MemShift     ; D5 should hold the value of position 5-3
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us mode

            CMP.L   #2,D5               ; if position 5-3 is 2 then it is mode 2
            BEQ     LSL_MemShift_Mode_2

            CMP.L   #3,D5               ; if position 5-3 is 3 then it is mode 3
            BEQ     LSL_MemShift_Mode_3

            CMP.L   #4,D5               ; if position 5-3 is 4 then it is mode 4
            BEQ     LSL_MemShift_Mode_4

            CMP.L   #7,D5               ; if position 5-3 is 7 then it is mode 7
            BEQ     LSL_MemShift_Mode_7

            JMP     InvalidOpcode       ; if it is not Addressing mode 2,3,4,7 it is invalid

LSL_MemShift_Mode_2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
			JSR 	PrintLSL
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintIndirAddrReg
            RTS                    ; Return to get more input

LSL_MemShift_Mode_3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
			JSR 	PrintLSL
			JSR		LengthW
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg
            RTS                    ; Return to get more input

LSL_MemShift_Mode_4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
			JSR 	PrintLSL
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg
            RTS                    ; Return to get more input

LSL_MemShift_Mode_7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register

            CMP.L   #1,D5               ; check if the register is 1
            BEQ     LSL_MemShift_xxxL   ; if mode is 7 and register is 1, it is <xxx>.L

            CMP.L   #0,D5               ; check if the register is 0
            BEQ     LSL_MemShift_xxxW   ; if mode is 7 and register is 1, it is <xxx>.W

            JMP     InvalidOpcode       ; if it is not <xxx>.W or <xxx>.L

LSL_MemShift_xxxW
			JSR 	PrintLSL
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintByteOrWord
			JSR		LengthW
            RTS                    ; Return to get more input

LSL_MemShift_xxxL
			JSR 	PrintLSL
			JSR		LengthW
			JSR     PrintSpace
			JSR     PrintLong
            RTS                    ; Return to get more input

ASL_MemShift    ; D5 should hold the value of position 5-3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us mode

            CMP.L   #2,D5               ; if position 5-3 is 2 then it is mode 2
            BEQ     ASL_MemShift_Mode_2

            CMP.L   #3,D5               ; if position 5-3 is 3 then it is mode 3
            BEQ     ASL_MemShift_Mode_3

            CMP.L   #4,D5               ; if position 5-3 is 4 then it is mode 4
            BEQ     ASL_MemShift_Mode_4

            CMP.L   #7,D5               ; if position 5-3 is 7 then it is mode 7
            BEQ     ASL_MemShift_Mode_7

            JMP     InvalidOpcode       ; if it is not Addressing mode 2,3,4,7 it is invalid

ASL_MemShift_Mode_2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
			JSR 	PrintASL
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintIndirAddrReg
            RTS                    ; Return to get more input

ASL_MemShift_Mode_3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
			JSR 	PrintASL
			JSR		LengthW
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg
            RTS                    ; Return to get more input

ASL_MemShift_Mode_4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
			JSR 	PrintASL
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg
            RTS                    ; Return to get more input

ASL_MemShift_Mode_7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register

            CMP.L   #1,D5               ; check if the register is 1
            BEQ     ASL_MemShift_xxxL   ; if mode is 7 and register is 1, it is <xxx>.L

            CMP.L   #0,D5               ; check if the register is 0
            BEQ     ASL_MemShift_xxxW   ; if mode is 7 and register is 1, it is <xxx>.W

            JMP     InvalidOpcode  ; if it is not <xxx>.W or <xxx>.L

ASL_MemShift_xxxW
			JSR 	PrintASL
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintByteOrWord
            RTS                    ; Return to get more input

ASL_MemShift_xxxL
			JSR 	PrintASL
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintLong
            RTS                    ; Return to get more input


*************************************************                ADD_Opcode                 *************************************************
; first four bit is (1101 #### #### ####)
ADD_Opcode  MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 11-9) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register

            MOVE.L  D5,D0               ; D0 will hold the register
        ; D0 will hold the register (position 11-9)

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 8-6) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the opmode

            CMP.L   #0,D5               ; if opmode is 0, it is a byte with location specified is a source  (<ea> + Dn -> Dn)
            BEQ     ADD_B_SrcEA

            CMP.L   #1,D5               ; if opmode is 1, it is a word with location specified is a source  (<ea> + Dn -> Dn)
            BEQ     ADD_W_SrcEA

            CMP.L   #2,D5               ; if opmode is 2, it is a long with location specified is a source  (<ea> + Dn -> Dn)
            BEQ     ADD_L_SrcEA

            CMP.L   #4,D5               ; if opmode is 4, it is a byte with location specified is a Destination (Dn + <ea> -> <ea>)
            BEQ     ADD_B_DesEA

            CMP.L   #5,D5               ; if opmode is 5, it is a word with location specified is a Destination (Dn + <ea> -> <ea>)
            BEQ     ADD_W_DesEA

            CMP.L   #6,D5               ; if opmode is 6, it is a long with location specified is a Destination (Dn + <ea> -> <ea>)
            BEQ     ADD_L_DesEA

            JMP     InvalidOpcode       ; if it is not one of the opmode the opcode is invalid

ADD_B_SrcEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     ADD_B_SrcEA_M0

            CMP.L   #1,D5               ; if EA mode is 1 EA is An*
            BEQ     ADD_B_SrcEA_M1

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     ADD_B_SrcEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     ADD_B_SrcEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     ADD_B_SrcEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     ADD_B_SrcEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_B_SrcEA_M0
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg

            RTS                     ; return to input to get more input

ADD_B_SrcEA_M1
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_B_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg

            RTS                     ; return to input to get more input

ADD_B_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_B_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_B_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_B_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     ADD_B_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     ADD_B_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_B_SrcEA_xxxW
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_B_SrcEA_xxxL
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_B_SrcEA_Data
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_SrcEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     ADD_W_SrcEA_M0

            CMP.L   #1,D5               ; if EA mode is 1 EA is An*
            BEQ     ADD_W_SrcEA_M1

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     ADD_W_SrcEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     ADD_W_SrcEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     ADD_W_SrcEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     ADD_W_SrcEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_W_SrcEA_M0
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_SrcEA_M1
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_W_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     ADD_W_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     ADD_W_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_W_SrcEA_xxxW
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_SrcEA_xxxL
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_SrcEA_Data
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_SrcEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     ADD_L_SrcEA_M0

            CMP.L   #1,D5               ; if EA mode is 1 EA is An*
            BEQ     ADD_L_SrcEA_M1

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     ADD_L_SrcEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     ADD_L_SrcEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     ADD_L_SrcEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     ADD_L_SrcEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_L_SrcEA_M0
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_SrcEA_M1
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_L_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     ADD_L_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     ADD_L_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_L_SrcEA_xxxW
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_SrcEA_xxxL
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_SrcEA_Data
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_B_DesEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     ADD_B_DesEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     ADD_B_DesEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     ADD_B_DesEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     ADD_B_DesEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_B_DesEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

ADD_B_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_B_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

ADD_B_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_B_DesEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     ADD_B_DesEA_xxxL

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_B_DesEA_xxxW
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

ADD_B_DesEA_xxxL
			JSR 	PrintAdd
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input

ADD_W_DesEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     ADD_W_DesEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     ADD_W_DesEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     ADD_W_DesEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     ADD_W_DesEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_W_DesEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

ADD_W_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

ADD_W_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_W_DesEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     ADD_W_DesEA_xxxL

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_W_DesEA_xxxW
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

ADD_W_DesEA_xxxL
			JSR 	PrintAdd
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input

ADD_L_DesEA
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     ADD_L_DesEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     ADD_L_DesEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     ADD_L_DesEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     ADD_L_DesEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_L_DesEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

ADD_L_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

ADD_L_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_L_DesEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     ADD_L_DesEA_xxxL

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_L_DesEA_xxxW
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

ADD_L_DesEA_xxxL
			JSR 	PrintAdd
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input


*************************************************                MULS_W_AND_Opcode          *************************************************
; first four bit is (1100 #### #### ####)
MULS_W_AND_Opcode
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 11-9) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register

            MOVE.L  D5,D0               ; D0 will hold the register
        ; D0 will hold the register (position 11-9)

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 8-6) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the opmode, and opcode

            CMP.L   #0,D5               ; if opmode is 0, it is a byte with location specified is a source  (<ea> ^ Dn -> Dn)
            BEQ     And_B_SrcEA

            CMP.L   #1,D5               ; if opmode is 1, it is a word with location specified is a source  (<ea> ^ Dn -> Dn)
            BEQ     And_W_SrcEA

            CMP.L   #2,D5               ; if opmode is 2, it is a long with location specified is a source  (<ea> ^ Dn -> Dn)
            BEQ     And_L_SrcEA

            CMP.L   #4,D5               ; if opmode is 4, it is a byte with location specified is desination (Dn ^ <ea> -> <ea>)
            BEQ     And_B_DesEA

            CMP.L   #5,D5               ; if opmode is 5, it is a word with location specified is desination (Dn ^ <ea> -> <ea>)
            BEQ     And_W_DesEA

            CMP.L   #6,D5               ; if opmode is 6, it is a long with location specified is desination (Dn ^ <ea> -> <ea>)
            BEQ     And_L_DesEA

            CMP.L   #7,D5               ; if opmode is 7, the opcode is MULS.W
            BEQ     MULS_W

            JMP     InvalidOpcode       ; it is not valid since it is not one of the valid opmode

And_B_SrcEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     And_B_SrcEA_M0

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     And_B_SrcEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     And_B_SrcEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     And_B_SrcEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     And_B_SrcEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_B_SrcEA_M0
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_B_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_B_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_B_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_B_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     And_B_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     And_B_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     And_B_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_B_SrcEA_xxxW
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_B_SrcEA_xxxL
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_B_SrcEA_Data
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_W_SrcEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     And_W_SrcEA_M0

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     And_W_SrcEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     And_W_SrcEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     And_W_SrcEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     And_W_SrcEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_W_SrcEA_M0
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_W_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_W_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_W_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_W_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     And_W_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     And_W_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     And_W_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_W_SrcEA_xxxW
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_W_SrcEA_xxxL
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_W_SrcEA_Data
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_L_SrcEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     And_L_SrcEA_M0

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     And_L_SrcEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     And_L_SrcEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     And_L_SrcEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     And_L_SrcEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_L_SrcEA_M0
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_L_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_L_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_L_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_L_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     And_L_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     And_L_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     And_L_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_L_SrcEA_xxxW
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_L_SrcEA_xxxL
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_L_SrcEA_Data
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_B_DesEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     And_B_DesEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     And_B_DesEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     And_B_DesEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     And_B_DesEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_B_DesEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

And_B_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

And_B_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

And_B_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     And_B_DesEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     And_B_DesEA_xxxL

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_B_DesEA_xxxW
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

And_B_DesEA_xxxL
			JSR 	PrintAnd
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input

And_W_DesEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     And_W_DesEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     And_W_DesEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     And_W_DesEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     And_W_DesEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_W_DesEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

And_W_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

And_W_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

And_W_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     And_W_DesEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     And_W_DesEA_xxxL

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_W_DesEA_xxxW
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

And_W_DesEA_xxxL
			JSR 	PrintAnd
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input

And_L_DesEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     And_L_DesEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     And_L_DesEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     And_L_DesEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     And_L_DesEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_L_DesEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

And_L_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

And_L_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

And_L_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     And_L_DesEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     And_L_DesEA_xxxL

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

And_L_DesEA_xxxW
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

And_L_DesEA_xxxL
			JSR 	PrintAnd
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input

MULS_W      MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     MULS_W_M0

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     MULS_W_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     MULS_W_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     MULS_W_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     MULS_W_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

MULS_W_M0   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintMuls
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_M2   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintMuls
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_M3   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintMuls
			JSR		LengthW
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_M4   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintMuls
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_M7   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     MULS_W_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     MULS_W_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     MULS_W_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

MULS_W_xxxW
			JSR 	PrintMuls
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_xxxL
			JSR 	PrintMuls
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_Data
			JSR 	PrintMuls
			JSR		LengthW
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

*************************************************                SUB_Opcode                 *************************************************
; first four bit is (1001 #### #### ####)
SUB_Opcode  MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 11-9) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register

            MOVE.L  D5,D0               ; D0 will hold the register
        ; D0 will hold the register (position 11-9)

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 8-6) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the opmode

            CMP.L   #0,D5               ; if opmode is 0, it is a byte with location specified is a source  (Dn - <ea> -> <ea>)
            BEQ     SUB_B_SrcEA

            CMP.L   #1,D5               ; if opmode is 1, it is a word with location specified is a source  (Dn - <ea> -> <ea>)
            BEQ     SUB_W_SrcEA

            CMP.L   #2,D5               ; if opmode is 2, it is a long with location specified is a source  (Dn - <ea> -> <ea>)
            BEQ     SUB_L_SrcEA

            CMP.L   #4,D5               ; if opmode is 4, it is a byte with location specified is a Destination (<ea> - Dn -> <ea>)
            BEQ     SUB_B_DesEA

            CMP.L   #5,D5               ; if opmode is 5, it is a word with location specified is a Destination (<ea> - Dn -> <ea>)
            BEQ     SUB_W_DesEA

            CMP.L   #6,D5               ; if opmode is 6, it is a long with location specified is a Destination (<ea> - Dn -> <ea>)
            BEQ     SUB_L_DesEA

            JMP     InvalidOpcode       ; if it is not one of the opmode the opcode is invalid

SUB_B_SrcEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     SUB_B_SrcEA_M0

            CMP.L   #1,D5               ; if EA mode is 1 EA is An*
            BEQ     SUB_B_SrcEA_M1

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     SUB_B_SrcEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     SUB_B_SrcEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     SUB_B_SrcEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     SUB_B_SrcEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_B_SrcEA_M0
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_B_SrcEA_M1
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace
            JSR		PrintAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_B_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_B_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_B_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_B_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     SUB_B_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     SUB_B_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     SUB_B_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_B_SrcEA_xxxW
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_B_SrcEA_xxxL
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_B_SrcEA_Data
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input


SUB_W_SrcEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     SUB_W_SrcEA_M0

            CMP.L   #1,D5               ; if EA mode is 1 EA is An*
            BEQ     SUB_W_SrcEA_M1

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     SUB_W_SrcEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     SUB_W_SrcEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     SUB_W_SrcEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     SUB_W_SrcEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_W_SrcEA_M0
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_W_SrcEA_M1
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_W_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_W_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_W_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_W_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     SUB_W_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     SUB_W_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     SUB_W_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_W_SrcEA_xxxW
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_W_SrcEA_xxxL
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_W_SrcEA_Data
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_L_SrcEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     SUB_L_SrcEA_M0

            CMP.L   #1,D5               ; if EA mode is 1 EA is An*
            BEQ     SUB_L_SrcEA_M1

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     SUB_L_SrcEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     SUB_L_SrcEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     SUB_L_SrcEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     SUB_L_SrcEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_L_SrcEA_M0
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_L_SrcEA_M1
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace
            JSR		PrintAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_L_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_L_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_L_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_L_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     SUB_L_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     SUB_L_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     SUB_L_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_L_SrcEA_xxxW
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_L_SrcEA_xxxL
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_L_SrcEA_Data
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_B_DesEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     SUB_B_DesEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     SUB_B_DesEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     SUB_B_DesEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     SUB_B_DesEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_B_DesEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

SUB_B_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

SUB_B_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

SUB_B_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     SUB_B_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     SUB_B_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     SUB_B_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_B_DesEA_xxxW
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

SUB_B_DesEA_xxxL
			JSR 	PrintSub
			JSR		LengthB
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input

SUB_W_DesEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     SUB_W_DesEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     SUB_W_DesEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     SUB_W_DesEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     SUB_W_DesEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_W_DesEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

SUB_W_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

SUB_W_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

SUB_W_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     SUB_W_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     SUB_W_SrcEA_xxxL

            CMP.L   #4,D5               ; if the register is 4 the EA mode is #<data>
            BEQ     SUB_W_SrcEA_Data

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_W_DesEA_xxxW
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

SUB_W_DesEA_xxxL
			JSR 	PrintSub
			JSR		LengthW
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input

SUB_L_DesEA MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us EA mode

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     SUB_L_DesEA_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     SUB_L_DesEA_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     SUB_L_DesEA_M4

            CMP.L   #7,D5               ; EA mode is 7, if it D5 is 7
            BEQ     SUB_L_DesEA_M7

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_L_DesEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

SUB_L_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

SUB_L_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

SUB_L_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register

            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     SUB_L_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 1 the EA mode is (xxx).L
            BEQ     SUB_L_SrcEA_xxxL

            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

SUB_L_DesEA_xxxW
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

SUB_L_DesEA_xxxL
			JSR 	PrintSub
			JSR		LengthL
			JSR     PrintSpace

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input

*************************************************                DIVU_W_Opcode              *************************************************
; first four bit is (1000 #### #### ####)
DIVU_W_Opcode
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 11-9) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the register

            MOVE.L  D5,D0               ; D0 will hold the register
        	; D0 will hold the register (position 11-9)

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 8-6) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #3,D5               ; position 8-6 should be 011, else it is invalid
            BNE     InvalidOpcode

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #0,D5               ; if EA mode is 0 EA is Dn
            BEQ     DIVU_W_M0

            CMP.L   #2,D5               ; if EA mode is 2 EA is (An)
            BEQ     DIVU_W_M2

            CMP.L   #3,D5               ; if EA mode is 3 EA is (An)+
            BEQ     DIVU_W_M3

            CMP.L   #4,D5               ; if EA mode is 4 EA is -(An)
            BEQ     DIVU_W_M4

            CMP.L   #7,D5               ; if EA mode is 7 if D5 is 7
            BEQ     DIVU_W_M7

            JMP     InvalidOpcode       ; not one of the valid EA mode


DIVU_W_M0   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register number
			JSR 	PrintDivu
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_M2   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register number
			JSR 	PrintDivu
			JSR		LengthW
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_M3   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register number
			JSR 	PrintDivu
			JSR		LengthW
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_M4   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register number
			JSR 	PrintDivu
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_M7   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register number

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     DIVU_W_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     DIVU_W_xxxL

            CMP.L   #4,D5          ; if position 2-0 is 4 the EA is #<data>
            BEQ     DIVU_W_Data

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1 or 4, it is invaid

DIVU_W_xxxW JSR 	PrintDivu
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_xxxL JSR 	PrintDivu
			JSR		LengthW
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_Data JSR 	PrintDivu
			JSR		LengthW
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

*************************************************                Bcc_Opcode                 *************************************************
; first four bit is (0110 #### #### ####)
Bcc_Opcode
            MOVE.L  #4,D4          ; get the next 4 bit from (A4)(position 11-8) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 4 bit of (A4), which tell us which Bcc
       ; cmp to see whice Bcc opcode the the next 4 bit(position 11-8) match with
            CMP.L   #14,D5
            BEQ     BGT_Opcode

            CMP.L   #15,D5
            BEQ     BLE_Opcode

            CMP.L   #0,D5
            BEQ     BRA_Opcode

            CMP.L   #7,D5
            BEQ     BEQ_Opcode

            JMP     InvalidOpcode   ; (position 11-8) did not match any of the Bcc opcode, so it is invalid


BGT_Opcode  JSR PrintBGT
            JMP     Bcc_displacement ; take care of output the displacement bit

BLE_Opcode  JSR PrintBLE
            JMP     Bcc_displacement ; take care of output the displacement bit

BRA_Opcode  JSR PrintBRA
            JMP     Bcc_displacement ; take care of output the displacement bit

BEQ_Opcode  JSR PrintBEQ
            JMP     Bcc_displacement ; take care of output the displacement bit

Bcc_displacement    ;for gettin the next 8 bit for displacement and outputting it
            MOVE.L  #8,D4          ; get the next 8 bit from (A4)(position 7-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 4 bit of (A4), which tell us the displacement

            CMP.L   #$00,D5          ; if displacement is $00 than it is a 16bit displacement
            BEQ     Bcc_16bit_Disp

            CMP.L   #$FF,D5
            BEQ     Bcc_32bit_Disp   ; if displacement is $00 than it is a 32bit displacement

            ; print 8bit displacemnt address from D5
            RTS                     ; return to input to get more input

Bcc_16bit_Disp
            ; print 16bit address
			MOVE.B   44(A6),(A1)+        *(space)
		    MOVE.B   38(A6),(A1)+        *$
            RTS                     ; return to input to get more input

Bcc_32bit_Disp
            ; print 32bit address
			MOVE.B   44(A6),(A1)+        *(space)
		    MOVE.B   38(A6),(A1)+        *$
            RTS                     ; return to input to get more input


*************************************************                NeedMoreBit                *************************************************
;Could be MOVEM, MULS.L, DIVU.L, JSR, NOT, LEA
; first four bit is (0100 #### #### ####)
NeedMoreBit
            MOVE.L  #6,D4          ; get the next 6 bit from (A4)(position 11-6) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 6 bit of (A4), which will narrow down the opcode possibility

            CMP.L   #34,D5         ; if position 11-6 equal to 34, it is MoveM register to memory size Word
            BEQ     MoveM_R2M_W

            CMP.L   #35,D5         ; if position 11-6 equal to 35, it is MoveM register to memory size Long
            BEQ     MoveM_R2M_L

            CMP.L   #50,D5         ; if position 11-6 equal to 50, it is MoveM memory to register size word
            BEQ     MoveM_M2R_W

            CMP.L   #51,D5         ; if position 11-6 equal to 51, it is MoveM memory to register size long
            BEQ     MoveM_M2R_L

            CMP.L   #48,D5         ; if position 11-6 equal to 48, it is MULS.L
            BEQ     Muls_L

            CMP.L   #49,D5         ; if position 11-6 equal to 49, it is DIVU.L
            BEQ     Divu_L

            CMP.L   #58,D5         ; if position 11-6 equal to 58, it is JSR
            BEQ     JSR_Opcode

            CMP.L   #24,D5         ; if position 11-6 equal to 24, it is NOT size byte
            BEQ     Not_B_Opcode

            CMP.L   #25,D5         ; if position 11-6 equal to 25, it is NOT size word
            BEQ     Not_W_Opcode

            CMP.L   #26,D5         ; if position 11-6 equal to 26, it is NOT size long
            BEQ     Not_L_Opcode


*************************************************                Lea_Opcode                 *************************************************
; notice there is no line that say jupm to Lea_Opcode, it should be run automatically of after NeedMoreBit, if it doesn't match other opcode
Lea_Opcode  ; the only posible opcode left is LEA, it is LEA if the bit from position 8-6 is all 1
            LSR.L   #1,D5          ; shift left to get carry bit of 6 place
            BCC     InvalidOpcode  ; if the carry bit is is not 1, it is not a valid opcode
            LSR.L   #1,D5          ; shift left to get carry bit of 5 place
            BCC     InvalidOpcode  ; if the carry bit is is not 1, it is not a valid opcode
            LSR.L   #1,D5          ; shift left to get carry bit of 4 place
            BCC     InvalidOpcode  ; if the carry bit is is not 1, it is not a valid opcode

        ; D5 should hold the position 11-9, which is the register, since D5 originaly hold bit from position 11-6 and we shift right 3 times.
        ; D0 will hold the register number for LEA opcode

            MOVE.L  D5,D0          ; D0 will hold the register number for LEA opcode

            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #2,D5          ; if position 5-3 is two the EA for LEA is (An) mode 2
            BEQ     Lea_M2_Opcode

            CMP.L   #7,D5          ; if position 5-3 is 7 the EA for LEA is mode 7
            BEQ     Lea_M7_Opcode

            JMP     InvalidOpcode  ; if it is not mode 7 or mode 2, LEA is invaid

Lea_M2_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintLEA
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintAddrReg
            RTS                     ; return to input to get more input

Lea_M7_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA for LEA is (xxx).W
            BEQ     Lea_xxxW_Opcode

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA for LEA is (xxx).L
            BEQ     Lea_xxxL_Opcode

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, LEA is invaid

Lea_xxxW_Opcode
			JSR 	PrintLEA
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintAddrReg
            RTS                     ; return to input to get more input

Lea_xxxL_Opcode
			JSR PrintLEA
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintAddrReg
            RTS                     ; return to input to get more input


*************************************************                MoveM_R2M_W                *************************************************
; MOVEM.W from register to memory
; first 10 bit is (0100 1000 10## ####)
PrintList
	MOVE.B   39(A6),(A1)+        *(
	MOVE.B   21(A6),(A1)+        *L
	MOVE.B   18(A6),(A1)+        *I
	MOVE.B   28(A6),(A1)+        *S
	MOVE.B   29(A6),(A1)+        *T
	MOVE.B   40(A6),(A1)+        *)
	RTS

MoveM_R2M_W
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #2,D5          ; if position 5-3 is two the EA for moveM is (An) mode 2
            BEQ     MoveM_R2M_W_M2

            CMP.L   #4,D5          ; if position 5-3 is two the EA for moveM is -(An) mode 4
            BEQ     MoveM_R2M_W_M4

            CMP.L   #7,D5          ; if position 5-3 is two the EA for moveM is mode 7
            BEQ     MoveM_R2M_W_M7

            JMP     InvalidOpcode  ; if it is not mode 2,4 or mode 7, moveM is invaid

MoveM_R2M_W_M2
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMoveM
            JSR 	LengthW
			JSR     PrintSpace
            JSR 	PrintList
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

MoveM_R2M_W_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMoveM
            JSR 	LengthW
			JSR     PrintSpace
            JSR 	PrintList
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

MoveM_R2M_W_M7
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA for MoveM is (xxx).W
            BEQ     MoveM_R2M_W_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA for MoveM is (xxx).L
            BEQ     MoveM_R2M_W_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, moveM is invaid

MoveM_R2M_W_xxxW
			JSR 	PrintMoveM
			JSR 	LengthW
			JSR     PrintSpace
            JSR 	PrintList
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

MoveM_R2M_W_xxxL
			JSR 	PrintMoveM
			JSR 	LengthW
			JSR     PrintSpace
            JSR 	PrintList
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input


*************************************************                MoveM_R2M_L                *************************************************
; MOVEM.L from register to memory
; first 10 bit is (0100 1000 11## ####)
MoveM_R2M_L
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #2,D5          ; if position 5-3 is two the EA for moveM is (An) mode 2
            BEQ     MoveM_R2M_L_M2

            CMP.L   #4,D5          ; if position 5-3 is two the EA for moveM is -(An) mode 4
            BEQ     MoveM_R2M_L_M4

            CMP.L   #7,D5          ; if position 5-3 is two the EA for moveM is mode 7
            BEQ     MoveM_R2M_L_M7

            JMP     InvalidOpcode  ; if it is not mode 2,4 or mode 7, moveM is invaid

MoveM_R2M_L_M2
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMoveM
            JSR 	LengthL
			JSR     PrintSpace
            JSR 	PrintList
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

MoveM_R2M_L_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMoveM
            JSR 	LengthL
			JSR     PrintSpace
            JSR 	PrintList
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

MoveM_R2M_L_M7
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA for MoveM is (xxx).W
            BEQ     MoveM_R2M_L_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA for MoveM is (xxx).L
            BEQ     MoveM_R2M_L_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, moveM is invaid

MoveM_R2M_L_xxxW
			JSR PrintMoveM
			JSR LengthL
			JSR     PrintSpace
            JSR 	PrintList
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

MoveM_R2M_L_xxxL
			JSR PrintMoveM
			JSR LengthL
			JSR     PrintSpace
            JSR 	PrintList
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintLong
            RTS                     ; return to input to get more input

*************************************************                MoveM_M2R_W                *************************************************
; MOVEM.W from memory to register
; first 10 bit is (0100 1100 10## ####)
MoveM_M2R_W
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #2,D5          ; if position 5-3 is two the EA for moveM is (An) mode 2
            BEQ     MoveM_M2R_W_M2

            CMP.L   #4,D5          ; if position 5-3 is two the EA for moveM is -(An) mode 4
            BEQ     MoveM_M2R_W_M4

            CMP.L   #7,D5          ; if position 5-3 is two the EA for moveM is mode 7
            BEQ     MoveM_M2R_W_M7

            JMP     InvalidOpcode  ; if it is not mode 2,4 or mode 7, moveM is invaid

MoveM_M2R_W_M2
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMoveM
            JSR 	LengthW
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	37(A6),(A1)+		 *,
            JSR 	PrintList
            RTS                     ; return to input to get more input

MoveM_M2R_W_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMoveM
            JSR 	LengthW
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	37(A6),(A1)+		 *,
            JSR 	PrintList
            RTS                     ; return to input to get more input

MoveM_M2R_W_M7
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA for MoveM is (xxx).W
            BEQ     MoveM_M2R_W_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA for MoveM is (xxx).L
            BEQ     MoveM_M2R_W_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, moveM is invaid

MoveM_M2R_W_xxxW
			JSR 	PrintMoveM
			JSR 	LengthW
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	37(A6),(A1)+		 *,
            JSR 	PrintList
            RTS                     ; return to input to get more input

MoveM_M2R_W_xxxL
			JSR 	PrintMoveM
			JSR 	LengthW
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	37(A6),(A1)+		 *,
            JSR 	PrintList
            RTS                     ; return to input to get more input

*************************************************                MoveM_M2R_L                *************************************************
; MOVEM.L from memory to register
; first 10 bit is (0100 1100 11## ####)
MoveM_M2R_L
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #2,D5          ; if position 5-3 is two the EA for moveM is (An) mode 2
            BEQ     MoveM_M2R_L_M2

            CMP.L   #4,D5          ; if position 5-3 is two the EA for moveM is -(An) mode 4
            BEQ     MoveM_M2R_L_M4

            CMP.L   #7,D5          ; if position 5-3 is two the EA for moveM is mode 7
            BEQ     MoveM_M2R_L_M7

            JMP     InvalidOpcode  ; if it is not mode 2,4 or mode 7, moveM is invaid

MoveM_M2R_L_M2
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMoveM
            JSR 	LengthL
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	37(A6),(A1)+		 *,
            JSR 	PrintList
            RTS                     ; return to input to get more input

MoveM_M2R_L_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMoveM
            JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	37(A6),(A1)+		 *,
            JSR 	PrintList
            RTS                     ; return to input to get more input

MoveM_M2R_L_M7
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA for MoveM is (xxx).W
            BEQ     MoveM_M2R_L_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA for MoveM is (xxx).L
            BEQ     MoveM_M2R_L_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, moveM is invaid

MoveM_M2R_L_xxxW
			JSR 	PrintMoveM
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	37(A6),(A1)+		 *,
            JSR 	PrintList
            RTS                     ; return to input to get more input

MoveM_M2R_L_xxxL
			JSR 	PrintMoveM
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	37(A6),(A1)+		 *,
            JSR 	PrintList
            RTS                     ; return to input to get more input

*************************************************                Muls_L                 *************************************************
; first 10 bit is (0100 1100 00## ####)
Muls_L      MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #0,D5          ; if position 5-3 is 0 the EA for MULS.L is Dn mode 0
            BEQ     Muls_L_M0

            CMP.L   #2,D5          ; if position 5-3 is 2 the EA for MULS.L is (An) mode 2
            BEQ     Muls_L_M2

            CMP.L   #3,D5          ; if position 5-3 is 3 the EA for MULS.L is (An)+ mode 3
            BEQ     Muls_L_M3

            CMP.L   #4,D5          ; if position 5-3 is 4 the EA for MULS.L is -(An) mode 4
            BEQ     Muls_L_M4

            CMP.L   #7,D5          ; if position 5-3 is 7 the EA for MULS.L is mode 7
            BEQ     Muls_L_M7

            JMP     InvalidOpcode  ; if it is not one of the moveM EA mode

Muls_L_M0   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMuls
            JSR 	LengthL
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Muls_L_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMuls
            JSR 	LengthL
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Muls_L_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMuls
            JSR 	LengthL
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Muls_L_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintMuls
            JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Muls_L_M7   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Muls_L_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Muls_L_xxxL

            CMP.L   #4,D5          ; if position 2-0 is 4 the EA is #<data>
            BEQ     Muls_L_Data

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1 or 4, MULS.L is invaid

Muls_L_xxxW JSR 	PrintMuls
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	37(A6),(A1)+		 *,

			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Muls_L_xxxL JSR 	PrintMuls
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Muls_L_Data JSR PrintMuls
			JSR LengthL
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

*************************************************                Divu_L                 *************************************************
; first 10 bit is (0100 1100 01## ####)
Divu_L      MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #0,D5          ; if position 5-3 is 0 the EA for MULS.L is Dn mode 0
            BEQ     Divu_L_M0

            CMP.L   #2,D5          ; if position 5-3 is 2 the EA for MULS.L is (An) mode 2
            BEQ     Divu_L_M2

            CMP.L   #3,D5          ; if position 5-3 is 3 the EA for MULS.L is (An)+ mode 3
            BEQ     Divu_L_M3

            CMP.L   #4,D5          ; if position 5-3 is 4 the EA for MULS.L is -(An) mode 4
            BEQ     Divu_L_M4

            CMP.L   #7,D5          ; if position 5-3 is 7 the EA for MULS.L is mode 7
            BEQ     Divu_L_M7

            JMP     InvalidOpcode  ; if it is not one of the moveM EA mode

Divu_L_M0   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
			JSR 	PrintDivu
			JSR 	LengthL
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Divu_L_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
			JSR 	PrintDivu
			JSR 	LengthL
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Divu_L_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
			JSR 	PrintDivu
			JSR 	LengthL
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Divu_L_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
			JSR 	PrintDivu
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Divu_L_M7   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Divu_L_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Divu_L_xxxL

            CMP.L   #4,D5          ; if position 2-0 is 4 the EA is #<data>
            BEQ     Divu_L_Data

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1 or 4, Divu.L is invaid

Divu_L_xxxW JSR 	PrintDivu
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Divu_L_xxxL JSR 	PrintDivu
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input

Divu_L_Data JSR 	PrintDivu
			JSR 	LengthL
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	37(A6),(A1)+		 *,
			MOVE.W	(A4)+,A4
			JSR     PrintAddr
            RTS                     ; return to input to get more input


*************************************************                JSR_Opcode             *************************************************
; first 10 bit is (0100 1110 10## ####)
JSR_Opcode  MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #2,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     JSR_M2

            CMP.L   #7,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     JSR_M7

            JMP     InvalidOpcode  ; if it is not a valid JSR EA mode if it is not 2 or 7

JSR_M2      MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
			JSR 	PrintJSR
			JSR     PrintSpace
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

JSR_M7      MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     JSR_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     JSR_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid JSR EA mode

JSR_xxxW    JSR 	PrintJSR
			JSR     PrintSpace
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

JSR_xxxL    JSR 	PrintJSR
			JSR     PrintSpace
			JSR		PrintLong
            RTS                     ; return to input to get more input


*************************************************                Not_B_Opcode           *************************************************
; first 10 bit is (0100 0110 00## ####)
Not_B_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #0,D5          ; if position 5-3 is 0 the EA is Dn
            BEQ     Not_B_M0

            CMP.L   #2,D5          ; if position 5-3 is 2 the EA is (An)
            BEQ     Not_B_M2

            CMP.L   #3,D5          ; if position 5-3 is 3 the EA is (An)+
            BEQ     Not_B_M3

            CMP.L   #4,D5          ; if position 5-3 is 4 the EA is -(An)
            BEQ     Not_B_M4

            CMP.L   #7,D5          ; if position 5-3 is 7 the EA is mode is 7
            BEQ     Not_B_M7

            JMP     InvalidOpcode  ; if it is not a valid NOT EA mode if it is not 0 2 3 4 7

Not_B_M0    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthB
			JSR     PrintSpace
            JSR		PrintDataReg
            RTS                     ; return to input to get more input

Not_B_M2    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthB
			JSR     PrintSpace
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

Not_B_M3    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthB
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

Not_B_M4    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthB
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

Not_B_M7    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Not_B_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Not_B_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid NOT EA mode

Not_B_xxxW  JSR 	PrintNot
			JSR 	LengthB
			JSR     PrintSpace
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

Not_B_xxxL  JSR 	PrintNot
			JSR 	LengthB
			JSR     PrintSpace
			JSR		PrintLong
            RTS                     ; return to input to get more input


*************************************************                Not_W_Opcode           *************************************************
; first 10 bit is (0100 0110 01## ####)
Not_W_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #0,D5          ; if position 5-3 is 0 the EA is Dn
            BEQ     Not_W_M0

            CMP.L   #2,D5          ; if position 5-3 is 2 the EA is (An)
            BEQ     Not_W_M2

            CMP.L   #3,D5          ; if position 5-3 is 3 the EA is (An)+
            BEQ     Not_W_M3

            CMP.L   #4,D5          ; if position 5-3 is 4 the EA is -(An)
            BEQ     Not_W_M4

            CMP.L   #7,D5          ; if position 5-3 is 7 the EA mode is 7
            BEQ     Not_W_M7

            JMP     InvalidOpcode  ; if it is not a valid NOT EA mode if it is not 0 2 3 4 7

Not_W_M0    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthW
			JSR     PrintSpace
            JSR		PrintDataReg
            RTS                     ; return to input to get more input

Not_W_M2    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthW
			JSR     PrintSpace
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

Not_W_M3    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthW
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

Not_W_M4    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthW
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

Not_W_M7    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Not_W_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Not_W_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid NOT EA mode

Not_W_xxxW  JSR 	PrintNot
			JSR 	LengthW
			JSR     PrintSpace
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

Not_W_xxxL  JSR 	PrintNot
			JSR 	LengthW
			JSR     PrintSpace
			JSR		PrintLong
            RTS                     ; return to input to get more input


*************************************************                Not_L_Opcode           *************************************************
; first 10 bit is (0100 0110 10## ####)
Not_L_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #0,D5          ; if position 5-3 is 0 the EA is Dn
            BEQ     Not_L_M0

            CMP.L   #2,D5          ; if position 5-3 is 2 the EA is (An)
            BEQ     Not_L_M2

            CMP.L   #3,D5          ; if position 5-3 is 3 the EA is (An)+
            BEQ     Not_L_M3

            CMP.L   #4,D5          ; if position 5-3 is 4 the EA is -(An)
            BEQ     Not_L_M4

            CMP.L   #7,D5          ; if position 5-3 is 7 the EA mode is 7
            BEQ     Not_L_M7

            JMP     InvalidOpcode  ; if it is not a valid NOT EA mode if it is not 0 2 3 4 7

Not_L_M0    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthL
			JSR     PrintSpace
            JSR		PrintDataReg
            RTS                     ; return to input to get more input

Not_L_M2    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthL
			JSR     PrintSpace
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

Not_L_M3    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthL
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

Not_L_M4    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR 	PrintNot
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

Not_L_M7    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Not_L_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Not_L_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid NOT EA mode

Not_L_xxxW  JSR 	PrintNot
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintByteOrWord
            RTS                     ; return to input to get more input

Not_L_xxxL  JSR 	PrintNot
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintLong
            RTS                     ; return to input to get more input


*************************************************                MOVE_W_Opcode          *************************************************
; first four bit is (0011 #### #### ####)
MOVE_W_Opcode
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 11-9) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the destination register

            MOVE.L  D5,D0               ; D0 will hold the destination register
        ; D0 will hold the destination register (position 11-9)

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 8-6) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the destination mode

            CMP.L   #1,D5               ; destination mode can't be mode one
            BEQ     InvalidOpcode

            CMP.L   #5,D5               ; destination mode can't be mode 5
            BEQ     InvalidOpcode

            CMP.L   #6,D5               ; destination mode can't be mode 6
            BEQ     InvalidOpcode

            CMP.L   #7,D5               ; if destination mode is 7, we need to check the register. the lable is in
            BEQ     MOVE_W_DesM7_Check

Continue_MOVE_W
            MOVE.L  D5,D1               ; D1 will hold the destination mode
        ; D1 will hold the destination mode (position 8-6)

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the source mode

            CMP.L   #0,D5          ; if position 5-3 is 0 the EA is Dn
            BEQ     MOVE_W_M0

            CMP.L   #1,D5          ; if position 5-3 is 1 the EA is An
            BEQ     MOVE_W_M1

            CMP.L   #2,D5          ; if position 5-3 is 2 the EA is (An)
            BEQ     MOVE_W_M2

            CMP.L   #3,D5          ; if position 5-3 is 3 the EA is (An)+
            BEQ     MOVE_W_M3

            CMP.L   #4,D5          ; if position 5-3 is 4 the EA is -(An)
            BEQ     MOVE_W_M4

            CMP.L   #7,D5          ; if position 5-3 is 7 the EA is mode 7
            BEQ     MOVE_W_M7

MOVE_W_DesM7_Check
            CMP.L   #1,D0               ; if destination mode is 7, and register is bigger than 1 it is invalid
            BGT     InvalidOpcode

            BRA     Continue_MOVE_W     ; if it is good then continue to decode move

MOVE_W_M0   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthW
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_W_M1   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthW
			JSR     PrintSpace
            JSR		PrintAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_W_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthW
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_W_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthW
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_W_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthW
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

CheckDest
			CMP.L   #0,D1          ; if position 5-3 is 0 the EA is Dn
			BEQ     DestDn

			CMP.L   #1,D1          ; if position 5-3 is 1 the EA is An
			BEQ     InvalidOpcode

			CMP.L   #2,D1          ; if position 5-3 is 2 the EA is (An)
			BEQ     DestIndirAn

			CMP.L   #3,D1          ; if position 5-3 is 3 the EA is (An)+
			BEQ     DestPostIncAn

			CMP.L   #4,D1          ; if position 5-3 is 4 the EA is -(An)
			BEQ     DestPreDeincAn

			CMP.L   #7,D1          ; if position 5-3 is 7 the EA is mode 7
			BEQ     DestWL
			RTS

DestDn
			MOVE.B	D0,D5
			JSR		PrintDataReg
			RTS

DestIndirAn
			MOVE.B	D0,D5
			JSR		PrintIndirAddrReg
			RTS

DestPostIncAn
			MOVE.B	D0,D5
			JSR		PrintPostIncAddrReg
			RTS

DestPreDeincAn
			MOVE.B	D0,D5
			JSR		PrintPreDeincAddrReg
			RTS

DestWL
			CMP.L	#0,D0
			BEQ		DestW

			CMP.L	#1,D0
			BEQ		DestL

			RTS

DestW
			JSR 	PrintByteOrWord
			RTS

DestL
			JSR 	PrintLong
			RTS

MOVE_W_M7   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     MOVE_W_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     MOVE_W_xxxL

            CMP.L   #4,D5          ; if position 2-0 is 4 the EA is #<data>
            BEQ     MOVE_W_data

            JMP     InvalidOpcode  ; for mode 7 if Source register is not 0 or 1 or 4, it is not a vaid NOT EA mode

MOVE_W_xxxW JSR 	PrintMove
			JSR 	LengthW
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_W_xxxL JSR 	PrintMove
			JSR 	LengthW
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_W_data JSR 	PrintMove
			JSR 	LengthW
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

*************************************************                MOVE_L_Opcode          *************************************************
; first four bit is (0010 #### #### ####)
MOVE_L_Opcode
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 11-9) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the destination register

            MOVE.L  D5,D0               ; D0 will hold the destination register
        ; D0 will hold the destination register (position 11-9)

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 8-6) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the destination mode

            CMP.L   #1,D5               ; destination mode can't be mode one
            BEQ     InvalidOpcode

            CMP.L   #5,D5               ; destination mode can't be mode 5
            BEQ     InvalidOpcode

            CMP.L   #6,D5               ; destination mode can't be mode 6
            BEQ     InvalidOpcode

            CMP.L   #7,D5               ; if destination mode is 7, we need to check the register. the lable is in
            BEQ     MOVE_L_DesM7_Check

Continue_MOVE_L
            MOVE.L  D5,D1               ; D1 will hold the destination mode
        ; D1 will hold the destination mode (position 8-6)

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the source mode

            CMP.L   #0,D5          ; if position 5-3 is 0 the EA is Dn
            BEQ     MOVE_L_M0

            CMP.L   #1,D5          ; if position 5-3 is 1 the EA is An
            BEQ     MOVE_L_M1

            CMP.L   #2,D5          ; if position 5-3 is 2 the EA is (An)
            BEQ     MOVE_L_M2

            CMP.L   #3,D5          ; if position 5-3 is 3 the EA is (An)+
            BEQ     MOVE_L_M3

            CMP.L   #4,D5          ; if position 5-3 is 4 the EA is -(An)
            BEQ     MOVE_L_M4

            CMP.L   #7,D5          ; if position 5-3 is 7 the EA is mode 7
            BEQ     MOVE_L_M7

MOVE_L_DesM7_Check
            CMP.L   #1,D0               ; if destination mode is 7, and register is bigger than 1 it is invalid
            BGT     InvalidOpcode

            BRA     Continue_MOVE_L     ; if it is good then continue to decode move

MOVE_L_M0   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthL
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_L_M1   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthL
			JSR     PrintSpace
            JSR		PrintAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_L_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthL
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_L_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthL
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_L_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_L_M7   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     MOVE_L_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     MOVE_L_xxxL

            CMP.L   #4,D5          ; if position 2-0 is 4 the EA is #<data>
            BEQ     MOVE_L_data

            JMP     InvalidOpcode  ; for mode 7 if Source register is not 0 or 1 or 4, it is not a vaid NOT EA mode

MOVE_L_xxxW JSR PrintMove
			JSR LengthL
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_L_xxxL JSR 	PrintMove
			JSR 	LengthL
			JSR     PrintSpace
			JSR		PrintLong

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_L_data JSR 	PrintMove
			JSR 	LengthL
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input


*************************************************                MOVE_B_Opcode          *************************************************
; first four bit is (0001 #### #### ####)
MOVE_B_Opcode
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 11-9) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the destination register

            MOVE.L  D5,D0               ; D0 will hold the destination register
        ; D0 will hold the destination register (position 11-9)

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 8-6) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the destination mode

            CMP.L   #1,D5               ; destination mode can't be mode one
            BEQ     InvalidOpcode

            CMP.L   #5,D5               ; destination mode can't be mode 5
            BEQ     InvalidOpcode

            CMP.L   #6,D5               ; destination mode can't be mode 6
            BEQ     InvalidOpcode

            CMP.L   #7,D5               ; if destination mode is 7, we need to check the register. the lable is in
            BEQ     MOVE_B_DesM7_Check

Continue_MOVE_B
            MOVE.L  D5,D1               ; D1 will hold the destination mode
        ; D1 will hold the destination mode (position 8-6)

            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the source mode

            CMP.L   #0,D5          ; if position 5-3 is 0 the EA is Dn
            BEQ     MOVE_B_M0

            CMP.L   #1,D5          ; if position 5-3 is 1 the EA is An
            BEQ     MOVE_B_M1

            CMP.L   #2,D5          ; if position 5-3 is 2 the EA is (An)
            BEQ     MOVE_B_M2

            CMP.L   #3,D5          ; if position 5-3 is 3 the EA is (An)+
            BEQ     MOVE_B_M3

            CMP.L   #4,D5          ; if position 5-3 is 4 the EA is -(An)
            BEQ     MOVE_B_M4

            CMP.L   #7,D5          ; if position 5-3 is 7 the EA is mode 7
            BEQ     MOVE_B_M7

MOVE_B_DesM7_Check
            CMP.L   #1,D0               ; if destination mode is 7, and register is bigger than 1 it is invalid
            BGT     InvalidOpcode

            BRA     Continue_MOVE_B     ; if it is good then continue to decode move

MOVE_B_M0   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthB
			JSR     PrintSpace
            JSR		PrintDataReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_B_M1   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthB
			JSR     PrintSpace
            JSR		PrintAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_B_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthB
			JSR     PrintSpace
            JSR		PrintIndirAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_B_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthB
			JSR     PrintSpace
			JSR 	PrintPostIncAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_B_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR 	PrintMove
			JSR 	LengthB
			JSR     PrintSpace
			JSR		PrintPreDeincAddrReg

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_B_M7   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     MOVE_B_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     MOVE_B_xxxL

            CMP.L   #4,D5          ; if position 2-0 is 4 the EA is #<data>
            BEQ     MOVE_B_data

            JMP     InvalidOpcode  ; for mode 7 if Source register is not 0 or 1 or 4, it is not a vaid NOT EA mode

MOVE_B_xxxW JSR 	PrintMove
			JSR 	LengthB
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_B_xxxL JSR 	PrintMove
			JSR 	LengthB
			JSR     PrintSpace
			JSR		PrintByteOrWord

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input

MOVE_B_data JSR 	PrintMove
			JSR 	LengthB
			JSR     PrintSpace
            JSR 	PrintImmediateData

			MOVE.B	37(A6),(A1)+		 *,
			JSR CheckDest
            RTS                     ; return to input to get more input


*************************************************                Invalid Handle          *************************************************

InvalidOpcode  ; don't use JSR to get here. Use JMP. If use JSR, RTS will not go back to input
            JSR     NotFound        ; Call Output NotFound subroutine to print, since it did not match with any posible opcode
            RTS                     ; Return to input to get more input

*************************************************                Subroutine             *************************************************

GetNextD4bit ; Subroutine for get the next (D4) bit from (A4) into D5
             ; D4 should contain the number of loop you want to do
            MOVE.L  #0,D3          ; initialize D3 to 0
            MOVE.L  #0,D5          ; initialize D5 to 0, for storing result of bit from (A4)

LOOP        CMP.B   D3,D4          ; for number of iterations
            BEQ     next_code      ; if equal to each other, move on to next
            ADDQ.L  #1,D3          ; D3++, increment D3

            LSL.L   #1,D5          ; Shift left one

            LSL.W   #1,D2          ; shift left one
            BCS     ADD1           ; If there is a carry bit add one to D5
            BRA     LOOP

ADD1        ADDQ.L  #1,D5          ; add 1 to D5
            BRA     LOOP           ; The goal is for D5 to hold the same bit as the first 4 bit of A4

next_code   RTS         ; return from subroutine

*-----------------------------------------------------------
* Title      : Output
* Written by :
* Date       :
* Description: output data
*-----------------------------------------------------------
*******     Using A6 for a list of alphabetical characters              ********

Print
    MOVE.B   #$00,(A1)               *Terminator for trap 14 - "hey! stop printing!"
    MOVE.L   PrintPointer,A1
    MOVE.B   #14,D0
    TRAP     #15
    RTS

PrintLine
    MOVE.B   #$00,(A1)               *Terminator for trap 13 - "hey! stop printing!"
    ADD.B    #1,PrintLines
    MOVE.B   PrintLines,D0
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
    MOVE.B   38(A6),(A1)+        *$
	JSR 	Print

	MOVE.W	(A4)+,D1
	MOVE.B	#16,D2
	MOVE.B  #15,D0
	TRAP 	#15
	RTS

PrintLong
    MOVE.B   38(A6),(A1)+        *$
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
    MOVE.B   13(A6),(A1)+        *D
    MOVE.B   10(A6),(A1)+        *A
    MOVE.B   29(A6),(A1)+        *T
    MOVE.B   10(A6),(A1)+        *A
	JSR      PrintTab
    MOVE.B   38(A6),(A1)+        *$

	MOVE.B	 -(A4),CurDecode	 ; Print out the next 16 bits (the opcode that couldn't be decoded)
	MOVE.B	 #16,D0
	BRA		 PrintBits

PrintBits
	CMP.B	#0,D0
	BEQ		PBDone
	MOVE.L  #1,D4 				 ;Get 1 bit from A4
	JSR		GetNextD4bit		 ;Store in D5

	MOVE.B	(A6,D5),(A1)+		 ;Put into print queue

	SUB.B	#1,D0				 ;Sub 1, do 8 times?

	BRA		PrintBits

PBDone
	MOVE.B	(A4)+,D0
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
	RTS

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
CR           EQU     $0D
LF           EQU     $0A

;EmptyChar    DC.W    '', 0
;SpaceChar    DC.W ' ', 0

EndAddr      EQU     $500                        ; store end address, avoid overwriting
StartAddr    EQU     $600                        ; store start address, avoid overwriting
Cur4bits     EQU     $400                        ; store first four bits

* introduction message
IntroMsg     DC.B    '**************************************************************',CR,LF
             DC.B    '*  TEAM 9 DISASSEMBLER',CR,LF,CR,LF
             DC.B    '*  Members: MARIANA HUYNH, HANNY LONG, ALEX VAN MATRE',CR,LF,CR,LF
             DC.B    '*************************************************************',CR,LF,CR,LF,0

AskStartAddr DC.B 'Enter starting address in hexadecimal:', CR, LF, 0

AskEndAddr   DC.B 'Enter ending address in hexadecimal:', CR, LF, 0

AskRestartOrExitMsg DC.B 'Enter 0 to exit program or 1 to restart the program: ', 0

* Error message
InvalidStartMessage  DC.B 'Invalid Start Address: input not valid hex value', CR, LF, 0
InvalidEndMessage  DC.B 'Invalid End Address: input not valid hex value or End <= Start', CR, LF, 0


* Hex Srting Numbers
Str0                       DC.W '0', 0
Str1                       DC.W '1', 0
Str2                       DC.W '2', 0
Str3                       DC.W '3', 0
Str4                       DC.W '4', 0
Str5                       DC.W '5', 0
Str6                       DC.W '6', 0
Str7                       DC.W '7', 0
Str8                       DC.W '8', 0
Str9                       DC.W '9', 0

* Hex String Letters
StrA                       DC.W 'A', 0
StrB                       DC.W 'B', 0
StrC                       DC.W 'C', 0
StrD                       DC.W 'D', 0
StrE                       DC.W 'E', 0
StrF                       DC.W 'F', 0


WaitForMore     DC.B   'Max number of lines on screen. Press enter to continue dissassembling', CR, LF, 0
Values          DC.B   '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','.',',','$','(',')','#','+','-',' '
*                       0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38  39  40  41  42  43  44
PrintPointer    DC.L   $3500
PrintLines      DC.L   $4500
CurDecode		DC.L   $5500

              END    START        ; last line of source






*~Font name~Courier New~
*~Font size~10~
*~Tab type~0~
*~Tab size~4~
