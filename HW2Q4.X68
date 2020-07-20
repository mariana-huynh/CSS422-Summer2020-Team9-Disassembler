*--------------------------------------------------------------
* Title      : HW2 Q4
* Written by : Mariana Huynh 
* Date       : 07/11/20
* Description: Write a program in 68K assembly language to 
*              decipher IEEE 32-bit floating point hexadecimal 
*              representation to sign bit, exponent bits, and 
*              mantissa bits. 
*--------------------------------------------------------------
             ORG    $4000
START:                              ; first instruction of program

* Put program code here

* Code for output
             LEA     msg,A1         ; load opening message to A1
             MOVE.B  #14,D0
             TRAP    #15            ; print to screen 
            
* Code for read in input and store
             MOVE.B  #2,D0          ; trap task 2: takes in input from keyboard and stores into A1 
             TRAP    #15        
             MOVE.W  A1,input       ; load user input (in A1) into address $A000 (variable)
            
* Convert from ASCII to hex           
             MOVE.L  #0,D3          ; initialize D3 to 0
             MOVE.L  #8,D4          ; initialize D4 to 8, for number of iterations in for_loop1
             MOVE.L  #0,D5          ; initialize D5 to 0, for storing result of converted input to hex
    
for_loop1    CMP.B   D3,D4          ; for number of iterations
             BEQ     next_code      ; if equal to each other, move on to next
             ADDQ.L  #1,D3          ; D3++
             
             ASL.L    #4,D5         ; shift to the left 4 bits (1 hex character)
             MOVE.B  (A1)+,D1       ; read one char into D1
             
             CMP.B   #$30,D1        ; check the char, "A-F", "0-9", "a-f"
             BLT     quit           ; D1 < 0x30
             CMP.B   #$39,D1
             BLE     calculate1     ; 0x30 (0) <= D1 <= 0x39 (9)  <-- see ASCII chart
             CMP.B   #$41,D1 
             BLT     quit           ; 0x39 < D1 < 0x41
             CMP.B   #$46,D1
             BLE     calculate3     ; 0x41 (A) <= D1 <= 0x46 (F)
             CMP.B   #$61,D1
             BLT     quit           ; 0x47 < D1 < 0x61 
             CMP.B   #$66,D1
             BLE     calculate2     ; 0x66 (f) < D1
     
calculate1
             SUB.L   #$30,D1        ; convert char (0-9) to number
             ADD.L   D1,D5
             BRA     for_loop1      ; go back and do next character 
       
calculate2
             SUB.L   #$57,D1        ; convert char (a-f) to number
             ADD.L   D1,D5
             BRA     for_loop1      ; go back and do next character 
       
calculate3
             SUB.L   #$37,D1        ; convert char (A-F) to number
             ADD.L   D1,D5
             BRA     for_loop1      ; go back and do next character 

next_code   
            MOVE.L  D5,input        ; load converted input (from D5) into input ($A000)
             
display 
* display sign bit
             LEA     msg_sign,A1    ;Load messgae into address register A1
             MOVE.B  #14,D0
             TRAP    #15
             
             CLR.L   D5             ; make sure D5 is cleared
             MOVE.L  (input),D5     ; move data in input (converted IEEE floating point) to D5
             LSL.L   #1,D5          ; shift left one bit to get MSB
             BCS     disp_sign_neg  ; if carry is set, sign = negative
             BRA     disp_sign_pos  ; otherwise, sign = postive
             
disp_sign_neg
             LEA     minus_sign,A1  ; load minus_sign message to address register A1
             MOVE.B  #14,D0
             Trap    #15
             BRA     disp_exp       ; move on to print exponent

disp_sign_pos
             LEA     plus_sign,A1   ; load plus_sign messgae to A1
             MOVE.B  #14,D0
             Trap    #15
             BRA     disp_exp       ; move on to print exponent
  
* display exponent
disp_exp
             LEA     msg_exp,A1     ; load message for Addsum to A1
             MOVE.B  #14,D0
             TRAP    #15
            
             CLR.L   D1             ; clear D1 just to be sure 
             ROL.L   #8,D5          ; rotate the eight exponent bits left 
             MOVE.B  D5,D1          ; move exponent bits for display 
             
             MOVE.B  #3,D0          ; trap task 3: display signed number from D1
             TRAP    #15    

* display mantissa
             LEA     msg_mantissa,A1 ; load message for carry bit to A1
             MOVE.B  #14,D0
             TRAP    #15
            
             CLR.L   D1              ; clear so can use D1 for mantissa 
             LSR.L   #8,D5           ; truncate exponent bits 
disp_mantissa             
             BTST.L  #0,D5           ; test LSB (if 0) in D5, Z bit is clear
             BEQ     shift_right_zeros_out  ; LSB is zero, continue to shift
             MOVE.L  D5,D1           ; move mantissa for display 
             
             MOVE.B  #3,D0           ; display signed number from D1
             TRAP    #15
             BRA     quit
             
shift_right_zeros_out
             LSR.L   #1,D5           ; shift left until all zero's on right are gone
             BRA     disp_mantissa   
                                  
quit
             MOVE.B  #9,D0           ; end 
             TRAP    #15
  

             SIMHALT                 ; halt simulator

* Put variables and constants here
CR           EQU     $0D         
LF           EQU     $0A 

input        EQU     $A000           ; variable input is at address $A000

msg          DC.B    'Please enter IEEE 32-bit floating number in hexadecimal: ',0
msg_sign     DC.B    CR,LF,'Sign bit: ',0
msg_exp      DC.B    CR,LF,'Exponent: ',0
msg_mantissa DC.B    CR,LF,'Mantissa: ',0

minus_sign   DC.B    '-',0
plus_sign    DC.B    '+',0

             END    START            ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
