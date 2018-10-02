*-----------------------------------------------------------
* Program    : Main file for task manager testing.
* Written by : A. Burguera
* Date       : 1-November-2012
* Description: Installs the task manager, inits tasks and 
*              launches task manager.
*-----------------------------------------------------------
			ORG	$1000
			OPT	MEX			; Explicitly expands the macros. Useful for debugging.
			
************************************************************
*                   SOURCE FILE INCLUDES                   *
************************************************************
			INCLUDE "taskmanager.x68" 	; Task manager library
			ds.w	0		  	; Perform memory alignment, just in case.			
			INCLUDE "tasks.x68" 	 	; The tasks
			ds.w	0		  	; Perform memory alignment, just in case.						
************************************************************

************************************************************
*                       MAIN PROGRAM                       *
************************************************************
START:			
			; Install the task manager
			bsr	TM_INSTALL
			
			; Perform the specific task initialization
			bsr	TK_INIT
			
			; Launch the task manager
			move.b	#2, D0
			trap	#0
						
			; If everything is OK, this point will never be reached.
			MOVE.B	#9,D0
			TRAP	#15		
					
			END	START		
************************************************************












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
