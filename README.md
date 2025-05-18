# Smartflow - Smart Flood-level Observation and Warning 

Made By Group 9

1. Alfonsus Tanara Gultom (2306267126)
2. Jonathan Matius Weni (2306161896)
3. Siti Amalia Nurfaidah (2306161851)
4. Wilman Saragih Sitio(2306161776)
5. Xavier Daniswara (2206030230)



## Introduction

### Problem

Banjir merupakan salah satu bencana alam yang sering terjadi dan dapat menyebabkan kerugian besar, terutama jika tidak terdeteksi sejak dini. Sistem pemantauan level air konvensional sering kali hanya memberikan informasi saat air sudah mencapai titik kritis. Hal ini menyebabkan keterlambatan dalam pengambilan tindakan dan meningkatkan risiko terhadap keselamatan dan kerugian materi.

### Solution

**SmartFlow** adalah sebuah sistem pemantauan level air pintar yang dirancang untuk memberikan peringatan dini terhadap potensi banjir. Sistem ini menggunakan sensor level air berbasis transistor untuk mendeteksi ketinggian air secara akurat. Data yang diperoleh akan diproses melalui ADC dan dikirim melalui komunikasi SPI untuk ditampilkan pada serial monitor. Sistem ini juga dilengkapi LED indikator sebagai penanda visual status level air, serta menggunakan timer dan interrupt untuk pembaruan data secara berkala dan peringatan otomatis saat kondisi berbahaya terdeteksi.



## Hardware Design and Implementation Detail

### Components Used

- Arduino Uno (Master & Slave)
- Liquid Level Sensor Module (berbasis transistor S8050 NPN)
- Resistor & Supporting Components
- LED (Hijau, Kuning, Merah)
- Jumper Wires & Breadboard
- Power Supply (5V)

### Hardware Schematic 
![image](https://hackmd.io/_uploads/H1-vZFNbxe.png)

### Hardware Connections
#### Water Sensor:

- Pin S (Signal) → Pin Analog Arduino A0 (PC0)
- Pin + → Arduino 5V (melalui induktor L1)
- Pin - → Arduino GND

#### Indikator LED:
- LED Hijau (D1) → Pin Analog Arduino A1 (PC1) (melalui resistor R3 220Ω)
- LED Kuning (D3) → Pin Analog Arduino A2 (PC2) (melalui resistor R4 220Ω)
- LED Merah (D2) → Pin Analog Arduino A3 (PC3) (melalui resistor R5 220Ω)
- Semua LED GND → Arduino GND

#### Buzzer Circuit:
- Pin PD7 → Base transistor Q1 (melalui resistor R1 220Ω)
- Buzzer positif → Arduino 5V (melalui resistor R2 10kΩ)
- Buzzer negatif → Collector transistor Q1
- Emitter transistor Q1 → Arduino GND

#### Komunikasi Antar Arduino:
- Arduino 1 (ARD1) RXD pin 0 → Arduino 2 (ARD2) TXD
- Arduino 1 (ARD1) TXD pin 1 → Arduino 2 (ARD2) RXD

#### Filter Circuit (untuk Water Sensor):
- Induktor L1 (270μH) terhubung antara 5V dan sensor pin +
- Kapasitor C1 (300μF) terhubung antara sensor pin + dan GND

#### Resistor Voltage Divider (untuk Water Sensor):
- Resistor RV1 terhubung antara sensor output dan GND





## Software Implementation

### Library yang Digunakan 

- avr/io.h - Untuk akses I/O dan register mikrokontroler AVR
- avr/interrupt.h - Untuk penanganan interupsi pada Arduino Master
- SPI.h (implisit dalam kode assembly) - Untuk komunikasi SPI antar Arduino

### Algoritma Code 

#### Arduino Master (Sensor dan Alarm)
1. Inisialisasi sistem
    - Konfigurasi Stack Pointer
    - Set pin LED (PC1, PC2, PC3) sebagai output untuk indikator level air
    - Konfigurasi pin buzzer (PD7) sebagai output untuk alarm
    - Inisialisasi SPI sebagai Master untuk komunikasi antar Arduino
    - Konfigurasi ADC untuk pembacaan sensor level air
    - Set Timer1 untuk pembacaan teratur dengan interval ~1 detik
    - Aktifkan global interrupt

2. Loop Utama

    - Baca nilai sensor level air menggunakan ADC
    - Skala hasil ADC 10-bit menjadi 8-bit untuk transmisi
    - Verifikasi level air:
        - Jika melebihi threshold (200), aktifkan alarm
        - Jika di bawah threshold, nonaktifkan alarm
    - Perbarui indikator LED berdasarkan level air:
        - Level rendah (<85): LED Hijau aktif
        - Level sedang (85-169): LED Kuning aktif
        - Level tinggi (≥170): LED Merah aktif
    - Kirim data level air ke Arduino slave melalui SPI
    Tunggu interupsi timer berikutnya

3. Interupsi Timer
    - Timer1 diatur untuk memicu interupsi setiap ~1 detik
    - Reset timer saat interupsi terjadi
    - Set flag untuk menandakan saatnya pembacaan sensor baru

4. Komunikasi SPI
    - Master mengirimkan data level air ke slave
    - Proses transmisi:
    - Aktifkan slave (SS low)
    - Kirim data level air
    - Tunggu transmisi selesai
    - Nonaktifkan slave (SS high)

5. Pembacaan Sensor
    - VKonversi analog ke digital dari sensor level air
    - Tunggu konversi ADC selesai
    - Baca hasil 10-bit dan skala menjadi 8-bit

#### Arduino Slave (Monitoring dan Komunikasi)
1. Inisialisasi sistem
    - Inisialisasi UART untuk komunikasi dengan terminal/komputer (9600 baud)
    - Kirim pesan sambutan ke terminal
    - Konfigurasi SPI sebagai Slave untuk menerima data dari Master

2. Loop Utama
    - Terima data level air dari Master melalui SPI
    - Proses data yang diterima
    - Kirim informasi status ke terminal melalui UART

3. Pemrosesan Data

    - Konversi nilai level air yang diterima (0-255) menjadi persentase (0-100%)
    - Tentukan kategori level air:
        - Level rendah (<33%): Status "LOW LEVEL"
        - Level sedang (33-65%): Status "MEDIUM LEVEL"
        - Level tinggi (>65%): Status "HIGH LEVEL WARNING!"
    - Kirim data level air dan status ke terminal

4. Komunikasi UART
    - Mengirim data level air dalam format persentase
    - Menampilkan status level air dengan pesan yang sesuai
    - Format output yang terstruktur dan mudah dibaca pada terminal

#### Alur Kerja Sistem

1. Arduino Master:
    - Melakukan pembacaan sensor level air secara kontinyu dengan interval ~1 detik
    - Mengaktifkan indikator visual (LED) dan alarm (buzzer) sesuai level air
    - Mengirim data level air ke Arduino Slave melalui SPI

2. Arduino Slave:
    - Menerima data level air dari Master
    - Mengkonversi data ke format persentase
    - Mengirim informasi level air dan status ke terminal/komputer
    - Memberikan output yang mudah dibaca untuk monitoring jarak jauh

3. Integrasi Sistem:
    - -Master menangani pengukuran dan peringatan lokal
    - Slave menangani monitoring dan komunikasi jarak jauh
    - Sistem memberikan peringatan lokal dan remote secara real-time

## Test Result and Performance Evaluation
