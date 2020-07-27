*-----------------------------------------------------------
* Title      : Team 9 Disassembler 
* Written by : Mariana Huynh, Hanny Long, Alex Van Matre
* Date       : 07/20/20
* Description: Disassmbles a program that is loaded into
*              memory
*-----------------------------------------------------------
            ORG    $1000
START:                                  ; first instruction of program

* Put program code here

* I/O 

* Get start address
GetStartAddr
             LEA     AskStartAddr,A1             ; load asking for start address message 
             MOVE.B  #14,D0
             TRAP    #15                         ; print to screen
    
             MOVEA.L #0,A1                       ; Clear A1
             LEA     StartAddr,A1                ; Move variable EndAddr for storing 
                                    
             MOVE.B  #2,D0                       ; trap task 2: takes in input from keyboard and stores into A1 
             TRAP    #15                    
    
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
    
             BRA     AsciiToHex                  ; convert input to hex            
            
* Convert from ASCII to hex    
AsciiToHex       
             MOVE.L  #0,D3              ; initialize D3 to 0
             MOVE.L  #8,D4              ; initialize D4 to 8, for number of iterations in for_loop1
             MOVE.L  #0,D5              ; initialize D5 to 0, for storing result of converted input to hex
    
for_loop1    
             CMP.B   D3,D4              ; for number of iterations
             BEQ     ValidateStart      ; if equal to each other, move on to validate start address
             ADDQ.L  #1,D3              ; D3++
             
             ASL.L    #4,D5             ; shift to the left 4 bits (1 hex character)
             MOVE.B  (A1)+,D1           ; read one char into D1
                
             CMP.B   #$30,D1            ; check the char, "A-F", "0-9", "a-f"
             BLT     InvalidAddrHandler ; D1 < 0x30
             CMP.B   #$39,D1
             BLE     calculate1         ; 0x30 (0) <= D1 <= 0x39 (9)  <-- see ASCII chart
             CMP.B   #$41,D1 
             BLT     InvalidAddrHandler ; 0x39 < D1 < 0x41

             CMP.B   #$46,D1
             BLE     calculate3         ; 0x41 (A) <= D1 <= 0x46 (F)
             CMP.B   #$61,D1
             BLT     InvalidAddrHandler ; 0x47 < D1 < 0x61
             CMP.B   #$66,D1
             BLE     calculate2         ; 0x66 (f) < D1
     
calculate1
             SUB.L   #$30,D1            ; convert char (0-9) to number
             ADD.L   D1,D5
             BRA     for_loop1          ; go back and do next character 
       
calculate2
             SUB.L   #$57,D1            ; convert char (a-f) to number
             ADD.L   D1,D5
             BRA     for_loop1          ; go back and do next character 
       
calculate3
             SUB.L   #$37,D1            ; convert char (A-F) to number
             ADD.L   D1,D5
             BRA     for_loop1          ; go back and do next character 
             
* validate addresses
ValidateStart 
             CMP         #1,D2  
             BEQ         ValidateEnd             ; if D2 = 1, already validated start address          
             ADDI        #1,D2                   ; if initially 0, add 1 to toggle to ValidateEnd

             BTST        #0,D3                   ; check if even number
             BNE         InvalidStartHandler     ; if not equal then odd number (error)
    
             JSR         PutStartToMemory        ; move converted starting address from D3 to defined memory location
             CLR         D3                   
             BRA         GetEndAddr              ; ask user for new end address

ValidateEnd
             BTST        #0,D3                   ; if =, then even
             BNE         InvalidEndHandler       ; if !=, equal then odd (error)
    
             CMP.L       StartAddr,D3            ; check if starting address is less than or equal to ending address
             BLE         InvalidEndHandler       ; if yes, = error (start must be less than end)
    
             CLR.W       D2                     
             JSR         PutEndToMemory          ; move ending address in D3 to defined memory location
             CLR.W       D3	                     
    
             BRA         LoadAddr  

PutStartToMemory
             MOVE.L      D3,StartAddr
             RTS
    
PutEndToMemory        
             MOVE.L      D3,EndAddr
             RTS

LoadAddr
             CLR.L       D2
             MOVE.L      StartAddr,A2
             MOVE.L      EndAddr,A3
             ;JSR         Loop      
             BRA quit
            
* Invalid input handlers 
InvalidAddrHandler
             CMP         #1,D2				     ; if toggle at D2 = 1 then end address error
             BEQ         InvalidEndHandler 
             BRA         InvalidStartHandler	 ; else starting address error

InvalidStartHandler                     
             MOVEA.L     #0,A1                   ; clear A1
             JSR         DispInvalidAddrError
             CLR         D3                      
             BRA         GetStartAddr            ; ask for starting address again
  

InvalidEndHandler                   
             MOVEA.L     #0,A1                   ; clear A1
             JSR         DispInvalidAddrError             
    
             CLR         D3	
             BRA         GetEndAddr

DispInvalidAddrError
             LEA         InvalidAddrMessage, A1  ; load error message
             MOVE.B      #13, D0                 ; print contents of A1
             TRAP        #15

quit    

             SIMHALT                             ; halt simulator

* Put variables and constants here
CR           EQU     $0D
LF           EQU     $0A

EndAddr      EQU     $500                        ; store end address, avoid overwriting 
StartAddr    EQU     $600                        ; store start address, avoid overwriting 

* introduction message 
Intro        DC.B    '*********************************************************************',CR,LF     
             DC.B    '*  TEAM 9 DISASSEMBLER',CR,LF,CR,LF
             DC.B    '*  TEAM 9: MARIANA HUYNH, HANNY LONG, ALEX VAN MATRE',CR,LF,CR,LF
             DC.B    '*********************************************************************',CR,LF,CR,LF,0

AskStartAddr DC.B 'Enter starting address in hexadecimal:', CR, LF, 0

AskEndAddr   DC.B 'Enter ending address in hexadecimal:', CR, LF, 0

AskToCont    DC.B 'Press Enter to continue:', 0

AskToRestart DC.B 'Enter 0 to exit program or 1 to restart the program: ', 0

* Error message
InvalidAddrMessage  DC.B 'Invalid Address: input not valid hex value', CR, LF, 0

              END    START        ; last line of source
              
              

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
