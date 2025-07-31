# SmartPaisaa 💰

> **AI-Powered Personal Finance Management App**

A comprehensive Flutter application that automatically processes SMS transactions, categorizes expenses, and provides intelligent financial insights with beautiful, responsive UI design.

## 🌟 Features

### 📱 **Core Functionality**
- **Automatic SMS Processing**: Intelligent extraction of transaction data from bank SMS
- **Smart Categorization**: AI-powered expense categorization with manual override
- **Multi-Account Support**: Track multiple bank accounts and payment methods
- **Real-time Sync**: Automatic transaction synchronization with manual trigger option
- **Offline-First**: Works seamlessly without internet connection

### 📊 **Advanced Analytics & Reports**
- **Interactive Charts**: Beautiful pie charts and bar charts with animations
- **Financial Insights**: AI-generated spending patterns and recommendations
- **Period Analysis**: Weekly, monthly, quarterly, and yearly breakdowns
- **Trend Visualization**: Visual spending trends with responsive design
- **Export Capabilities**: Generate and share financial reports

### 🎨 **Enhanced User Experience**
- **Responsive Design**: Optimized for all screen sizes (280px to 500px+ width)
- **Dark/Light Themes**: Automatic system theme detection
- **Smooth Animations**: Lottie animations with fallback support
- **Professional UI**: Gradient designs, shadows, and modern components
- **Haptic Feedback**: Enhanced tactile interaction feedback

### 🔧 **Technical Features**
- **SMS Validation**: Advanced filtering system for transaction SMS
- **Data Security**: Local storage with Hive database
- **Performance Optimized**: Efficient memory management and smooth scrolling
- **Error Handling**: Comprehensive error recovery and user feedback
- **Modular Architecture**: Clean, maintainable code structure

## 🚀 Getting Started

### Prerequisites
Flutter SDK: >=3.0.0
Dart SDK: >=3.0.0
Android Studio / VS Code
Git

### Installation

1. **Clone the repository**
   git clone https://github.com/pranavkumar2601/smartpaisaa.git
   cd smartpaisaa
2. flutter pub get

3. **Configure permissions** (Android)

