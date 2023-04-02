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
GLOBAL pause
GLOBAL speed ; clr:1x, set:2x 
GLOBAL bar_length
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
pause:
    DS 1
bar_length:
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
speed:
    DS 1
    
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto       main

PSECT CODE
main:
  clrf TRISA ; make PORTA an output
  setf TRISB ; make PORTB an input
  call initialization
  call event_loop
  return


initialization:
    clrf LATA
    clrf LATB
    call one_second_busy_wait
    movlw 0x04
    movwf bar_length
    subwf LATA, 1
    return
    
  
event_loop: ; while(true) { read inputs, function the metronome }
    call input_check
    call metronome_routine
    goto event_loop

metronome_routine:
    return
input_check: ; checks PORTB detect the changes     
    movff LATB, curr_inputs ; save current inputs
    comf curr_inputs,0 ; complement current inputs
    andwf prev_inputs, 0 ; wreg <- prev & curr^
    movwf changes
    movff curr_inputs, prev_inputs
    tstfsz changes
    call record_changes
    return

    
record_changes:  ; checks RB<#>
    btfsc changes,0 
    comf pause
    btfsc changes,1
    comf speed
    btfsc changes,2
    nop
    btfsc changes,3
    nop
    btfsc changes,4
    nop
    return

one_second_busy_wait:
  movlw 17
  movwf var2
  clrf var1 ; var1 = 0
  movlw 250
  movwf var3 
  movlw 0x07
  movwf LATA
  outer_loop_start:
    mid_loop_start:
	loop_start:
	  incfsz var1 ; var1 += 1; if (var1 == 0) skip next
	  goto loop_start
      decf var2
      bnz mid_loop_start
    incfsz var3 ; var1 += 1; if (var1 == 0) skip next
    goto outer_loop_start
  return

end resetVec
