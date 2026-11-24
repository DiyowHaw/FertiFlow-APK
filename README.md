**FertiFlow** adalah aplikasi mobile berbasis Flutter yang menggabungkan Artificial Intelligence, IoT, dan sistem fertigation untuk membantu pemantauan serta pengelolaan tanaman cabai secara presisi.

Project ini mengintegrasikan aplikasi Android/iOS dengan ESP32, Firebase, model deteksi gambar YOLOv8/TFLite, cuaca, database lokal, dan asisten AI berbasis LLM.

---

## Tujuan dan konsep utama

FertiFlow dirancang untuk membantu petani:

- Memantau kelembapan tanah.
- Memantau suhu dan kelembapan udara.
- Memantau level air tandon.
- Mengendalikan pompa dan penyemprotan.
- Mendeteksi hama atau penyakit pada daun cabai.
- Menghasilkan rekomendasi penyiraman otomatis.
- Membuat jadwal perawatan.
- Mengelola beberapa zona tanaman.
- Mendapatkan konsultasi dengan asisten AI.
- Mengakses riwayat deteksi, penyiraman, dan aktivitas penyemprotan.

Nama **FertiFlow** berasal dari penggabungan fertigation dan aliran air yang dikendalikan secara cerdas.

---

## Teknologi yang digunakan

### Aplikasi

- Flutter dengan Material Design.
- Bahasa pemrograman Dart.
- Mendukung Android, iOS, Web, Windows, Linux, dan macOS.
- Material theme light dan dark mode.
- Dukungan bahasa Indonesia dan Inggris.
- Google Fonts dan ikon Cupertino.

### Backend dan cloud

- Firebase Core.
- Firebase Authentication.
- Firebase Realtime Database.
- Cloud Firestore.
- Google Sign-In.

### Penyimpanan lokal

- SQLite melalui package `sqflite`.
- Penyimpanan path data dan aset aplikasi.
- Data aplikasi disimpan lokal melalui `DatabaseService`.

### IoT

- ESP32 sebagai node sensor dan aktuator.
- Komunikasi dengan aplikasi melalui Firebase.
- Relay untuk pompa air dan pestisida.
- Sensor kelembapan tanah.
- Sensor suhu dan kelembapan udara.
- Sensor atau indikator level air tandon.

### AI dan deteksi objek

- YOLOv8.
- TensorFlow Lite.
- Package `tflite_flutter`.
- Model `assets/models/best.tflite`.
- Daftar kelas pada `assets/models/labels.txt`.
- Google Generative AI untuk layanan konsultasi dan rekomendasi.
- Roboflow sebagai layanan deteksi tambahan.

---

## Paket utama

Beberapa dependency penting pada `pubspec.yaml`:

| Fungsi | Package |
|---|---|
| Font | `google_fonts` |
| Pemilihan gambar | `image_picker` |
| Firebase | `firebase_core`, `firebase_auth`, `firebase_database`, `cloud_firestore` |
| Database lokal | `sqflite`, `path` |
| Lokasi | `geolocator` |
| HTTP/API | `http` |
| AI TFLite | `tflite_flutter` |
| AI generatif | `google_generative_ai` |
| Gambar | `image` |
| Multibahasa | `flutter_localizations`, `intl` |
| Pembuka tautan | `url_launcher`, `flutter_linkify` |
| Tampilan indikator | `percent_indicator` |
| Ikon | `cupertino_icons` |

Project menggunakan Dart SDK `^3.12.2` dan aplikasi memiliki versi `2.4.0+1`.

---

# Struktur aplikasi

## Inisialisasi aplikasi

Pada `lib/main.dart`, aplikasi melakukan:

1. Menginisialisasi binding Flutter.
2. Menginisialisasi Firebase.
3. Membuka database SQLite.
4. Memuat state dan data tersimpan.
5. Memuat model TFLite ke memori.
6. Memulai subscription data sensor dan relay dari Firebase.
7. Menampilkan tema dan bahasa yang dipilih pengguna.
8. Membuka splash screen.

Aplikasi mendukung navigasi utama:

- Beranda.
- IoT dan monitoring.
- Penanganan tanaman.
- Jadwal perawatan.

Selain itu, tersedia dua floating action:

- Tombol konsultasi AI.
- Tombol kamera atau deteksi gambar.

---

# Fitur aplikasi

## 1. Splash screen dan autentikasi

Aplikasi memiliki:

- Splash screen khusus.
- Tampilan branding FertiFlow.
- Layar login.
- Firebase Authentication.
- Google Sign-In.
- Dukungan informasi sesi pengguna.

---

## 2. Halaman beranda

Halaman beranda menampilkan ringkasan kondisi kebun:

- Status keseluruhan sistem.
- Status koneksi ESP32.
- Peringatan kelembapan tanah rendah.
- Peringatan level air tandon.
- Hasil deteksi hama terbaru.
- Jumlah tanaman sehat.
- Jumlah tanaman yang perlu perhatian.
- Kelembapan tanah.
- Suhu udara.
- Kelembapan udara.
- Grafik sensor tujuh hari.
- Grafik penggunaan atau volume air.
- Status penyemprotan terbaru.
- Riwayat aktivitas.

