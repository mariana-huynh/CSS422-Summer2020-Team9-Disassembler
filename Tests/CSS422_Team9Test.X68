*-----------------------------------------------------------
* Title      : Team9 Testing 
* Written by : Mariana Huynh
* Date       : August 10th, 2020
* Description: Tests
*-----------------------------------------------------------
    ORG    $9000
START:                  ; first instruction of program

* Put program code here

* test NOP three times 
        NOP
        NOP
        NOP
    
* test MOVE
* test sizes
        MOVE.B  D1,D2           ; byte
        MOVE.W  D3,D4           ; word
        MOVE.L  D5,D6           ; long 
    
* test destination not Dn, keep size and source same 
        MOVE.B  D1,(A0)         ;(An)
        MOVE.B  D1,(A0)+        ;(An)+
        MOVE.B  D1,-(A0)        ; -(An)
        MOVE.B  D1,$12AB        ;(xxx).W
        MOVE.B  D1,$00005000    ;(xxx).L

* test source
        MOVE.W  A1,D1           ; An
        MOVE.B  (A1),D1         ;(An)
        MOVE.B  (A1)+,D1        ;(An)+
        MOVE.B  -(A1),D1        ; -(An)
        MOVE.W  $12AB,D1        ; (xxx).W
        MOVE.L  $00005000,D1    ; (xxx).L
        MOVE.B  #$1A,D1         ; #<data>
        
* other     
        MOVE.W  #$9013,D0       ; W vs L    
        MOVE.L  #$9013,D0       
        MOVE.B  $00003213,D3    ; source too big   
        MOVE.B  $AB40,D3       
        MOVE.B  $FFFF1234,D3    
        MOVE.B  $FFFF5678,D3   
        MOVE.W  $AB40,D3        
        MOVE.B  $A000,A3        ; dest An

* test MOVEM **
* various EA modes
        MOVEM       D0-D7,-(A7)                     
        MOVEM       (A7)+,D0-D7                     

        MOVEM       A0-A6,-(A7)                     
        MOVEM       (A7)+,A0-A6                     
  
        MOVEM       A0-A6/D0-D7,-(A7)              
        MOVEM       (A7)+,A0-A6/D0-D7              
 
        MOVEM       D0-D7/A0-A6,$2468               
        MOVEM       D0-D7/A0-A6,$2468               

* test sizes        
        MOVEM       (A1)+,D0-D7                     
        MOVEM.W     (A1)+,D0-D7                    
        MOVEM.L     (A1)+,D0-D7                     
        MOVEM.L     D0-D7/A0-A6,$1234               

        MOVEM.L     (A5),D0-D2/D5-D7/A0-A3/A6     
        MOVEM.W     D0-D5/D7/A0-A6,-(A7)         
        MOVEM.W     (A7)+,D0-D5/D7/A0-A6           

        MOVEM.L     A0/A1/A2/D5/D6/D7,$3A(A6,D4.L) 
        MOVEM.L     (A0)+,D0/D1/D2/A4/A3/A0/A1      
 
* not required
        MOVEA.W $1234,D0        ; not required opcode, also invalid 
        ANDI.B  #23,#$100       ; not required opcode, also invalid 

* test add
* test sizes 
        ADD.B  D1,D2           ; byte
        ADD.W  D3,D4           ; word
        ADD.L  D5,D6           ; long      

* test destination not Dn, keep size and source same 
        ADD.B  D1,(A0)         ;(An)
        ADD.B  D1,(A0)+        ;(An)+
        ADD.B  D1,-(A0)        ; -(An)
        ADD.B  D1,$12AB        ;(xxx).W
        ADD.B  D1,$00005000    ;(xxx).L

* test source
        ADD.W  A1,D1           ; An
        ADD.B  (A1),D1         ;(An)
        ADD.B  (A1)+,D1        ;(An)+
        ADD.B  -(A1),D1        ; -(An)
        ADD.W  $12AB,D1        ; (xxx).W
        ADD.L  $00005000,D1    ; (xxx).L
        ADD.B  #$1A,D1         ; #<data>
        
* other     
        ADD.W  #$9013,D0       ; W vs L    
        ADD.L  #$9013,D0       
        ADD.B  $00003213,D3    ; source too big   
        ADD.B  $AB40,D3       
        ADD.B  $FFFF1234,D3    
        ADD.B  $FFFF5678,D3   
        ADD.W  $AB40,D3        
        ADD.B  $A000,A3         ; dest An  
        ADD.B   #$1000,D2       ; exceed 8 bits, need 16 bits
        
* test shifts **
        LSL.B	D0,D0
		LSL.W	#4,D0
		LSL.W	(A2)+
		ASR.B	D6,D7
		LSL     $00001234
        LSL     $FFFF1123
        LSR     (A1)+
        LSR     -(A2)    
        LSL.B   D1,D2
        LSL.W   D1,D2
        LSL.L   D3,D4
        LSL.B   #8,D5
        LSL.W   #4,D6
        LSL.L   #1,D1
		
* test LEA ** 
        LEA	    $DC00FF00,A2
		LEA	    (A5),A4
		LEA	    -$20(A2,D7),A2
		
* test MULS and DIVU **
        MULS	D0,D3		
		MULS	(A6),D0		
		MULS	#$4567,D1	
		MULS    #45,D1
        MULS    $00001234,D7
        MULS    $FFFF1000, D2 
        
        DIVU	(A3)+,D5
        DIVU    #45,D1
        DIVU    $00001234,D7
        DIVU    $FFFF1000, D2 

* test SUB **
        SUB.L	#$00000055,D4
		SUB.L	#$FFFFFFEE,D7
		SUB.B   D5,D4
        SUB.W   D5,D4
        SUB.L   D5,D4
        SUB.L   D1,$00001234
        SUB.L   $00001234,D1
        SUB.L   D1, $FFFF1234
        SUB.L   $FFFF1234,D1
        SUB     (A0),D3
        SUB     D1, (A1)
        SUB     -(A1),D3
        SUB     D4, 0(A3,D5)  
        SUB     D4, 0(A3,D5)
		
* test branches **
        BGT.W     $00009028
        BGT.W     $00009218
        BGT.W     $00009228
        BLE.W     $00009028
        BLE.W     $00009218
        BLE.W     $00009228
        
* test JSR ** 
        JSR       $00009028
        JSR       $00009218
        JSR       $00009228
    
        

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source
    

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
