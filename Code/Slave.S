; SPI SLAVE MODULE

#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

; R18 - Data dari SPI
; R19 - Ketinggian air
; R20 - Flag data baru

main:
    RCALL UART_Init              ; Inisialisasi UART
    RCALL Send_Welcome_Message   ; Kirim pesan sambutan
    RCALL SPI_Slave_Init         ; Inisialisasi SPI slave
   
slave_loop:
    RCALL SPI_Receive            ; Terima data SPI
    RCALL Process_Data           ; Proses data
    RJMP slave_loop              ; Ulangi loop

; Inisialisasi SPI sebagai Slave
SPI_Slave_Init:
    LDI R16, (1<<4)              ; PB4 sebagai output
    OUT DDRB, R16

    LDI R16, (1<<SPE)            ; Aktifkan SPI
    OUT SPCR, R16

    IN R16, SPSR                 ; Baca status
    IN R16, SPDR                 ; Baca data awal

    RET

; Terima data dari SPI Master
SPI_Receive:
    CLR R20                      ; Reset flag data baru

    IN R16, SPSR                 ; Cek status SPI
    SBRS R16, SPIF               ; Kalau belum ada data
    RJMP SPI_Receive_Exit        ; Keluar

    IN R18, SPDR                 ; Ambil data

    LDI R20, 1                   ; Set flag data baru

SPI_Receive_Exit:
    RET

; Delay dalam milidetik (R16 = jumlah ms)
Delay_ms:
    PUSH R16
    PUSH R17

delay_ms_loop:
    LDI R17, 200
delay_inner_loop:
    DEC R17
    BRNE delay_inner_loop

    DEC R16
    BRNE delay_ms_loop

    POP R17
    POP R16
    RET

; Delay singkat (mikrodetik)
Delay_Short:
    LDI R16, 50
delay_short_loop:
    DEC R16
    BRNE delay_short_loop
    RET

; UART COMMUNICATION MODULE

; Konfigurasi UART
UART_Init:
    LDI R16, 103
    STS UBRR0L, R16
    CLR R16
    STS UBRR0H, R16
    
    LDI R16, (1<<TXEN0)
    STS UCSR0B, R16
    
    LDI R16, (1<<UCSZ01) | (1<<UCSZ00)
    STS UCSR0C, R16
    
    RET

Send_Welcome_Message:
    LDI ZL, lo8(welcome_msg)
    LDI ZH, hi8(welcome_msg)
    
send_msg_loop:
    LPM R16, Z+
    CPI R16, 0
    BREQ send_msg_done
    
    RCALL Send_Char
    RJMP send_msg_loop
    
send_msg_done:
    RET

; Update Terminal
Process_Data:
    CPI R20, 1
    BRNE Process_Data_Exit
    
    MOV R19, R18
    
    RCALL Update_Terminal_Display
    
Process_Data_Exit:
    RET

; Update data water level
Update_Terminal_Display:
    LDI ZL, lo8(water_level_msg)
    LDI ZH, hi8(water_level_msg)
    
process_msg_loop:
    LPM R16, Z+
    CPI R16, 0
    BREQ send_water_level
    
    RCALL Send_Char
    RJMP process_msg_loop
    
send_water_level:
    MOV R16, R19
    RCALL Send_Decimal_Value
    
    RCALL Send_Status_Message
    
    LDI R16, 13
    RCALL Send_Char
    LDI R16, 10
    RCALL Send_Char
    
    RET

; Menampilkan indikator water level
Send_Status_Message:
    CPI R19, 33
    BRSH check_medium
    
    LDI ZL, lo8(low_level_msg)
    LDI ZH, hi8(low_level_msg)
    RCALL Send_Status_String
    RJMP status_done
    
check_medium:
    CPI R19, 66
    BRSH high_level
    
    LDI ZL, lo8(medium_level_msg)
    LDI ZH, hi8(medium_level_msg)
    RCALL Send_Status_String
    RJMP status_done
    
high_level:
    LDI ZL, lo8(high_level_msg)
    LDI ZH, hi8(high_level_msg)
    RCALL Send_Status_String
    
status_done:
    RET

Send_Status_String:
status_string_loop:
    LPM R16, Z+
    CPI R16, 0
    BREQ status_string_done
    
    RCALL Send_Char
    RJMP status_string_loop
    
status_string_done:
    RET

Send_Char:
uart_tx_wait:
    LDS R17, UCSR0A
    SBRS R17, UDRE0
    RJMP uart_tx_wait
    
    STS UDR0, R16
    
    RET

; Konversi nilai dari dec menjadi skala persentase
Send_Decimal_Value:
    PUSH R16
    
    CPI R16, 255
    BRNE normal_percentage_calculation_uart
    
    LDI R16, 100
    RJMP uart_percentage_ok
    
normal_percentage_calculation_uart:
    LDI R17, 100
    MUL R16, R17
    
    MOV R16, R1
    
    MOV R17, R0
    CPI R17, 128
    BRLO uart_percentage_ok
    INC R16
    
uart_percentage_ok:
    CLR R21
    
    CLR R17
    
    CPI R16, 100
    BRLO check_tens
    SUBI R16, 100
    LDI R17, 1
    
    MOV R19, R16
    
    MOV R16, R17
    SUBI R16, -48
    RCALL Send_Char
    LDI R21, 1
    
    MOV R16, R19
    RJMP tens_process
    
check_tens:
    MOV R19, R16
    
tens_process:
    CLR R17
    
tens_loop:
    CPI R16, 10
    BRLO tens_done
    SUBI R16, 10
    INC R17
    RJMP tens_loop
    
tens_done:
    PUSH R16
    
    CPI R17, 0
    BRNE send_tens
    CPI R21, 0
    BREQ ones_process_restore
    
send_tens:
    MOV R16, R17
    SUBI R16, -48
    RCALL Send_Char
    LDI R21, 1
    
ones_process_restore:
    POP R16
    
    SUBI R16, -48
    RCALL Send_Char
    
    LDI R16, '%'
    RCALL Send_Char
    
    POP R16
    RET

; Message untuk ditampilkan ke Terminal
welcome_msg:
    .ascii "Water Level Monitoring System - SPI Slave Ready\r\n"
    .ascii "Waiting for data from master...\r\n"
    .byte 0

water_level_msg:
    .ascii "Water level: "
    .byte 0

low_level_msg:
    .ascii " - LOW LEVEL (Green LED)"
    .byte 0

medium_level_msg:
    .ascii " - MEDIUM LEVEL (Yellow LED)"
    .byte 0

high_level_msg:
    .ascii " - HIGH LEVEL WARNING! (Red LED)"
    .byte 0