Status perangkat dapat berupa:

- Belum terhubung.
- Terputus atau data tidak terkini.
- Terhubung dan mengirim data real-time.

---

## 3. Monitoring IoT ESP32

Halaman monitoring menghubungkan aplikasi dengan perangkat FertiFlow.

### Status node

Aplikasi menampilkan:

- Nama node FertiFlow IoT.
- Status koneksi ESP32.
- Waktu pembaruan terakhir.
- Kondisi sensor real-time.

### Data yang dipantau

- Level air tandon.
- Kelembapan tanah.
- Suhu lingkungan.
- Kelembapan udara.
- Status pompa.
- Status pestisida A.
- Status pestisida B.
- Mode otomatis atau manual.

### Kontrol relay

Aplikasi dapat mengirim perintah melalui Firebase untuk mengendalikan:

- Pompa air pada CH1.
- Pestisida A pada CH2 dan CH4.
- Pestisida B pada CH3 dan CH4.
- Penyiraman otomatis.
- Penyiraman atau penyemprotan manual.

Saat mode otomatis aktif, kontrol manual dinonaktifkan.

---

## 4. Zona tanaman

Project menyediakan fitur pengelolaan zona melalui `zone_service.dart`.

Terdapat contoh zona:

- Zona A — Cabai Rawit.
- Zona B — Cabai Keriting.
- Zona bebas atau tanpa zona.

Setiap zona dapat digunakan sebagai konteks saat:

- Memindai tanaman.
- Menyimpan hasil diagnosis.
- Membuat rekomendasi penyiraman.
- Membuat jadwal perawatan.
- Berkonsultasi dengan AI.

---

## 5. Deteksi hama dan penyakit

Fitur deteksi memungkinkan pengguna mengambil atau memilih foto tanaman melalui:

- Kamera.
- Galeri.
- Scan cepat.
- Scan berdasarkan zona.

Deteksi menggunakan model YOLOv8/TFLite dan dapat menampilkan:

- Nama hama atau penyakit.
- Tingkat keyakinan model.
- Tingkat keparahan.
- ID zona atau tanaman.
- Waktu pendeteksian.
- Riwayat hasil deteksi.

Jenis hasil yang dikenali diimplementasikan antara lain:

- Kutu daun.
- Thrips.
- Tungau.

Setiap hasil dapat disertai:

- Deskripsi hama.
- Gejala umum.
- Tingkat keparahan ringan, sedang, atau berat.
- Rekomendasi penanganan.
- Informasi untuk konsultasi AI.

---

## 6. Analisis gambar

Halaman `analysis_screen.dart` memproses gambar yang dipilih pengguna.

Alurnya meliputi:

1. Pengguna memilih atau mengambil foto.
2. Gambar dikirim ke layanan analisis.
3. Model mendeteksi objek atau kondisi tanaman.
4. Aplikasi menampilkan label dan tingkat kepercayaan.
5. Aplikasi menyimpan riwayat deteksi.
6. Pengguna dapat meneruskan hasil ke panduan penanganan.
7. Pengguna dapat membuka konsultasi AI berdasarkan hasil scan.

Proses dapat menggunakan:

- Model TFLite lokal.
- Roboflow.
- Konteks sensor dan zona aktif.

---

## 7. Panduan penanganan

Halaman `treatment_screen.dart` menyimpan tindakan penanganan tanaman.

Fitur ini dapat mengelola:

- Nama hama.
- Tingkat keparahan.
- Nama tanaman atau zona.
- Status penanganan.
- Langkah-langkah treatment.
- Jadwal penyiraman.
- Durasi pompa.
- Volume air.
- Catatan keterbatasan.
- Status masuk ke jadwal.
- ID rekomendasi.

Rekomendasi penyiraman AI dapat ditambahkan langsung ke panduan penanganan.

---

## 8. Jadwal perawatan

Fitur jadwal memungkinkan pengguna mengatur:

- Jadwal penyiraman.
- Hari penyiraman.
- Waktu penyiraman.
- Durasi penyiraman.
- Frekuensi.
- Target zona.
- Aktivitas penyemprotan.
- Jadwal penanganan hama.

Aplikasi dapat mengubah jadwal manual menjadi jadwal berdasarkan rekomendasi AI.

---

## 9. Konsultasi pintar

`SmartConsultationScreen` menyediakan chat AI dengan kemampuan:

- Chat teks.
- Lampiran gambar dari kamera atau galeri.
- Analisis gambar tanaman.
- Rekomendasi penyiraman.
- Konsultasi hama dan penyakit.
- Analisis data sensor real-time.
- Pemanfaatan cuaca dan zona tanaman.
- Penyimpanan rekomendasi ke panduan perawatan.
- Pembuatan jadwal penyiraman.

Chat AI juga dapat menerima konteks otomatis setelah pengguna:

- Melakukan scanning tanaman.
- Memilih zona tanaman.
- Meminta analisis kebun.
- Meminta rekomendasi penyiraman.

Jawaban dapat memuat:

