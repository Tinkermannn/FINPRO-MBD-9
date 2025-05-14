# 🏡 Smartflow - Smart Flood-level Observation and Warning 🏡

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

---

## Features

- 📡 **Real-time Water Level Monitoring**: Mengukur dan membaca level air secara langsung.
- 💧 **Analog Signal Processing**: Menggunakan arus listrik melalui air untuk menghasilkan sinyal proporsional terhadap level air.
- 🔄 **Periodic Data Update**: Timer digunakan untuk membaca data secara berkala.
- 🚨 **Early Flood Warning**: Interrupt akan aktif dan memberikan peringatan ketika level air mencapai ambang kritis.
- 💡 **LED Indicator**: Memberikan informasi visual tentang status level air (Aman, Waspada, Bahaya).
- 🖥️ **SPI Communication**: Arduino master membaca data sensor dan slave menampilkan data di serial monitor.

---

## Hardware Overview

### Components Used

- Arduino Uno (Master & Slave)
- Liquid Level Sensor Module (berbasis transistor S8050 NPN)
- Resistor & Supporting Components
- LED (Hijau, Kuning, Merah)
- Jumper Wires & Breadboard
- Power Supply (5V)

### Working Principle

1. **Sensor**: Modul level air mendeteksi keberadaan air dengan menghantarkan arus kecil. Air yang menyentuh sensor mengaktifkan transistor NPN S8050, menghasilkan sinyal analog.
2. **ADC**: Arduino membaca sinyal analog melalui ADC dan mengkonversinya menjadi nilai digital.
3. **SPI**: Data level air dikirim melalui protokol SPI dari Arduino master ke slave.
4. **Monitoring**: Slave menampilkan level air melalui serial monitor, dengan LED sebagai indikator visual.
5. **Interrupt**: Ketika level air melebihi ambang batas tertentu, interrupt akan memicu sistem peringatan.
6. **Timer**: Membaca ulang sensor setiap beberapa detik untuk pembaruan data secara otomatis.

## Software Implementation

Pada bagian implementasi perangkat lunak (software implementation), sistem dibangun menggunakan bahasa Assembly untuk platform mikrokontroler AVR, dengan arsitektur master-slave melalui komunikasi SPI. Perangkat Master bertugas membaca level air dari sensor analog menggunakan ADC, mengatur siklus pembacaan secara periodik menggunakan Timer1 dalam mode CTC, dan mengirimkan data yang telah diskalakan menjadi 8-bit ke Slave melalui SPI. Nilai ADC dari sensor air dibaca setiap satu detik melalui interupsi Timer1 dan kemudian dikategorikan menjadi tiga tingkat level air: rendah, sedang, dan tinggi. Status level air ini ditampilkan melalui tiga LED indikator (PC1–PC3), serta buzzer pada PD7 akan diaktifkan bila level air melebihi ambang batas tertentu. Komunikasi SPI dilakukan dengan konfigurasi MOSI, SCK, dan SS sebagai output, dan pengiriman data dilakukan secara sinkron melalui register SPDR.

Di sisi lain, perangkat Slave menerima data dari Master melalui SPI dan menampilkannya melalui LED bar (PORTC) dengan representasi visual level air. Slave dikonfigurasi sebagai perangkat SPI Slave yang menerima data secara otomatis ketika SS (PB2) diaktifkan (LOW) oleh Master. Setelah data diterima, data 8-bit akan dibaca dari SPDR dan langsung ditampilkan pada PORTC, memungkinkan sistem menampilkan status level air secara langsung melalui bar LED. Selain itu, Slave juga menggunakan register SPIF untuk memastikan data sudah diterima sebelum diproses. Pendekatan ini memungkinkan sistem monitoring level air secara real-time dengan indikator visual dan alarm berbasis logika terintegrasi antara Master dan Slave menggunakan SPI.


