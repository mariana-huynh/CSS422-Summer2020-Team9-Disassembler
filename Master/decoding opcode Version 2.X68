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
            ;print #<1-8> from D0
            ;print ,Dy from D5  
            
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
            ;print ASL.B
            RTS                     ; return from subroutine            
  
ASL_Output_Word
            ;print ASL.W
            RTS                     ; return from subroutine    
    
ASL_Output_Long       
            ;print ASL.L
            RTS                     ; return from subroutine        


LSL_Count_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register
            
            JSR     LSL_Output_Size    ;output LSL and size from D1
            
            JSR     CheckCount     ; change D0 to 8 if D0 equal to 0
            ;print #<1-8> from # = D0
            ;print ,Dy from y = D5
            
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
            ;print LSL.B
            RTS                     ; return from subroutine            
  
LSL_Output_Word
            ;print LSL.W
            RTS                     ; return from subroutine    
    
LSL_Output_Long       
            ;print LSL.L
            RTS                     ; return from subroutine        
     
CheckCount  ; Subroutine for change D0 to 8 if D0 equal to 0
            CMP.L   #0,D1
            BEQ     D0_to_8  
            RTS                     ; return from subroutine    
                
D0_to_8     MOVE.L  #8,D0
            RTS                     ; return from subroutine
            
ASL_Register_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register
            
            JSR     ASL_Output_Size    ;output ASL and size from D1            
            ;print Dx from x = D0
            ;print ,Dy from y = D5
            
            RTS                    ; Return to get more input


LSL_Register_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us which register
            
            JSR     LSL_Output_Size    ;output ASL and size from D1
            
            ;print Dx from x = D0
            ;print ,Dy from y = D5
            
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
            ;print LSL.W
            ;print (An) register number is in D5
            RTS                    ; Return to get more input

LSL_MemShift_Mode_3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
            ;print LSL.W
            ;print (An)+ register number is in D5
            RTS                    ; Return to get more input
            
LSL_MemShift_Mode_4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
            ;print LSL.W
            ;print -(An) register number is in D5
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
            ;print LSL.W
            ;print <xxx>.W
            RTS                    ; Return to get more input
            
LSL_MemShift_xxxL  
            ;print LSL.W
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
            ;print ASL.W
            ;print (An) register number is in D5
            RTS                    ; Return to get more input
            
ASL_MemShift_Mode_3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
            ;print ASL.W
            ;print (An)+ register number is in D5
            RTS                    ; Return to get more input
            
ASL_MemShift_Mode_4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us register
            ;print ASL.W
            ;print -(An) register number is in D5
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
            ;print ASL.W
            ;print <xxx>.W
            RTS                    ; Return to get more input
            
ASL_MemShift_xxxL  
            ;print ASL.W
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
            
            CMP.L   #1,D5               ; if opmode is 0, it is a word with location specified is a source  (<ea> + Dn -> Dn)
            BEQ     ADD_W_SrcEA

            CMP.L   #2,D5               ; if opmode is 0, it is a long with location specified is a source  (<ea> + Dn -> Dn)
            BEQ     ADD_L_SrcEA
            
            CMP.L   #4,D5               ; if opmode is 0, it is a byte with location specified is a Destination (Dn + <ea> -> <ea>)
            BEQ     ADD_B_DesEA
            
            CMP.L   #5,D5               ; if opmode is 0, it is a word with location specified is a Destination (Dn + <ea> -> <ea>)
            BEQ     ADD_W_DesEA

            CMP.L   #6,D5               ; if opmode is 0, it is a long with location specified is a Destination (Dn + <ea> -> <ea>)
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
            ;print ADD.B
            ;print Dn register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_B_SrcEA_M1
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.B
            ;print An register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_B_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.B
            ;print (An) register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_B_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.B
            ;print (An)+ register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_B_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.B
            ;print -(An) register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_B_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            
            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_B_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 0 the EA mode is (xxx).L
            BEQ     ADD_B_SrcEA_xxxL
            
            CMP.L   #4,D5               ; if the register is 0 the EA mode is #<data>
            BEQ     ADD_B_SrcEA_Data
            
            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_B_SrcEA_xxxW
            ;print ADD.B
            ;print (xxx).w
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input

