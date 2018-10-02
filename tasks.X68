*-----------------------------------------------------------
* Program    : Some routines implementing tasks to be used
*              with taskmanager installed on trap #0. See
*              taskmanager.x68 for more details.
* Written by : A. Burguera
* Date       : 11-Dec-2011
* Description: There are four tasks implemented in this file:
*              - T1 (Ball): Plots a ball bouncing on the screen.
*              - T2 (Double buffer): Manages double buffering
*              - T3 (Keyboard): Checks SPACE and creates a new
*                   ball if pressed.
*              - T4 (Mouse): Plots mouse coordinates and checks
*                   if mouse is inside a ball. If so, the ball
*                   color is set to green. Also, if mouse is
*                   clicked, the ball task is killed. This task
*                   is a good example of how a given task can
*                   iterate over all tasks to perform actions
*                   on them.
*-----------------------------------------------------------
	
************************************************************
*                     COMMON CONSTANTS                     *
************************************************************
TK_SCREEN_WIDTH			EQU	640
TK_SCREEN_HEIGHT		EQU	480
; Task types
TK_TYPE_SPACE			EQU	0
TK_TYPE_MAIN			EQU	1
TK_TYPE_HIST			EQU	2
TK_TYPE_LOSE			EQU	3
TK_TYPE_WIN			EQU	4
TK_TYPE_SCREEN			EQU	5
TK_TYPE_KEYBOARD		EQU	6
TK_TYPE_SHIP			EQU	7
TK_TYPE_ENEMY			EQU	8
TK_TYPE_BULLET			EQU	9
TK_TYPE_ENEMY_BULLET		EQU	10
TK_TYPE_ENEMY_CREATOR		EQU	11
TK_TYPE_LIFE_BAR		EQU	12
TK_TYPE_BULLET_COLLECTOR	EQU	13
; Variable offsets used for all tasks
TK_VAR_FIRST_TIME		EQU	0
TK_VAR_ID			EQU	1
TK_VAR_TYPE			EQU	2
; Variable offsets used on shared memory
TK_BULLET_COUNT			EQU	0
TK_LIFE_HIT			EQU	1
TK_SHIP_YPOS			EQU	2
TK_BULLET_IDS			EQU	4
; Constants
TK_ENTER_XCOR			EQU	29
TK_ENTER_YCOR			EQU	30
TK_PERM_BULLET			EQU	3

************************************************************
*                       COMMON MACROS                      *
************************************************************

* ----------------------------------------------------------
TK_SET_RES			MACRO
* Sets graphics to window mode and resolution
* Parameters:	\1 Width, \2 Height
* ----------------------------------------------------------
				move.l	#1, D1
				move.b	#33, D0
				trap	#15
				move.b	#33, D0
				move.l	#\1*$10000+\2, D1
				trap	#15
				ENDM

* ----------------------------------------------------------
TK_DRAW_RECTANGLE		MACRO
* Just a wrapper for trap #15 task 87. Parameters must
* be previously loaded in registers as explained in task 87
* docs.
* ----------------------------------------------------------
				move.b	#87, D0
				trap	#15
				ENDM

* ----------------------------------------------------------
TK_DRAW_ELLIPSE			MACRO
* Just a wrapper for trap #15 task 88. Parameters must
* be previously loaded in registers as explained in task 88
* docs.
* ----------------------------------------------------------
				move.b	#88, D0
				trap	#15
				ENDM
				
* ----------------------------------------------------------
TK_SET_PEN 			MACRO
* Sets the drawing pen color
* Parameters:	\1 Pen color in format $00BBGGRR
* ----------------------------------------------------------
				move.l	\1, D1
				move.b	#80, D0
				trap	#15
				ENDM	
		
* ----------------------------------------------------------
TK_SET_FILL 			MACRO
* Sets the drawing fill color
* Parameters:	\1 fill color in format $00BBGGRR
* ----------------------------------------------------------
				move.l	\1, D1
				move.b	#81, D0
				trap	#15		
				ENDM	

************************************************************
*                       COMMON STRING                      *
************************************************************
TK_STR_CONT			dc.b	'Press ENTER to continue',0

************************************************************
*                    INITIALIZATION ROUTINE                *
************************************************************

* ----------------------------------------------------------
TK_INIT:
* Adds the tasks in the apropiate order into the task
* manager.
* ----------------------------------------------------------
; Define minimum cycle time
			move.l	#0, D1
			move.b	#8, D0
			trap	#0
; Add draw space task			
			lea	T1_START, A0
			clr.b	D0
			trap	#0
; Add main page task			
			lea	T2_START, A0
			clr.b	D0
			trap	#0
; Add the double buffer manager
			lea	T6_START, A0
			clr.b	D0
			trap	#0
; Add the keyboard manager			
			lea	T7_START, A0
			clr.b	D0
			trap	#0
; Begin music
;			lea	MUSIC, A1
;			move.b	#71, D0
;			move.b	#1, D1
;			trap	#15
;			move.l	#1, D2
;			move.b	#76, D0
;			trap	#15
			rts
* ----------------------------------------------------------
;MUSIC				dc.b	'sound02.wav',0


************************************************************
*                            TASK 1                        *
************************************************************

; ==========================================================
; Task 1 constants
; ==========================================================
T1_VAR_X			EQU	4
T1_MOD_X			EQU	6
T1_MOD_Y			EQU	8
T1_VAR_COLOR			EQU	10

; ==========================================================
; Task 1 functions
; ==========================================================

* ----------------------------------------------------------
T1_START:
* Task 1 entry point
* Draws starry space on the screen
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T1_INIT
; If this is not the first time, draw space
; Get and set pen color
				TK_SET_PEN	T1_VAR_COLOR(A0)
; Start boolean to control X pointer alternation
				clr.b	D3
; Get starting position
				move.w	T1_VAR_X(A0), D1
				move.w	T1_MOD_Y(A0), D2
; Loop to draw first line of stars
.LOOP:				move.b	#82, D0
				trap	#15
				add.w	T1_MOD_X(A0), D1
				cmp.w	#TK_SCREEN_WIDTH, D1
				ble	.LOOP
; Jump to next line
				not.b	D3
				cmp.b	#$FF, D3
				beq	.ALTX
				move.w	T1_VAR_X(A0), D1
				bra	.MODY
.ALTX:				move.w	T1_MOD_X(A0), D1
.MODY:				add.w	T1_MOD_Y(A0), D2
				cmp.w	#TK_SCREEN_HEIGHT, D2
				ble	.LOOP
				
; End by switching to next task
				move.b	#3, D0
				trap	#0												
				

* ----------------------------------------------------------
T1_INIT:
* Task 1 initialization
* Sets initial space coordinates and loop adds
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_SPACE, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Set coordinates where to begin drawing
				move.w	#5, T1_VAR_X(A0)
; Set distance modifiers
				move.w	#20, T1_MOD_X(A0)
				move.w	#10, T1_MOD_Y(A0)
; Set color to white
				move.l	#$00FFFFFF, T1_VAR_COLOR(A0)
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------


************************************************************
*                            TASK 2                        *
************************************************************

; ==========================================================
; Task 2 constants
; ==========================================================
T2_J_X				EQU	4
T2_J_Y				EQU	6
T2_E_X				EQU	8
T2_E_Y				EQU	10
T2_T1_X				EQU	12
T2_T1_Y				EQU	14
T2_T2_X				EQU	16
T2_T2_Y				EQU	18
T2_A_X				EQU	20
T2_A_Y				EQU	22
T2_S_X				EQU	24
T2_S_Y				EQU	26
T2_K_X				EQU	28
T2_K_Y				EQU	30
T2_PEN_COLOR			EQU	32
T2_FILL_COLOR			EQU	36

; ==========================================================
; Task 2 functions
; ==========================================================

* ----------------------------------------------------------
T2_START:
* Task 2 entry point
* Shows main page screen
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T2_INIT
; If this is not the first time, draw title screen
; Set pen and fill color
				TK_SET_PEN	T2_PEN_COLOR(A0)
				TK_SET_FILL	T2_FILL_COLOR(A0)
