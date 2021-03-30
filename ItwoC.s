;*************************************************************** 
; ItwoC.s
; Initiating I2C communication protocol
; in EE447 Laboratory Project Audio Recorder and Player
; Created by Ilayda BEYRELI 2093474 & Mehmet Ali YANIKLAR 1877059
; Created at 07/01/2017 12.06
; Last Updated at 20/01/2017 14.00
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

RCGCI2C0            EQU 		    0x400FE620 ;
GPIO_PORTB_RCGCGPIO EQU 			0x400FE608 ;
GPIO_PORTB_AFSEL    EQU   			0x40005420 ;
GPIO_PORTB_DIR      EQU  			0x40005400 ;
GPIO_PORTB_DEN      EQU 			0x4000551C ;
GPIO_PORTB_GPIOODR  EQU    			0x4000550C ;
GPIO_PORTB_GPIOPUR	EQU				0x40005510 ; 
GPIO_PORTB_GPIOPCTL EQU    			0x4000552C ;
GPIO_PORTB_LOCK		EQU				0x40005520 ;
KEY					EQU				0x4C4F434B ;
GPIO_PORTB_CMT		EQU				0x40005524 ;	
	
I2C0_MCR    		EQU 			0x40020020 ;
I2C0_MTPR    		EQU  			0x4002000C ; 
I2C0_MSA     		EQU  			0x40020000 ;
I2C0_MDR     		EQU				0x40020008 ; I2C Master Data
I2C0_MCS			EQU 			0x40020004 ; I2C Master Control/Status
	

;ADC Register
SYSCTL_RCGCADC		EQU 			0x400FE638 ; ADC Clock Resigter
ADC1_ACTSS			EQU				0x40039000 ; Sample Sequencer (Base Address of ADC0)
ADC1_RIS			EQU				0x40039004 ; Raw Interrupt Status
ADC1_IM				EQU				0x40039008 ; Interupt Select
ADC1_EMUX			EQU				0x40039014 ; Trigger Select
ADC1_PSSI			EQU             0x40039028 ; Initiate Sample
ADC1_SSMUX3			EQU				0x400390A0 ; Input Channel Select
ADC1_SSCTL3			EQU				0x400390A4 ; Sample Sequence Control
ADC1_SSFIFO3		EQU				0x400390A8 ; Channel 3 Status
ADC1_PP				EQU				0x40039FCA ; Sample Rate
ADC1_ISC			EQU				0x4003900C ; Interrupt Status & Clear
	
;General GPIO Registers
SYSCTL_RCGCGPIO 	EQU 			0x400FE608 ; GPIO Gate Control

;GPIO Registers for Port E3
GPIO_PORTE_DATA		EQU 			0x40024020 ; Access E3
GPIO_PORTE_DIR 		EQU 			0x40024400 ; Port Direction
GPIO_PORTE_AFSEL	EQU 			0x40024420 ; Alt Function enable
GPIO_PORTE_DEN 		EQU 			0x4002451C ; Digital Enable
GPIO_PORTE_AMSEL 	EQU 			0x40024528 ; Analog enable
GPIO_PORTE_PCTL 	EQU				0x4002452C ; Alternate Functions



MEMORY				EQU				0x20000400 ; selected for avoiding stack interference	
	
;***************************************************************
; Directives - This Data Section is part of the code
; It is in the read only section  so values cannot be changed.
;***************************************************************
;LABEL				DIRECTIVE		VALUE			COMMENT
					AREA        	routines, CODE, READONLY
					THUMB
					EXTERN 			OutChar ;
					EXTERN			DELAY ; 
					EXTERN			DELAY100 ; 
					
					
					EXPORT 			I2C0_INIT ; 
					EXPORT			I2C0_SEND ; 
					EXPORT			ADC1_INIT ;
					