ADD_B_SrcEA_xxxL   
            ;print ADD.B
            ;print (xxx).L
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
    
ADD_B_SrcEA_Data
            ;print ADD.B
            ;print #<Data>
            ;print ,Dn register # is in D0  
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
            ;print ADD.W
            ;print Dn register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_W_SrcEA_M1
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.W
            ;print An register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_W_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.W
            ;print (An) register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_W_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.W
            ;print (An)+ register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_W_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.W
            ;print -(An) register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_W_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            
            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_W_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 0 the EA mode is (xxx).L
            BEQ     ADD_W_SrcEA_xxxL
            
            CMP.L   #4,D5               ; if the register is 0 the EA mode is #<data>
            BEQ     ADD_W_SrcEA_Data
            
            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_W_SrcEA_xxxW
            ;print ADD.W
            ;print (xxx).w
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input

ADD_W_SrcEA_xxxL   
            ;print ADD.W
            ;print (xxx).L
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
    
ADD_W_SrcEA_Data
            ;print ADD.W
            ;print #<Data>
            ;print ,Dn register # is in D0
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
            ;print ADD.L
            ;print Dn register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_L_SrcEA_M1
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.L
            ;print An register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_L_SrcEA_M2
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.L
            ;print (An) register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_L_SrcEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.L
            ;print (An)+ register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_L_SrcEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.L
            ;print -(An) register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_L_SrcEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            
            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_L_SrcEA_xxxW

            CMP.L   #1,D5               ; if the register is 0 the EA mode is (xxx).L
            BEQ     ADD_L_SrcEA_xxxL
            
            CMP.L   #4,D5               ; if the register is 0 the EA mode is #<data>
            BEQ     ADD_L_SrcEA_Data
            
            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_L_SrcEA_xxxW
            ;print ADD.L
            ;print (xxx).w
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input

ADD_L_SrcEA_xxxL   
            ;print ADD.L
            ;print (xxx).L
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
    
ADD_L_SrcEA_Data
            ;print ADD.L
            ;print #<Data>
            ;print ,Dn register # is in D0
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
            ;print ADD.B
            ;print Dn register # is in D0
            ;print ,(An) register # is in D5
            RTS                     ; return to input to get more input
            
ADD_B_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.B
            ;print (An)+ register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_B_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.B
            ;print Dn register # is in D0
            ;print ,-(An) register # is in D5
            RTS                     ; return to input to get more input
            
ADD_B_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            
            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_B_DesEA_xxxW

            CMP.L   #1,D5               ; if the register is 0 the EA mode is (xxx).L
            BEQ     ADD_B_DesEA_xxxL
                        
            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_B_DesEA_xxxW
            ;print ADD.B
            ;print Dn register # is in D0
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

ADD_B_DesEA_xxxL   
            ;print ADD.B
            ;print Dn register # is in D0
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
            ;print ADD.W
            ;print Dn register # is in D0
            ;print ,(An) register # is in D5
            RTS                     ; return to input to get more input
            
ADD_W_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.W
            ;print (An)+ register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_W_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.W
            ;print Dn register # is in D0
            ;print ,-(An) register # is in D5
            RTS                     ; return to input to get more input
            
ADD_W_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            
            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_W_DesEA_xxxW

            CMP.L   #1,D5               ; if the register is 0 the EA mode is (xxx).L
            BEQ     ADD_W_DesEA_xxxL
                        
            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_W_DesEA_xxxW
            ;print ADD.W
            ;print Dn register # is in D0
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

ADD_W_DesEA_xxxL   
            ;print ADD.W
            ;print Dn register # is in D0
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
            ;print ADD.L
            ;print Dn register # is in D0
            ;print ,(An) register # is in D5
            RTS                     ; return to input to get more input
            
