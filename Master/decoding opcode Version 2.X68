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
*******     LSL by 1 and look at the carry and branch to the write part ********
*******     Using D3,D4 for loop and,D5 result                          ********
*******     POSTCONDITION: (A4) will hold 0 after RTS from this SR      ********
*******                    except for if the opcode is NOP or RTS       ********
;Ctrl+F "Print" to see where all the print is

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
            BEQ     MULS.W_AND_Opcode
            
            CMP.L   #9,D5
            BEQ     SUB_Opcode
            
            CMP.L   #8,D5
            BEQ     DIVU.W_Opcode
            
            CMP.L   #6,D5
            BEQ     Bcc_Opcode
            
            CMP.L   #4,D5
            BEQ     NeedMoreBit
            
            CMP.L   #3,D5
            BEQ     MOVE.W_Opcode
            
            CMP.L   #2,D5
            BEQ     MOVE.L_Opcode
            
            CMP.L   #1,D5
            BEQ     MOVE.B_Opcode
            
            JMP     InvalidOpcode  ; Call Output NotFound subroutine, since it did not match with any first 4 bit of the opcode




*************************************************                LSL_ASL_Opcode                  *************************************************
; first four bit is (1110 #### #### ####)

; D0 will hold the count or register (position 11-9)
; D1 will hold the size (position 7-6)          
LSL_ASL_Opcode  
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 11-9) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which is count or register it is
            
            MOVE.L  D5,D0          ; D0 will hold the count or register 
            
            MOVE.L  #1,D4          ; get the next 1 bit from (A4)(position 8) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 1 bit of (A4), which tell us the direction
            
            CMP.L   #1,D5          ; D5 should be 1 since we are shifting left
            BNE     InvalidOpcode  ; if D5 doesn't equal 1 it is not a valid machine code
            
            MOVE.L  #2,D4          ; get the next 2 bit from (A4)(position 7-6) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 2 bit of (A4), which tell us the size
            
            CMP.L   #3,D5          ; if size is 3 then it is a memory shift
            JMP     MemShift
            
            MOVE.L  D5,D1          ; D1 will hold the size
            
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
            
ASL_Count_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register
            
            ;print ASL
            ;print size from D1
            
            JSR     CheckCount     ; change D0 to 8 if D0 equal to 0
            ;print #<1-8> from D0
            ;print ,Dy from D5  
            
            RTS                    ; Return to get more input


LSL_Count_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register
            
            ;print LSL
            ;print size from D1
            
            JSR     CheckCount     ; change D0 to 8 if D0 equal to 0
            ;print #<1-8> from # = D0
            ;print ,Dy from y = D5
            
            RTS                    ; Return to get more input
            
CheckCount  ; Subroutine for change D0 to 8 if D0 equal to 0
            CMP.L   #0,D1
            BEQ     D0_to_8  
            RTS                     ; return from subroutine    
                
D0_to_8     MOVE.L  #8,D0
            RTS                     ; return from subroutine
            
ASL_Register_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register
            
            ;print ASL
            ;print size from D1
            
            ;print Dx from x = D0
            ;print ,Dy from y = D5
            
            RTS                    ; Return to get more input


LSL_Register_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register
            
            ;print LSL
            ;print size from D1
            
            ;print Dx from x = D0
            ;print ,Dy from y = D5
            
            RTS                    ; Return to get more input

MemShift    ; D0 will hold the count or register (position 11-9)
            ; D1 will hold the mode (position 5-3)
            CMP.L   #1,D0
            BEQ     LSL_MemShift
            CMP.L   #0,D0
            BEQ     ASL_MemShift
            JMP     InvalidOpcode  ; for memory shift (position 11-9)need to be 0 or 1

LSL_MemShift; D1 will hold the mode (position 5-3)
            ;print LSL.W            
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us mode
            
            CMP.L   #2,D5          ; check if mode is in valid range
            BLT     InvalidOpcode  ; if it is less then 2 it is not valid
            CMP.L   #5,D5          ; if it is less then 5 it is not valid
            BEQ     InvalidOpcode  
            CMP.L   #6,D5          ; if it is less then 6 it is not valid
            BEQ     InvalidOpcode  
            MOVE.L  D5,D1          ; D1 will hold the mode (position 5-3)
            
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us register
            CMP.L   #7,D1
            BEQ     Shift_Mode_7
            
            ;print <ea> mode is D1, register number is in D5
            
ASL_MemShift
            ;print LSL.W 
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us mode
            
            CMP.L   #2,D5          ; check if mode is in valid range
            BLT     InvalidOpcode  ; if it is less then 2 it is not valid
            CMP.L   #5,D5          ; if it is less then 5 it is not valid
            BEQ     InvalidOpcode  
            CMP.L   #6,D5          ; if it is less then 6 it is not valid
            BEQ     InvalidOpcode  
            MOVE.L  D5,D1          ; D1 will hold the mode (position 5-3)
            
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us register
            CMP.L   #7,D1
            BEQ     Shift_Mode_7
            
            ;print <ea> mode is D1, register number is in D5

Shift_Mode_7
            CMP.L   #1,D5           ; check if the register is larger than 1
            BGT     InvalidOpcode   ; if mode is 7 and register is larger than 1, it is invalid    
            
            CMP.L   #0,D5           
            BEQ     Shift_xxxW
            
            CMP.L   #1,D5           
            BEQ     Shift_xxxL
            
Shift_xxxW
            ;print <xxx>.W
            RTS                    ; Return to get more input
            
Shift_xxxL
            ;print <xxx>.L
            RTS                    ; Return to get more input

            