; Draw each letter
				move.w	T2_J_X(A0), D1
				move.w	T2_J_Y(A0), D2
				bsr	TK_J

				move.w	T2_E_X(A0), D1
				move.w	T2_E_Y(A0), D2
				bsr	TK_E

				move.w	T2_T1_X(A0), D1
				move.w	T2_T1_Y(A0), D2
				bsr	TK_T

				move.w	T2_T2_X(A0), D1
				move.w	T2_T2_Y(A0), D2
				bsr	TK_T

				move.w	T2_A_X(A0), D1
				move.w	T2_A_Y(A0), D2
				bsr	TK_A

				move.w	T2_S_X(A0), D1
				move.w	T2_S_Y(A0), D2
				bsr	TK_S

				move.w	T2_K_X(A0), D1
				move.w	T2_K_Y(A0), D2
				bsr	TK_K

				bsr	TK_ENTER
				
; End by switching to next task
				move.b	#3, D0
				trap	#0												
				

* ----------------------------------------------------------
T2_INIT:
* Task 2 initialization
* Sets initial coordinates for each letter
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_MAIN, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Set starting coordinates of each letter
				move.w	#190, T2_J_X(A0)
				move.w	#115, T2_J_Y(A0)
				move.w	#280, T2_E_X(A0)
				move.w	#115, T2_E_Y(A0)
				move.w	#370, T2_T1_X(A0)
				move.w	#115, T2_T1_Y(A0)
				move.w	#145, T2_T2_X(A0)
				move.w	#205, T2_T2_Y(A0)
				move.w	#235, T2_A_X(A0)
				move.w	#205, T2_A_Y(A0)
				move.w	#405, T2_S_X(A0)
				move.w	#205, T2_S_Y(A0)
				move.w	#415, T2_K_X(A0)
				move.w	#205, T2_K_Y(A0)
; Set pen and fill colors
				move.l	#$00187AF0, T2_PEN_COLOR(A0)
				move.l	#$001818F0, T2_FILL_COLOR(A0)
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------


************************************************************
*                            TASK 3                        *
************************************************************

; ==========================================================
; Task 3 constants
; ==========================================================
T3_VAR_X			EQU	18
T3_VAR_Y			EQU	10

; ==========================================================
; Task 3 functions
; ==========================================================

* ----------------------------------------------------------
T3_START:
* Task 3 entry point
* Writes game history
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T3_INIT
; If this is not the first time, write history
; Set pen and fill color
				TK_SET_PEN	#$00FFFFFF	; White pen
				TK_SET_FILL	#$00000000	; Black fill
; Get and set starting position
				move.b	#T3_VAR_X, D1
				lsl.w	#8, D1
				move.b	#T3_VAR_Y, D1
				move.b	#11, D0
				trap	#15
; Draw strings. Set position before every string
				lea	T3_STR_1, A1
				move.b	#14, D0
				trap	#15

				or.w	#$FF00, D1
				and.w	#$0AFF, D1
				addq.w	#2, D1
				move.b	#11, D0
				trap	#15
				lea	T3_STR_2, A1
				move.b	#14, D0
				trap	#15

				or.w	#$FF00, D1
				and.w	#$0DFF, D1
				addq.w	#2, D1
				move.b	#11, D0
				trap	#15
				lea	T3_STR_3, A1
				move.b	#14, D0
				trap	#15

				or.w	#$FF00, D1
				and.w	#$06FF, D1
				addq.w	#2, D1
				move.b	#11, D0
				trap	#15
				lea	T3_STR_4, A1
				move.b	#14, D0
				trap	#15

				or.w	#$FF00, D1
				and.w	#$1EFF, D1
				addq.w	#2, D1
				move.b	#11, D0
				trap	#15
				lea	T3_STR_5, A1
				move.b	#14, D0
				trap	#15

				bsr	TK_ENTER
				
; End by switching to next task
				move.b	#3, D0
				trap	#0												
				

* ----------------------------------------------------------
T3_INIT:
* Task 3 initialization
* Sets initial string coordinates
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_HIST, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)	
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------

; ==========================================================
; Task 3 strings
; ==========================================================
T3_STR_1			dc.b	'A new war is developed in the Andromeda galaxy.',0
T3_STR_2			dc.b	'Talaskia creatures have sent an scout to undermine our defenses.',0
T3_STR_3			dc.b	'It is suspected that some commander is behind the attack.',0
T3_STR_4			dc.b	'Your mission, as captain of the KOBAYASHI MARU, is to stop the advance.',0
T3_STR_5			dc.b	'Long live and prosper.',0


************************************************************
*                            TASK 4                        *
************************************************************

; ==========================================================
; Task 4 constants
; ==========================================================
T4_G_X				EQU	4
T4_G_Y				EQU	6
T4_A_X				EQU	8
T4_A_Y				EQU	10
T4_M_X				EQU	12
T4_M_Y				EQU	14
T4_E1_X				EQU	16
T4_E1_Y				EQU	18
T4_O_X				EQU	20
T4_O_Y				EQU	22
T4_V_X				EQU	24
T4_V_Y				EQU	26
T4_E2_X				EQU	28
T4_E2_Y				EQU	30
T4_R_X				EQU	32
T4_R_Y				EQU	34
T4_PEN_COLOR			EQU	36
T4_FILL_COLOR			EQU	40

; ==========================================================
; Task 4 functions
; ==========================================================

* ----------------------------------------------------------
T4_START:
* Task 4 entry point
* Shows GAME OVER screen
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T4_INIT
; If this is not the first time, draw GAME OVER screen
; Set pen and fill color
				TK_SET_PEN	T4_PEN_COLOR(A0)
				TK_SET_FILL	T4_FILL_COLOR(A0)
; Draw each letter
				move.w	T4_G_X(A0), D1
				move.w	T4_G_Y(A0), D2
				bsr	TK_G

				move.w	T4_A_X(A0), D1
				move.w	T4_A_Y(A0), D2
				bsr	TK_A

				move.w	T4_M_X(A0), D1
				move.w	T4_M_Y(A0), D2
				bsr	TK_M

				move.w	T4_E1_X(A0), D1
				move.w	T4_E1_Y(A0), D2
				bsr	TK_E

				move.w	T4_O_X(A0), D1
				move.w	T4_O_Y(A0), D2
				bsr	TK_O

				move.w	T4_V_X(A0), D1
				move.w	T4_V_Y(A0), D2
				bsr	TK_V

				move.w	T4_E2_X(A0), D1
				move.w	T4_E2_Y(A0), D2
				bsr	TK_E

				move.w	T4_R_X(A0), D1
				move.w	T4_R_Y(A0), D2
				bsr	TK_R

				bsr	TK_ENTER
				
; End by switching to next task
				move.b	#3, D0
				trap	#0												
				

* ----------------------------------------------------------
T4_INIT:
* Task 4 initialization
* Sets initial coordinates for each letter
* Also deletes al tasks of game play
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_LOSE, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Set starting coordinates of each letter
				move.w	#225, T4_G_X(A0)
				move.w	#115, T4_G_Y(A0)
				move.w	#235, T4_A_X(A0)
				move.w	#115, T4_A_Y(A0)
				move.w	#325, T4_M_X(A0)
				move.w	#195, T4_M_Y(A0)
				move.w	#415, T4_E1_X(A0)
				move.w	#115, T4_E1_Y(A0)
				move.w	#145, T4_O_X(A0)
				move.w	#205, T4_O_Y(A0)
				move.w	#235, T4_V_X(A0)
				move.w	#205, T4_V_Y(A0)
				move.w	#325, T4_E2_X(A0)
				move.w	#205, T4_E2_Y(A0)
				move.w	#495, T4_R_X(A0)
				move.w	#205, T4_R_Y(A0)
; Set pen and fill colors
				move.l	#$00187AF0, T4_PEN_COLOR(A0)
				move.l	#$001818F0, T4_FILL_COLOR(A0)
; Delete all tasks except SPACE, BUFFER, KEYBOARD and this one
				bsr	TK_DELETE
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------


************************************************************
*                            TASK 5                        *
************************************************************

; ==========================================================
; Task 5 constants
; ==========================================================
T5_VAR_X			EQU	32
T5_VAR_Y			EQU	10

; ==========================================================
; Task 5 functions
; ==========================================================

