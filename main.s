PROCESSOR    18F4620

#include <xc.inc>

; CONFIGURATION (DO NOT EDIT)
CONFIG OSC = HSPLL      ; Oscillator Selection bits (HS oscillator, PLL enabled (Clock Frequency = 4 x FOSC1))
CONFIG FCMEN = OFF      ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
CONFIG IESO = OFF       ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)
; CONFIG2L
CONFIG PWRT = ON        ; Power-up Timer Enable bit (PWRT enabled)
CONFIG BOREN = OFF      ; Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software)
CONFIG BORV = 3         ; Brown Out Reset Voltage bits (Minimum setting)
; CONFIG2H
CONFIG WDT = OFF        ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
; CONFIG3H
CONFIG PBADEN = OFF     ; PORTB A/D Enable bit (PORTB<4:0> pins are configured as digital I/O on Reset)
CONFIG LPT1OSC = OFF    ; Low-Power Timer1 Oscillator Enable bit (Timer1 configured for higher power operation)
CONFIG MCLRE = ON       ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)
; CONFIG4L
CONFIG LVP = OFF        ; Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
CONFIG XINST = OFF      ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))

; GLOBAL SYMBOLS
; You need to add your variables here if you want to debug them.
GLOBAL var1
GLOBAL var2
GLOBAL is_paused
GLOBAL reset_bl
GLOBAL decrease_bl
GLOBAL increase_bl
GLOBAL prev_inputs
GLOBAL curr_inputs
GLOBAL changes
; Define space for the variables in RAM
PSECT udata_acs
var1:
    DS 1 
var2:
    DS 1   
var3:
    DS 1
is_paused:
    DS 1
reset_bl:
    DS 1
decrease_bl:
    DS 1
increase_bl:
    DS 1
prev_inputs:
    DS 1
curr_inputs:
    DS 1
changes:
    DS 1
    
    
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto       main

PSECT CODE
main:
  clrf TRISA ; make PORTA an output
  setf TRISB ; make PORTB an input
  movlw 0x7
  movwf PORTA
  movlw 0x00
  movwf prev_inputs
  movlw 0xff
  movwf LATB
  call input_check
  nop
  
  return
  
metronome_check:
    return
  
ms_wait: ;takes halfbar_duration as parameter 
    ; check halfbar_duration
    ;
    return
    
one_second_busy_wait:

  
  movlw 17
  movwf var2
  clrf var1 ; var1 = 0
  movlw 250
  movwf var3 
  outer_loop_start:
    mid_loop_start:
	loop_start:
	  incfsz var1 ; var1 += 1; if (var1 == 0) skip next
	  goto loop_start
      decf var2
      bnz mid_loop_start
    incfsz var3 ; var1 += 1; if (var1 == 0) skip next
    goto outer_loop_start
  ; 8 bit
  ; var1 = 255
  ; var1 = 0
  decf LATA
  return
    
input_check: ; checks the changes
    movff LATB, curr_inputs ; save current inputs
    comf curr_inputs ; complement current inputs 
    setf WREG 
    andwf prev_inputs,0  ; load prev inputs to wreg
    andwf curr_inputs, 0 ; prev_inputs & curr_inputs^  -> wreg holds 1 to 0 changes
    movwf changes ;
    tstfsz changes
    call record_changes
    return
    
record_changes:  ; checks RB<#>
    btfsc changes,0 
    nop
    btfsc changes,1
    nop
    btfsc changes,2
    nop
    btfsc changes,3
    nop
    btfsc changes,4
    nop
    
    return
 
end resetVec
