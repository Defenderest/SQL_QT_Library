# Librarium: A Comprehensive C++/Qt Bookstore & Library Management System

<div align="center">

**A full-featured, database-driven desktop application built with C++ and the Qt framework, demonstrating modern software architecture and development practices with CMake.**

[![Language](https://img.shields.io/badge/Language-C%2B%2B17-00599C.svg?style=for-the-badge&logo=cplusplus)](https://isocpp.org/)
[![Framework](https://img.shields.io/badge/Framework-Qt_6-41CD52.svg?style=for-the-badge&logo=qt)](https://www.qt.io/)
[![Build System](https://img.shields.io/badge/Build_System-CMake-064F8C.svg?style=for-the-badge&logo=cmake)](https://cmake.org/)
[![Database](https://img.shields.io/badge/Database-PostgreSQL-336791.svg?style=for-the-badge&logo=postgresql)](https://www.postgresql.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

</div>

Librarium is more than just a software project; it's a comprehensive portfolio piece designed to showcase a robust, scalable, and user-friendly desktop application. It covers the entire lifecycle of bookstore management, from inventory and author tracking to user authentication and sales processing, all wrapped in a clean, intuitive Qt interface.

---

## 📜 Table of Contents

- [⭐ Project Philosophy & Goals](#-project-philosophy--goals)
- [✨ Core Features in Detail](#-core-features-in-detail)
- [🖼️ Application Showcase (Screenshots)](#️-application-showcase-screenshots)
- [🏛️ Architectural Design](#️-architectural-design)
- [🗃️ Database Schema](#️-database-schema)
- [🛠️ Technology Stack](#️-technology-stack)
- [📋 Prerequisites](#-prerequisites)
- [🚀 Build & Run: A Comprehensive Guide](#-build--run-a-comprehensive-guide)
  - [Step 1: Database Setup (Crucial First Step)](#step-1-database-setup-crucial-first-step)
  - [Step 2: Building with CMake](#step-2-building-with-cmake)
  - [Step 3: Running the Application](#step-3-running-the-application)
- [📂 Project Structure Explained](#-project-structure-explained)
- [🔧 Configuration](#-configuration)
- [❓ Troubleshooting & FAQ](#-troubleshooting--faq)
- [🗺️ Ambitious Future Roadmap](#️-ambitious-future-roadmap)
- [🤝 Contribution Guidelines](#-contribution-guidelines)
- [📄 License](#-license)
- [🙏 Acknowledgements](#-acknowledgements)

---

## ⭐ Project Philosophy & Goals

The primary goal of Librarium is to serve as a high-quality reference project that demonstrates:
- **Modern C++ Practices**: Utilizing C++17 features for clean, efficient, and maintainable code.
- **Advanced Qt Capabilities**: Going beyond basic widgets to implement custom models, complex views, and a responsive user experience.
- **Robust Software Architecture**: Implementing a clear separation of concerns (UI, business logic, data access) for scalability and testability.
- **Real-World Build Systems**: Using CMake for cross-platform project configuration and compilation.
- **Database Integration**: Showcasing how to effectively connect a desktop application to a powerful relational database like PostgreSQL.

## ✨ Core Features in Detail

- **Interactive Administrator Dashboard**: A central hub providing at-a-glance analytics, including real-time counts of books, authors, genres, and users, giving administrators a clear view of the system's state.
- **Dynamic Book Catalog with Advanced Filtering**: Users can seamlessly browse the entire book collection. The catalog features a powerful, multi-select, checkbox-based filtering system by genre and availability status.
- **Comprehensive Book Details Page**: Each book has its own dedicated view showing cover art, a detailed synopsis, ISBN, publisher info, pricing, and an aggregated rating. It also features a section for user-submitted reviews and ratings.
- **Author Directory & Profile Pages**: A searchable directory of all authors. Each author has a profile page with a biography and a list of all their books available in the system, creating a rich discovery experience.
- **Full-Fledged Shopping Cart**: A persistent shopping cart allows users to add, remove, and modify quantities of books before proceeding to a simulated checkout process.
- **Secure User Authentication & Profiles**: A complete user subsystem with registration and login. Logged-in users have a personal profile page where they can view their order history, manage personal information, and track their contributions (reviews).

## 🖼️ Application Showcase (Screenshots)

| Main Dashboard | Book Catalog with Filters |
| :---: | :---: |
| <img width="1011" height="776" alt="main" src="https://github.com/user-attachments/assets/b184396c-b9fc-4974-aaa8-109cb66aaac5" /> |<img width="1027" height="698" alt="Book Catalog" src="https://github.com/user-attachments/assets/290c7051-f699-46ed-bdd0-01c1a692c770" />

| Book Details & Reviews | Author Directory |
| :---: | :---: |
| <img width="883" height="682" alt="book_details" src="https://github.com/user-attachments/assets/e1aa10fb-26ae-402b-935c-169b3bce355e" /> |<img width="976" height="782" alt="authors_page" src="https://github.com/user-attachments/assets/ab7f51bf-ebcb-41cd-b079-ba2647ed9042" />

| Shopping Cart | User Profile |
| :---: | :---: |
|<img width="806" height="713" alt="cart" src="https://github.com/user-attachments/assets/c2b2105c-5b9e-4e79-aed9-d2372563d692" />|<img width="886" height="697" alt="profile" src="https://github.com/user-attachments/assets/1df74e9a-6f32-46a2-9654-f2e82e65d969" />
|

## 🏛️ Architectural Design

The application follows a design pattern inspired by **Model-View-Controller (MVC)** to ensure a clean separation of concerns:
- **Model**: Represents the data and business logic. This layer is responsible for interacting with the database via Qt's SQL module. It fetches data, performs validation, and executes business rules.
- **View**: The UI components of the application (`.ui` files and their corresponding C++ classes). The View is responsible for displaying data to the user and capturing user input. It should be as "dumb" as possible, delegating all logic to the Controller.
- **Controller**: Acts as the intermediary between the Model and the View. It responds to user input from the View, processes it (by calling methods on the Model), and updates the View with the results. This separation makes the code easier to test, maintain, and scale.

## 🗃️ Database Schema

The backbone of Librarium is its relational database. The schema is designed for data integrity and efficient querying, with clear relationships between entities like books, authors, users, genres, reviews, and orders.

<div align="center">

<img width="3840" height="3594" alt="er_diagram" src="https://github.com/user-attachments/assets/c4f8afc0-205b-4fdd-a86b-6a7f7d49aae0" />

*Entity-Relationship Diagram illustrating the database tables and their relationships.*

</div>

## 🛠️ Technology Stack

- **Core Language**: C++ (C++17 standard)
- **UI Framework**: Qt 6.2 or newer
- **Build System**: CMake (version 3.16 or newer)
- **Database**: PostgreSQL (recommended), though easily adaptable to other SQL databases.
- **Key Qt Modules**: `QtWidgets`, `QtSql`, `QtCore`, `QtGui`.

## 📋 Prerequisites

Before you begin, ensure you have the following installed and configured:
- A modern C++ compiler (GCC 7+, Clang 6+, MSVC 2017+).
- Qt Framework (version 6.2 or newer).
- CMake (version 3.16 or newer).
- A running instance of a PostgreSQL server.

---

## 🚀 Build & Run: A Comprehensive Guide

Follow these three essential steps to get the application running.

### Step 1: Database Setup (Crucial First Step)

The application cannot run without a properly configured database.

1.  **Create a Database and User**:
    Connect to your PostgreSQL server and create a dedicated user and database for this application.
    ```sql
    CREATE USER librarium_user WITH PASSWORD 'your_secure_password';
    CREATE DATABASE librarium_db OWNER librarium_user;
    ```
2.  **Populate the Schema**:
    Use a tool like `psql` or a GUI client (like DBeaver or pgAdmin) to run the schema creation script on the newly created database. This script will create all the necessary tables, relationships, and constraints.
    ```bash
    psql -U librarium_user -d librarium_db -f path/to/your/schema.sql
    ```
    *(You will need to find the `.sql` schema file within the project's source code).*

### Step 2: Building with CMake

This project uses a modern CMake workflow.

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/Defenderest/SQL_QT_Library.git
    cd SQL_QT_Library
    ```

2.  **Create a Build Directory**:
    This keeps the main project folder clean from build artifacts.
    ```bash
    mkdir build && cd build
    ```

3.  **Configure the Project using CMake**:
    This step generates the native build files (e.g., Makefiles, Visual Studio projects). You **must** tell CMake where your Qt installation is located.

    *Replace `/path/to/your/Qt` with the actual path to your Qt kit (e.g., `C:/Qt/6.4.0/mingw_64`)*.

    ```bash
    # Example for Linux/macOS
    cmake .. -DCMAKE_PREFIX_PATH=/path/to/your/Qt/6.x.x/gcc_64

    # Example for Windows with Visual Studio
    cmake .. -G "Visual Studio 17 2022" -DCMAKE_PREFIX_PATH=C:/path/to/your/Qt/6.x.x/msvc2019_64
    ```

4.  **Compile the Source Code**:
    This command invokes the compiler to build the executable.
    ```bash
    cmake --build . --config Release
    ```
    The `--config Release` flag is recommended for an optimized build.

### Step 3: Running the Application

- The compiled executable will be located in the `build` directory (or a subdirectory like `build/Release`).
- **Important**: On Windows and sometimes on Linux, you may need to copy the required Qt DLLs (or `.so` files) and platform plugins (especially the SQL driver) next to your executable for it to run. Qt's `windeployqt` or `macdeployqt` tools can automate this process.

## 📂 Project Structure Explained
```
Librarium/
├── src/                  # All C++ source code and UI files
│   ├── core/             # Core application logic, database manager, singleton classes
│   ├── models/           # Custom data models (e.g., for QTableView, QListView)
│   ├── views/            # UI classes (windows, dialogs, custom widgets)
│   ├── resources/        # Application resources like icons, stylesheets (.qrc)
│   └── main.cpp          # Main application entry point
├── docs/                 # Documentation assets
│   └── images/           # All screenshots, diagrams, and other visual assets
├── CMakeLists.txt        # The main CMake build script defining the project
└── README.md             # This documentation file
```
## 🔧 Configuration

Database connection details (host, port, dbname, user, password) should be managed securely. This project may use one of the following methods:
- A `config.ini` file that is read at startup.
- A settings dialog within the application for first-time setup.
- Environment variables.

Please check the source code in `src/core/` for the exact implementation.

## ❓ Troubleshooting & FAQ

- **Problem**: `CMake Error: Could not find a package configuration file provided by "Qt6"`.
  - **Solution**: Your `-DCMAKE_PREFIX_PATH` is incorrect or missing. Ensure it points directly to the Qt kit directory (e.g., `C:/Qt/6.4.0/msvc2019_64`).

- **Problem**: The application starts, but I get a "QPSQL driver not loaded" error.
  - **Solution**: This is a deployment issue. Qt's SQL driver is a plugin. You need to copy the driver file (`qpsql.dll` or `libqpsql.so`) from your Qt installation's `plugins/sqldrivers` folder to a `sqldrivers` subdirectory next to your application's executable.

- **Problem**: The application runs but cannot connect to the database.
  - **Solution**:
    1.  Verify the database service (PostgreSQL) is running.
    2.  Check your firewall settings to ensure connections to the database port (default 5432) are allowed.
    3.  Double-check the credentials (host, user, password, dbname) used by the application.

## 🗺️ Ambitious Future Roadmap

- [ ] **CI/CD Integration**: Set up GitHub Actions to automatically build and test the project on every push.
- [ ] **Cross-Platform Packaging**: Create installers/packages for Windows (MSIX), macOS (DMG), and Linux (AppImage/DEB).
- [ ] **Internationalization (i18n)**: Implement full support for multiple languages using Qt's translation tools.
- [ ] **REST API Backend**: Develop a companion REST API to allow for a future web or mobile client.
- [ ] **Performance Optimization**: Profile the application and optimize slow database queries and rendering bottlenecks.
- [ ] **Unit & Integration Testing**: Build a comprehensive test suite using the Qt Test framework to ensure code quality and prevent regressions.

## 🤝 Contribution Guidelines

We welcome contributions! Please follow these guidelines:
1.  **Fork the repository** and create a new branch from `main`.
2.  **Code Style**: Please adhere to the existing code style (naming conventions, formatting).
3.  **Commit Messages**: Write clear and concise commit messages explaining your changes.
4.  **Pull Request**: Submit a pull request with a detailed description of the feature or bug fix. Explain *why* the change is needed and *how* it was implemented.

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

## 🙏 Acknowledgements

- The **Qt Project** for creating an outstanding cross-platform framework.
- The **CMake** team for their powerful build system generator.
- The **PostgreSQL** community for their world-class open-source database.