* ----------------------------------------------------------
T5_START:
* Task 5 entry point
* Writes game win page
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T5_INIT
; If this is not the first time, draw CONGRATULATIONS screen
; Set pen and fill color
				TK_SET_PEN	#$00FFFFFF	; White pen
				TK_SET_FILL	#$00000000	; Black fill
; Get and set starting position
				move.b	#T5_VAR_X, D1
				lsl.w	#8, D1
				move.b	#T5_VAR_Y, D1
				move.b	#11, D0
				trap	#15
; Draw strings. Set position before every string
				lea	T5_STR_1, A1
				move.b	#14, D0
				trap	#15

				or.w	#$FF00, D1
				and.w	#$0CFF, D1
				addq.w	#3, D1
				move.b	#11, D0
				trap	#15
				lea	T5_STR_2, A1
				move.b	#14, D0
				trap	#15

				or.w	#$FF00, D1
				and.w	#$16FF, D1
				addq.w	#2, D1
				move.b	#11, D0
				trap	#15
				lea	T5_STR_3, A1
				move.b	#14, D0
				trap	#15

				bsr	TK_ENTER
				
; End by switching to next task
				move.b	#3, D0
				trap	#0												
				

* ----------------------------------------------------------
T5_INIT:
* Task 5 initialization
* Sets initial string coordinates
* Also deletes al tasks of game play
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_WIN, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Delete all tasks except SPACE, BUFFER, KEYBOARD and this one
				bsr	TK_DELETE	
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------

; ==========================================================
; Task 5 strings
; ==========================================================
T5_STR_1			dc.b	'CONGRATULATIONS!',0
T5_STR_2			dc.b	'You have defeated the Talaskian scout and its commander.',0
T5_STR_3			dc.b	'Return to base and enjoy your reward.',0


************************************************************
*                            TASK 6                        *
************************************************************
								
; ==========================================================
; Task 6 functions
; ==========================================================

* ----------------------------------------------------------
T6_START:
* Task 6 entry point
* Does the double buffer thing
* First time:
* - Init double buffer
* - Clears hidden buffer
* Further executions
* - Shows graphics
* Note: This task must be added to Task Manager after all those
*       tasks that paint something on screen
* ----------------------------------------------------------
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T6_INIT
; Show hidden buffer
				move.b	#94, D0
				trap	#15
; Clear hidden buffer and exit
				bra	T6_CLEAR_HIDDEN
								

* ----------------------------------------------------------
T6_INIT:
* Task 6 initialization
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_SCREEN, TK_VAR_TYPE(A0)				
; Remember next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)				
; Set resolution
				TK_SET_RES	TK_SCREEN_WIDTH, TK_SCREEN_HEIGHT				
; Init double buffer
				move.b	#92, D0
				move.b	#17, D1
				trap	#15
; Clear hidden buffer (make it black)
T6_CLEAR_HIDDEN:		TK_SET_PEN	#$00000000
				TK_SET_FILL	#$00000000
				move.w	#0, D1
				move.w	#0, D2
				move.w	#TK_SCREEN_WIDTH, D3
				move.w	#TK_SCREEN_HEIGHT, D4
				move.b	#87, D0
				trap	#15
				; move.w	#$FF00, D1
				; move.b	#11, D0
				; trap	#15
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------


************************************************************
*                            TASK 7                        *
************************************************************

; ==========================================================
; Task 7 constants
; ==========================================================
T7_VAR_UP			EQU	4
T7_VAR_DOWN			EQU	5
T7_VAR_SPACE			EQU	6
T7_VAR_ENTER			EQU	7

; ==========================================================
; Task 7 functions
; ==========================================================

* ----------------------------------------------------------
T7_START:
* Task 7 entry point
* Checks for [UP], [DOWN], [SPACE] and [ENTER]
* Different functions with each button if pressed
* ----------------------------------------------------------
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T7_INIT
; Check and get UP, DOWN, SPACE and ENTER keys state
				move.b	#19, D0
				move.l	#$2628200D, D1
				;move.l	#'W'<<24+'S'<<16,D1
				;move.w	#$200D, D1		; Check for Up, Down, Space and Enter
				trap	#15
				
				and.l	#$01010101, D1		; Just change FF to 01 to
								; avoid sign problems
				move.b	D1, D3
				lsr.l	#8, D1
				move.b	D1, D4
				lsr.l	#8, D1
				move.b	D1, T7_VAR_DOWN(A0)
				lsr.l	#8, D1
				move.b	D1, T7_VAR_UP(A0)
; Check for SHIP task. If it not exist, jump to ENTER operations
				move.b	#6, D0
				trap	#0
T7_TASK_LOOP:			cmp.b	#TK_TYPE_SHIP, TK_VAR_TYPE(A1)
				beq	T7_UDS_OP
				move.b	#7, D0
				trap	#0
				cmp.b	#$FF, D1
				bne	T7_TASK_LOOP
				bra	T7_ENTER_OP

; If UP key was not pressed, jump to DOWN operations
T7_UDS_OP:			btst.b	#0, T7_VAR_UP(A0)
				beq	T7_DOWN_OP
				subq.w	#1, T8_VAR_Y(A1)
; If DOWN key was not pressed, jump to SPACE operations
T7_DOWN_OP:			btst.b	#0, T7_VAR_DOWN(A0)
				beq	T7_SPACE_OP
				addq.w	#1, T8_VAR_Y(A1)
; Check if SPACE was pressed previously. 
T7_SPACE_OP:			move.b	D4, D1
				sub.b	T7_VAR_SPACE(A0), D1
				cmp.b	#1, D1
				bne	T7_END
				move.w	T8_VAR_Y(A1), D5	; Save current y-position of space ship
; Recover task data
				move.b	#4, D0
				trap	#0
				move.w	D5, TK_SHIP_YPOS(A1)	; Save space ship current y-position in shared memory
; If there are more than the permitted bullets on screen, do nothing
				cmp.b	#0, TK_BULLET_COUNT(A1)
				beq	T7_END
; If not, create a new bullet and subtract one from the permitted bullets
				lea	T10_START, A0
				clr.b	D0
				trap	#0
				subq.b	#1, TK_BULLET_COUNT(A1)

				bra	T7_END			; Jump ENTER operations

; Check that ENTER was not pressed previously
T7_ENTER_OP:			move.b	D3, D1
				sub.b	T7_VAR_ENTER(A0), D1
				cmp.b	#1, D1	
				bne	T7_END
; If ENTER was pressed, search in which task was
				move.b	#6, D0
				trap	#0
T7_ENTER_LOOP:			cmp.b	#TK_TYPE_MAIN, TK_VAR_TYPE(A1)
				beq	T7_MAIN_OP
				cmp.b	#TK_TYPE_HIST, TK_VAR_TYPE(A1)
				beq	T7_HIST_OP
				cmp.b	#TK_TYPE_LOSE, TK_VAR_TYPE(A1)
				beq	T7_LW_OP
				cmp.b	#TK_TYPE_WIN, TK_VAR_TYPE(A1)
				beq	T7_LW_OP
				move.b	#7, D0
				trap	#0
				bra	T7_ENTER_LOOP
; If it's MAIN task, then remove it and put HISTORY task
T7_MAIN_OP:			move.b	D2, D1
				move.b	#1, D0
				trap	#0
				lea	T3_START, A0
				clr.b	D0
				trap	#0
				bra	T7_END
; It it's HISTORY task, then remove it and put SHIP, ENEMY_CREATOR, 
; LIFE_BAR and BULLET_COLLECTOR tasks
T7_HIST_OP:			move.b	D2, D1
				move.b	#1, D0
				trap	#0
				clr.b	D0
				lea	T8_START, A0
				trap	#0
				lea	T12_START, A0
				trap	#0
				lea	T13_START, A0
				trap	#0
				lea	T14_START, A0
				trap	#0
				bra	T7_END
; If it's GAME_OVER or CONGRATULATION task, then remove it and put MAIN task
T7_LW_OP:			move.b	D2, D1
				move.b	#1, D0
				trap	#0
				lea	T2_START, A0
				clr.b	D0
				trap	#0
				
; End by switching to next task
T7_END:				move.b	#4, D0
				trap	#0
				move.b	D3, T7_VAR_ENTER(A0)
				move.b	D4, T7_VAR_SPACE(A0)				
				move.b	#3, D0
				trap	#0				

