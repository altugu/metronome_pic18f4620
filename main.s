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
GLOBAL var3
GLOBAL pause
GLOBAL speed ; clr:1x, set:2x 
GLOBAL bar_length
GLOBAL bl
GLOBAL decrease_bl
GLOBAL increase_bl
GLOBAL prev_inputs
GLOBAL curr_inputs
GLOBAL changes
GLOBAL count
; Define space for the variables in RAM
PSECT udata_acs
var1:
    DS 1 
var2:
    DS 1   
var3:
    DS 1
count:
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
bl:
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
    clrf PORTB
    clrf var1
    clrf var2
    clrf var3
    clrf pause
    clrf speed
    clrf changes
    clrf bl
    clrf bar_length
    clrf decrease_bl
    clrf increase_bl
    clrf prev_inputs
    clrf curr_inputs
    clrf count
    movlw 0x07
    movwf LATA
    call one_second_busy_wait
    clrf LATA
    movlw 0x04
    movwf bar_length
    return
   
 test: ; 10 MS BUSY WAIT
    movlw 223
    movwf var2
    outer_loop:
	movlw 156
	movwf var1
	inner_loop:
	    incfsz var1 ; var1 += 1; if (var1 == 0) skip next
	    goto inner_loop
	incfsz var2 
	goto outer_loop
    return
 
 load_speed:
    btfsc speed, 0
    goto count_load_10
    goto count_load_20
    count_load_10:
	movlw 25
	movwf count
	return
    count_load_20:
	movlw 50
	movwf count
	return
event_loop: ; 
    movff bar_length, bl
    bsf LATA, 1
    while_barlength:

	bsf LATA, 0 ; RA0 <- 1
	call load_speed
	; count=20 if speed 1x, =10 if 2x
	while_count1:
	    call input_check
	    call test
	    decf count
	    bnz while_count1
	call load_speed
	btfsc LATA, 1 ; toggle RA1 if 1
	bcf LATA, 1
	bcf LATA, 0 ; RA0 <- 0
	while_count2:
	    call input_check
	    call test
	    decf count
	    bnz while_count2
	decf bl
	bnz while_barlength
    goto event_loop

metronome_routine:
    return
input_check: ; checks PORTB detect the changes     
    movff PORTB, curr_inputs ; save current inputs
    comf curr_inputs,0 ; complement current inputs
    andwf prev_inputs, 0 ; wreg <- prev & curr^
    movwf changes
    movff curr_inputs, prev_inputs
    tstfsz changes
    call record_changes
    return
    
input_check_during_pause:
    movff PORTB, curr_inputs ; save current inputs
    comf curr_inputs,0 ; complement current inputs
    andwf prev_inputs, 0 ; wreg <- prev & curr^
    movwf changes
    movff curr_inputs, prev_inputs
    tstfsz changes
    call another_record_changes
    return
    
another_record_changes:
    btfsc changes,0 
    btg pause, 0
    btfsc changes,1
    comf speed
    btfsc changes,2
    call reset_bar_length
    btfsc changes,3
    call dec_bar_length
    btfsc changes,4
    call inc_bar_length
    return
    
pause_action:
    movlw 0x04
    movwf LATA
    call test
    call input_check_during_pause
    btfsc pause, 0
    goto pause_action
    movlw 0x03
    movwf LATA
    return

record_changes:  ; checks RB<#>
    btfsc changes,0 
    btg pause, 0
    btfsc changes,1
    btg speed, 0
    btfsc changes,2
    call reset_bar_length
    btfsc changes,3
    call dec_bar_length
    btfsc changes,4
    call inc_bar_length
    btfsc pause, 0
    call pause_action
    return

reset_bar_length:
    movf bl, 0
    subwf bar_length, 1
    movlw 0x04
    cpfslt bar_length
    goto greater_or_equeal
    goto less
    less:
	subfwb bar_length, 1 ; 4 - bl
	movff bar_length, bl
	movwf bar_length
	return
    greater_or_equeal:
	clrf bl
	incf bl
	movwf bar_length
    return
dec_bar_length:
    decf bl
    decf bar_length
    return
inc_bar_length:
    incf bl
    incf bar_length
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
  return

end resetVec
