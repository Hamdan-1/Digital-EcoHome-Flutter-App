# Digital EcoHome Flutter App

## Project Overview

The Digital EcoHome Flutter App is a comprehensive application designed to help users monitor and manage their home's energy usage. The app provides real-time data, energy-saving tips, and gamification features to encourage sustainable living.

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

## Getting Started

To get started with the Digital EcoHome Flutter App, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/Hamdan-1/Digital-EcoHome-Flutter-App.git
   ```

2. Navigate to the project directory:
   ```bash
   cd Digital-EcoHome-Flutter-App
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

For more information on Flutter development, visit the [Flutter documentation](https://docs.flutter.dev/).

## Contributing

Contributions are welcome! If you have any suggestions or improvements, please create an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