ADD_L_DesEA_M3
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.L
            ;print (An)+ register # is in D5
            ;print ,Dn register # is in D0
            RTS                     ; return to input to get more input
            
ADD_L_DesEA_M4
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            ;print ADD.L
            ;print Dn register # is in D0
            ;print ,-(An) register # is in D5
            RTS                     ; return to input to get more input
            
ADD_L_DesEA_M7
            MOVE.L  #3,D4               ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit        ; D5 hold the next 3 bit of (A4), which tell us the EA register
            
            CMP.L   #0,D5               ; if the register is 0 the EA mode is (xxx).W
            BEQ     ADD_L_DesEA_xxxW

            CMP.L   #1,D5               ; if the register is 0 the EA mode is (xxx).L
            BEQ     ADD_L_DesEA_xxxL
                        
            JMP     InvalidOpcode       ; if it is not one of the EA mode, it is invalid

ADD_L_DesEA_xxxW
            ;print ADD.L
            ;print Dn register # is in D0
            ;print ,(xxx).w
            RTS                     ; return to input to get more input

ADD_L_DesEA_xxxL   
            ;print ADD.L
            ;print Dn register # is in D0
            ;print (xxx).L
            RTS                     ; return to input to get more input

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
            
            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Muls_L_xxxW
            
            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Muls_L_xxxL
            
            CMP.L   #4,D5          ; if position 2-0 is 1 the EA is (xxx).L
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
            ;print DIVU.L            
            ;print Dn register number is in D5
            ;print ,destination address
            RTS                     ; return to input to get more input

Divu_L_M2   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print DIVU.L            
            ;print (An) register number is in D5
            ;print ,destination address
            RTS                     ; return to input to get more input
            
Divu_L_M3   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print DIVU.L            
            ;print (An)+ register number is in D5
            ;print ,destination address
            RTS                     ; return to input to get more input
            
Divu_L_M4   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print DIVU.L            
            ;print -(An) register number is in D5
            ;print ,destination address
            RTS                     ; return to input to get more input        
        
Divu_L_M7   MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            
            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Divu_L_xxxW
            
            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Divu_L_xxxL
            
            CMP.L   #4,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Divu_L_Data
            
            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1 or 4, Divu.L is invaid
            
Divu_L_xxxW ;print DIVU.L            
            ;print (xxx).W
            ;print ,destination address
            RTS                     ; return to input to get more input

Divu_L_xxxL ;print DIVU.L            
            ;print (xxx).L 
            ;print ,destination address
            RTS                     ; return to input to get more input
          
Divu_L_Data ;print DIVU.L            
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
            ;print JSR            
            ;print (An) register number is in D5
            RTS                     ; return to input to get more input

JSR_M7      MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            
            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     JSR_xxxW
            
            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     JSR_xxxL
            
            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid JSR EA mode

JSR_xxxW    ;print JSR          
            ;print (xxx).W 
            RTS                     ; return to input to get more input
            
JSR_xxxL    ;print JSR          
            ;print (xxx).L 
            RTS                     ; return to input to get more input
            

