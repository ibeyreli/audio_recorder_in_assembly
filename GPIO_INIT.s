;*************************************************************** 
; GPIO_INIT.s
; GIPO initialization for EE447 Laboratory Project
; Audio Recorder and Player
; Created by Ilayda BEYRELI 2093474 & Mehmet Ali YANIKLAR 1877059
; Created at 03/01/2017 14.12
; Last Updated at 07/01/2017 12.06
; Additional Components : 
; 1. MAX9814 Microphone Amplifier with AGC and Low-Noise Microphone Bias
; 2. MCP4725 12-Bit Digital-to-Analog Converter with EEPROM Memory in SOT-23-6
; 3. PAM8302A 2.5W Filterless Class-D Mono Audio Amplifier
;***************************************************************	
;*************************************************************** 
; EQU Directives
; These directives do not allocate memory
;***************************************************************
;LABEL				DIRECTIVE		VALUE			COMMENT

;ADC Register
SYSCTL_RCGCADC		EQU 			0x400FE638 ; ADC Clock Resigter
ADC0_ACTSS			EQU				0x40038000 ; Sample Sequencer (Base Address of ADC0)
ADC0_RIS			EQU				0x40038004 ; Raw Interrupt Status
ADC0_IM				EQU				0x40038008 ; Interupt Select
ADC0_EMUX			EQU				0x40038014 ; Trigger Select
ADC0_PSSI			EQU             0x40038028 ; Initiate Sample
ADC0_SSMUX3			EQU				0x400380A0 ; Input Channel Select
ADC0_SSCTL3			EQU				0x400380A4 ; Sample Sequence Control
ADC0_SSFIFO3		EQU				0x400380A8 ; Channel 3 Status
ADC0_PP				EQU				0x40038FCA ; Sample Rate
ADC0_ISC			EQU				0x4003800C ; Interrupt Status & Clear

;General GPIO Registers
SYSCTL_RCGCGPIO 	EQU 			0x400FE608 ; GPIO Gate Control

;GPIO Registers for Port E3
GPIO_PORTE_DATA		EQU 			0x40024020 ; Access E3
GPIO_PORTE_DIR 		EQU 			0x40024400 ; Port Direction
GPIO_PORTE_AFSEL	EQU 			0x40024420 ; Alt Function enable
GPIO_PORTE_DEN 		EQU 			0x4002451C ; Digital Enable
GPIO_PORTE_AMSEL 	EQU 			0x40024528 ; Analog enable
GPIO_PORTE_PCTL 	EQU				0x4002452C ; Alternate Functions


;GPIO Registers for Port F0(SW1) & F4(SW2)
GPIO_PORTF_DATA		EQU 			0x40025044 ; Access F0 and F4 *******
GPIO_PORTF_DIR 		EQU 			0x40025400 ; Port Direction
GPIO_PORTF_AFSEL	EQU 			0x40025420 ; Alt Function enable
GPIO_PORTF_DEN 		EQU 			0x4002551C ; Digital Enable
GPIO_PORTF_AMSEL 	EQU 			0x40025528 ; Analog enable
GPIO_PORTF_PCTL 	EQU				0x4002552C ; Alternate Functions
GPIO_PORTF_PDR		EQU				0x40025514 ; GPIO Port F Pull Down Select
GPIO_PORTF_PUR		EQU				0x40025510 ; GPIO Port F Pull Up Select
GPIO_PORTF_LOCK		EQU				0x40025520 ; Lock Register
GPIO_KEY			EQU				0x4C4F434B ;
GPIO_PORTF_CMR		EQU				0x40025524 ; Commit Register
	; Interupt Control

GPIO_PORTF_IS		EQU				0x40025404;
GPIO_PORTF_IBE		EQU				0x40025408;
GPIO_PORTF_IEV		EQU				0x4002540C;
GPIO_PORTF_IM		EQU				0x40025410;
GPIO_PORTF_ICR		EQU				0x4002541C;
GPIO_PORTF_RIS		EQU				0x40025414;	

;***************************************************************
; Directives - This Data Section is part of the code
; It is in the read only section  so values cannot be changed.
;***************************************************************
;LABEL				DIRECTIVE		VALUE			COMMENT
					AREA        	routines, CODE, READONLY
					THUMB
					
					EXPORT			KEY_INIT ; 
					EXPORT 			ADC0_INIT ; 
					EXPORT			DELAY ; 
					EXPORT			DELAY100;



;***************************************************************
; Subroutine Section _ KEY_INIT : Initialization of on-board
;								  switches F0(SW1) & F4 (SW2) 
;								  to control recorder
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT	