Add SMS permissions to `android/app/src/main/AndroidManifest.xml`:
<uses-permission android:name="android.permission.READ_SMS" /> <uses-permission android:name="android.permission.RECEIVE_SMS" /> ```

flutter run


📦 Dependencies
Core Dependencies
dependencies:
flutter:
sdk: flutter

# Data Storage
hive: ^2.2.3
hive_flutter: ^1.1.0
path_provider: ^2.1.1
shared_preferences: ^2.2.2

# SMS Processing
telephony: ^0.2.0
permission_handler: ^11.0.1

# UI & Animations
lottie: ^2.7.0
flutter_staggered_animations: ^1.1.1

# Charts & Visualization
fl_chart: ^0.64.0

# Utilities
intl: ^0.18.1

dev_dependencies:
flutter_test:
sdk: flutter
hive_generator: ^2.0.1
build_runner: ^2.4.7

🏗️ Architecture
Project Structure

lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── transaction.dart      # Transaction model with Hive annotations
│   ├── category.dart         # Category model
│   └── haptic_feedback_type.dart
├── screens/                  # UI Screens
│   ├── dashboard_screen.dart # Enhanced responsive dashboard
│   ├── transactions_screen.dart # Transaction management
│   ├── categories_screen.dart # Category management
│   ├── reports_screen.dart   # Analytics & insights
│   └── settings_screen.dart  # App configuration
├── services/                 # Business Logic
│   ├── storage_service.dart  # Hive database operations
│   ├── sms_service.dart      # SMS processing engine
│   ├── sms_sync_service.dart # Sync management
│   ├── category_service.dart # Category operations
│   └── settings_service.dart # App settings
├── widgets/                  # Reusable Components
│   ├── charts/
│   │   ├── pie_chart_widget.dart # Enhanced pie chart
│   │   └── bar_chart_widget.dart # Enhanced bar chart
│   └── common/               # Common UI components
├── theme/                    # App Theming
│   └── theme.dart           # Color schemes & styles
└── utils/                    # Utilities
└── helpers.dart         # Helper functions

Design Patterns
Singleton Pattern: Services (Storage, SMS, Settings)

Repository Pattern: Data access abstraction

Observer Pattern: State management and UI updates

Factory Pattern: Model creation and initialization

🎨 UI/UX Highlights
Responsive Design System
Breakpoints: 280px, 320px, 350px, 400px+ width categories

Adaptive Components: Dynamic sizing and spacing

Typography Scale: Responsive font sizes and line heights

Touch Targets: Minimum 44px for accessibility

Animation System
Micro-interactions: Button presses, card taps, transitions

Page Transitions: Smooth navigation with staggered animations

Loading States: Beautiful skeleton UI with shimmer effects

Chart Animations: Elastic and bounce effects for data visualization

Color Palette
// Primary Colors
vibrantBlue: #2196F3
vibrantGreen: #4CAF50
warningOrange: #FF9800
darkOrangeRed: #FF5722
tealGreenDark: #00695C

// Gradients used throughout the app
cardGradients: Multiple gradient combinations
surfaceGradients: Subtle background enhancements

🔧 Configuration
SMS Processing Rules
The app uses intelligent SMS validation with scoring system:
// Validation Criteria (each adds to score)
- Banking sender pattern
- Transaction keywords
- Amount extraction
- Spam filtering
- OTP detection

Category Management
Default Categories: 6 pre-configured categories

Custom Categories: User-defined categories with icons and colors

Smart Assignment: AI-powered automatic categorization

Manual Override: User can reassign categories

📊 Analytics Engine
Metrics Tracked
Total Income/Expense: Period-based calculations

Savings Rate: Income vs expense ratio

Category Distribution: Spending breakdown by category

Trends Analysis: Monthly, weekly, and daily patterns

Average Calculations: Per transaction and per day averages

Insights Generation
Spending Patterns: Identifies high-spend categories

Savings Opportunities: Suggests areas for expense reduction

Budget Recommendations: AI-powered budgeting advice

Goal Tracking: Progress towards financial objectives

🔐 Privacy & Security
Data Protection
Local Storage: All data stored locally using Hive

No Cloud Sync: Data never leaves the device

SMS Privacy: Only transaction SMS processed, others ignored

Permission Management: Minimal required permissions

Security Features
Input Validation: All user inputs sanitized

Error Handling: Graceful error recovery

Memory Management: Proper disposal of resources

Data Encryption: Hive provides built-in encryption options

🛠️ Development Guidelines
Code Style
Dart Analysis: Strict linting rules enabled

Documentation: Comprehensive inline documentation

Error Handling: Try-catch blocks with user feedback

Performance: Optimized for 60fps animations

Testing Strategy
# Unit Tests
flutter test

# Widget Tests
flutter test test/widget_test.dart

# Integration Tests
flutter test integration_test/

Build & Deployment
# Debug Build
flutter build apk --debug

# Release Build
flutter build apk --release

# App Bundle (Google Play)
flutter build appbundle --release

🤝 Contributing
Development Setup
Fork the repository

Create feature branch: git checkout -b feature/amazing-feature

Follow code style guidelines

Add tests for new features

Submit pull request

Coding Standards
Use meaningful variable names

Add documentation for public methods

Follow Flutter/Dart conventions

Ensure responsive design compatibility

Test on multiple screen sizes

📱 Device Compatibility
Tested Devices
Android: 6.0+ (API level 23+)

Screen Sizes: 4" to 7" displays

Resolution: 720p to 1440p

RAM: 2GB minimum, 4GB+ recommended

Performance Benchmarks
App Launch: <3 seconds on mid-range devices

SMS Processing: <1 second per message

Chart Rendering: 60fps on supported devices

Memory Usage: <150MB typical usage

🐛 Known Issues & Solutions
Common Issues
SMS Permission Denied: Guide users through permission settings

Animation Lag: Fallback to reduced animations on low-end devices

Layout Overflow: Comprehensive responsive design prevents this

Memory Leaks: Proper widget disposal implemented

🔮 Roadmap
Upcoming Features
Export to Excel: CSV/Excel export functionality

Budgeting Tools: Set and track spending budgets

Receipt Scanning: OCR-based receipt processing

Backup/Restore: Cloud backup options

Multi-language: Localization support

Widgets: Home screen widgets for quick insights

Technical Improvements
Performance Optimization: Further memory usage reduction

Accessibility: Enhanced screen reader support

Testing: Comprehensive test coverage

CI/CD: Automated testing and deployment

📞 Support & Contact
Getting Help
Issues: GitHub Issues

Discussions: GitHub Discussions

Documentation: Check the /docs folder

Bug Reports
Please include:

Device model and Android version

App version

Steps to reproduce

Screenshots (if applicable)

Logs (if available)

📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments
Technologies Used
Flutter Team: Amazing framework and tools

Hive Team: Excellent local database solution

FL Chart: Beautiful charting library

Lottie: Smooth animations

Community: Stack Overflow and Flutter community

Special Thanks
Alpha testers for valuable feedback

Open source contributors

Design inspiration from leading fintech apps

<div align="center">
Built with ❤️ using Flutter

⭐ Star this repo • 🐛 Report Bug • ✨ Request Feature

</div> ```



