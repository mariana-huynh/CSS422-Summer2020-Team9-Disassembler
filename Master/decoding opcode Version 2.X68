*-----------------------------------------------------------
* Title      : Opcode decoding
* Written by :
* Date       :
* Description: decoding opcode from machine code by looking at the bit and narrowing down the possibility
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

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
            CMPI.W  #20081,(A4)    ; NOP if equal
            JSR     PrintNOP       ; Call Output PrintNOP subroutine
            RTS                    ; Return to get more input

            CMPI.W  #20085,(A4)    ; RTS if equal
            JSR     PrintRTS       ; Call Output PrintRTS subroutine
            RTS                    ; Return to get more input

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
            RTS                     ; return from subroutine

ASL_Output_Word
			JSR 	PrintASL
			JSR		LengthW
            RTS                     ; return from subroutine

ASL_Output_Long
			JSR 	PrintASL
			JSR		LengthL
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
            RTS                     ; return from subroutine

LSL_Output_Word
			JSR 	PrintLSL
			JSR		LengthW
            RTS                     ; return from subroutine

LSL_Output_Long
			JSR 	PrintLSL
			JSR		LengthL
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
            JSR		PrintIndirAddrReg
            RTS                    ; Return to get more input

LSL_MemShift_Mode_3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
			JSR 	PrintLSL
			JSR		LengthW
			JSR 	PrintPostIncAddrReg
            RTS                    ; Return to get more input

LSL_MemShift_Mode_4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
			JSR 	PrintLSL
			JSR		LengthW
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
            ;print <xxx>.W
            RTS                    ; Return to get more input

LSL_MemShift_xxxL
			JSR 	PrintLSL
			JSR		LengthW
            ;print <xxx>.L
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
            JSR		PrintIndirAddrReg
            RTS                    ; Return to get more input

ASL_MemShift_Mode_3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
			JSR 	PrintASL
			JSR		LengthW
			JSR 	PrintPostIncAddrReg
            RTS                    ; Return to get more input

ASL_MemShift_Mode_4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
			JSR 	PrintASL
			JSR		LengthW
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
            ;print <xxx>.W
            RTS                    ; Return to get more input

ASL_MemShift_xxxL
			JSR 	PrintASL
			JSR		LengthW
            ;print <xxx>.L
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
            ;print (xxx).w

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_B_SrcEA_xxxL
			JSR 	PrintAdd
			JSR		LengthB
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_B_SrcEA_Data
			JSR 	PrintAdd
			JSR		LengthB
            ;print #<Data>

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
            ;print (xxx).w

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_SrcEA_xxxL
			JSR 	PrintAdd
			JSR		LengthW
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_W_SrcEA_Data
			JSR 	PrintAdd
			JSR		LengthW
            ;print #<Data>

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
            ;print (xxx).w

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_SrcEA_xxxL
			JSR 	PrintAdd
			JSR		LengthL
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

ADD_L_SrcEA_Data
			JSR 	PrintAdd
			JSR		LengthL
            ;print #<Data>

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

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

ADD_B_DesEA_xxxL
			JSR 	PrintAdd
			JSR		LengthB

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print (xxx).L
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

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

ADD_W_DesEA_xxxL
			JSR 	PrintAdd
			JSR		LengthW

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print (xxx).L
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

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

ADD_L_DesEA_xxxL
			JSR 	PrintAdd
			JSR		LengthL

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print (xxx).L
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
            ;print (xxx).w

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_B_SrcEA_xxxL
			JSR 	PrintAnd
			JSR		LengthB
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_B_SrcEA_Data
			JSR 	PrintAnd
			JSR		LengthB
            ;print #<data>

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
            ;print (xxx).w

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_W_SrcEA_xxxL
			JSR 	PrintAnd
			JSR		LengthW
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_W_SrcEA_Data
			JSR 	PrintAnd
			JSR		LengthW
            ;print #<data>

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
            ;print (xxx).w

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_L_SrcEA_xxxL
			JSR 	PrintAnd
			JSR		LengthL
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

And_L_SrcEA_Data
			JSR 	PrintAnd
			JSR		LengthL
            ;print #<data>

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

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

And_B_DesEA_xxxL
			JSR 	PrintAnd
			JSR		LengthB

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).L
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

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

And_W_DesEA_xxxL
			JSR 	PrintAnd
			JSR		LengthW

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).L
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

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