;***************************************************************
; Subroutine Section _ I2C0_INIT : Initialtig I2C communication protocl ports
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT	    	
I2C0_INIT      	PROC
				PUSH			{LR} ;
				
				LDR   			R1,=RCGCI2C0 ;
				LDR   			R0,[R1] ;
				ORR   			R0,R0,#0x01  ;set bit 1 for mode 0
				STR   			R0,[R1] ;
				
				NOP ;
				NOP ;
				NOP ;
				
				LDR   			R1,=SYSCTL_RCGCGPIO ;
				LDR 			R0,[R1] ;
				ORR   			R0,R0,#0x02 ;
				STR   			R0,[R1]      ;port B activation
				
				NOP ;
				NOP ;
				NOP	;
				
				LDR				R1, =GPIO_PORTB_LOCK ;
				LDR				R0, =KEY ;
				STR				R0, [R1] ;
				
				LDR				R1, =GPIO_PORTB_CMT ;
				MOV				R0, #0x0C ;
				STR				R0, [R1] ;
				
				LDR   			R1,=GPIO_PORTB_AFSEL ;
				LDR   			R0,[R1] ;
				ORR   			R0,R0,#0x0C ;
				STR   			R0,[R1] ;
				
				LDR   			R1,=GPIO_PORTB_GPIOODR ; 
				LDR   			R0,[R1] ;
				ORR   			R0,R0,#0x08 ;
				STR   			R0,[R1] ;
				
				LDR				R1, =GPIO_PORTB_DIR ; set direction of B2 & B3
				LDR 			R0, [R1] ;
				ORR				R0, R0, #0x0C ; set bit3 for output
				STR 			R0, [R1] ;
				
				LDR 			R1, =GPIO_PORTB_DEN ; disable port digital
				LDR 			R0, [R1] ;
				ORR 			R0, R0, #0x0C
				STR 			R0, [R1] ;
				
				LDR  			R1,=GPIO_PORTB_GPIOPCTL ;
				LDR  			R0,[R1] ;
				MOV  			R0,#0x00003300
				STR  			R0,[R1] ;
				
				LDR				R1, =GPIO_PORTB_GPIOODR ; 
				LDR  			R0,[R1] ;
				ORR				R0, #0x8 ;
				STR				R0, [R1] ;

				
				LDR  			R1,=I2C0_MCR  ;initialize the i2c master
				MOV32 			R0,#0x00000010
				STR  			R0,[R1] ;
				
				LDR  			R1,=I2C0_MTPR ;clock periods
				MOV32 			R0,#9 ;
				STR  			R0,[R1] ;
				
				LDR 			R1,=I2C0_MSA ; master slave address
				MOV32 			R0,#0x000000C4 ;1 bit left for data
				STR 			R0,[R1] ; 
				POP {LR} ; 
				BX LR ;
				ENDP ; 

;***************************************************************
; Subroutine Section _ I2C0_SEND : Sending desired data stored
;							in the memory starting from memory 
;							location in R3, to audio amplifier
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT	   
I2C0_SEND		PROC
				PUSH  			{LR} ;
				PUSH			{R0-R12} ;
				
				MOV				R6, #1 ;  
				MOV 			R9, #0x64 ;
				
				;BL 				ADC1_INIT ;
				
				;LDR				R1, =ADC1_PSSI ; initialize sampling
				;LDR				R0, [R1] ;
				;ORR				R0, R0, #0x08 ;
				;STR				R0, [R1] ;
				
				
i2csending		MOV				R4, #0 ; data to be sent holder
				
;ADCPolling		LDR				R1, =ADC1_RIS ; checking RIS resigter by polling
				;LDR				R0, [R1] ;
				;ANDS			R0, R0, #0x08 ;
				;BEQ				ADCPolling ;
						
				;LDR				R1, =ADC1_SSFIFO3 ; read the result in case of interrupt
				;LDR				R8, [R1] ;
				;SDIV			R6, R8, R9 ;
				;ADD				R6, R6, #1 ;
				
				;LDR				R1, =ADC1_ISC ; clearing interrupt flag
				;MOV				R0, #0x8 ;
				;STR				R0, [R1] ; 
				
				LDRB			R4, [R3] ; byte stored in adress R3 is loaded to R4
				ADD				R3, R3, R6 ;
				
				LDR 			R1, =I2C0_MDR ;
				AND				R0, R4, #0xF0 ; msb of R4 (7:4) is loaded to R0 as 0x00X 
				LSR				R0, R0, #4 ;
				STR				R0,[R1] ;
				
				
				LDR				R2, =I2C0_MCS ;
				MOV				R0, #0x03 ; START/RUN
				STR				R0, [R2] ;

				LDR				R2, =I2C0_MCS ;
				MOV				R0, #0x01 ; RUN
				STR				R0, [R2] ;
				

