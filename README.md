# On-the-Job Training Management System

A desktop application built with **Flutter** and **Dart**, using **Sqflite** as the local database. This system is designed to manage student OJT (On-the-Job Training) records, generate official documents such as certificates, and provide data export functionalities.

---

## 🚀 Features

- 🔧 **CRUD Operations** for OJT students  
- 📄 **Certificate Generation** with student details  
- 🔗 **QR Code Generation** linking to uploaded Word files on Google Drive  
- ☁️ **Google Drive Upload Integration** (per program and year)
- 📊 **Excel Report Generation** filtered by Program, School, and Year  
- 📥 **Import/Export CSV Files** for backup or migration  
- 🔍 **Advanced Filtering** (by program, year, school) with Autocomplete  
- 🖨️ **PDF Certificate Output** (supports up to 2 students per page)

---

## 🛠 Tech Stack

- **Flutter** (desktop app)
- **Dart**
- **Sqflite** (SQLite for local storage)
- **syncfusion_flutter_xlsio** (for Excel)
- **googleapis / drive_v3** (for Google Drive)
- **qr_flutter** (for QR code generation)
- **pdf** (for certificate PDFs)

---

## 📁 Folder Structure

lib/
├── main.dart
├── db/ # Database helper classes
├── models/ # Student and QR models
├── screens/ # All UI pages (Home, Input, QR Code, Certificate, etc.)
├── utils/ # Helper functions (PDF, QR, Excel, Google Drive)

## 📦 Setup Instructions

Ensure you've set up:

Google Drive API credentials

Internet connection for uploading and QR linking

📌 Notes
Word files for each program are uploaded to a specified Google Drive folder.

QR Codes are generated and linked to the uploaded Word files.

Reports are generated based on filtered student data and exported to Excel.

All QR links are saved to the database and used in certificate generation.

🧑‍💼 Author
Developed by NotJaypee as part of a professional OJT requirement.

📄 License
This project is licensed for educational and institutional use. Contact the developer for reuse or deployment.

Let me know if you'd like to add screenshots, usage GIFs, or customize the license section.