- Diagnosis.
- Saran penanganan.
- Target penyiraman.
- Waktu penyiraman.
- Hari penyiraman.
- Durasi pompa.
- Volume air.
- Catatan atau keterbatasan.

---

## 10. Informasi cuaca

Layanan cuaca digunakan untuk mendukung rekomendasi AI.

Aplikasi dapat mempertimbangkan:

- Suhu cuaca.
- Kelembapan udara.
- Kondisi hujan.
- Kondisi cerah atau berawan.

Rekomendasi penyiraman dapat berubah berdasarkan:

- Kelembapan tanah.
- Kelembapan udara.
- Suhu.
- Status hujan.
- Status ESP32.
- Kondisi tanaman.
- Zona yang dipilih.

---

## 11. Riwayat aktivitas

Aplikasi menyimpan riwayat:

- Deteksi hama.
- Rekomendasi AI.
- Penyiraman.
- Penyemprotan.
- Perubahan status penyiraman.
- Aktivitas pemakaian pestisida.

Riwayat digunakan untuk dashboard dan analisis aktivitas mingguan.

---

## 12. Pengaturan

Layar pengaturan menyediakan:

- Mode gelap atau terang.
- Pemilihan bahasa.
- Bahasa Indonesia.
- Bahasa Inggris.
- Pengaturan aplikasi.
- Informasi sistem.

---

# Arsitektur aplikasi

## Folder utama

```text
lib/
├── main.dart
├── firebase_options.dart
├── l10n/
├── screens/
├── services/
└── widgets/
```

## Layanan aplikasi

| File | Fungsi |
|---|---|
| `app_state.dart` | State global aplikasi |
| `auth_service.dart` | Autentikasi pengguna |
| `database_service.dart` | Database SQLite |
| `firebase_service.dart` | Integrasi Firebase |
| `iot_service.dart` | Sensor dan kontrol ESP32 |
| `llm_service.dart` | Konsultasi AI dan rekomendasi |
| `roboflow_service.dart` | Analisis melalui Roboflow |
| `weather_service.dart` | Informasi cuaca |
| `yolo_tflite_service.dart` | Model YOLOv8 lokal |
| `zone_service.dart` | Manajemen zona tanaman |
| `repository.dart` | Lapisan akses data |

---

# Bagian ESP32

Folder `esp32/fertiflow_esp32/fertiflow_esp32.ino` berisi firmware Arduino untuk ESP32.

Firmware ini kemungkinan menangani:

- Pembacaan sensor.
- Pengiriman data ke Firebase.
- Penerimaan status relay.
- Pengontrolan pompa.
- Pengontrolan pestisida.
- Pelaporan level air.
- Sinkronisasi mode otomatis.

---

# Dukungan platform

Project sudah menyertakan scaffolding untuk:

- Android.
- iOS.
- Web.
- Windows.
- Linux.
- macOS.

Konfigurasi Android menggunakan:

- MainActivity Kotlin.
- Firebase Google Services.
- Launcher icon.
- Native splash screen.

Project memiliki konfigurasi:

- Firebase Hosting.
- Launcher icon.
- Native splash.
- Lokalization.
- Flutter testing.

---

# Alur kerja utama

## Alur deteksi hama

```text
Buka aplikasi
  → Pilih zona
  → Ambil atau pilih foto
  → Model YOLO/TFLite menganalisis gambar
  → Aplikasi menampilkan hama dan tingkat keparahan
  → Hasil disimpan ke riwayat
  → User dapat membuka konsultasi AI
  → AI memberikan rekomendasi penanganan
```

## Alur monitoring IoT

```text
ESP32 membaca sensor
  → Data dikirim ke Firebase
  → Aplikasi menerima data real-time
  → Dashboard memperbarui sensor
  → Aplikasi memberi peringatan
  → Pengguna mengaktifkan mode otomatis atau manual
  → Perintah dikirim kembali ke ESP32
  → Pompa atau penyemprot diaktifkan
```

## Alur rekomendasi penyiraman

```text
Ambil data sensor
  → Ambil data cuaca
  → Cek zona dan tanaman
  → Cek diagnosis atau kondisi kesehatan
  → Kirim data ke AI
  → AI membuat jadwal penyiraman
  → Aplikasi menampilkan durasi, waktu, hari, dan volume
  → Pengguna menyimpan rekomendasi
  → Jadwal dapat dijalankan oleh sistem
```

---

# Kesimpulan

FertiFlow-APK adalah aplikasi AIoT untuk pertanian presisi yang menggabungkan:

- Flutter sebagai antarmuka pengguna.
- Firebase sebagai komunikasi cloud.
- ESP32 sebagai node sensor dan kontrol.
- YOLOv8/TFLite sebagai pendeteksi hama.
- Google Generative AI sebagai asisten pertanian.
- SQLite sebagai penyimpanan lokal.
- Sistem zona dan jadwal sebagai pengelolaan kebun.
- Penyiraman dan penyemprotan otomatis sebagai aktuasi.

Dengan kata lain, project ini bukan sekadar aplikasi monitoring. Ia merupakan sistem terpadu yang menghubungkan data lapangan, deteksi tanaman, rekomendasi AI, jadwal perawatan, dan kontrol perangkat fisik.