i2cbusy1		LDR				R0, [R2] ;
				ANDS			R0, #0x01 ;			
				BNE 			i2cbusy1 ;

				AND				R0, R4, #0x0F ; lsb of R4 (7:4) is loaded to R0 as 0xX00 
				LSL				R0, R0, #8 ;
				STR				R0,[R1] ;

				LDR				R2, =I2C0_MCS ;
				MOV				R0, #0x01 ; RUN
				STR				R0, [R2] ;

i2cbusy2		LDR				R0, [R2] ;
				ANDS			R0, #0x01 ;			
				BNE 			i2cbusy2 ;
				
				LDR				R2, =I2C0_MCS ;
				MOV				R0, #0x4 ; STOP 
				STR				R0, [R2] ;
				
				CMP				R7, #0 ;
				SUBNE			R7,R7, R6 ;
				
				BNE				i2csending ;
				
				POP				{R0-R12} ;
				POP				{LR} ;
				BX 				LR ;
				ENDP ;

;***************************************************************
; Subroutine Section _ ADC_INIT : Initialization of ADC0 module
;								  with related GPIO configuration
;***************************************************************
;LABEL			DIRECTIVE		VALUE			COMMENT	
ADC1_INIT		PROC
				PUSH			{LR} ;
				PUSH			{R0-R12} ;
				
; initialting clocks for GPIO and ADC blocks

				LDR				R1, =SYSCTL_RCGCADC ; enable clock for ADC block 
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x02 ;
				STR				R0, [R1] ;
				
				BL				DELAY ; let the clock stabilize
				
				LDR				R1, =SYSCTL_RCGCGPIO ; enable clock for GPIO Port E
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x10 ; 
				STR				R0, [R1] ;				
				
				BL				DELAY100 ; let the clock stabilize

; GPIO Setup _ Port E3

				LDR				R1, =GPIO_PORTE_DIR ; set E4 as input
				LDR				R0, [R1] ;
				BIC				R0, R0, #0xFF ; 
				STR				R0, [R1] ;
				
				LDR				R1, =GPIO_PORTE_AFSEL ; set alt function for E4
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x10 ; 
				STR				R0, [R1] ;
				
				LDR				R1, =GPIO_PORTE_DEN ; disable digital for E4
				LDR				R0, [R1] ;
				BIC				R0, R0, #0x10 ; 
				STR				R0, [R1] ;
				
				LDR				R1, =GPIO_PORTE_AMSEL ; enable analog for E4
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x10 ; 
				STR				R0, [R1] ;				

; ADC Setup _ ADC1

				LDR				R1, =ADC1_ACTSS ; disable sequencer during setup
				LDR				R0, [R1] ;
				BIC				R0, R0, #0x08 ; clear bit for SS3
				STR				R0, [R1] ;
				
				LDR				R1, =ADC1_EMUX ; clearing bits 12:15 to select software
				LDR				R0, [R1] ;
				BIC				R0, R0, #0xF000 ; 
				STR				R0, [R1] ;

				LDR				R1, =ADC1_SSMUX3 ; writing bits 0:3 to select AIN9
				LDR				R0, [R1];
				BIC				R0, R0, #0x000F;
				ORR				R0, R0, #0x9 ;
				STR				R0, [R1];

				LDR				R1, =ADC1_SSCTL3 ; disabling interupt and ending the sequence 
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x06 ; IE0 = 1, END0 = 1 
				STR				R0, [R1] ;

				LDR				R1, =ADC1_PP ; sampling rate is set to be 125 samples for second
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x01 ; 
				STR				R0, [R1] ;
				
				LDR				R1, =ADC1_ACTSS ; enable sequencer
				LDR				R0, [R1] ;
				ORR				R0, R0, #0x08 ; set bit for SS3
				STR				R0, [R1] ;

				POP			{R0-R12} ;

				POP 			{LR}
				BX				LR
				ENDP

				ALIGN ;
				END 