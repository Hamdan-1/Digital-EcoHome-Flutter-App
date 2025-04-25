# Digital EcoHome - Smart Home Energy Management System

<div align="center">
  <img src="Digital EcoHome logo Light Mode.png" alt="Digital EcoHome Logo" width="300">
</div>

## AUS Senior Design Project - Submission for AUS Competition 2025

**Team: The Digital Trailblazers**
- Ahmad Suleiman (Advisor)
- Hamdan Moohialdin (Lead App Developer)
- Mubarak Bushra (Developer and Hardware Engineer)
- Mustafa Amer (UI/UX Designer)
## Project Structure

The project is organized into several directories and files, each serving a specific purpose. Below is a detailed breakdown of the project structure and the functionality of each file and directory.

### Main Components

#### `lib/main.dart`
- Initializes the Flutter app, sets up providers and services, and defines the main navigation structure.

#### `lib/models/app_state.dart`
- Manages the app's state, including device management, energy usage simulation, and gamification logic.

### Directories

#### `lib/pages`
- Contains various pages for the app, such as:
  - `dashboard_page.dart`: Displays the main dashboard with energy usage data and controls.
  - `devices_page.dart`: Lists and manages connected devices.
  - `settings_page.dart`: Provides settings and configuration options.
  - `sustainability_score_page.dart`: Shows the user's sustainability score and related metrics.

#### `lib/widgets`
- Contains reusable widgets like:
  - `usage_chart.dart`: Displays energy usage data in a chart format.
  - `notification_panel.dart`: Shows notifications and alerts.
  - `score_gauge.dart`: Displays the user's sustainability score.
  - `achievement_badge.dart`: Shows badges for achievements earned by the user.

#### `lib/services`
- Contains service files like:
  - `ai_service.dart`: Manages AI-related functionalities.
  - `notification_service.dart`: Handles in-app notifications.
  - `recommendation_service.dart`: Provides energy-saving recommendations.

#### `lib/theme.dart`
- Defines the app's theme and colors.

#### `lib/themes/app_themes.dart`
- Contains specific theme configurations.

#### `lib/providers/theme_provider.dart`
- Manages the app's theme state and provides methods to switch between themes.

#### `lib/utils`
- Contains utility files like:
  - `animations.dart`: Provides custom animations.
  - `custom_page_transitions.dart`: Defines custom page transitions.
  - `error_handler.dart`: Handles errors and exceptions.
  - `notification_helper.dart`: Provides helper methods for notifications.

#### `lib/models`
- Contains various data models used in the app, such as:
  - `app_state.dart`: Manages the app's state.
  - `data_status.dart`: Defines the status of data operations.
  - `gamification.dart`: Manages gamification logic and data.
  - `sustainability_score.dart`: Defines the sustainability score model.
  - Settings-related models:
    - `app_settings.dart`
    - `user_preferences.dart`
    - `home_configuration.dart`
    - `device_management.dart`
    - `advanced_settings.dart`

#### `lib/pages/device_control`
- Contains pages for controlling specific devices, such as:
  - `ac_control_page.dart`: Controls the air conditioner.
  - `light_control_page.dart`: Controls the lights.
  - `washing_machine_control_page.dart`: Controls the washing machine.

#### `lib/widgets/demo`
- Contains widgets related to demo mode, such as:
  - `ui_highlighter.dart`: Highlights UI elements in demo mode.

#### `lib/models/simulation`
- Contains models related to IoT simulation, such as:
  - `device_behavior.dart`
  - `device_discovery.dart`
  - `energy_usage_simulator.dart`
  - `iot_simulation_controller.dart`

#### `lib/models/reports`
- Contains models related to energy reports, such as:
  - `energy_report_model.dart`
  - `energy_report.dart`

#### `lib/models/settings`
- Contains models related to app settings, such as:
  - `app_settings.dart`
  - `user_preferences.dart`
  - `home_configuration.dart`
  - `device_management.dart`
  - `advanced_settings.dart`
---