* ----------------------------------------------------------
T7_INIT:
* Task 7 initialization
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_KEYBOARD, TK_VAR_TYPE(A0)				
; Remember next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Assuming that prior to execution keys were not pressed
				clr.b	T7_VAR_UP(A0)
				clr.b	T7_VAR_DOWN(A0)			
				clr.b	T7_VAR_SPACE(A0)
				clr.b	T7_VAR_ENTER(A0)				
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------


************************************************************
*                            TASK 8                        *
************************************************************

; ==========================================================
; Task 8 constants
; ==========================================================
T8_VAR_Y			EQU	4
T8_PEN_COLOR			EQU	6
T8_FILL_COLOR			EQU	10
T8_SHIP_DIST			EQU	5
T8_RADIUS			EQU	15

; ==========================================================
; Task 8 functions
; ==========================================================

* ----------------------------------------------------------
T8_START:
* Task 8 entry point
* Draw space ship
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T8_INIT
; If this is not the first time, draw space ship
; Set pen and fill color
				TK_SET_PEN	T8_PEN_COLOR(A0)
				TK_SET_FILL	T8_FILL_COLOR(A0)
; Set coordinates
				move.w	#T8_RADIUS, D1
				lsl.w	#1, D1
				addq.w	#T8_SHIP_DIST, D1
				move.w	D1, D3			; For later use
				move.w	T8_VAR_Y(A0), D2
				move.w	D2, D4			; For later use
				move.b	#86, D0
				trap	#15
; Draw space ship lines
				move.b	#85, D0
				
				move.w	#T8_SHIP_DIST, D1
				sub.w	#T8_RADIUS, D2
				trap	#15
				
				move.w	D4, D2
				add.w	#T8_RADIUS, D2
				trap	#15

				move.w	D3, D1
				move.w	D4, D2
				trap	#15

; Fill space ship
				sub.w	#T8_SHIP_DIST, D1
				move.b	#89, D0
				trap	#15
				
; End by switching to next task
				move.b	#3, D0
				trap	#0

* ----------------------------------------------------------
T8_INIT:
* Task 8 initialization
* Sets initial space ship coordinates and color
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_SHIP, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Set ship starting coordinates
				move.w	#TK_SCREEN_HEIGHT/2, T8_VAR_Y(A0)
; Set space ship pen and fill colors
				move.l	#$0000FF00, T8_PEN_COLOR(A0)
				move.l	#$0000AB00, T8_FILL_COLOR(A0)	
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------


************************************************************
*                            TASK 9                        *
************************************************************

; ==========================================================
; Task 9 constants
; ==========================================================
T9_VAR_X			EQU	4
T9_VAR_Y			EQU	6
T9_VAR_SX			EQU	8
T9_VAR_SY			EQU	10
T9_PEN_COLOR			EQU	12
T9_FILL_COLOR			EQU	16
T9_SHOOT_COUNTER		EQU	20
T9_SHOOT_READY			EQU	22
T9_ENEMY_SIDE			EQU	52
T9_SHOOT_CYCLE			EQU	100

; ==========================================================
; Task 9 functions
; ==========================================================

* ----------------------------------------------------------
T9_START:
* Task 9 entry point
* Draw and move enemy ship
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T9_INIT
; If this is not the first time, draw enemy ship and do stuff
; Set pen and fill color
				addq.l		#1, T9_FILL_COLOR(A0)
				cmp.l		#$00FFFFFF, T9_FILL_COLOR(A0)
				bne		T9_SET_COLOR
				clr.l		T9_FILL_COLOR(A0)
T9_SET_COLOR:			TK_SET_PEN	T9_PEN_COLOR(A0)
				TK_SET_FILL	T9_FILL_COLOR(A0)
; Draw enemy ship
				;move.w	T9_VAR_X(A0), D1
				;move.w	D1, D3
				;move.w	T9_VAR_Y(A0), D2
				;move.w	D2, D4
				;add.w	#T9_ENEMY_SIDE, D3
				;add.w	#T9_ENEMT_SIDE, D4
				;TK_DRAW_ELLIPSE
				
				move.w	T9_VAR_X(A0), D1
				move.w	T9_VAR_Y(A0), D2
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				add.w	#T9_ENEMY_SIDE/2, D1
				add.w	#T9_ENEMY_SIDE/4, D2
				trap	#15

				add.w	#T9_ENEMY_SIDE/2, D1
				sub.w	#T9_ENEMY_SIDE/4, D2
				trap	#15

				sub.w	#T9_ENEMY_SIDE/4, D1
				add.w	#T9_ENEMY_SIDE/2, D2
				trap	#15

				add.w	#T9_ENEMY_SIDE/4, D1
				add.w	#T9_ENEMY_SIDE/2, D2
				trap	#15

				sub.w	#T9_ENEMY_SIDE/2, D1
				sub.w	#T9_ENEMY_SIDE/4, D2
				trap	#15

				sub.w	#T9_ENEMY_SIDE/2, D1
				add.w	#T9_ENEMY_SIDE/4, D2
				trap	#15

				add.w	#T9_ENEMY_SIDE/4, D1
				sub.w	#5, D1
				sub.w	#T9_ENEMY_SIDE/2, D2
				add.w	#5, D2
				trap	#15

				move.w	T9_VAR_X(A0), D1
				move.w	T9_VAR_Y(A0), D2
				add.w	#T9_ENEMY_SIDE/2, D2
				trap	#15

				add.w	#T9_ENEMY_SIDE/4, D1
				sub.w	#5, D1
				sub.w	#5, D2
				trap	#15

				move.w	T9_VAR_X(A0), D1
				move.w	T9_VAR_Y(A0), D2
				trap	#15

				add.w	#T9_ENEMY_SIDE/2, D1
				add.w	#T9_ENEMY_SIDE/2, D2
				move.b	#89, D0
				trap	#15

; Check if enemy ship shoots
				subq.w	#1, T9_SHOOT_COUNTER(A0)
				cmp.w	#0, T9_SHOOT_COUNTER(A0)
				bne	T9_UPDATE_COOR
				lea	T11_START, A0
				clr.b	D0
				trap	#0
				move.b	#4, D0
				trap	#0
				move.w	#T9_SHOOT_CYCLE, T9_SHOOT_COUNTER(A0)
				not.b	T9_SHOOT_READY(A0)
; Update enemy ship coordinates
T9_UPDATE_COOR:			move.w	T9_VAR_SX(A0), D6
				add.w	D6, T9_VAR_X(A0)
				move.w	T9_VAR_X(A0), D3
				add.w	#T9_ENEMY_SIDE, D3	; D3:=Enemy Down X, for later use
				move.w	T9_VAR_SY(A0), D6
				add.w	D6, T9_VAR_Y(A0)
				move.w	T9_VAR_Y(A0), D4
				add.w	#T9_ENEMY_SIDE, D4	; D4:=Enemy Down Y, for later use
; Check bounce
				cmp.w	#0, T9_VAR_Y(A0)
				bne	T9_DOWN_Y
				neg.w	T9_VAR_SY(A0)		; Bounce Up Y
				bra	T9_ENEMY_OUT
T9_DOWN_Y:			cmp.w	#TK_SCREEN_HEIGHT, D4
				bne	T9_ENEMY_OUT
				neg.w	T9_VAR_SY(A0)		; Bounce Down Y
; Check if enemy ship out of window
T9_ENEMY_OUT:			;bra	T9_ENEMY_CRASH
				cmp.w	#0, D3
				bgt	T9_ENEMY_CRASH		; **
				; bgt	T9_END			; *
				move.b	TK_VAR_ID(A0), (A4)+	; *
				;move.b	TK_VAR_ID(A0), D1	; **
				;move.b	#1, D0			; **
				;trap	#0			; **
				bra	T9_END			; *
; Check if enemy ship crashed with space ship
T9_ENEMY_CRASH:			move.b	#6, D0
				trap	#0
T9_LOOP:			cmp.b	#TK_TYPE_SHIP, TK_VAR_TYPE(A1)
				beq	T9_CRASH
				move.b	#7, D0
				trap	#0
				cmp.b	#$FF, D1
				bne	T9_LOOP
				bra	T9_END

