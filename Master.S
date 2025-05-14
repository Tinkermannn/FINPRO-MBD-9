#define __SFR_OFFSET 0x00
#include "avr/io.h"
#include "avr/interrupt.h"

.global main

.org 0x0000
    JMP main              ; Vektor Reset
.org 0x001A
    JMP TIMER1_COMPA_ISR  ; Vektor Interupsi Timer1 Compare Match A

main:
    ; Inisialisasi Stack Pointer
    LDI R16, hi8(RAMEND)
    OUT SPH, R16
    LDI R16, lo8(RAMEND)
    OUT SPL, R16
    
    ; Set pin LED sebagai output (PC1, PC2, PC3 untuk indikator level air)
    LDI R16, (1<<1)|(1<<2)|(1<<3)
    OUT DDRC, R16
    
    ; Inisialisasi pin buzzer sebagai output (PD7)
    LDI R16, (1<<7)
    OUT DDRD, R16
    CBI PORTD, 7          ; Buzzer mati pada awalnya
    
    ; Inisialisasi SPI sebagai Master
    RCALL SPI_Init
    
    ; Set ADC untuk pembacaan sensor level air
    RCALL ADC_Init
    
    ; Inisialisasi Timer1 untuk pembacaan
    RCALL Timer1_Init
    
    ; Aktifkan global interrupt
    SEI
    
main_loop:
    ; Baca nilai sensor level air menggunakan ADC
    RCALL Read_ADC

    ; Hasil ke rentang 8-bit
    RCALL Scale_ADC_Result
    
    ; Periksa jika level air melebihi threshold dan aktifkan alarm
    RCALL Check_Alarm_Threshold
    
    ; Perbarui indikator LED berdasarkan level air
    RCALL Update_LED_Indicators
    
    ; Kirim nilai ADC yang telah diskalakan ke slave lewat SPI
    RCALL SPI_Transmit
    
    ; Loop dan tunggu interupsi timer berikutnya
    RJMP main_loop

; Routine Interuppt Timer1 Compare Match A
TIMER1_COMPA_ISR:
    PUSH R16
    IN R16, SREG
    PUSH R16
    
    ; Reset timer
    LDI R16, 0
    STS 0x85, R16    ; TCNT1H_ADDR = 0x85
    STS 0x84, R16    ; TCNT1L_ADDR = 0x84
    
    ; Set flag untuk menandakan saatnya membaca sensor
    
    POP R16
    OUT SREG, R16
    POP R16
    RETI

; Inisialisasi Timer1 untuk pembacaan teratur
Timer1_Init:
    ; Set Timer1 dalam mode CTC
    LDI R16, 0
    STS 0x80, R16    ; TCCR1A_ADDR = 0x80, Operasi port normal, mode CTC
    
    ; Set prescaler ke 1024 dan mode CTC (WGM12 = 3)
    LDI R16, (1<<3)|(1<<2)|(1<<0)  ; WGM12=3, CS12=2, CS10=0
    STS 0x81, R16    ; TCCR1B_ADDR = 0x81
    
    ; Set nilai pembanding untuk interval ~1 detik (16MHz/1024/15625 = 1dtk)
    LDI R16, hi8(15624)          ; 15624 = 16MHz/1024/1Hz - 1
    STS 0x89, R16    ; OCR1AH_ADDR = 0x89
    LDI R16, lo8(15624)
    STS 0x88, R16    ; OCR1AL_ADDR = 0x88
    
    ; Aktifkan interupsi Timer1 Compare A (OCIE1A = 1)
    LDI R16, (1<<1)  ; OCIE1A = 1
    STS 0x6F, R16    ; TIMSK1_ADDR = 0x6F
    
    RET

; Inisialisasi SPI sebagai Master
SPI_Init:
    ; Set MOSI (PB3), SCK (PB5), dan SS (PB2) sebagai output
    LDI R16, (1<<3)|(1<<5)|(1<<2)  ; MOSI=3, SCK=5, SS=2
    OUT DDRB, R16
    
    ; Set SS high awalnya (tidak aktif)
    SBI PORTB, 2     ; SS = 2
    
    ; Aktifkan SPI, mode Master, set clock rate (fck/16)
    ; SPE=6, MSTR=4, SPR0=0
    LDI R16, (1<<6)|(1<<4)|(1<<0)
    OUT SPCR, R16
    
    RET

