*-----------------------------------------------------------
* Title      : Team 9 Disassembler 
* Written by : Mariana Huynh, Hanny Long, Alex Van Matre
* Date       : 07/20/20
* Description: Disassmbles a program that is loaded into
*              memory
*-----------------------------------------------------------
              ORG    $1000
START:                                           ; first instruction of program

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
    
             ;MOVE.B  #1,D2                       ; If you need to go to invalidate, make sure its ending addr
             CMP     #8,D1                       ; Check if the given value was 8 characters long, if not it needs to be given again
             BNE     InvalidAddrHandler
             ;MOVE.B  #0,D2                       ; Reset D2, if valid length
    
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
             JSR         ReadNextLoop      
             ;BRA quit
            
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
ReadNextLoop      
             CMPA.L      A3,A2
             ;BGE         AskExitOrRestart
             BRA         AskExitOrRestart
             
*StartParse
*             BSR         CheckIf20Lines
*             JSR         DispAddr
*             MOVE.W      (A2)+, D7               *Testing for MOVE
*             JSR         ParseOpcode
*             JMP         ReadNextLoop
    
*CheckIf20Lines
*             ADD         #1, D2				     ; D2 = counter for number of lines 									
*             CMP         #20, D2 				
*										
*             BGE         EnterToCont          	 ; if 20 lines in ouput console, display press enter 
*             LEA         EmptyChar, A1			
*             MOVE.B      #14, D0
*             TRAP        #15
*    
*             RTS
    
*EnterToCont
*             JSR         DispPressEnter          ; ask user to press enter to continue
*             MOVE        #0, D2		             ; set D2 counter back to 0
*             MOVE.B      #5, D0
*             TRAP        #15	
*             RTS	  
    
*DispPressEnter
*             LEA         AskToCont,A1
*             MOVE.B      #14, D0
*             TRAP        #15
*             RTS

DispAddr
             MOVE.L      A2, D5 				  ; store current address to D5 
             MOVE.L      D5, Cur4bits             ; move current address value to memory
             JSR         HexToAscii			      ; display first four hexabits
             MOVE.W      A2, D5		        	  ; repeat, but word to get last four hexabits
             MOVE.W      D5, Cur4bits     		
             JSR         HexToAscii		        
             JSR         DispSpaceChar			  ; display space
             RTS 
    
DispSpaceChar
             MOVEA.L     #0, A1
             LEA         SpaceChar, A1
             MOVE.B      #14, D0
             TRAP        #15
             RTS
    
HexToAscii  
             LEA         HexJumpTable,A4           ; move subroutine to A4
    
             MOVE.W      Cur4bits,D3        
             JSR         ShiftToFirst4bitsD3        
             MULU        #6,D3
             JSR         0(A4,D3)
    
             MOVE.W      Cur4bits,D3
             JSR         ShiftToSecond4bitsD3
             MULU        #6,D3
             JSR         0(A4,D3)
    
             MOVE.W      Cur4bits,D3
             JSR         ShiftToThird4bitsD3
             MULU        #6,D3
             JSR         0(A4,D3)
    
             MOVE.W      Cur4bits,D3
             JSR         ShiftToFourth4bitsD3
             MULU        #6,D3
             JSR         0(A4,D3)
    
             CLR.W       D3
             RTS

ShiftToFirst4bitsD3    
             LSR         #8,D3      ; shift 8 bits to right
             LSR         #4,D3      ; shift 4 bits to right, now left most 4 bits is now right-most 4 bits
             RTS

ShiftToSecond4bitsD3  
             LSL         #4,D3      ; shift out left most 4 bits  
             LSR         #4,D3      ; return the original place
             LSR         #8,D3      ; shift out two rightmost 4 bits 
             RTS

ShiftToThird4bitsD3    
             LSL         #8,D3      ; shift out two left most 4 bits 
             LSR         #8,D3      ; shift bits back to original position 
             LSR         #4,D3      ; shift out rightmost 4 bits 
             RTS

ShiftToFourth4bitsD3   
             LSL         #8,D3	    ; shift out two left most 4 bits 
             LSL         #4,D3	    ; shift out third left most 4 bits 
             LSR         #8,D3	    ; return to original position 
             LSR         #4,D3
             RTS

HexJumpTable
             JMP         Disp0
             JMP         Disp1
             JMP         Disp2
             JMP         Disp3
             JMP         Disp4
             JMP         Disp5
             JMP         Disp6
             JMP         Disp7
             JMP         Disp8
             JMP         Disp9
             
             JMP         DispA
             JMP         DispB
             JMP         DispC
             JMP         DispD
             JMP         DispE
             JMP         DispF
             
* Display Hex Numbers 
Disp0
             LEA         STR0,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

Disp1
             LEA         STR1,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

Disp2
             LEA         STR2,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

Disp3
             LEA         STR3,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

Disp4
             LEA         STR4,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

Disp5
             LEA         STR5,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

Disp6
             LEA         STR6,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

Disp7
             LEA         STR7,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

Disp8
             LEA         Str8,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

Disp9
             LEA         Str9,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

* Display Hex Letters 
DispA 
             LEA         STRA,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

DispB
             LEA         STRB,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

DispC
             LEA         STRC,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS
    
DispD
             LEA         STRD,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

DispE
             LEA         STRE,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS

DispF 
             LEA         STRF,A1
             MOVE.B      #14,D0
             TRAP        #15
             RTS



* Parse opcode
ParseOpcode  ; insert hanny's code here  
            
                      
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

             SIMHALT                             ; halt simulator

* Put variables and constants here
CR           EQU     $0D
LF           EQU     $0A

EmptyChar    DC.W    '', 0
SpaceChar    DC.W ' ', 0

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

;AskToCont    DC.B 'Press Enter to continue:', 0

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


              END    START        ; last line of source
              
              






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