T9_CRASH:			cmp.w	#T8_RADIUS*2+T8_SHIP_DIST, T9_VAR_X(A0)
				bge	T9_END
				move.w	T8_VAR_Y(A1), D2
				sub.w	#T8_RADIUS, D2		; D2:=Ship Up Y
				move.w	D2, D3
				add.w	#T8_RADIUS*2, D3	; D3:=Ship Down Y
; If enemy Up Y it's above Ship Up Y, jump
				cmp.w	T9_VAR_Y(A0), D2
				bge	T9_ABOVE_Y
; If enemy Up Y it's under Ship Down Y, jump to end
				cmp.w	T9_VAR_Y(A0), D3
				ble	T9_END
; If enemy Up Y it's in between, game over
				bra	T9_HIT
; If enemy Down Y it's under Ship Up Y, game over
T9_ABOVE_Y:			cmp.w	D2, D4
				ble	T9_END
T9_HIT:				move.b	#4, D0
				trap	#0
				move.b	#$F0, TK_LIFE_HIT(A1)
				move.b	TK_VAR_ID(A0), (A4)+

; End by switching to next task
T9_END:				move.b	#3, D0
				trap	#0

* ----------------------------------------------------------
T9_INIT:
* Task 9 initialization
* Sets initial enemy ship coordinates, speed and color
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_ENEMY, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Set enemy ship random starting coordinates
				move.w	#TK_SCREEN_WIDTH-1, T9_VAR_X(A0)
				move.b	#8, D0
				trap	#15
				and.b	#$0F, D1
				move.w	#80, T9_VAR_Y(A0)
				cmp.b	#0, D1
				beq	T9_INIT_SPEED
T9_INIT_LOOP:			add.w	#20, T9_VAR_Y(A0)
				subq.b	#1, D1
				beq	T9_INIT_SPEED
				bra	T9_INIT_LOOP
; Set speed
T9_INIT_SPEED:			move.b	(A3)+, D1
				cmp.b	#0, D1
				bne	T9_SPEED_45
				move.w	#-1, T9_VAR_SX(A0)
				clr.w	T9_VAR_SY(A0)
				bra	T9_INIT_COLOR
T9_SPEED_45:			subq.b	#1, D1
				bne	T9_SPEED_60
				move.w	#-1, T9_VAR_SX(A0)
				move.w	#-1, T9_VAR_SY(A0)
				bra	T9_INIT_COLOR
T9_SPEED_60:			move.w	#-2, T9_VAR_SX(A0)
				move.w	#1, T9_VAR_SY(A0)
; Set pen and fill color
T9_INIT_COLOR:			move.l	#$00FFFB00, T9_PEN_COLOR(A0)
				move.l	#$00000000, T9_FILL_COLOR(A0)
; Start shoot counter and clear boolean shoot ready
				move.w	#T9_SHOOT_CYCLE, T9_SHOOT_COUNTER(A0)
				clr.b	T9_SHOOT_READY(A0)
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------


************************************************************
*                           TASK 10                        *
************************************************************

; ==========================================================
; Task 10 constants
; ==========================================================
T10_VAR_X			EQU	4
T10_VAR_Y			EQU	6
T10_COLOR			EQU	8
T10_SPEED_X			EQU	1
T10_LONG_BULLET			EQU	3

; ==========================================================
; Task 10 functions
; ==========================================================

* ----------------------------------------------------------
T10_START:
* Task 10 entry point
* Draw bullet and check if it hit an enemy
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T10_INIT
; If this is not the first time, draw bullet and do stuff
; Set color
				TK_SET_PEN	T10_COLOR(A0)
; Set coordinates
				move.w	T10_VAR_X(A0), D1
				move.w	T10_VAR_Y(A0), D2
				move.b	#86, D0
				trap	#15
; Draw bullet
				subq.w	#T10_LONG_BULLET, D1
				move.w	D1, D5			; Save for later use
				move.b	#85, D0
				trap	#15
; Check if it hit an enemy or out of window
				move.b	#6, D0
				trap	#0
T10_LOOP:			cmp.b	#TK_TYPE_ENEMY, TK_VAR_TYPE(A1)
				bne	T10_NEXT
				move.w	T9_VAR_X(A1), D3	; D3:=Enemy Up X
				move.w	T9_VAR_Y(A1), D4	; D4:=Enemy Up Y
				cmp.w	T10_VAR_X(A0), D3
				bgt	T10_NEXT
				add.w	#T9_ENEMY_SIDE, D3	; D3:=Enemy Down X
				cmp.w	T10_VAR_X(A0), D3
				blt	T10_NEXT
				cmp.w	T10_VAR_Y(A0), D4
				bgt	T10_NEXT
				add.w	#T9_ENEMY_SIDE, D4	; D4:=Enemy Down Y
				cmp.w	T10_VAR_Y(A0), D4
				blt	T10_NEXT
				;move.b	D1, D3			; Save index for later iteration
				move.b	D2, D1			; Get enemy ID
				move.b	#1, D0
				trap	#0
				;move.b	D3, D1			; Recover index
				bra	T10_DEL_BULLET
T10_NEXT:			move.b	#7, D0
				trap	#0
				cmp.b	#$FF, D1
				bne	T10_LOOP
				
				move.w	D5, D1
				cmp.w	#TK_SCREEN_WIDTH, D1
				beq	T10_DEL_BULLET	
; Update bullet coordinates
				addq.w	#T10_SPEED_X, T10_VAR_X(A0)
				bra	T10_END
; Put bullet ID on deleted bullet array in shared memory
T10_DEL_BULLET:			move.b	#4, D0
				trap	#0
				move.b	TK_VAR_ID(A0), (A4)+
				
; End by switching to next task
T10_END:			move.b	#3, D0
				trap	#0

* ----------------------------------------------------------
T10_INIT:
* Task 10 initialization
* Sets initial bullet coordinates and color
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_BULLET, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Set bullet starting coordinates
				move.w	#T8_RADIUS*2+T8_SHIP_DIST, T10_VAR_X(A0)
				move.w	TK_SHIP_YPOS(A1), T10_VAR_Y(A0)
; Set bullet color
				move.l	#$0000FF00, T10_COLOR(A0)
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------


************************************************************
*                           TASK 11                        *
************************************************************

; ==========================================================
; Task 11 constants
; ==========================================================
T11_VAR_X1			EQU	4
T11_VAR_X2			EQU	6
T11_VAR_X3			EQU	8
T11_VAR_Y1			EQU	10
T11_VAR_Y2			EQU	12
T11_VAR_Y3			EQU	14
T11_COLOR			EQU	16
T11_B1_LEFT			EQU	20
T11_B2_LEFT			EQU	21
T11_B3_LEFT			EQU	22
T11_VAR_SX1			EQU	-1
T11_VAR_SX2			EQU	-2
T11_VAR_SY1			EQU	0
T11_VAR_SY2			EQU	1
T11_LONG_1			EQU	3
T11_LONG_2			EQU	2

; ==========================================================
; Task 11 functions
; ==========================================================

* ----------------------------------------------------------
T11_START:
* Task 11 entry point
* Draw enemy bullet and check if it hit space ship
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T11_INIT
; If this is not the first time, draw enemy bullet and do stuff
; Set color
				TK_SET_PEN	T11_COLOR(A0)
; Check if enemy bullet 1 left
				cmp.b	#$FF, T11_B1_LEFT(A0)
				beq	T11_B2_CHECK
; Update enemy bullet 1 coordinates
				add.w	#T11_VAR_SX2, T11_VAR_X1(A0)
				sub.w	#T11_VAR_SY2, T11_VAR_Y1(A0)
; Draw enemy bullet 1
				move.w	T11_VAR_X1(A0), D1
				move.w	T11_VAR_Y1(A0), D2
				move.b	#86, D0
				trap	#15
				add.w	#T11_LONG_2, D1
				move.w	D1, D4				; Save for later use
				add.w	#T11_LONG_2, D2
				move.w	D2, D5				; Save for later use
				move.b	#85, D0
				trap	#15
; Check if enemy bullet 1 out of window
				cmp.w	#0, D4
				bgt	T11_B1_OW
				not.b	T11_B1_LEFT(A0)
				bra	T11_B2_CHECK
T11_B1_OW:			cmp.w	#0, D5
				bgt	T11_B1_HIT
				not.b	T11_B1_LEFT(A0)
				bra	T11_B2_CHECK