And_L_DesEA_xxxL
			JSR 	PrintAnd
			JSR		LengthL

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).L
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
            JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_M2   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintMuls
			JSR		LengthW
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_M3   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintMuls
			JSR		LengthW
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_M4   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
			JSR 	PrintMuls
			JSR		LengthW
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
            ;print (xxx).w

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_xxxL
			JSR 	PrintMuls
			JSR		LengthW
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

MULS_W_Data
			JSR 	PrintMuls
			JSR		LengthW
            ;print #<data>

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
            ;print (xxx).w

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_B_SrcEA_xxxL
			JSR 	PrintSub
			JSR		LengthB
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_B_SrcEA_Data
			JSR 	PrintSub
			JSR		LengthB
            ;print #<Data>

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
            ;print (xxx).w

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_W_SrcEA_xxxL
			JSR 	PrintSub
			JSR		LengthW
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_W_SrcEA_Data
			JSR 	PrintSub
			JSR		LengthW
            ;print #<Data>

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
            ;print (xxx).w

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_L_SrcEA_xxxL
			JSR 	PrintSub
			JSR		LengthL
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

SUB_L_SrcEA_Data
			JSR 	PrintSub
			JSR		LengthL
            ;print #<Data>

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

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

SUB_B_DesEA_xxxL
			JSR 	PrintSub
			JSR		LengthB

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).L
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

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

SUB_W_DesEA_xxxL
			JSR 	PrintSub
			JSR		LengthW

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).L
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

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

SUB_L_DesEA_xxxL
			JSR 	PrintSub
			JSR		LengthL

			MOVE.B	D5,D7
			MOVE.B	D0,D5
			JSR		PrintDataReg

			MOVE.B	D7,D5
            ;print ,(xxx).L
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
            JSR		PrintDataReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_M2   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register number
			JSR 	PrintDivu
			JSR		LengthW
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_M3   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register number
			JSR 	PrintDivu
			JSR		LengthW
			JSR 	PrintPostIncAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_M4   MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register number
			JSR 	PrintDivu
			JSR		LengthW
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
            ;print (xxx).W

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_xxxL JSR 	PrintDivu
			JSR		LengthW
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

DIVU_W_Data JSR 	PrintDivu
			JSR		LengthW
            ;print #<data>

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
            RTS                     ; return to input to get more input

Bcc_32bit_Disp
            ; print 32bit address
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
            JSR PrintLEA
            JSR		PrintIndirAddrReg

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
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
			JSR PrintLEA
            ;print (xxx).W

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input

Lea_xxxL_Opcode
			JSR PrintLEA
            ;print (xxx).L

			MOVE.B	D0,D5
			MOVE.B	37(A6),(A1)+		 *,
			JSR		PrintDataReg
            RTS                     ; return to input to get more input


