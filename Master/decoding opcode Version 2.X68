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
            
            BRA     InvalidOpcode  ; Call Output NotFound subroutine, since it did not match with any first 4 bit of the opcode




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
            BRA     MemShift
            
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
            BRA     InvalidOpcode  ; for memory shift (position 11-9)need to be 0 or 1

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

     
MULS.W_AND_Opcode
SUB_Opcode     
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
            
            BRA     InvalidOpcode   ; (position 11-8) did not match any of the Bcc opcode, so it is invalid


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
            



****at least this much done
NeedMoreBit     ; 6 opcode worth
MOVE.W_Opcode
MOVE.L_Opcode
MOVE.B_Opcode




InvalidOpcode 
            JSR     NotFound        ; Call Output NotFound subroutine, since it did not match with any first 4 bit of the opcode
            RTS                     ; Return to input to get more input
            
GetNextD4bit ; Subroutine for get the next (D4) bit from (A4) in to D5
            MOVE.L  #0,D3          ; initialize D3 to 0
            MOVE.L  #0,D5          ; initialize D5 to 0, for storing result of converted input to hex

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