; Check if enemy bullet 1 hit space ship
T11_B1_HIT:			move.w	T11_VAR_X1(A0), D4
				move.w	T11_VAR_Y1(A0), D5
				bsr	TK_HIT_SHIP
				move.b	D7, T11_B1_LEFT(A0)

; Check if enemy bullet 2 left
T11_B2_CHECK:			cmp.b	#$FF, T11_B2_LEFT(A0)
				beq	T11_B3_CHECK
; Update enemy bullet 2 coordinates
				add.w	#T11_VAR_SX1, T11_VAR_X2(A0)
				add.w	#T11_VAR_SY1, T11_VAR_Y2(A0)
; Draw enemy bullet 2
				move.w	T11_VAR_X2(A0), D1
				move.w	T11_VAR_Y2(A0), D2
				move.b	#86, D0
				trap	#15
				add.w	#T11_LONG_1, D1
				move.w	D1, D4				; Save for later use
				move.b	#85, D0
				trap	#15
; Check if enemy bullet 2 out of window
				cmp.w	#0, D4
				bgt	T11_B2_HIT
				not.b	T11_B2_LEFT(A0)
				bra	T11_B3_CHECK
; Check if enemy bullet 2 hit space ship
T11_B2_HIT:			move.w	T11_VAR_X2(A0), D4
				move.w	T11_VAR_Y2(A0), D5
				bsr	TK_HIT_SHIP
				move.b	D7, T11_B2_LEFT(A0)

; Check if enemy bullet 3 left
T11_B3_CHECK:			cmp.b	#$FF, T11_B3_LEFT(A0)
				beq	T11_END
; Update enemy bullet 3 coordinates
				add.w	#T11_VAR_SX2, T11_VAR_X3(A0)
				add.w	#T11_VAR_SY2, T11_VAR_Y3(A0)
; Draw enemy bullet 3
				move.w	T11_VAR_X3(A0), D1
				move.w	T11_VAR_Y3(A0), D2
				move.b	#86, D0
				trap	#15
				add.w	#T11_LONG_2, D1
				move.w	D1, D4				; Save for later use
				sub.w	#T11_LONG_2, D2
				move.w	D2, D5				; Save for later use
				move.b	#85, D0
				trap	#15
; Check if enemy bullet 3 out of window
				cmp.w	#0, D4
				bgt	T11_B3_OW
				not.b	T11_B3_LEFT(A0)
				bra	T11_END
T11_B3_OW:			cmp.w	#TK_SCREEN_HEIGHT, D5
				blt	T11_B3_HIT
				not.b	T11_B3_LEFT(A0)
				bra	T11_END
; Check if enemy bullet 3 hit space ship
T11_B3_HIT:			move.w	T11_VAR_X3(A0), D4
				move.w	T11_VAR_Y3(A0), D5
				bsr	TK_HIT_SHIP
				move.b	D7, T11_B3_LEFT(A0)

; Check if all three bullet left the screen
T11_END:			cmp.b	#$FF, T11_B1_LEFT(A0)
				bne	T11_NEXT_END
				cmp.b	#$FF, T11_B2_LEFT(A0)
				bne	T11_NEXT_END
				cmp.b	#$FF, T11_B3_LEFT(A0)
				bne	T11_NEXT_END
				move.b	TK_VAR_ID(A0), (A4)+
				
; End by switching to next task
T11_NEXT_END:			move.b	#3, D0
				trap	#0

* ----------------------------------------------------------
T11_INIT:
* Task 11 initialization
* Sets initial enemy bullet coordinates and color
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_ENEMY_BULLET, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Set bullet starting coordinates
				move.b	#6, D0
				trap	#0
T11_INIT_LOOP:			cmp.b	#TK_TYPE_ENEMY, TK_VAR_TYPE(A1)
				bne	T11_INIT_NEXT
				cmp.b	#$FF, T9_SHOOT_READY(A1)
				bne	T11_INIT_NEXT
				move.w	T9_VAR_X(A1), D2
				move.w	D2, T11_VAR_X1(A0)
				move.w	D2, T11_VAR_X2(A0)
				move.w	D2, T11_VAR_X3(A0)
				move.w	T9_VAR_Y(A1), D2
				add.w	#T9_ENEMY_SIDE/2, D2
				move.w	D2, T11_VAR_Y1(A0)
				move.w	D2, T11_VAR_Y2(A0)
				move.w	D2, T11_VAR_Y3(A0)
				clr.b	T9_SHOOT_READY(A1)
				bra	T11_INIT_COLOR
T11_INIT_NEXT:			move.b	#7, D0
				trap	#0
				cmp.b	#$FF, D1
				bne	T11_INIT_LOOP
; Set bullet color
T11_INIT_COLOR:			move.l	#$00FFFB00, T11_COLOR(A0)
; Set bullet left counter
				clr.b	T11_B1_LEFT(A0)
				clr.b	T11_B2_LEFT(A0)
				clr.b	T11_B3_LEFT(A0)
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------


************************************************************
*                           TASK 12                        *
************************************************************

; ==========================================================
; Task 12 constants
; ==========================================================
T12_SPAWN_COUNTER		EQU	500
T12_ENEMY_SPAWN			EQU	4

; ==========================================================
; Task 12 functions
; ==========================================================

* ----------------------------------------------------------
T12_START:
* Task 12 entry point
* Enemy creator
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T12_INIT
; If this is not the first time, create enemy/enemies
; Subtract one from T12_ENEMY_SPAWN, if 0, then spawn and reset counter
				subq.w	#1, T12_ENEMY_SPAWN(A0)
				cmp.w	#0, T12_ENEMY_SPAWN(A0)
				bne	T12_END
; Restart counter
				move.w	#T12_SPAWN_COUNTER, T12_ENEMY_SPAWN(A0)
; Create as many tasks as enemy array and advance the pointer
				clr.w	D7
				move.b	(A2)+, D7
				cmp.b	#0, D7
				; beq	T12_CREATE_BOSS
				beq	T12_CREATE_CONGR
				cmp.b	#9, D7
				beq	T12_END
				subq.w	#1, D7
; Each loop creates a task
T12_LOOP:			lea	T9_START, A0
				clr.b	D0
				trap	#0
				dbf.w	D7, T12_LOOP
				bra	T12_END
; If reached array end, win the game
T12_CREATE_CONGR:		lea	T5_START, A0
				clr.b	D0
				trap	#0
				
; End by switching to next task
T12_END:			move.b	#3, D0
				trap	#0												
				
* ----------------------------------------------------------
T12_INIT:
* Task 12 initialization
* Selects enemy array and starts counter
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_ENEMY_CREATOR, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Select enemy spawn array
				;lea	T12_ARRAY_5, A2
				;lea	T12_ENEMY_TYPE_5, A3
				;bra	T12_START_COUNTER

				move.b	#8, D0
				trap	#15
				and.b	#$0F, D1
				cmp.b	#$0F, D1
				bne	T12_LESS_4
				lea	T12_ARRAY_5, A2
				lea	T12_ENEMY_TYPE_5, A3
				bra	T12_START_COUNTER
T12_LESS_4:			cmp.b	#$04, D1
				bge	T12_LESS_8
				lea	T12_ARRAY_1, A2
				lea	T12_ENEMY_TYPE_1, A3
				bra	T12_START_COUNTER
T12_LESS_8:			cmp.b	#$08, D1
				bge	T12_LESS_12
				lea	T12_ARRAY_2, A2
				lea	T12_ENEMY_TYPE_2, A3
				bra	T12_START_COUNTER
T12_LESS_12:			cmp.b	#$0C, D1
				bge	T12_LESS_16
				lea	T12_ARRAY_3, A2
				lea	T12_ENEMY_TYPE_3, A3
				bra	T12_START_COUNTER
T12_LESS_16:			lea	T12_ARRAY_4, A2
				lea	T12_ENEMY_TYPE_4, A3
; Start enemy spawn counter
T12_START_COUNTER:		move.w	#T12_SPAWN_COUNTER, T12_ENEMY_SPAWN(A0)
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------

