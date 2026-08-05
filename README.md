# 🏪 ERP & POS System - Al-Haseeb Foods & Bakers

A modern **ERP (Enterprise Resource Planning)** and **Point of Sale (POS)** application built with **Flutter** and **Firebase** for managing retail stores, bakeries, and small businesses.

The application helps businesses manage inventory, sales, suppliers, invoices, employees, and analytics from a single platform with secure role-based access.

---

## ✨ Features

### 🔐 Authentication
- Firebase Authentication
- Secure Login
- Role-Based Access Control
- Admin & Staff Accounts

### 👨‍💼 Admin Panel
- Dashboard Overview
- Sales Analytics & Daily Revenue
- Product Management
- Inventory Management
- Supplier Management
- Employee Management
- Invoice History
- Backup & Restore
- Adaptive Theme Settings (Light/Dark Mode)

### 👨‍💻 Staff Panel
- Secure Login
- Create New Sales (POS)
- View Products
- Check Stock Availability
- Invoice Generation
- View Today's Sales

### 🛒 Point of Sale (POS)
- Fast Billing System
- Dynamic Cart Management
- Real-Time Automatic Stock Updates in UI
- Discount Support (Percentage)
- Invoice Generation
- PDF Invoice Export
- Print Invoice

### 📦 Inventory Management
- Add Products
- Update Products
- Delete Products
- Dynamic Grid & List Views
- Low Stock Alerts & Visual Indicators
- Stock Tracking & Updates

### 🚚 Supplier Management
- Add Suppliers
- Update Supplier Information
- Contact Details
- Stock-In Procurement Tracking

### 📊 Analytics & Reports
- Daily Sales Summary
- Expense Tracking
- Revenue Overview
- Dynamic Top Product Cards

### 📄 Invoice Management
- Invoice History
- PDF Download
- Print Invoice

---

# 📱 Screens

- Login / Register
- Admin Dashboard & Staff Dashboard
- Point of Sale (New Sale)
- Product Catalog (Add/Edit Products)
- Supplier Management & Stock Procurement
- Customer Management & Purchase History
- Staff Management
- Attendance & Payroll
- Sales History & Today's Sales
- Expenses Management
- Financial Reports
- Backup & Restore
- Profile Settings
- Theme Settings
- Invoice Details

---

# 🛠 Tech Stack

| Technology | Description |
|------------|-------------|
| Flutter | Cross-platform UI Framework |
| Dart | Programming Language |
| Firebase Authentication | User Authentication |
| Cloud Firestore | Database |
| Cloudinary | Image Storage & Hosting |
| Cached Network Image | Image Caching |
| PDF | Invoice Generation |
| Printing | Print Support |
| Flutter SVG | SVG Icons |

---

# 📂 Project Structure

```
lib/
│
├── models/
├── services/
├── screens/
│   ├── admin/
│   ├── auth/
│   ├── settings/
│   ├── shared/
│   └── staff/
├── theme/
├── utils/
├── widgets/
└── main.dart
```

---

# 🚀 Getting Started

## 1. Clone the repository

```bash
git clone https://github.com/Haseeb-ML/Al-Haseeb.git
```

## 2. Navigate into the project

```bash
cd erp
```

## 3. Install dependencies

```bash
flutter pub get
```

## 4. Configure Firebase

- Create a Firebase Project
- Enable Authentication
- Enable Cloud Firestore
- Generate `firebase_options.dart`

## 5. Run the project

```bash
flutter run
```

---

# 📌 Requirements

- Flutter 3.x+
- Dart 3.x+
- Firebase Project
- Android Studio / VS Code

---

# 🔒 User Roles

### Admin
- Full System Access
- Manage Products & Inventory
- Manage Staff Roles & Payroll
- Manage Suppliers
- View Global Financial Reports
- System Settings & Themes
- Backup & Restore

### Staff
- Create Sales via POS
- View Products & Stock
- Generate Invoices
- View Own Profile

---

# 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your branch
5. Open a Pull Request

---

# 📄 License

This project is licensed under the MIT License.

---

# 👨‍💻 Developer

**Muhammad Haseeb**

Flutter Developer | Firebase | ERP & POS Systems

If you like this project, don't forget to ⭐ the repository.