*************************************************                ADD_Opcode                 *************************************************
; first four bit is (1101 #### #### ####)     
ADD_Opcode

*************************************************                MULS.W_AND_Opcode          *************************************************
; first four bit is (1100 #### #### ####)
MULS.W_AND_Opcode

*************************************************                SUB_Opcode                 *************************************************
; first four bit is (1001 #### #### ####)
SUB_Opcode 

*************************************************                DIVU.W_Opcode              *************************************************
; first four bit is (1000 #### #### ####)
DIVU.W_Opcode

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


BGT_Opcode  ;print BGT
            JMP     Bcc_displacement ; take care of output the displacement bit            

BLE_Opcode  ;print BLE
            JMP     Bcc_displacement ; take care of output the displacement bit

BRA_Opcode  ;print BRA
            JMP     Bcc_displacement ; take care of output the displacement bit

BEQ_Opcode  ;print  BEQ
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
            ;print LEA
            ;print (An) register number is in D5
            ;print ,An  register number is in D0
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
            ;print LEA
            ;print (xxx).W
            ;print ,An  register number is in D0
            RTS                     ; return to input to get more input
            
Lea_xxxL_Opcode
            ;print LEA
            ;print (xxx).L
            ;print ,An  register number is in D0
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
            ;print MOVEM.W
            ;print <list>
            ;print ,(An) register number is in D5
            RTS                     ; return to input to get more input            
                
MoveM_R2M_W_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print MOVEM.W
            ;print <list>
            ;print ,-(An) register number is in D5
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
            ;print MOVEM.W
            ;print <list>
            ;print ,(xxx).W
            RTS                     ; return to input to get more input
            
MoveM_R2M_W_xxxL
            ;print MOVEM.W
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
            ;print MOVEM.L
            ;print <list>
            ;print ,(An) register number is in D5
            RTS                     ; return to input to get more input            
                
MoveM_R2M_L_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print MOVEM.L
            ;print <list>
            ;print ,-(An) register number is in D5
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
            ;print MOVEM.L
            ;print <list>
            ;print ,(xxx).W
            RTS                     ; return to input to get more input
            
MoveM_R2M_L_xxxL
            ;print MOVEM.L
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
            ;print MOVEM.W            
            ;print (An) register number is in D5
            ;print ,<list>
            RTS                     ; return to input to get more input            
                
MoveM_M2R_W_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print MOVEM.W
            ;print -(An) register number is in D5
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
            ;print MOVEM.W
            ;print (xxx).W
            ;print ,<list>
            RTS                     ; return to input to get more input
            
MoveM_M2R_W_xxxL
            ;print MOVEM.W
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
            ;print MOVEM.L            
            ;print (An) register number is in D5
            ;print ,<list>
            RTS                     ; return to input to get more input            
                
MoveM_M2R_L_M4
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print MOVEM.L
            ;print -(An) register number is in D5
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
            ;print MOVEM.L
            ;print (xxx).W
            ;print ,<list>
            RTS                     ; return to input to get more input
            
MoveM_M2R_L_xxxL
            ;print MOVEM.L
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
            ;print MULS.L            
            ;print Dn register number is in D5
            ;print ,destination address
            RTS                     ; return to input to get more input
            
Muls_L_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print MULS.L            
            ;print (An) register number is in D5
            ;print ,destination address
            RTS                     ; return to input to get more input
            
Muls_L_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print MULS.L            
            ;print (An)+ register number is in D5
            ;print ,destination address
            RTS                     ; return to input to get more input
            
Muls_L_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print MULS.L            
            ;print -(An) register number is in D5
            ;print ,destination address
            RTS                     ; return to input to get more input
            
Muls_L_M7   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            
            CMP.L   #0,D5          ; if position 2-0 is 0 the EA for MoveM is (xxx).W
            BEQ     Muls_L_xxxW
            
            CMP.L   #1,D5          ; if position 2-0 is 1 the EA for MoveM is (xxx).L
            BEQ     Muls_L_xxxL
            
            CMP.L   #4,D5          ; if position 2-0 is 1 the EA for MoveM is (xxx).L
            BEQ     Muls_L_Data
            
            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1 or 4, MULS.L is invaid
            
Muls_L_xxxW ;print MULS.L            
            ;print (xxx).W
            ;print ,destination address
            RTS                     ; return to input to get more input

Muls_L_xxxL ;print MULS.L            
            ;print (xxx).L 
            ;print ,destination address
            RTS                     ; return to input to get more input
          
Muls_L_Data ;print MULS.L            
            ;print #<data>
            ;print ,destination address
            RTS                     ; return to input to get more input          

*************************************************                Divu_L                 ************************************************* 
; first 10 bit is (0100 1100 01## ####) 
Divu_L

*************************************************                JSR_Opcode             *************************************************
; first 10 bit is (0100 1110 10## ####)  
JSR_Opcode

*************************************************                Not_B_Opcode           *************************************************
; first 10 bit is (0100 0110 00## ####)
Not_B_Opcode

*************************************************                Not_W_Opcode           *************************************************
; first 10 bit is (0100 0110 01## ####)
Not_W_Opcode

*************************************************                Not_L_Opcode           *************************************************
; first 10 bit is (0100 0110 10## ####)
Not_L_Opcode






*************************************************                MOVE.W_Opcode          *************************************************
; first four bit is (0011 #### #### ####)
MOVE.W_Opcode

*************************************************                MOVE.L_Opcode          *************************************************
; first four bit is (0010 #### #### ####)
MOVE.L_Opcode

*************************************************                MOVE.B_Opcode          *************************************************
; first four bit is (0001 #### #### ####)
MOVE.B_Opcode




InvalidOpcode  ; don't use JSR to get here. Use JMP. If use JSR, RTS will not go back to input
            JSR     NotFound        ; Call Output NotFound subroutine, since it did not match with any first 4 bit of the opcode
            RTS                     ; Return to input to get more input
            
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