KEY_INIT		PROC
				PUSH 			{LR}
				
				PUSH			{R0-R1};
				
				LDR				R1, =SYSCTL_RCGCGPIO ; enable clock for GPIO Port F
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x20 ; 
				STR				R0, [R1] ;				
				
				BL				DELAY ; let the clock stabilize
				
				LDR				R1, =GPIO_PORTF_LOCK ; unlocking pin F0 for enabling SW2
				LDR				R0, =GPIO_KEY
				STR				R0, [R1] ;

				LDR				R1, =GPIO_PORTF_CMR ; 
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x11 ; 
				STR				R0, [R1] ;

				LDR				R1, =GPIO_PORTF_DIR ; set F0 and F4 as input
				LDR				R0, [R1] ;
				BIC				R0, R0, #0x11 ; 
				STR				R0, [R1] ;
				
				LDR				R1, =GPIO_PORTF_AFSEL ; disable alt function 
				LDR				R0, [R1] ;
				BIC				R0, R0, #0x11 ; 
				STR				R0, [R1] ;
				
				LDR				R1, =GPIO_PORTF_DEN ; enable digital 
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x11 ; 
				STR				R0, [R1] ;
				
				LDR				R1, =GPIO_PORTF_AMSEL ; disable analog 
				LDR				R0, [R1] ;
				BIC				R0, R0, #0x11 ; 
				STR				R0, [R1] ;				

				LDR				R1, =GPIO_PORTF_PUR ; pull_up resistors
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x11 ; 
				STR				R0, [R1] ;	


				POP 			{R0-R1};

				POP 			{LR};
				BX				LR;
				ENDP;

;***************************************************************
; Subroutine Section _ ADC_INIT : Initialization of ADC0 module
;								  with related GPIO configuration
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT	
ADC0_INIT		PROC
				PUSH			{LR} ;
				PUSH			{R0-R12} ;
				
; initialting clocks for GPIO and ADC blocks

				LDR				R1, =SYSCTL_RCGCADC ; enable clock for ADC block 
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x01 ;
				STR				R0, [R1] ;
				
				BL				DELAY ; let the clock stabilize
				
				LDR				R1, =SYSCTL_RCGCGPIO ; enable clock for GPIO Port E
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x10 ; 
				STR				R0, [R1] ;				
				
				BL				DELAY ; let the clock stabilize

; GPIO Setup _ Port E3

				LDR				R1, =GPIO_PORTE_DIR ; set E3 as input
				LDR				R0, [R1] ;
				BIC				R0, R0, #0x30 ; 
				STR				R0, [R1] ;
				
				LDR				R1, =GPIO_PORTE_AFSEL ; set alt function for E3
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x08 ; 
				STR				R0, [R1] ;
				
				LDR				R1, =GPIO_PORTE_DEN ; disable digital for E3
				LDR				R0, [R1] ;
				BIC				R0, R0, #0x08 ; 
				STR				R0, [R1] ;
				
				LDR				R1, =GPIO_PORTE_AMSEL ; enable analog for E3
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x08 ; 
				STR				R0, [R1] ;				

; ADC Setup _ ADC0

				LDR				R1, =ADC0_ACTSS ; disable sequencer during setup
				LDR				R0, [R1] ;
				BIC				R0, R0, #0x08 ; clear bit for SS3
				STR				R0, [R1] ;
				
				LDR				R1, =ADC0_EMUX ; clearing bits 12:15 to select software
				LDR				R0, [R1] ;
				BIC				R0, R0, #0xF000 ; 
				STR				R0, [R1] ;

				LDR				R1, =ADC0_SSMUX3 ; clearing bits 0:3 to select AIN0
				LDR				R0, [R1];
				BIC				R0, R0, #0x000F; 
				STR				R0, [R1];

				LDR				R1, =ADC0_SSCTL3 ; disabling interupt and ending the sequence 
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x06 ; IE0 = 1, END0 = 1 
				STR				R0, [R1] ;

				LDR				R1, =ADC0_PP ; sampling rate is set to be 125 samples for second
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x07 ; 
				STR				R0, [R1] ;
				
				LDR				R1, =ADC0_ACTSS ; enable sequencer
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x08 ; set bit for SS3
				STR				R0, [R1] ;

				POP			{R0-R12} ;

				POP 			{LR}
				BX				LR
				ENDP
					
;***************************************************************
;  Subroutine section _ DELAY
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT
DELAY			PROC
				PUSH			{LR};
				
				PUSH			{R0-R12};
				LDR 			R4,=520; decrement 
decrease		SUBS			R4,R4,#1;
				BNE				decrease;
				POP				{R0-R12};
				
				POP				{LR};
				BX 				LR;
				ENDP

;***************************************************************
;  Subroutine section _ DELAY100: a subroutine that causes 
;								approximately 100 msec delay
;								upon calling
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT
DELAY100		PROC
				PUSH			{LR};
				
				PUSH			{R0-R12};
				LDR 			R4,=6000; decrement from approximately 100msec
dec100			SUBS			R4,R4,#1;
				BNE				dec100;
				POP				{R0-R12};
				
				POP				{LR};
				BX 				LR;
				ENDP
					

				ALIGN           ; make sure the end of this section is aligned
				END             ; end of file