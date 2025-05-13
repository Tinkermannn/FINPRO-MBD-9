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