; Inisialisasi ADC untuk pembacaan sensor level air
ADC_Init:
    ; Set PC0 (ADC0) sebagai input untuk sensor level air
    CBI DDRC, 0      ; ADC_PIN = 0
    ; Pull-up dinonaktifkan, Input diputuskan dari logika port
    CBI PORTC, 0     ; ADC_PIN = 0
    
    ; Pilih channel ADC 0 (PC0) dengan hasil rata kanan
    ; Gunakan AVCC sebagai tegangan referensi
    ; ADLAR=5, REFS0=6
    LDI R16, (0<<5) | (1<<6)
    STS 0x7C, R16    ; ADMUX_ADDR = 0x7C
    
    ; Aktifkan ADC, mulai konversi, set prescaler ke 128
    ; ADEN=7, ADSC=6, ADPS2=2, ADPS1=1, ADPS0=0
    LDI R16, (1<<7)|(1<<6)|(1<<2)|(1<<1)|(1<<0)
    STS 0x7A, R16    ; ADCSRA_ADDR = 0x7A
    
    ; Tunggu konversi pertama selesai
adc_init_wait:
    LDS R16, 0x7A    ; ADCSRA_ADDR = 0x7A
    SBRC R16, 6      ; ADSC = 6
    RJMP adc_init_wait
    
    RET

; Baca nilai ADC dari sensor level air (hasil 10-bit)
Read_ADC:
    ; Mulai konversi ADC
    LDS R16, 0x7A    ; ADCSRA_ADDR = 0x7A
    ORI R16, (1<<6)  ; ADSC = 6
    STS 0x7A, R16    ; ADCSRA_ADDR = 0x7A
    
    ; Tunggu konversi selesai
adc_wait:
    LDS R16, 0x7A    ; ADCSRA_ADDR = 0x7A
    SBRC R16, 6      ; ADSC = 6
    RJMP adc_wait
    
    ; Baca hasil 10-bit (rata kanan)
    LDS R16, 0x78    ; ADCL_ADDR = 0x78, read ADCL dulu
    LDS R17, 0x79    ; ADCH_ADDR = 0x79, ADCH
    
    RET

; Skala hasil ADC 10-bit menjadi 8-bit untuk transmisi
Scale_ADC_Result:
    ; Hasil 10-bit ada di R17:R16
    ; Shifting bit untuk mendapatkan 8 bit teratas
    ; Shift kanan 2 bit untuk mendapatkan 8 bit teratas dari hasil 10-bit
    LSR R17
    ROR R16
    LSR R17
    ROR R16
    
    ; Sekarang R16 berisi hasil 8-bit yang telah diskalakan
    MOV R18, R16
    
    RET

; Periksa jika level air melebihi max
Check_Alarm_Threshold:
    ; Bandingkan level air (R18) dengan max 200
    CPI R18, 200    
    BRLO below_threshold
    
    ; Level air di atas max - aktifkan alarm
    SBI PORTD, 7          ; Nyalakan buzzer
    RJMP check_done
    
below_threshold:
    ; Level air di bawah max - nonaktifkan alarm
    CBI PORTD, 7          ; Matikan buzzer
    
check_done:
    RET

; Perbarui indikator LED berdasarkan level air
Update_LED_Indicators:
    ; Periksa jika level < 85 (low)
    CPI R18, 85
    BRSH check_medium_level
    
    ; Keadaan 1: level air rendah
    SBI PORTC, 1      ; Nyalakan LED 1
    CBI PORTC, 2      ; Matikan LED 2
    CBI PORTC, 3      ; Matikan LED 3
    RJMP led_update_done
    
check_medium_level:
    ; Periksa jika 85 ≤ level < 170 (medium)
    CPI R18, 170
    BRSH high_level
    
    ; Keadaan 2: Level air sedang
    CBI PORTC, 1      ; Matikan LED 1
    SBI PORTC, 2      ; Nyalakan LED 2 (Kuning)
    CBI PORTC, 3      ; Matikan LED 3
    RJMP led_update_done
    
high_level:
    ; Keadaan 3: level air tinggi
    CBI PORTC, 1      ; Matikan LED 1
    CBI PORTC, 2      ; Matikan LED 2
    SBI PORTC, 3      ; Nyalakan LED 3 (Merah)

led_update_done:
    RET

; Kirim data melalui SPI
SPI_Transmit:
    CBI PORTB, 2     ; SS = 2 aktifkan slave (SS low)
    
    NOP
    NOP
    
    OUT SPDR, R18
    
spi_wait:
    IN R16, SPSR
    SBRS R16, SPIF   ; SPIF = 7
    RJMP spi_wait
    
    ; Delay singkat sebelum menonaktifkan SS
    NOP
    NOP
    
    ; Nonaktifkan slave (SS high)
    SBI PORTB, 2     ; SS = 2
    
    RET