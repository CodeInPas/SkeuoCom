# SkeuoSimControls

**SkeuoSimControls** adalah pustaka komponen kustom untuk [Lazarus](https://www.lazarus-ide.org/) / Free Pascal yang dirancang khusus untuk membangun antarmuka pengguna (UI) bergaya *skeuomorphic* yang realistis. 

Dibangun di atas engine grafis **BGRABitmap**, komponen ini menawarkan rendering anti-aliased berkualitas tinggi yang sangat cocok untuk aplikasi simulasi, dashboard avionik, panel kontrol industri, dan antarmuka perangkat lunak audio (Virtual Instruments/Mixer).

## 🚀 Fitur Utama
- **20+ Komponen Interaktif**: Mulai dari sakelar sederhana hingga layar radar dan osiloskop dinamis.
- **High-Quality Rendering**: Menggunakan BGRABitmap untuk gradien yang halus, efek bayangan (drop shadow), pendaran cahaya (glow), dan pantulan kaca (gloss).
- **Sangat Dapat Dikustomisasi**: Ubah warna, batas nilai, dan status komponen langsung melalui *Object Inspector*.
- **Mandiri (Self-Contained)**: Rendering digambar murni melalui kode matematika dan BGRABitmap (tanpa bergantung pada aset gambar bitmap eksternal untuk logika UI).

## 🎛️ Daftar Komponen (SkeuoSim Palette)
- **Indicators & Displays**: `TLEDIndicator`, `TSevenSegment`, `TSimLedBarGraph`, `TSimLcdDisplay`
- **Switches & Buttons**: `TSimToggleSwitch`, `TSimPushButton`, `TSimSafetySwitch`, `TSimMatrixPad`
- **Dials & Sliders**: `TKnob`, `TSimFader`, `TSimSelectorSwitch`, `TSimThrottleLever`, `TSimJoystick`
- **Gauges**: `TCircularGauge`, `TLinearGauge`, `TVuMeter`, `TCompass`, `TAviatorGauge`
- **Advanced Screens**: `TSimOscilloscope`, `TSimRadarScreen`
- **Misc**: `TSimGroupBox`, `TSimAudioJack`

## 📦 Prasyarat Instalasi
1. Lazarus IDE (Terbaru direkomendasikan).
2. Paket **BGRABitmap** (Dapat diinstal melalui *Online Package Manager* / OPM di Lazarus).

## 🛠️ Cara Instalasi
1. Clone atau *download* repositori ini.
2. Buka Lazarus IDE.
3. Buka menu **Package** -> **Open Package File (.lpk)**.
4. Pilih file `SkeuoSimControls.lpk` dari folder *source*.
5. Klik **Compile**. Pastikan kompilasi berhasil tanpa error.
6. Klik **Install** dan biarkan Lazarus melakukan *rebuild*.
7. Setelah Lazarus terbuka kembali, Anda akan menemukan tab baru bernama **"SkeuoSim"** di *Component Palette*.

## 📜 Lisensi
MIT Licens
