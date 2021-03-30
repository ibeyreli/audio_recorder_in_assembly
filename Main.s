;*************************************************************** 
; Main.s
; Includes the main code section for EE447 Laboratory Project
; Audio Recorder and Player
; Created by Ilayda BEYRELI 2093474 & Mehmet Ali YANIKLAR 1877059
; Created at 03/01/2017 13.26
; Last Updated at 07/01/2017 12.06
; Additional Components : 
; 1. MAX9814 Microphone Amplifier with AGC and Low-Noise Microphone Bias
; 2. MCP4725 12-Bit Digital-to-Analog Converter with EEPROM Memory in SOT-23-6
; 3. PAM8302A 2.5W Filterless Class-D Mono Audio Amplifier
; Added Files : 
; InChar.s, OutChar.s, OutStr.s, Startup.s, GPIO_INIT.s 
;***************************************************************	
;*************************************************************** 
; EQU Directives
; These directives do not allocate memory
;***************************************************************
;LABEL				DIRECTIVE		VALUE			COMMENT

;GPIO Registers for Port F0(SW1) & F4(SW2)
GPIO_PORTF_DATA		EQU 			0x40025044 ; Access F0 and F4 *******
	
; Starting address memory used for data storage
MEMORY				EQU				0x20000400 ; selected for avoiding stack interference

TIMER0_CTL			EQU 			0x4003000C

;***************************************************************
; Directives - This Data Section is part of the code
; It is in the read only section  so values cannot be changed.
;***************************************************************
;LABEL				DIRECTIVE		VALUE			COMMENT
					AREA        	sdata, DATA, READONLY
					THUMB
;***************************************************************
; Program section					      
;***************************************************************
;LABEL				DIRECTIVE		VALUE			COMMENT
					AREA    		main, READONLY, CODE
					THUMB
					EXTERN			OutStr	; Reference external subroutine	
					EXTERN			InChar	;
					EXTERN			OutChar	;
						
					EXTERN			PLLClock ; 
					EXTERN			RECORD ;
						
					EXTERN			ADC0_INIT ; Analog to Digital Converter subroutine
					EXTERN 			KEY_INIT ; switch input enabling subroutine
					EXTERN			DELAY100  ;
					EXTERN 			I2C0_INIT ; 
					EXTERN			I2C0_SEND ; 
			
						
					EXPORT  		__main	; Make available
						
; Starting Main Program
;*****************************************************************
__main	
start				NOP;
					
					BL PLLClock ;

					BL KEY_INIT;
					
					MOV 			R5, #90;
					BL 				OutChar; 				
										
roundrobinstart 	LDR  			R1, =GPIO_PORTF_DATA ;

SwitchPoll			LDR				R0,[R1] ;
													
					CMP				R0, #0x11 ; 
					BEQ				SwitchPoll ; 

; pressing a switch breaks the loop		
					
					BL				DELAY100 ; 
					LDR				R2,[R1];
				
					CMP				R0, R2;
					BNE 			SwitchPoll ;
					
					CMP				R0, #0x1 ;
					BEQ 			SW1 ; 
					BNE				SW2 ; 

; F4 is cleared, SW1 is pressed	 ------  RECORD				
SW1					
	;test branches
					MOV 			R5, #80 ; P 
					BL 				OutChar;
	; actual operation branches		
					MOV32			R7, #24000 ; 
					LDR				R3, =MEMORY ; 
					
					BL 				ADC0_INIT ;
					
					;MOV 			R5, #83 ; S 
					;L 				OutChar
					
					BL				RECORD; 
					
;test sample loading for I2C 

;test_loop			MOV				R0, #0xFF ;
					;STRB			R0, [R3], #1 ;
					;SUBS			R7, R7, #1 ;
					;BNE				test_loop ;
					
					;MOV 			R5, R3 ;  
					;BL 				OutChar
					
					B				roundrobin ; 
					
; F0 is cleared, SW2 is pressed  ------- PLAY		
SW2 
	; test branches
					MOV 			R5, #50 ; 2
					BL 				OutChar;

	; actual operation branches

					MOV32			R7, #24000 ; 
					LDR				R3, =MEMORY ;
					
					
					BL 				I2C0_INIT ;
					
					MOV 			R5, #54 ; 6
					BL 				OutChar;					
					
					BL				I2C0_SEND ;
					
					MOV 			R5, #55 ; 7
					BL 				OutChar;

;RecordPoll
					
					B				roundrobin ;					
					

roundrobin			B				roundrobinstart ; 

;***************************************************************
; End of the program  section
;***************************************************************
;LABEL     			DIRECTIVE       VALUE                           COMMENT
					ALIGN
					END