*************************************************                Not_B_Opcode           *************************************************
; first 10 bit is (0100 0110 00## ####)
Not_B_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #0,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_B_M0
            
            CMP.L   #2,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_B_M2

            CMP.L   #3,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_B_M3
            
            CMP.L   #4,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_B_M4

            CMP.L   #7,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_B_M7

            JMP     InvalidOpcode  ; if it is not a valid NOT EA mode if it is not 0 2 3 4 7

Not_B_M0    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.B            
            ;print Dn register number is in D5
            RTS                     ; return to input to get more input

Not_B_M2    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.B            
            ;print (An) register number is in D5
            RTS                     ; return to input to get more input
            
Not_B_M3    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.B            
            ;print (An)+ register number is in D5
            RTS                     ; return to input to get more input
            
Not_B_M4    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.B            
            ;print -(An) register number is in D5
            RTS                     ; return to input to get more input
            
Not_B_M7    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            
            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Not_B_xxxW
            
            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Not_B_xxxL
            
            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid NOT EA mode

Not_B_xxxW  ;print NOT.B          
            ;print (xxx).W 
            RTS                     ; return to input to get more input
            
Not_B_xxxL  ;print NOT.B          
            ;print (xxx).L 
            RTS                     ; return to input to get more input


*************************************************                Not_W_Opcode           *************************************************
; first 10 bit is (0100 0110 01## ####)
Not_W_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #0,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_W_M0
            
            CMP.L   #2,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_W_M2

            CMP.L   #3,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_W_M3
            
            CMP.L   #4,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_W_M4

            CMP.L   #7,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_W_M7

            JMP     InvalidOpcode  ; if it is not a valid NOT EA mode if it is not 0 2 3 4 7

Not_W_M0    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.W            
            ;print Dn register number is in D5
            RTS                     ; return to input to get more input

Not_W_M2    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.W            
            ;print (An) register number is in D5
            RTS                     ; return to input to get more input
            
Not_W_M3    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.W            
            ;print (An)+ register number is in D5
            RTS                     ; return to input to get more input
            
Not_W_M4    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.W            
            ;print -(An) register number is in D5
            RTS                     ; return to input to get more input
            
Not_W_M7    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            
            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Not_W_xxxW
            
            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Not_W_xxxL
            
            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid NOT EA mode

Not_W_xxxW  ;print NOT.W          
            ;print (xxx).W 
            RTS                     ; return to input to get more input
            
Not_W_xxxL  ;print NOT.W          
            ;print (xxx).L 
            RTS                     ; return to input to get more input


*************************************************                Not_L_Opcode           *************************************************
; first 10 bit is (0100 0110 10## ####)
Not_L_Opcode
            MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 5-3) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the EA mode

            CMP.L   #0,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_L_M0
            
            CMP.L   #2,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_L_M2

            CMP.L   #3,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_L_M3
            
            CMP.L   #4,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_L_M4

            CMP.L   #7,D5          ; if position 5-3 is 2 the EA is (An) mode 2
            BEQ     Not_L_M7

            JMP     InvalidOpcode  ; if it is not a valid NOT EA mode if it is not 0 2 3 4 7

Not_L_M0    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.L
            ;print Dn register number is in D5
            RTS                     ; return to input to get more input

Not_L_M2    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.L
            ;print (An) register number is in D5
            RTS                     ; return to input to get more input
            
Not_L_M3    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.L
            ;print (An)+ register number is in D5
            RTS                     ; return to input to get more input
            
Not_L_M4    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            ;print NOT.L
            ;print -(An) register number is in D5
            RTS                     ; return to input to get more input
            
Not_L_M7    MOVE.L  #3,D4          ; get the next 3 bit from (A4)(position 2-0) in to D5
            JSR     GetNextD4bit   ; D5 hold the next 3 bit of (A4), which tell us the register
            
            CMP.L   #0,D5          ; if position 2-0 is 0 the EA is (xxx).W
            BEQ     Not_L_xxxW
            
            CMP.L   #1,D5          ; if position 2-0 is 1 the EA is (xxx).L
            BEQ     Not_L_xxxL
            
            JMP     InvalidOpcode  ; for mode 7 if register is not 0 or 1, it is not a vaid NOT EA mode

Not_L_xxxW  ;print NOT.L
            ;print (xxx).W 
            RTS                     ; return to input to get more input
            
Not_L_xxxL  ;print NOT.L
            ;print (xxx).L 
            RTS                     ; return to input to get more input
            


  

*************************************************                MOVE.W_Opcode          *************************************************
; first four bit is (0011 #### #### ####)
MOVE.W_Opcode

*************************************************                MOVE.L_Opcode          *************************************************
; first four bit is (0010 #### #### ####)
MOVE.L_Opcode

*************************************************                MOVE.B_Opcode          *************************************************
; first four bit is (0001 #### #### ####)
MOVE.B_Opcode





*************************************************                Invaid Handle          *************************************************

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