; ==========================================================
; Task 12 arrays
; ==========================================================
T12_ARRAY_1			dc.b	1,2,3,9,0
T12_ENEMY_TYPE_1		dc.b	0,1,2,0,1,2
T12_ARRAY_2			dc.b	2,2,2,9,0
T12_ENEMY_TYPE_2		dc.b	0,1,0,2,1,2
T12_ARRAY_3			dc.b	1,1,1,2,2,2,9,0
T12_ENEMY_TYPE_3		dc.b	2,1,2,1,2,0,2,0,1
T12_ARRAY_4			dc.b	1,2,1,2,2,2,3,9,0
T12_ENEMY_TYPE_4		dc.b	0,0,0,1,1,2,2,1,0,0,0,1,2
T12_ARRAY_5			dc.b	2,4,2,4,3,3,4,5,9,0
T12_ENEMY_TYPE_5		dc.b	0,1,1,0,0,2,1,2,1,0,2,2,0,1,2,0,1,2,1,1,0,2,0,0,0,0,0


************************************************************
*                           TASK 13                        *
************************************************************

; ==========================================================
; Task 13 constants
; ==========================================================
T13_MAX_HITS			EQU	3
T13_LIFE_BAR			EQU	4

; ==========================================================
; Task 13 functions
; ==========================================================

* ----------------------------------------------------------
T13_START:
* Task 13 entry point
* Life bar
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T13_INIT
; If this is not the first time, check if space ship was hit and
; draw life bar at up-left corner
; If space ship was hit, subtract one from life bar
				cmp.b	#$F0, TK_LIFE_HIT(A1)
				bne	T13_DRAW_LIFE
				subq.b	#1, T13_LIFE_BAR(A0)
				clr.b	TK_LIFE_HIT(A1)
; If life bar is 0, game over
				cmp.b	#0, T13_LIFE_BAR(A0)
				bne	T13_DRAW_LIFE
				lea	T4_START, A0
				clr.b	D0
				trap	#0
; Restore task info and then draw life bar
				move.b	#4, D0
				trap	#0
T13_DRAW_LIFE:			TK_SET_PEN	#$00FFFFFF
				TK_SET_FILL	#$00FFFFFF

				clr.w	D1
				clr.w	D2
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				add.w	#17, D1
				trap	#15
				add.w	#9, D2
				trap	#15
				sub.w	#17, D1
				trap	#15
				sub.w	#9, D2
				trap	#15

				clr.w	D5
				move.b	T13_LIFE_BAR(A0), D5
				cmp.b	#0, D5
				beq	T13_END
				subq.w	#1, D5
				move.w	#2, D1
				move.w	#2, D2
				move.w	D1, D3
				add.w	#3, D3
				move.w	D2, D4
				add.w	#5, D4
T13_LOOP:			TK_DRAW_RECTANGLE
				add.w	#5, D1
				add.w	#5, D3
				dbf.w	D5, T13_LOOP

; End by switching to next task
T13_END:			move.b	#3, D0
				trap	#0												

* ----------------------------------------------------------
T13_INIT:
* Task 13 initialization
* Start the life bar
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_LIFE_BAR, TK_VAR_TYPE(A0)	
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Set hits of life bar
				move.b	#T13_MAX_HITS, T13_LIFE_BAR(A0)
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------



************************************************************
*                           TASK 14                        *
************************************************************

; ==========================================================
; Task 14 functions
; ==========================================================

* ----------------------------------------------------------
T14_START:
* Task 14 entry point
* Bullet collector
* ----------------------------------------------------------
; Task memory is set to 0 when task is created. Use
; this to decide whether is the first time or not.
				cmp.b	#0, TK_VAR_FIRST_TIME(A0)
				beq	T14_INIT
; If this is not the first time, proceed to eliminate bullet tasks
; Loop through eliminated bullet array
			     	move.b  #$F0, (A4)
			      	lea     TK_BULLET_IDS(A1), A4
T14_LOOP:			move.b	(A4)+, D1
				cmp.b	#$F0, D1
				beq	T14_RESET_POINTER

				move.b	#5, D0
				trap	#0
				move.b	TK_VAR_TYPE(A0), D2

				move.b	#1, D0
				trap	#0
				cmp.b	#TK_TYPE_ENEMY, D2
				beq	T14_LOOP
				cmp.b	#TK_TYPE_ENEMY_BULLET, D2
				beq	T14_LOOP
				addq.b	#1, TK_BULLET_COUNT(A1)
				bra	T14_LOOP
; Reset pointer
T14_RESET_POINTER:		lea	TK_BULLET_IDS(A1), A4
				
; End by switching to next task
				move.b	#3, D0
				trap	#0												

* ----------------------------------------------------------
T14_INIT:
* Task 14 initialization
* Start the pointer
* ----------------------------------------------------------
; Store task ID. When switching to a task, the ID is in D1, but
; storing in task memory makes things easier.
				move.b	D1, TK_VAR_ID(A0)
; Store the task type
				move.b	#TK_TYPE_BULLET_COLLECTOR, TK_VAR_TYPE(A0)		
; Remember that next time will not be the first one
				move.b	#$FF, TK_VAR_FIRST_TIME(A0)
; Set permitted bullets
				move.b	#TK_PERM_BULLET, Tk_BULLET_COUNT(A1)
; Sets the pointer at eliminated bullets IDs array in shared memory
				lea	TK_BULLET_IDS(A1), A4
; End by switching to next task
				move.b	#3, D0
				trap	#0				
* ----------------------------------------------------------


************************************************************
*             	    AUXILIARY SUBROUTINES                  *
************************************************************

* ----------------------------------------------------------
TK_ENTER:
* Writes the CONTINUE string
* ----------------------------------------------------------
				TK_SET_PEN	#$00FFFFFF
				TK_SET_FILL	#$00000000
				
				move.b	#4, D0
				trap	#0

				move.b	#TK_ENTER_XCOR, D1
				lsl.w	#8, D1
				move.b	#TK_ENTER_YCOR, D1
				move.b	#11, D0
				trap	#15
				lea	TK_STR_CONT, A1
				move.b	#14, D0
				trap	#15
				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_DELETE:
* Delete all tasks except SPACE, BUFFER, KEYBOARD or the one 
* calling this subroutine
* ----------------------------------------------------------
; Loop for all tasks
; Get first task info
				move.b	#6, D0
				trap	#0
; If it's SPACE, BUFFER, KEYBOARD, WIN/LOSE task, get next
TK_DEL_LOOP:			cmp.b	#TK_TYPE_SPACE, TK_VAR_TYPE(A1)
				beq	TK_DEL_NEXT
				cmp.b	#TK_TYPE_SCREEN, TK_VAR_TYPE(A1)
				beq	TK_DEL_NEXT
				cmp.b	#TK_TYPE_KEYBOARD, TK_VAR_TYPE(A1)
				beq	TK_DEL_NEXT
				cmp.b	#TK_TYPE_LOSE, TK_VAR_TYPE(A1)
				beq	TK_DEL_NEXT
				cmp.b	#TK_TYPE_WIN, TK_VAR_TYPE(A1)
				beq	TK_DEL_NEXT

; Save task index, get task ID and delete. Then restore task index
				move.b	D1, D3
				move.b	D2, D1
				move.b	#1, D0
				trap	#0
				subq.b	#1, D3
				move.b	D3, D1

TK_DEL_NEXT:			move.b	#7, D0
				trap	#0
; If it isn't last task, loop
				cmp.b	#$FF, D1
				bne	TK_DEL_LOOP
				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_HIT_SHIP:
* Checks if enemy bullet hit space ship
* Pre: 	D4:	Enemy bullet X
*	D5:	Enemy bullet Y
* Post:	D7:	$FF if enemy bullet hit, 0 otherwise
* ----------------------------------------------------------
				move.b	#6, D0
				trap	#0
.LOOP:				cmp.b	#TK_TYPE_SHIP, TK_VAR_TYPE(A1)
				bne	.NEXT
				bra	.CHECK
.NEXT:				move.b	#7, D0
				trap	#0
				cmp.b	#$FF, D1
				bne	.LOOP
				clr.b	D7
				bra	.END1

.CHECK:				move.w	T8_VAR_Y(A1), D6
				sub.w	#T8_RADIUS, D6			; D6:=Ship Up Y
				move.w	D6, D7
				add.w	#T8_RADIUS*2, D7		; D7:=Ship Down Y
				move.b	#4, D0
				trap	#0
