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

            LSL.W   (A4)                    ; shift left one bit to get the 15 place sign
            BCS     15_place_1              ; if carry is set,15 place bit is 1
            BRA     15_place_0              ; otherwise, it is 0
                       
15_place_1          ; bit we know so far (1### #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 14 place sign
            BCS     1_14_place_1            ; if carry is set,14 place bit is 1
            BRA     1_14_place_0            ; otherwise, it is 0

15_place_0          ; bit we know so far (0### #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 14 place sign
            BCS     0_14_place_1            ; if carry is set,14 place bit is 1
            BRA     0_14_place_0            ; otherwise, it is 0

1_14_place_1        ; bit we know so far (11## #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 13 place sign
            BCS     11_13_place_1           ; if carry is set,13 place bit is 1
            BRA     11_13_place_0           ; otherwise, it is 0

1_14_place_0        ; bit we know so far (10## #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 13 place sign
            BCS     10_13_place_1           ; if carry is set,13 place bit is 1
            BRA     10_13_place_0           ; otherwise, it is 0
            
0_14_place_1        ; bit we know so far (01## #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 13 place sign
            BCS     01_13_place_1           ; if carry is set,13 place bit is 1
            BRA     01_13_place_0           ; otherwise, it is 0
            
0_14_place_0        ; This is a MOVE opcode, since both the 15 and 14 place is 0  (00## #### #### ####)
            ****    continue at the 13 place, whice is size ********
            ****    the machine code is in (A4)             ********
            BRA    MOVE_OPCODE
           
11_13_place_1       ; bit we know so far (111# #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 12 place sign
            BCS     111_12_place_1          ; if carry is set,12 place bit is 1
            BRA     111_12_place_0          ; otherwise, it is 0
            
11_13_place_0       ; bit we know so far (110# #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 12 place sign
            BCS     110_12_place_1          ; if carry is set,12 place bit is 1
            BRA     110_12_place_0          ; otherwise, it is 0
     
10_13_place_1       ; This is an INVAID opcode, bit we know so far (101# #### #### ####)
            BRA     INVALID_OPCODE

10_13_place_0       ; bit we know so far (100# #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 12 place sign
            BCS     100_12_place_1          ; if carry is set,12 place bit is 1
            BRA     100_12_place_0          ; otherwise, it is 0
            
01_13_place_1       ; bit we know so far (011# #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 12 place sign
            BCS     011_12_place_1          ; if carry is set,12 place bit is 1
            BRA     011_12_place_0          ; otherwise, it is 0

01_13_place_0       ; bit we know so far (010# #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 12 place sign
            BCS     010_12_place_1          ; if carry is set,12 place bit is 1
            BRA     010_12_place_0          ; otherwise, it is 0

111_12_place_1      ; This is an INVAID opcode, since both the 15-12 place is all 1  (1111 #### #### ####)
            BRA     INVALID_OPCODE

111_12_place_0      ; bit we know so far (1110 #### #### ####)
            ****    this is LSL or ASL                      ********
            ****    continue at the 11 place, whice is size ********
            ****    the machine code is in (A4)             ********
            ****     ****     ** ******** ******** *******           ******    *******   *******   ********
            ****    /**/**   /**/**///// /**///// /**////**         **////**  **/////** /**////** /**///// 
            ****    /**//**  /**/**      /**      /**    /**       **    //  **     //**/**    /**/**      
            ****    /** //** /**/******* /******* /**    /**      /**       /**      /**/**    /**/******* 
            ****    /**  //**/**/**////  /**////  /**    /**      /**       /**      /**/**    /**/**////  
            ****    /**   //****/**      /**      /**    **       //**    **//**     ** /**    ** /**      
            ****    /**    //***/********/********/*******         //******  //*******  /*******  /********
            ****    //      /// //////// //////// ///////           //////    ///////   ///////   //////// 

110_12_place_1      ; bit we know so far (1101 #### #### ####)
            ****    this is ADD opcode  ****
            ****    continue at the 11 place, whice is size ********
            ****    the machine code is in (A4)             ********
            BRA     ADD_OPCODE
            
110_12_place_0      ; bit we know so far (1100 #### #### ####)
            ****    this is MULS.W or AND                   ********
            ****    continue at the 11 place, whice is size ********
            ****    the machine code is in (A4)             ********
            ****     ****     ** ******** ******** *******           ******    *******   *******   ********
            ****    /**/**   /**/**///// /**///// /**////**         **////**  **/////** /**////** /**///// 
            ****    /**//**  /**/**      /**      /**    /**       **    //  **     //**/**    /**/**      
            ****    /** //** /**/******* /******* /**    /**      /**       /**      /**/**    /**/******* 
            ****    /**  //**/**/**////  /**////  /**    /**      /**       /**      /**/**    /**/**////  
            ****    /**   //****/**      /**      /**    **       //**    **//**     ** /**    ** /**      
            ****    /**    //***/********/********/*******         //******  //*******  /*******  /********
            ****    //      /// //////// //////// ///////           //////    ///////   ///////   //////// 

100_12_place_1      ; bit we know so far (1001 #### #### ####)
            ****    this is SUB opcode  ****
            ****    continue at the 11 place, whice is size ********
            ****    the machine code is in D5               ********
            BRA     SUB_OPCODE
            
100_12_place_0      ; bit we know so far (1000 #### #### ####)
            ****    this is DIVU.W opcode                   ********
            ****    continue at the 11 place, whice is size ********
            ****    the machine code is in (A4)             ********
            BRA     DIVU.W_OPCODE
            
011_12_place_1      ; This is an INVAID opcode, bit we know so far (0111 #### #### ####)
            BRA     INVALID_OPCODE
            
011_12_place_0      ; bit we know so far (0110 #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 12 place sign
            BCS     0110_11_place_1         ; if carry is set,11 place bit is 1
            BRA     0110_11_place_0         ; otherwise, it is 0
            
010_12_place_1      ; This is an INVAID opcode, bit we know so far (0101 #### #### ####)
            BRA     INVALID_OPCODE
            
010_12_place_0      ; bit we know so far (0100 #### #### ####)
            LSL.W   (A4)                    ; shift left one bit to get the 12 place sign
            BCS     0100_11_place_1         ; if carry is set,11 place bit is 1
            BRA     0100_11_place_0         ; otherwise, it is 0

0110_11_place_1
0110_11_place_0
0100_11_place_1
0100_11_place_0

    
INVALID_OPCODE      ****    INVALID DECODING GO HERE                ********
MOVE_OPCODE         ****    MOVE DECODING GO HERE                   ********
ADD_OPCODE          ****    ADD DECODING GO HERE                    ********
SUB_OPCODE          ****    SUB DECODING GO HERE                    ********
DIVU.W_OPCODE       ****    DIVU.W DECODING GO HERE                 ********


    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
