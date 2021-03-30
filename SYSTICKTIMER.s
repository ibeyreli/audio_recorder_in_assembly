;*************************************************************** 
; TIMER.s
; Initiating systick for measuring 8kHz for sampling a sound signal 
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
STCTRL				EQU				0xE000E010;	SysTick Timer Control
STRELOAD		 	EQU				0xE000E014;	SysTick Timer Reload
STCURRENT			EQU				0xE000E018; SysTick Timer Current
	
PERIOD				EQU				0x00000011; 

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
					
					
					EXPORT 			SYSTICK


;***************************************************************
;  Subroutine section _ DELAY100 : 	a subroutine that causes
;									approximately 100 msec delay
;									upon calling
;Asked in Q1														-	Q1
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT
SYSTICK			PROC
				PUSH			{LR};
				PUSH			{R0-R2};
							
timerloop		
				LDR				R0, =STCTRL; disable systick during set up
				MOV				R1, #0;
				STR				R1, [R0];
				
				LDR				R1, =PERIOD ; 
				STR				R1, [R0, #4]; reload counter
				STR				R1, [R0, #8]; clear counter
				MOV				R1, #0x5; enable without interrupt
				STR				R1, [R0]; start counter
				
CountLoop		MOV				R2, #0x10000;
				LDR				R1, [R0];
				ANDS			R2, R2, R1;
				BNE				CountLoop;
				
;Sampling the audio signal

Sample			LDR				R1, =ADC0_PSSI ; initialize sampling
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x08 ;
				STR				R0, [R1] ;

;Polling			LDR				R1, =ADC0_RIS ; checking RIS resigter by polling
				;LDR				R0, [R1] ;
				;ANDS			R0, R0, #0x08 ;
				;BEQ				Polling ;
				
				LDR				R1, =ADC0_SSFIFO3 ; read the result in case of interrupt
				LDR				R4, [R1] ;
				
; Storing the Data
				LSR				R4, #4;
				STRB			R4, [R3], #1 ; 
				
				;MOV				R5, R7 ;
				;BL 				OutChar ;
				
				LDR				R1, =ADC0_ISC ; clearing interrupt flag
				MOV				R0, #0x8 ;
				STR				R0, [R1] ; 

; Resampling Decision Segment
				CMP				R7, #0; 
				BNE 			SampleNotDone ; 
				B				EndofHandler				
				
SampleNotDone	
				
				MOV 			R5, #70 ; 'F'
				BL 				OutChar;
				
				SUB				R7, R7, #1;
				B 				timerloop ;
				
EndofHandler					
				MOV 			R5, #72 ; 'H'
				BL 				OutChar;
				
				MOV				R1, #0;
				STR				R1, [R0]; disable systick wihle exitting the subroutine
				
				POP 			{R0-R2};
				POP				{LR};
				BX				LR;
				ENDP
				
				ALIGN
				END	