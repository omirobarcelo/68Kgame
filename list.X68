************************************************************
*                         LIST LIBRARY                     *
*==========================================================*
* LIST FORMAT DESCRIPTION:                                 *
* A list is composed of:                                   *
* - Header                                                 *
*   + 1 WORD : List size (N)                               *
*   + 1 WORD : Item size (M)                               *
* - N data blocks, each one composed of:                   *
*   + 1 WORD : Occupied field                              *
*   + M WORDs : The data                                   *
*                                                          *
* The "occupied" field has two possible values:            *
*   + $0000 : The data block is empty and can be used to   *
*             put data                                     *
*   + $FFFF : The data block is occupied and has data      *
************************************************************

*-----------------------------------------------------------
LS_INIT:
* Description : Inits a list structure by setting to zero all 
*               the occupied fields and filling the header.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: Pointer to the RAM area to 
*                   store the list.
*                 - Offset 8: WORD: List size.
*                 - Offset 10: WORD: Item size (expressed in 
*                   WORDs)
* Post        : All registers are restored to their initial 
*               values.
* Note        : When calling this subroutine, the first
*               parameter (the pointer) must point to a RAM 
*               area with enough space to store the list. 
*-----------------------------------------------------------
		; PUSH registers. Only the parts that may change are stored
		; to improve execution speed. 2 LONGs and 1 WORD is 10 bytes.
		; So, add 10 to the stack offsets.
		movem.l	D1/A0, -(A7)	; Store registers whose 32 bits may change
		move.w	D0, -(A7)	; Store registers whose 16 MSB won't change

		; Prepare registers
		eor.l	D1, D1		; Put all D1 bits to zero. This register is going to be
                                        ; added, later, to an address register (32 bit). So, we
		                        ; have to ensure there is no trash in the 16 MSB.
		                        
		; Access to the stack parameters                        
		move.l	14(A7), A0	; List address
		move.w	18(A7), D0	; List size
		move.w	20(A7), D1	; Item size
		
		; Store list header
		move.w	D0, (A0)+	; Store list size
		move.w	D1, (A0)+	; Store item size
		
		; Prepare registers before loop
		lsl.l	#1, D1		; D1:=D1*2. Required as item size is expressed in WORDs
		sub.w	#1, D0		; Required as DBF loops N+1 times
		
		; Loop through all data blocks and put zeros to the occupied field.
.LOOP:		move.w	#0, (A0)+	; Occupied field:=0
		adda.l	D1, A0		; Go to the next data block
		dbf.w	D0, .LOOP

		; POP registers.		
		move.w	(A7)+, D0
		movem.l	(A7)+, D1/A0
		rts
*-----------------------------------------------------------

*-----------------------------------------------------------
LS_PUT:
* Description : Puts the specified item in the first free 
*               position, if any.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer
*                 - Offset 8: M Words: Data to put in the list
* Post        : All registers are restored to their initial 
*               values.
*               Stack. The stack offsets specified now are
*               based on the same reference that the input ones.
*                 - Offset 4: LONG: Item pointer or $FFFFFFFF
*                   if item could not be included in the list.
*                   The pointer points to the data block. That
*                   is, to the occupied field of the data block.
* Note        : When calling this subroutine, the list is supposed
*               to be properly initialized.  
*-----------------------------------------------------------
		; PUSH registers. 3 LONG + 3 WORD = 18 bytes. Add 18
		; to all stack references
		movem.l	D1/A0-A1, -(A7)
		movem.w	D0/D2-D3, -(A7)

		; Get parameters and prepare registers
		eor.l	D1, D1		; Put all D1 bits to zero		
		move.l	22(A7), A0	; List address
		move.w	(A0)+, D0	; List size
		move.w	(A0)+, D1	; Item size
		move.w	D1, D2		; Copy item size for future use
		lsl.l	#1, D1		; D1:=D1*2 (size is specified in WORDs)
		sub.w	#1, D0		; Required for DBF later
		
		; Search for an empty slot
.LOOP:		move.w	(A0)+, D3	; Occupied field
		or.w	D3, D3
		beq	.SLOT_FOUND	; If not occupied, put item
		adda.l	D1, A0		; If occupied, go to the next item
		dbf.w	D0, .LOOP

		; If no empty slot, output $FFFFFFFF
		move.l	#$FFFFFFFF, 22(A7) ; No place for new item.
		bra	.END
		
		; If slot found, store output pointer
.SLOT_FOUND:	move.l	A0, A1		; A0 points to the area to put the data
		suba.l	#2, A1		; A1 points to the data block, including occupied field
		move.l	A1, 22(A7)	; Store the output pointer
		move.w	#$FFFF, (A1)	; Mark as occupied

		; Prepare registers
		move.l	A7, A1
		adda.l	#26, A1		; Now A1 points to the data in the stack		
		subq.w	#1, D2		; Item size, in words, minus one to use in DBF
		
		; Copy the data
.LOOP2:		move.w	(A1)+, (A0)+	; Copy data from stack to data block
		dbf.w	D2, .LOOP2
				
		; POP registers
.END:		movem.w	(A7)+, D0/D2-D3
		movem.l	(A7)+, D1/A0-A1

		rts		
*-----------------------------------------------------------
		