## Table of Contents
- [Project Overview](#project-overview)
- [Innovation and Impact](#innovation-and-impact)
- [Key Features](#key-features)
- [Technical Architecture](#technical-architecture)
- [Hardware Integration](#hardware-integration)
- [Sustainability Impact](#sustainability-impact)
- [Installation Guide](#installation-guide)
- [User Manual](#user-manual)
- [System Requirements](#system-requirements)
- [Future Development](#future-development)
- [Awards and Recognition](#awards-and-recognition)
- [Contact Information](#contact-information)

---

## Project Overview

Digital EcoHome is a comprehensive smart home energy management system designed to address the growing concern of energy consumption and environmental sustainability. By combining cutting-edge IoT technology with intuitive mobile software, our solution empowers homeowners to monitor, analyze, and optimize their energy usage in real-time.

**Mission Statement:** To reduce residential energy consumption by providing users with actionable insights, intelligent automation, and personalized recommendations, ultimately contributing to a more sustainable future.

**Problem Statement:** The average household wastes 20-30% of its energy due to inefficient device usage, lack of awareness about consumption patterns, and absence of timely feedback mechanisms. Traditional solutions either lack user engagement or provide only partial monitoring, missing the opportunity to create lasting behavioral changes toward sustainable living.

**Our Solution:** Digital EcoHome offers a holistic approach through:
- Real-time energy monitoring across all connected devices
- AI-powered analysis and personalized recommendations
- Gamification of energy conservation through challenges and rewards
- Seamless integration with smart home devices
- Educational components to foster sustainable habits

---

## Innovation and Impact

### Innovative Aspects
1. **Holistic Device Integration:** Unlike existing solutions focused on individual appliances, Digital EcoHome provides a unified platform for comprehensive home energy management.

2. **AI-Powered Recommendations:** Our system leverages machine learning to analyze usage patterns and provide personalized energy-saving recommendations based on the specific household profile, evolving as usage patterns change.

3. **Sustainability Gamification:** The app transforms energy conservation from a chore into an engaging activity through challenges, achievements, and a sustainability score system.

4. **Behavioral Science Approach:** Digital EcoHome is built on behavioral psychology principles to create lasting habit changes, not just temporary modifications.

5. **Multi-dimensional Analysis:** The system considers various factors including time of day, seasonal variations, occupancy patterns, and local energy pricing to optimize recommendations.

### Projected Impact
- **Energy Savings:** Average household reduction of 15-25% in energy consumption
- **Environmental Impact:** Potential annual reduction of 1.8 tons of CO₂ emissions per household
- **Financial Benefit:** Estimated savings of AED 2,400-3,600 annually per household
- **Awareness Increase:** 40% improvement in user understanding of energy consumption patterns

---

## Key Features

### 1. Intuitive Dashboard
- At-a-glance view of current energy usage
- Real-time device status and consumption metrics
- Dynamic forecasting of monthly usage and costs
- Weather-adaptive recommendations

### 2. Comprehensive Device Management
- Automatic device discovery and integration
- Individual device monitoring and control
- Usage pattern analysis for each device
- Energy efficiency ranking and recommendations

### 3. Detailed Energy Reports
- Daily, weekly, monthly, and annual consumption reports
- Device-specific and category-based breakdowns
- Comparative analysis with previous periods
- Cost projection and saving opportunities
- CO₂ emission tracking

### 4. AI-Driven Energy Assistant
- Natural language interface for energy-related queries
- Personalized energy-saving recommendations
- Anomaly detection and alerts
- Usage pattern analysis and insights

### 5. Sustainability Scoring System
- Dynamic sustainability score based on energy usage
- Personalized challenges and goals
- Achievements and rewards for energy conservation
- Community comparisons and leaderboards

### 6. Smart Automation
- Schedule-based device management
- Occupancy-based optimization
- Peak energy usage avoidance
- Eco-mode scheduling and optimization

### 7. Educational Resources
- Energy conservation tips and guides
- Environmental impact visualization
- Learning modules for sustainable living
- Regular updates on energy-saving technologies

---

## Technical Architecture

### Software Components
- **Frontend:** Flutter-based cross-platform application providing a unified experience across iOS, Android, and web platforms
- **State Management:** Provider pattern implementation for efficient app-wide state management
- **Visualization:** Custom charting implementation using FL Chart for intuitive data representation
- **AI Integration:** OpenRouter API integration for intelligent recommendations and natural language processing
- **Theme System:** Adaptable UI with support for light/dark modes and accessibility features
- **Gamification Engine:** Custom-built system for challenges, achievements, and sustainability scoring

### Technology Stack
- **Cross-Platform Framework:** Flutter/Dart
- **State Management:** Provider package
- **Data Visualization:** FL Chart
- **Local Storage:** Shared Preferences
- **API Communication:** HTTP package
- **AI Services:** OpenRouter API

### Architecture Pattern
The application follows a modified MVVM (Model-View-ViewModel) architecture:
- **Models:** Core data structures for devices, reports, settings, and gamification
- **Views:** UI components and pages for user interaction
- **Services:** Business logic and external API integration
- **State Management:** Centralized state handling through AppState and specialized providers

### Design Principles
- **Separation of Concerns:** Clear distinction between UI, business logic, and data management
- **Reactive Programming:** State-driven UI updates for a responsive user experience
- **Progressive Disclosure:** Information presented in layered approach from overview to details
- **Accessibility First:** Designed with accessibility guidelines in mind
- **Offline Functionality:** Core features available without internet connectivity

---

## Hardware Integration

Digital EcoHome integrates with smart home hardware components to provide comprehensive monitoring and control:

### Supported Hardware
- **Smart Plugs/Outlets:** For individual device monitoring and control
- **Smart Thermostats:** For HVAC energy optimization
- **Smart Lighting Systems:** For lighting efficiency management
- **Water Monitors:** For tracking water heater and appliance usage
- **Motion and Occupancy Sensors:** For presence-based optimizations

### Integration Approach
- **Arduino-based Controller:** Central communication hub for various sensors
- **WiFi Connectivity:** Wireless communication between devices and app
- **Sensor Array:** Multiple sensor types for comprehensive environmental monitoring:
  - Temperature and humidity sensors
  - Light level sensors
  - Motion detection sensors
  - Power consumption sensors
  - Water flow sensors

### Custom Hardware Components
- **Arduino WiFi Shield:** Enables wireless communication
- **Current Sensors:** Non-invasive monitoring of electrical consumption
- **Custom PCB Design:** Optimized for low power consumption and reliability

---

## Sustainability Impact

Digital EcoHome is designed with sustainability at its core, offering multiple pathways to environmental impact:

### Direct Energy Savings
- **Device Optimization:** Intelligent scheduling and management of energy-intensive appliances
- **Idle Power Reduction:** Identification and elimination of phantom power consumption
- **Peak Usage Avoidance:** Shifting energy consumption away from peak demand periods

### Behavioral Change
- **Awareness Building:** Visualizing energy consumption and its environmental impact
- **Habit Formation:** Gamification techniques to establish sustainable routines
- **Educational Content:** Increasing knowledge about energy conservation

### Environmental Metrics
- **Carbon Footprint Tracking:** CO₂ emission visualization based on energy usage
- **Resource Conservation:** Water usage monitoring for comprehensive resource management
- **Sustainability Score:** Holistic assessment of household environmental impact

### Long-term Impact
- **Community Effect:** Neighborhood comparisons to encourage community-wide conservation
- **Data Collection:** Anonymous aggregation of usage patterns for research and improvement
- **Ecosystem Contribution:** API for integration with broader sustainability initiatives

---

## Installation Guide

### Prerequisites
- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 2.17.0 or higher)
- Android Studio / Xcode for mobile deployment
- Git

### Setting Up Development Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Hamdan-1/Digital-EcoHome-Flutter-App.git
   ```

2. **Navigate to the project directory:**
   ```bash
   cd Digital-EcoHome-Flutter-App
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the application:**
   - For mobile debugging:
     ```bash
     flutter run
     ```
   - For web deployment:
     ```bash
     flutter build web --base-href="/Digital-EcoHome-Flutter-App/" --no-tree-shake-icons
     ```

### Hardware Setup (Optional)
For full functionality with hardware components:

1. **Arduino Setup:**
   - Flash the `digital_ecohome_wifi.ino` file to your Arduino board with WiFi capabilities
   - Connect the sensors according to the wiring diagram in the documentation
   - Configure the WiFi settings in the Arduino code to match your network

2. **Network Configuration:**
   - Ensure your smart devices and Arduino controller are on the same network
   - Configure port forwarding if accessing remotely

3. **Device Pairing:**
   - Use the "Scan for Devices" feature in the app to discover and pair with hardware

---

## User Manual

### Getting Started
1. **Initial Setup:**
   - Complete the onboarding process to set up your home profile
   - Enter your home details (size, occupants, location)
   - Set energy cost parameters based on your utility provider

2. **Device Discovery:**
   - Navigate to the Devices section
   - Tap "Scan for Devices" to find compatible smart devices
   - Follow the on-screen instructions to pair and configure each device

3. **Dashboard Navigation:**
   - View current energy status and active devices
   - Track your sustainability score
   - Access quick controls for commonly used functions

### Key Features Guide

#### Energy Monitoring
- **Real-time Updates:** Dashboard shows current consumption
- **Device-Specific Data:** Tap on any device to view detailed usage
- **History View:** Swipe charts to view historical data

#### Reports and Analysis
- **Time Range Selection:** Toggle between day, week, month, and year views
- **Comparison Mode:** Enable to compare with previous periods
- **Export Function:** Share reports via email or save as PDF

#### Sustainability Score
- **Score Components:** View the factors affecting your score
- **Improvement Tips:** Access personalized recommendations
- **Challenges:** Participate in energy-saving challenges

#### Device Control
- **Manual Control:** Directly toggle devices on/off
- **Scheduling:** Set up automatic schedules for each device
- **Eco Mode:** One-tap activation of energy-saving configurations

#### AI Assistant
- **Natural Queries:** Ask questions about your energy usage
- **Command Support:** Control devices through conversation
- **Learning Resources:** Request energy-saving tips and information

---

## System Requirements

### Mobile Application
- **Android:** Version 8.0 (Oreo) or higher
- **iOS:** Version 13 or higher
- **Storage:** 100MB minimum free space
- **RAM:** 2GB minimum recommended

### Web Application
- **Browsers:** Chrome, Firefox, Safari, Edge (latest versions)
- **JavaScript:** Enabled
- **LocalStorage:** Enabled for offline capabilities

### Hardware Components (Optional)
- **Arduino:** Arduino Uno/Mega with WiFi shield or ESP8266/ESP32
- **Sensors:** Compatible temperature, light, motion, and power sensors
- **Network:** 2.4GHz WiFi network (802.11 b/g/n)
- **Power:** Stable power source for continuous operation

---

## Future Development

Our roadmap for Digital EcoHome includes:

### Short-term (6-12 months)
- Integration with additional smart home ecosystems (Google Home, Apple HomeKit)
- Advanced machine learning algorithms for more precise consumption predictions
- Community features for sharing tips and comparing sustainability efforts
- Expanded sensor capabilities for more granular monitoring

### Medium-term (1-2 years)
- Solar panel integration and renewable energy tracking
- Electric vehicle charging management and optimization
- Water conservation monitoring and recommendations
- API ecosystem for third-party developer integrations

### Long-term Vision (3-5 years)
- Predictive maintenance for home appliances based on energy signatures
- Neighborhood-level energy optimization and grid integration
- Carbon offset program integration
- AI-driven home energy autonomy systems
---

## Contact Information

### Development Team
- **Email:** b00108790@aus.edu
- **GitHub:** [github.com/Hamdan-1/Digital-EcoHome-Flutter-App](https://github.com/Hamdan-1/Digital-EcoHome-Flutter-App)
---

<div align="center">
  <p>© 2025 Digital Trailblazers Team - American University of Sharjah</p>
  Licensed under the CC0-1.0 License See the [LICENSE](LICENSE) file for details.
</div>