; Check if hit the space ship in the X axis
				cmp.w	#T8_RADIUS*2+T8_SHIP_DIST, D4
				bge	.END1
; Check if hit the space ship int the Y axis
				cmp.w	D6, D5
				ble	.END1
				cmp.w	D7, D5
				bge	.END1
; If arrives at this point, space ship is hit
				move.b	#$F0, TK_LIFE_HIT(A1)
				move.b	#4, D0
				trap	#0
				move.b	#$FF, D7
				bra	.END2

.END1:				clr.b	D7
.END2:				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_G:
* Draw G letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				sub.w	#80, D1
				trap	#15

				add.w	#80, D2
				trap	#15

				add.w	#62, D1
				trap	#15

				sub.w	#35, D2
				trap	#15

				add.w	#18, D1
				trap	#15

				sub.w	#10, D2
				trap	#15

				sub.w	#40, D1
				trap	#15

				add.w	#10, D2
				trap	#15

				add.w	#18, D1
				trap	#15

				add.w	#25, D2
				trap	#15

				sub.w	#48, D1
				trap	#15

				sub.w	#60, D2
				trap	#15

				add.w	#70, D1
				trap	#15

				sub.w	#10, D2
				trap	#15

				sub.w	#4, D1
				add.w	#4, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_A:
* Draw A letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0
				
				add.w	#80, D1
				trap	#15

				add.w	#80, D2
				trap	#15

				sub.w	#10, D1
				trap	#15

				sub.w	#30, D2
				trap	#15

				sub.w	#60, D1
				trap	#15

				add.w	#30, D2
				trap	#15

				sub.w	#10, D1
				trap	#15

				sub.w	#80, D2
				trap	#15

				; Buit interior
				add.w	#10, D1
				add.w	#10, D2
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				add.w	#60, D1
				trap	#15

				add.w	#30, D2
				trap	#15

				sub.w	#60, D1
				trap	#15

				sub.w	#30, D2
				trap	#15

				sub.w	#4, D1
				sub.w	#4, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_M:
* Draw M letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				add.w	#10, D1
				trap	#15

				sub.w	#70, D2
				trap	#15

				add.w	#25, D1
				add.w	#40, D2
				trap	#15

				add.w	#10, D1
				trap	#15

				add.w	#25, D1
				sub.w	#40, D2
				trap	#15

				add.w	#70, D2
				trap	#15

				add.w	#10, D1
				trap	#15

				sub.w	#80, D2
				trap	#15

				sub.w	#10, D1
				trap	#15

				sub.w	#30, D1
				add.w	#40, D2
				trap	#15

				sub.w	#30, D1
				sub.w	#40, D2
				trap	#15

				sub.w	#10, D1
				trap	#15

				add.w	#80, D2
				trap	#15

				add.w	#5, D1
				sub.w	#5, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_E:
* Draw E letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				add.w	#80, D1
				trap	#15

				add.w	#10, D2
				trap	#15

				sub.w	#70, D1
				trap	#15

				add.w	#25, D2
				trap	#15

				add.w	#30, D1
				trap	#15

				add.w	#10, D2
				trap	#15

				sub.w	#30, D1
				trap	#15

				add.w	#25, D2
				trap	#15

				add.w	#70, D1
				trap	#15

				add.w	#10, D2
				trap	#15

				sub.w	#80, D1
				trap	#15

				sub.w	#80, D2
				trap	#15

				add.w	#4, D1
				add.w	#4, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_O:
* Draw O letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				add.w	#80, D1
				trap	#15

				add.w	#80, D2
				trap	#15

				sub.w	#80, D1
				trap	#15

				sub.w	#80, D2
				trap	#15

				; Buit interior
				add.w	#10, D1
				add.w	#10, D2
				move.b	#86, D0
				trap	#15
				move.b	#85, D0
				
				add.w	#60, D1
				trap	#15
				
				add.w	#60, D2
				trap	#15
				
				sub.w	#60, D1
				trap	#15
				
				sub.w	#60, D2
				trap	#15

				sub.w	#5, D1
				sub.w	#5, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_V:
* Draw V letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				add.w	#10, D1
				trap	#15

				add.w	#30, D1
				add.w	#70, D2
				trap	#15

				add.w	#30, D1
				sub.w	#70, D2
				trap	#15

				add.w	#10, D1
				trap	#15

				sub.w	#40, D1
				add.w	#80, D2
				trap	#15

				sub.w	#40, D1
				sub.w	#80, D2
				trap	#15

				add.w	#5, D1
				add.w	#3, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_R:
* Draw R letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				sub.w	#80, D1
				trap	#15

				add.w	#80, D2
				trap	#15

				add.w	#10, D1
				trap	#15

				sub.w	#35, D2
				trap	#15

				add.w	#60, D1
				add.w	#35, D2
				trap	#15

				add.w	#10, D1
				trap	#15

				sub.w	#60, D1
				sub.w	#40, D2
				trap	#15

				add.w	#60, D1
				trap	#15

				sub.w	#40, D2
				trap	#15

				; Buit interior
				sub.w	#10, D1
				add.w	#10, D2
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				sub.w	#60, D1
				trap	#15

				add.w	#20, D2
				trap	#15

				add.w	#60, D1
				trap	#15

				sub.w	#20, D2
				trap	#15

				add.w	#5, D1
				add.w	#5, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_J:
* Draw J letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				add.w	#80, D1
				trap	#15

				add.w	#10, D2
				trap	#15

				sub.w	#25, D1
				trap	#15

				add.w	#40, D2
				trap	#15

				sub.w	#20, D1
				add.w	#30, D2
				trap	#15

				sub.w	#10, D1
				trap	#15

				sub.w	#20, D1
				sub.w	#30, D2
				trap	#15

				add.w	#10, D1
				trap	#15

				add.w	#15, D1
				add.w	#20, D2
				trap	#15

				add.w	#15, D1
				sub.w	#20, D2
				trap	#15

				sub.w	#40, D2
				trap	#15

				sub.w	#45, D1
				trap	#15

				sub.w	#10, D2
				trap	#15

				add.w	#5, D1
				add.w	#5, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_T:
* Draw T letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				add.w	#80, D1
				trap	#15

				add.w	#10, D2
				trap	#15

				sub.w	#35, D1
				trap	#15

				add.w	#70, D2
				trap	#15

				sub.w	#10, D1
				trap	#15

				sub.w	#70, D2
				trap	#15

				sub.w	#35, D1
				trap	#15

				sub.w	#10, D2
				trap	#15

				add.w	#5, D1
				add.w	#5, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_S:
* Draw S letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				sub.w	#80, D1
				trap	#15

				add.w	#45, D2
				trap	#15

				add.w	#70, D1
				trap	#15

				add.w	#25, D2
				trap	#15

				sub.w	#70, D1
				trap	#15

				add.w	#10, D2
				trap	#15

				add.w	#80, D1
				trap	#15

				sub.w	#45, D2
				trap	#15

				sub.w	#70, D1
				trap	#15

				sub.w	#25, D2
				trap	#15

				add.w	#70, D1
				trap	#15

				sub.w	#10, D2
				trap	#15

				sub.w	#5, D1
				add.w	#5, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------

* ----------------------------------------------------------
TK_K:
* Draw K letter with coordinates at D1.W and D2.W
* ----------------------------------------------------------
				move.b	#86, D0
				trap	#15
				move.b	#85, D0

				add.w	#10, D1
				trap	#15

				add.w	#30, D2
				trap	#15

				add.w	#60, D1
				sub.w	#30, D2
				trap	#15

				add.w	#10, D1
				trap	#15

				sub.w	#65, D1
				add.w	#40, D2
				trap	#15

				add.w	#65, D1
				add.w	#40, D2
				trap	#15

				sub.w	#10, D1
				trap	#15

				sub.w	#60, D1
				sub.w	#30, D2
				trap	#15

				add.w	#30, D2
				trap	#15

				sub.w	#10, D1
				trap	#15

				sub.w	#80, D2
				trap	#15

				add.w	#5, D1
				add.w	#5, D2
				move.b	#89, D0
				trap	#15

				rts
* ----------------------------------------------------------
























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
