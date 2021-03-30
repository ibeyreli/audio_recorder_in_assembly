;*************************************************************** 
; TIMER.s
; Initiating Timer 0 for measuring 8kHz for sampling a sound signal 
; in EE447 Laboratory Project Audio Recorder and Player
; Created by Ilayda BEYRELI 2093474 & Mehmet Ali YANIKLAR 1877059
; Created at 07/01/2017 12.06
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

;Nested Vector Interrupt Controller registers
NVIC_EN0_INT19		EQU 0x00080000 ; Interrupt 19 enable
NVIC_EN0			EQU 0xE000E100 ; IRQ 0 to 31 Set Enable Register
NVIC_PRI4			EQU 0xE000E410 ; IRQ 16 to 19 Priority Register

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

; 16/32 Timer Registers
TIMER0_CFG			EQU 			0x40030000
TIMER0_TAMR			EQU 			0x40030004
TIMER0_CTL			EQU 			0x4003000C
TIMER0_IMR			EQU 			0x40030018
TIMER0_RIS			EQU 			0x4003001C ; Timer Interrupt Status
TIMER0_ICR			EQU 			0x40030024 ; Timer Interrupt Clear
TIMER0_TAILR		EQU 			0x40030028 ; Timer interval
TIMER0_TAPR			EQU 			0x40030038 ; Prescaler
TIMER0_TAR			EQU				0x40030048 ; Timer register
	
;System Registers
SYSCTL_RCGCGPIO 	EQU 			0x400FE608 ; GPIO Gate Control
SYSCTL_RCGCTIMER 	EQU 			0x400FE604 ; GPTM Gate Control

PERIOD				EQU 			0x0000003 ; 8kHz ;
; Starting address memory used for data storage
MEMORY				EQU				0x20000400 ; selected for avoiding stack interference

;***************************************************************
; Directives - This Data Section is part of the code
; It is in the read only section  so values cannot be changed.
;***************************************************************
;LABEL				DIRECTIVE		VALUE			COMMENT
					AREA        	routines, CODE, READONLY
					THUMB
					EXTERN 			OutChar ;
					EXTERN			ADC0_INIT ; 
					EXTERN			DELAY ; 20msec
					EXTERN			DELAY100 ; 100msec
					
					
					EXPORT 			Custom_Timer0A_Handler
					EXPORT			TIMER ; 

;***************************************************************
; Subroutine Section _ TIMER : Initialtig TIMER0
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT	
TIMER			PROC
				PUSH 			{LR} ;
				
				
				LDR 			R1, =SYSCTL_RCGCTIMER ; Start Timer0
				LDR 			R2, [R1] ;
				ORR 			R2, R2, #0x01 ;
				STR 			R2, [R1] ;
				
				NOP ; allow clock to settle
				NOP
				NOP
				NOP
				NOP
				NOP
			
				MOV 			R5, #52; '4'
				BL 				OutChar; 
			
				LDR 			R1, =TIMER0_CTL ; disable timer during setup LDR R2, [R1]
				BIC 			R2, R2, #0x01
				STR				R2, [R1]
				
				MOV 			R5, #0x39;
				BL 				OutChar; 
				
				LDR				R1, =TIMER0_CFG ; set 32 bit mode
				MOV 			R2, #0x00 ;
				STR 			R2, [R1]
				
				LDR 			R1, =TIMER0_TAMR
				MOV				R2, #0x02 ; set to periodic, count down
				STR				R2, [R1]
				
				LDR				R1, =TIMER0_TAILR ; initialize match clocks
				LDR 			R2, =PERIOD ;
				STR 			R2, [R1]
								
				LDR 			R1, =TIMER0_IMR ; enable timeout interrupt
				MOV 			R2, #0x01
				STR 			R2, [R1]
; Configure interrupt priorities
; Timer0A is interrupt #19.
; Interrupts 16-19 are handled by NVIC register PRI4.
; Interrupt 19 is controlled by bits 31:29 of PRI4.
; set NVIC interrupt 19 to priority 2
				LDR R1, =NVIC_PRI4
				LDR R2, [R1]
				AND R2, R2, #0x00FFFFFF ; clear interrupt 19 priority
				ORR R2, R2, #0x40000000 ; set interrupt 19 priority to 2
				STR R2, [R1]
; NVIC has to be enabled
; Interrupts 0-31 are handled by NVIC register EN0
; Interrupt 19 is controlled by bit 19
; enable interrupt 19 in NVIC
				LDR R1, =NVIC_EN0
				MOVT R2, #0x08 ; set bit 19 to enable interrupt 19
				STR R2, [R1]
; Enable timer
				LDR R1, =TIMER0_CTL
				LDR R2, [R1]
				ORR R2, R2, #0x03 ; set bit0 to enable
				STR R2, [R1] ; and bit 1 to stall on debug
			
				MOV 			R5, #0x40; '@'
				BL 				OutChar; 
			
				POP				{LR} ;
				BX 				LR ;
				ENDP
					
;***************************************************************
; Subroutine Section _ Custom_Timer0A_Handler : Handler subroutine
; 						for Timer 0A. The aim is to create 125 ns 
;  						period for sampling the sound signal at 8kHZ.
; 						Choosing R7 to count the numbers (24x10^6)
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT	
Custom_Timer0A_Handler			PROC
				PUSH 			{LR} ;
				
				MOV 			R5, #71 ; 'G'
				BL 				OutChar;
				
; Sampling the audio signal

Sample			LDR				R1, =ADC0_PSSI ; initialize sampling
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x08 ;
				STR				R0, [R1] ;

Polling			LDR				R1, =ADC0_RIS ; checking RIS resigter by polling
				LDR				R0, [R1] ;
				ANDS			R0, R0, #0x08 ;
				BEQ				Polling ;
				
				LDR				R1, =ADC0_SSFIFO3 ; read the result in case of interrupt
				LDR				R4, [R1] ;
				
; Storing the Data
				LSR				R4, #4;
				STRB			R4, [R3], #1 ; 
				
				LDR				R1, =ADC0_ISC ; clearing interrupt flag
				MOV				R0, #0x8 ;
				STR				R0, [R1] ; 


; Resampling Decision Segment
				CMP				R7, #0; 
				BNE 			SampleNotDone ; 
				
SampleDone  	LDR 			R1, =TIMER0_CTL ; disable timer  
				LDR 			R2, [R1]
				BIC 			R2, R2, #0x01
				STR				R2, [R1];
				
				MOV 			R5, #69 ; 'E'
				BL 				OutChar;
				
				B				EndofHandler
								
				
SampleNotDone	
				SUB				R7, R7, #1;
				
				;MOV				R5, R7;
				;BL OutChar
				
				LDR 			R0, =TIMER0_TAILR ;
				LDR				R1, =PERIOD ;
				STR 			R1, [R0] ;

EndofHandler					
				LDR 			R0, =TIMER0_ICR; clearing the time out interrupt flag
				LDR 			R1, [R0];
				ORR 			R1, #0x01;
				STR 			R1, [R0];
				
				MOV 			R5, #70 ; 'F'
				BL 				OutChar;

				POP				{LR} ;
				BX 				LR ;
				ENDP
					
				ALIGN
				END