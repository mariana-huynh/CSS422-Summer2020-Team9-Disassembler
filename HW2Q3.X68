*-----------------------------------------------------------
* Title      : HW2 Question 3
* Written by : Mariana Huynh 
* Date       : 07/10/20
* Description: HW2 Q3
*-----------------------------------------------------------
            ORG    $1000
START:                           ; first instruction of program

* Put program code here

* Code for output
             LEA     msg,A1       ; load opening message to A1
             MOVE.B  #14,D0
             TRAP    #15          ; print to screen 
            
* Code for read in input and store
             MOVE.B  #2,D0        ; trap task 2: takes in input from keyboard and stores into A1 
             TRAP    #15        
             MOVE.W  A1,$A000     ; load user input (in A1) into address $A000
            
* Convert from ASCII to hex           
             MOVE.L  #0,D3        ; initialize D3 to 0
             MOVE.L  #2,D4        ; initialize D4 to 0, for number of iterations in for_loop1
             MOVE.L  #0,D5        ; initialize D5 to 0, for storing result of converted input to hex
    
for_loop1    CMP.B   D3,D4          ; for number of iterations
             BEQ     next           ; if equal to each other, move on to next
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
            
* Read each byte data in memory between addresses $6000 and $8000 and find match or not 
next         
             MOVE.B  D5,$A000     ; load converted input (from D5) into $A000

             LEA     a6000,A0     ; load variable a6000 ($6000) to A0
             MOVE.B  ($A000),D2   ; load data in $A000 to D2
             CMP.B   (A0),D2      ; load data from A0 to D2
             BEQ     found        ; if equal, found data
             BRA     for_loop2    ; keep looking if not equal     
for_loop2    
             ADD.W   #$2,A0       ; increment byte by byte
             LEA     a8000,A1     ; load $8000 into A1
             MOVE.W  A0,D6        ; move address in A0 to D6
             MOVE.W  A1,D7        ; move address $8000 to D7
             CMP.W   D6,D7        ; compare the two data values 
             BEQ     not_found    ; if address are equal to each other, reached $8000 (end of range)
             MOVE.B  (A0),D3      ; otherwise, move data in A0 to D3
             CMP.B   D3,D2        ; compare data in A0 to data in $A000
             BEQ     found      
             BRA     for_loop2    ; keep looking
            
found
             MOVE.L  A0,Addr1     ; move address of A0 into Addr1
             BRA     Sum512      

not_found
             MOVE.L  #$6000,Addr1 ; set default address to $6000 = 24576 in decimal
             BRA     Sum512
            
* Add series of bytes stored in 512 consecutive memory locations beginning at address Addr1
Sum512      
             LEA     Addr1,A2     ; load Addr1 into A2
             LEA     Addr1,A3     ; again but for A3
             ADDA.W  #$512,A3     ; add $512 to A3 (end address)
             MOVE.W  #0,Addsum    ; Addsum = 0
             MOVE.B  #0,CarryBit  ; CarryBit = 0
             CLR     D1             
             
sum_for_loop CMPA.L  A2,A3        ; compare Addr1 to Addr1 + $512
             BLT     disp         ; if equal, go to disp
             MOVE.B  (A2)+,D1     ; A2++
             ADD.W   D1,Addsum    ; Add D1 to Addsum
             BCS     have_carry   ; if carry bit set
             BRA     sum_for_loop
             
have_carry
             MOVE.B  #1,CarryBit  ; if carry bit set, CarryBit = 1
             BRA     sum_for_loop

* Display Addr1 (in decimal value)
disp
             LEA     msg_addr1,A1  ;Load messgae into address register A1
             MOVE.B  #14,D0
             TRAP    #15
             MOVE.L  Addr1,D1      ; load Addr1 to D1
             MOVE.B  #3,D0                
             TRAP    #15
            
* disp_Addsum
             LEA     msg_Addsum,A1 ; load message for Addsum to A1
             MOVE.B  #14,D0
             TRAP    #15
            
             CLR.L   D1
             MOVE.W  Addsum,D1     ; move Addsum to D1 to display
             MOVE.B  #3,D0
             TRAP    #15

* disp_CarryBit
             LEA     msg_CarryBit,A1 ; load message for carry bit to A1
             MOVE.B  #14,D0
             TRAP    #15
            
             CLR.L   D1
             MOVE.B  CarryBit,D1     ; move CarryBit for display 
             MOVE.B  #3,D0
             TRAP    #15
                     
quit
             MOVE.B  #9,D0           ; end 
             TRAP    #15
               
             SIMHALT                ; halt simulator

* Put variables and constants here
CR           EQU     $0D         
LF           EQU     $0A 

msg          DC.B    'Enter one hex byte value: ',0
Addr1        DC.L    0              ; longword variable
Addsum       DC.W    0              ; word variable
CarryBit     DC.B    0              ; byte variable

a6000        EQU     $6000          ; start address
a8000        EQU     $8000          ; end address

msg_Addr1    DC.B    CR,LF,'Addr1: ',0
msg_Addsum   DC.B    CR,LF,'Addsum: ', 0
msg_CarryBit DC.B    CR,LF,'CarryBit: ', 0

             END    START           ; last line of source
    






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
