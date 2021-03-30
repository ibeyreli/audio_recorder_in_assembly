;*************************************************************** 
; SYSCLOCK.s
; Setting the System Clock as PLL for EE447 Laboratory Project
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
SYSCTLR_RCC			EQU 			0x400FE060 ; Run Mode Clock Configuration
SYSCTLR_RIS			EQU				0x400FE050 ; Raw Interup Status, bit 6 PLL Lock Raw Interupt Status
PLLFREQ0			EQU				0x400FE160 ; PLL Frequency 0 19:10 MFRAC - 9:0 MINT
PLLFREQ1			EQU				0x400FE164 ; 12:8 Q - 4:0 N
PLLSTAT				EQU				0x400FE168 ; PLL Status
	
;***************************************************************
; Directives - This Data Section is part of the code
; It is in the read only section  so values cannot be changed.
;***************************************************************
;LABEL				DIRECTIVE		VALUE			COMMENT
					AREA        	routines, CODE, READONLY
					THUMB
					EXTERN OutChar ;
					EXPORT			PLLClock ; 

;***************************************************************
; Subroutine Section _ PLLClock : Setting the system clock as PLL at 20MHz
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT	
PLLClock		PROC
				PUSH 			{LR} ;
				PUSH			{R0-R1};
				
				LDR				R1, =SYSCTLR_RCC ;
				LDR				R0, [R1] ;
				ORR				R0, #0x800 ; set BYPASS bit (11)
				BIC				R0, #0x400000 ; clear USESYS bit (22)
				LDR				R0, [R1] ;
				

				BIC				R0, #0x20 ; clear bit 5 for PIOSC	
				ORR				R0, #0x10 ; set bit 4 for PIOSC
				LDR				R0, [R1] ;
				
				BIC				R0, #0x1C0 ; set XTAL to 0x18
				ORR				R0, #0x600 ; 
				LDR				R0, [R1] ;
				
				BIC				R0, #0x2000 ; clearing PWRDN bit (13)
				LDR				R0, [R1] ;
				
; Setting system divider 20 MHz and setting USESYS bit
				
				BIC				R0, #0x3000000 ; 
				ORR				R0, #0x4C00000 ; 
				LDR				R0, [R1] ;
				
				NOP ; 
				NOP ;
				NOP ;
				NOP ;
				NOP ;
				NOP ; 
			
;; checking locking status of PLL

;PLLLockPoll		LDR 			R1, =SYSCTLR_RIS ; 
				;LDR				R0, [R1] ;
				;ANDS			R0, #0x20 ;
;; testing				
				;MOV 			R5, #54;
				;BL 				OutChar; 				

				;BEQ				PLLLockPoll ; 
				
; enabling the use of PLL by clearing the bypass bit

				LDR				R1, =SYSCTLR_RCC ;
				LDR				R0, [R1] ;
				BIC				R0, #0x800 ; clear BYPASS bit (11)
				
; testing the Q & N values for PLL				
				;LDR				R1, =PLLFREQ1;
				;LDR				R0, [R1] ;
				;MOV				R5, R0
				;BL OutChar
				
				POP				{R0-R1};
				POP 			{LR} ;
				BX				LR ; 
				ENDP
				

				

				ALIGN           ; make sure the end of this section is aligned
				END             ; end of file