*************************************************                MoveM_R2M_W                *************************************************
; MOVEM.W from register to memory
; first 10 bit is (0100 1000 10## ####)
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
            JSR PrintMoveM
            JSR LengthW
            ;print <list>
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

MoveM_R2M_W_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintMoveM
            JSR LengthW
            ;print <list>
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
			JSR PrintMoveM
			JSR LengthW
            ;print <list>
            ;print ,(xxx).W
            RTS                     ; return to input to get more input

MoveM_R2M_W_xxxL
			JSR PrintMoveM
			JSR LengthW
            ;print <list>
            ;print ,(xxx).L
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
            JSR PrintMoveM
            JSR LengthL
            ;print <list>
			MOVE.B	37(A6),(A1)+		 *,
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

MoveM_R2M_L_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintMoveM
            JSR LengthL
            ;print <list>
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
            ;print <list>
            ;print ,(xxx).W
            RTS                     ; return to input to get more input

MoveM_R2M_L_xxxL
			JSR PrintMoveM
			JSR LengthL
            ;print <list>
            ;print ,(xxx).L
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
            JSR PrintMoveM
            JSR LengthW
            JSR		PrintIndirAddrReg
            ;print ,<list>
            RTS                     ; return to input to get more input

MoveM_M2R_W_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintMoveM
            JSR LengthW
			JSR		PrintPreDeincAddrReg
            ;print ,<list>
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
			JSR PrintMoveM
			JSR LengthW
            ;print (xxx).W
            ;print ,<list>
            RTS                     ; return to input to get more input

MoveM_M2R_W_xxxL
			JSR PrintMoveM
			JSR LengthW
            ;print (xxx).L
            ;print ,<list>
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
            JSR PrintMoveM
            JSR LengthL
            JSR		PrintIndirAddrReg
            ;print ,<list>
            RTS                     ; return to input to get more input

MoveM_M2R_L_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintMoveM
            JSR LengthL
			JSR		PrintPreDeincAddrReg
            ;print ,<list>
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
			JSR PrintMoveM
			JSR LengthL
            ;print (xxx).W
            ;print ,<list>
            RTS                     ; return to input to get more input

MoveM_M2R_L_xxxL
			JSR PrintMoveM
			JSR LengthL
            ;print (xxx).L
            ;print ,<list>
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
            JSR PrintMuls
            JSR LengthL
            JSR		PrintDataReg
            ;print ,destination address
            RTS                     ; return to input to get more input

Muls_L_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintMuls
            JSR LengthL
            JSR		PrintIndirAddrReg
            ;print ,destination address
            RTS                     ; return to input to get more input

Muls_L_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintMuls
            JSR LengthL
			JSR 	PrintPostIncAddrReg
            ;print ,destination address
            RTS                     ; return to input to get more input

Muls_L_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintMuls
            JSR LengthL
			JSR		PrintPreDeincAddrReg
            ;print ,destination address
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

Muls_L_xxxW JSR PrintMuls
			JSR LengthL
            ;print (xxx).W
            ;print ,destination address
            RTS                     ; return to input to get more input

Muls_L_xxxL JSR PrintMuls
			JSR LengthL
            ;print (xxx).L
            ;print ,destination address
            RTS                     ; return to input to get more input

Muls_L_Data JSR PrintMuls
			JSR LengthL
            ;print #<data>
            ;print ,destination address
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
			JSR PrintDivu
			JSR LengthL
            JSR		PrintDataReg
            ;print ,destination address
            RTS                     ; return to input to get more input

Divu_L_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
			JSR PrintDivu
			JSR LengthL
            JSR		PrintIndirAddrReg
            ;print ,destination address
            RTS                     ; return to input to get more input

Divu_L_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
			JSR PrintDivu
			JSR LengthL
			JSR 	PrintPostIncAddrReg
            ;print ,destination address
            RTS                     ; return to input to get more input

Divu_L_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
			JSR PrintDivu
			JSR LengthL
			JSR		PrintPreDeincAddrReg
            ;print ,destination address
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

Divu_L_xxxW JSR PrintDivu
			JSR LengthL
            ;print (xxx).W
            ;print ,destination address
            RTS                     ; return to input to get more input

Divu_L_xxxL JSR PrintDivu
			JSR LengthL
            ;print (xxx).L
            ;print ,destination address
            RTS                     ; return to input to get more input

Divu_L_Data JSR PrintDivu
			JSR LengthL
            ;print #<data>
            ;print ,destination address
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
			JSR PrintJSR
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

JSR_M7      MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     JSR_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     JSR_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid JSR EA mode

JSR_xxxW    JSR PrintJSR
            ;print (xxx).W
            RTS                     ; return to input to get more input

JSR_xxxL    JSR PrintJSR
            ;print (xxx).L
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
            JSR PrintNot
			JSR LengthB
            JSR		PrintDataReg
            RTS                     ; return to input to get more input

Not_B_M2    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintNot
			JSR LengthB
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

Not_B_M3    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintNot
			JSR LengthB
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

Not_B_M4    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintNot
			JSR LengthB
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

Not_B_M7    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Not_B_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Not_B_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid NOT EA mode

Not_B_xxxW  JSR PrintNot
			JSR LengthB
            ;print (xxx).W
            RTS                     ; return to input to get more input

Not_B_xxxL  JSR PrintNot
			JSR LengthB
            ;print (xxx).L
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
            JSR PrintNot
			JSR LengthW
            JSR		PrintDataReg
            RTS                     ; return to input to get more input

Not_W_M2    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintNot
			JSR LengthW
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

Not_W_M3    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintNot
			JSR LengthW
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

Not_W_M4    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintNot
			JSR LengthW
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

Not_W_M7    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Not_W_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Not_W_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid NOT EA mode

Not_W_xxxW  JSR PrintNot
			JSR LengthW
            ;print (xxx).W
            RTS                     ; return to input to get more input

Not_W_xxxL  JSR PrintNot
			JSR LengthW
            ;print (xxx).L
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
            JSR PrintNot
			JSR LengthL
            JSR		PrintDataReg
            RTS                     ; return to input to get more input

Not_L_M2    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintNot
			JSR LengthL
            JSR		PrintIndirAddrReg
            RTS                     ; return to input to get more input

Not_L_M3    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintNot
			JSR LengthL
			JSR 	PrintPostIncAddrReg
            RTS                     ; return to input to get more input

Not_L_M4    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            JSR PrintNot
			JSR LengthL
			JSR		PrintPreDeincAddrReg
            RTS                     ; return to input to get more input

Not_L_M7    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Not_L_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Not_L_xxxL

            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid NOT EA mode

Not_L_xxxW  JSR PrintNot
			JSR LengthL
            ;print (xxx).W
            RTS                     ; return to input to get more input

Not_L_xxxL  JSR PrintNot
			JSR LengthL
            ;print (xxx).L
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
            JSR PrintMove
			JSR LengthW
            JSR		PrintDataReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_W_M1   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthW
            JSR		PrintAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_W_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthW
            JSR		PrintIndirAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_W_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthW
			JSR 	PrintPostIncAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_W_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthW
			JSR		PrintPreDeincAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_W_M7   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register

            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     MOVE_W_xxxW

            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     MOVE_W_xxxL

            CMP.L   #4,D5          ; if position 2-0 is 4 the EA is #<data>
            BEQ     MOVE_W_data

            JMP     InvalidOpcode  ; for mode 7 if Source register is not 0 or 1 or 4, it is not a vaid NOT EA mode

MOVE_W_xxxW JSR PrintMove
			JSR LengthW
            ;print (xxx).W
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_W_xxxL JSR PrintMove
			JSR LengthW
            ;print (xxx).L
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_W_data JSR PrintMove
			JSR LengthW
            ;print #<data>
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
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
            JSR PrintMove
			JSR LengthL
            JSR		PrintDataReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_L_M1   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthL
            JSR		PrintAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_L_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthL
            JSR		PrintIndirAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_L_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthL
			JSR 	PrintPostIncAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_L_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthL
			JSR		PrintPreDeincAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
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
            ;print (xxx).W
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_L_xxxL JSR PrintMove
			JSR LengthL
            ;print (xxx).L
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_L_data JSR PrintMove
			JSR LengthL
            ;print #<data>
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
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
            JSR PrintMove
			JSR LengthB
            JSR		PrintDataReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_B_M1   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthB
            JSR		PrintAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_B_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthB
            JSR		PrintIndirAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_B_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthB
			JSR 	PrintPostIncAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_B_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the source register
            JSR PrintMove
			JSR LengthB
			JSR		PrintPreDeincAddrReg
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
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

MOVE_B_xxxW JSR PrintMove
			JSR LengthB
            ;print (xxx).B
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_B_xxxL JSR PrintMove
			JSR LengthB
            ;print (xxx).B
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input

MOVE_B_data JSR PrintMove
			JSR LengthB
            ;print #<data>
            ;print Destination Addressing mode, the mode number is in D1       ; for mode 7, register is valid, since I check in MOVE_DesM7_Check
            ;print Destination Register in D0   ; since this hold nothing useful for mode 7, maybe for have the subroutine take in both D1 and D0
            RTS                     ; return to input to get more input


*************************************************                Invalid Handle          *************************************************

InvalidOpcode  ; don't use JSR to get here. Use JMP. If use JSR, RTS will not go back to input
            JSR     NotFound        ; Call Output NotFound subroutine to print, since it did not match with any posible opcode
            RTS                     ; Return to input to get more input

*************************************************                Subroutine             *************************************************

GetNextD4bit ; Subroutine for get the next (D4) bit from (A4) in to D5
             ; D4 should contain the number of loop you want to do
            MOVE.L  #0,D3          ; initialize D3 to 0
            MOVE.L  #0,D5          ; initialize D5 to 0, for storing result of bit from (A4)

LOOP        CMP.B   D3,D4          ; for number of iterations
            BEQ     next_code      ; if equal to each other, move on to next
            ADDQ.L  #1,D3          ; D3++, increment D3

            LSL.L   #1,D5          ; Shift left one
            LSL.W   (A4)           ; Shift left one
            BCS     ADD1           ; If there is a carry bit add one to D5
            BRA     LOOP

ADD1        ADDQ.L  #1,D5          ; add 1 to D5
            BRA     LOOP           ; The goal is for D5 to hold the same bit as the first 4 bit of A4

next_code   RTS         ; return from subroutine

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
