# Tajiri AI

An AI-based financial tracker and advisory provider aimed for personal and small business use. This is a final year project by Hassan Waziri, Christine Christopher, and Allen Chanila.

## Project Overview

Tajiri AI is a comprehensive financial management application designed to help users track their finances, set and manage budgets and goals, and receive personalized financial advice through an AI-powered assistant.

## Features

* **User Authentication**: Secure user registration and login with email/password and Google Sign-In.
* **Account Management**: Users can create, read, update, and delete financial accounts with various currencies.
* **Transaction Tracking**: Easily log and manage income, expenses, and transfers between accounts.
* **Budgeting**: Set and manage monthly budgets for different spending categories to stay on top of your finances.
* **Financial Goals**: Define, track, and manage your financial goals with detailed daily progress logs.
* **AI Financial Advisor**: Get personalized financial advice, create transactions, and view spending summaries through a conversational AI-powered chat interface.
* **Data Analytics**: Visualize your financial data with detailed analytics, including spending breakdowns by category and income vs. expense comparisons.
* **Custom Categories**: Create, edit, and delete personalized categories for both income and expenses to better organize your transactions.

## Tech Stack

* **Frontend**: Flutter
* **Backend**: Firebase (Authentication, Firestore, Cloud Functions, Storage, App Check)
* **AI**: Google's Gemini model via Vertex AI

## Project Structure

The project is organized into the following main directories:

* `lib`: Contains the core Flutter application code.
  * `core`: Core components like models, services, and utilities.
  * `features`: Feature-specific modules, such as the advisor chat.
  * `screens`: UI screens for different parts of the application.
  * `main.dart`: The main entry point of the application.
* `functions`: Contains the Firebase Cloud Functions written in TypeScript.
* Platform-specific directories: `android`, `ios`, `web`, `windows`, `linux`, `macos`.

## Important Documentation

* **`firebase.json`**: This file configures the Firebase services used in the project, including Firestore and Cloud Functions.
* **`pubspec.yaml`**: Lists all the Flutter and Dart packages and assets used in the project.
* **`functions/src/index.ts`**: This file contains the core backend logic for the AI advisor, transaction and goal management, and other server-side functionalities.
* **`lib/core/services/firestore_service.dart`**: This service class handles all the interactions with the Firestore database, including all CRUD operations for accounts, transactions, budgets, goals, and categories.
* **`lib/main.dart`**: This is the main entry point for the Flutter application. It initializes Firebase services, sets up the application's theme, and handles the initial navigation logic.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

* Flutter SDK
* Firebase CLI

### Installation

1. Clone the repo

    ```sh
    git clone https://github.com/your_username_/Chanilla-s-branch.git
    ```

2. Install Flutter packages

    ```sh
    flutter pub get
    ```

3. Set up Firebase for your project.
4. Run the app

    ```sh
    flutter run
    ```