*-----------------------------------------------------------
LS_REMOVE:
* Description : Removes the specified data block by putting
*               a zero in the occupied field.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: Pointer to the data block to remove.
* Post        : All registers are restored to their initial 
*               values.
* Note        : When calling this subroutine, the pointer is
*               supposed to point to an item.
*-----------------------------------------------------------
		; PUSH registers. 1 LONG = 4 bytes. Add 4
		; to all stack references
		move.l 	A0, -(A7)
		
		; Get parameters
		move.l 	8(A7), A0	; Pointer to data block
		
		; Change occupied field
		clr.w 	(A0)		; Mark as empty
		
		; POP registers
		move.l 	(A7)+, A0

		rts				
*-----------------------------------------------------------

*-----------------------------------------------------------
LS_FIRST:
* Description : Outputs a pointer to the first occupied item
*               or $FFFFFFFF if empty list.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer.
* Post        : All registers are restored to their initial 
*               values.
*               Stack. The stack offsets specified now are
*               based on the same reference that the input ones.
*                 - Offset 4: LONG: Item pointer or $FFFFFFFF
*                   if empty list.
*                   The pointer points to the data block. That
*                   is, to the occupied field of the data block.
* Note        : When calling this subroutine, the pointer is
*               supposed to point to a properly initialized list.
*-----------------------------------------------------------
		; PUSH registers. 2 LONG + 2 WORD = 12 bytes. Add 12
		; to all stack references
		movem.l	D1/A0, -(A7)
		movem.w	D0/D3, -(A7)

		; Get parameters and prepare registers
		eor.l	D1, D1		; Put all D1 bits to zero		
		move.l	16(A7), A0	; List address
		move.w	(A0)+, D0	; List size
		move.w	(A0)+, D1	; Item size
		lsl.l	#1, D1		; D1:=D1*2 (size is specified in WORDs)
		sub.w	#1, D0		; Required for DBF later
		
		; Search for an occupied slot
.LOOP:		move.w	(A0)+, D3	; Occupied field
		eor.w	#$FFFF, D3
		beq	.SLOT_FOUND	; If not empty, return pointer
		adda.l	D1, A0		; If empty, go to the next item
		dbf.w	D0, .LOOP

		; If no empty slot, output $FFFFFFFF
		move.l	#$FFFFFFFF, 16(A7) ; Not found occupied slot.
		bra	.END
		
		; If slot found, store output pointer
.SLOT_FOUND:	suba.l	#2, A0		; A0 points to the data block, including occupied field
		move.l	A0, 16(A7)	; Store the output pointer
		
		; POP registers
.END:		movem.w	(A7)+, D0/D3
		movem.l	(A7)+, D1/A0


		rts
*-----------------------------------------------------------
		
*-----------------------------------------------------------
LS_NEXT:
* Description : Given an item, outputs a pointer to the next 
*               occupied item or $FFFFFFFF if empty list.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer.
*                 - Offset 8: LONG: Current item pointer
* Post        : All registers are restored to their initial 
*               values.
*               Stack. The stack offsets specified now are
*               based on the same reference that the input ones.
*                 - Offset 8: LONG: Next item pointer or $FFFFFFFF
*                   if empty list.
*                   The pointer points to the data block. That
*                   is, to the occupied field of the data block.
* Note        : When calling this subroutine, the list pointer is
*               supposed to point to a properly initialized list.
*-----------------------------------------------------------
		; PUSH registers. 4 LONG + 2 WORD = 20 bytes. Add 20
		; to all stack references
		movem.l	D1-D2/D4/A0, -(A7)
		movem.w	D0/D3, -(A7)

		; Get parameters and prepare registers
		eor.l	D1, D1		; Put all D1 bits to zero		
		move.l	24(A7), A0	; List address
		move.w	(A0)+, D0	; List size
		move.w	(A0)+, D1	; Item size
		lsl.l	#1, D1		; D1:=D1*2 (size is specified in WORDs)
		subq.w	#1, D0		; Required for DBF later
		move.l 	28(A7), D4	; Current item pointer

		; Move to current item pointer subtracting from D0
		move.l	A0, D2		; First item pointer
		move.l	D4, A0		; Current item pointer
		move.w	D1, D3
		addq.w	#2, D3		; Total item size = M+1 WORD
		sub.l	D2, D4		; Difference between first item and current item pointers
		divu.w	D3, D4		; Number of items between first item and current item
		sub.w	D4, D0
		
		or.w	D0, D0
		beq	.NO_SLOT	; If D0=0 there're no more items.
		adda.l	#2, A0
		adda.l	D1, A0		; A0 points to next item after current item pointer
		subq.w	#1, D0		; Subtract one from D0 since we advanced one item
		; Search for an empty slot
.LOOP:		move.w	(A0)+, D3	; Occupied field
		eor.w	#$FFFF, D3
		beq	.SLOT_FOUND	; If not occupied, return pointer
		adda.l	D1, A0		; If occupied, go to the next item
		dbf.w	D0, .LOOP

		; If no empty slot, output $FFFFFFFF
.NO_SLOT	move.l	#$FFFFFFFF, 28(A7) ; Not found empty slot.
		bra	.END
		
		; If slot found, store output pointer
.SLOT_FOUND:	suba.l	#2, A0		; A0 points to the data block, including occupied field
		move.l	A0, 28(A7)	; Store the output pointer
		
		; POP registers
.END:		movem.w	(A7)+, D0/D3
		movem.l	(A7)+, D1-D2/D4/A0


		rts		
*-----------------------------------------------------------










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
