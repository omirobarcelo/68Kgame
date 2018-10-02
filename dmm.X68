************************************************************
*                  DINAMIC MEMORY MANAGER                  *
*==========================================================*
* User subroutines providing the following functionalities:*
* 1.- DMM_INIT    : Inits the Dinamic Memory Manager.
* 2.- DMM_ALLOCATE: Reserves a chunk of memory and outputs
*                   a pointer to it.
* 3.- DMM_RELEASE : Releases a chunk of memory
*                   and makes it useable in future calls of
*                   DMM_ALLOCATE
* Nots:
*  + The list library MUST be available (previously included).
*  + The constants TM_MAX_TASKS (maximum number of tasks) and
*    TM_TASK_MEMORY_SIZE (memory assigned to each task size in bytes)
*  + A "chunk" of memory is a set of TM_TASK_MEMORY_SIZE bytes.
************************************************************

*-----------------------------------------------------------
DMM_INIT:
* Description : Inits the Dynamic Memory Manager in two steps:
*               1.- Clears the pointers list (using LS_INIT)
*               2.- Fills the pointers list with pointers to
*                   consecutive chunks of memory. The memory
*                   pointer start at DMM_MEMORY and each
*                   chunk has a size of TM_TASK_MEMORY_SIZE
*                   bytes.
* Pre         : Nothing.
* Post        : DMM initialized. 
* Modifies    : Nothing: all registers are restored.
* Note        : When calling this subroutine, the required constants
*               are assumed to have the correct values.
*-----------------------------------------------------------
	move.w		D0, -(A7)		; Push registers
	; Prepare the list
	move.w		#2, -(A7)		; Item size is 2 WORDS (=1 DOUBLE = 1 POINTER)
	move.w		#TM_MAX_TASKS, -(A7) 	; List size is the number of tasks
	move.l		#DMM_MEMLIST, -(A7)	; List is stored in DMM_MEMLIST
	bsr		LS_INIT			; Init the list
	addq.l		#8, A7			; Restore stack	
	; Put the pointers to all chunks of memory and make them available
	move.w		#TM_MAX_TASKS-1, D0	; Used in DBF loop	
	; Fill the list
	move.l		#DMM_MEMORY, -(A7)	; Pointer to the first chunk
	move.l		#DMM_MEMLIST, -(A7)	; Pointer to the list
.LOOP:	bsr		LS_PUT
	add.l		#TM_TASK_MEMORY_SIZE, 4(A7)	; Next chunk
	move.l		#DMM_MEMLIST, (A7)	; Restore list pointer
	dbf.w		D0, .LOOP	
	addq.w		#8, A7			; Restore stack	
	move.w		(A7)+, D0		; Restore registers
	rts
*-----------------------------------------------------------
	
*-----------------------------------------------------------
DMM_ALLOCATE:
* Description : Outputs a pointer to the first available memory chunk and
*               clears the memory chunk (all to zero).
* Pre         : Nothing.
* Post        : A0: Pointer to the chunk or $FFFFFFFF if no memory available
* Modifies    : Nothing, except A0 which is the output.
* Note        : When calling this subroutine, the required constants
*               are assumed to have the correct values.
*-----------------------------------------------------------
	move.l		A1, -(A7)		; PUSH registers
	move.l		#DMM_MEMLIST, -(A7)	; List pointer
	bsr		LS_FIRST		; Get the first available chunk
	move.l		(A7), A1		; Get the pointer
	cmp.l		#$FFFFFFFF, A1		; Valid pointer?
	beq		.NOMEM			; No more memory?
	move.l		2(A1), A0		; Get the pointer
	bsr		DMM_CLEAR_AREA		; Put the memory chunk to zero
	bsr		LS_REMOVE		; Memory chunk assigned, remove from available chunks list
	bra		.END
.NOMEM:	move.l		#$FFFFFFFF, A0	
.END:	addq.l		#4, A7			; Restore stack
	move.l		(A7)+, A1		; POP registers
	rts	
*-----------------------------------------------------------
	
*-----------------------------------------------------------
DMM_CLEAR_AREA:
* Description : Puts TM_TASK_MEMORY_SIZE bytes to zero starting from
*               A0
* Pre         : A0: Pointer to the memory area to clear
* Post        : Memory area cleared
* Modifies    : Nothing
* Note        : When calling this subroutine, the required constants
*               are assumed to have the correct values.
*-----------------------------------------------------------
	move.l		A0, -(A7)		; Push registers
	move.w		D0, -(A7)
	move.w		#TM_TASK_MEMORY_SIZE-1, D0
.LOOP:	clr.b		(A0)+
	dbf.w		D0, .LOOP		
	move.w		(A7)+, D0
	move.l		(A7)+, A0
	rts
*-----------------------------------------------------------

	
*-----------------------------------------------------------
DMM_RELEASE:
* Description : Releases the specified memory chunk (i.e. puts it into the list
*               of available memory chunks)
* Pre         : A0: Pointer to the memory chunk to release.
* Post        : Memory chunk released.
* Modifies    : Nothing
* Note        : When calling this subroutine, the required constants
*               are assumed to have the correct values.
*-----------------------------------------------------------
	move.l		A0, -(A7)		; Item pointer
	move.l		#DMM_MEMLIST, -(A7)	; List pointer
	bsr		LS_PUT
	addq.l 		#8, A7
	rts
*-----------------------------------------------------------
					
************************************************************
*                         VARIABLES                        *
************************************************************
; The Dinamic Memory Manager manages a list of TM_MAX_TASKS items of 1 DOUBLE 
; (a pointer) each. This is because the DMM can only be used by the Task
; Manager to assign one chunk of memory per task.
; This list holds the available memory chunks
DMM_MEMLIST:		ds.w	2+TM_MAX_TASKS*(2+1)

; RAM space that DMM can assign. Only one chunk of TM_TASK_MEMORY_SIZE bytes
; is available to each task.
DMM_MEMORY:		ds.b	TM_MAX_TASKS*TM_TASK_MEMORY_SIZE
************************************************************


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
