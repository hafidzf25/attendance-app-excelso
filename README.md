# Excelso Attendance App

A Flutter mobile application for employee attendance tracking with GPS location validation and photo capture.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── constants/
│   ├── colors.dart                    # App color palette & gradients
│   ├── strings.dart                   # App-wide string constants
│   └── index.dart                     # Barrel export
├── services/
│   ├── location_service.dart          # Singleton: GPS location handling
│   ├── camera_service.dart            # Singleton: Camera & photo processing
│   └── index.dart                     # Barrel export
├── pages/
│   ├── welcome_page.dart              # Entry page with location info
│   ├── attendance_page.dart           # Main attendance (Check In/Out)
│   └── camera_page.dart               # Camera preview & photo capture
├── widgets/
│   ├── circular_action_button.dart    # Reusable action button
│   ├── welcome_header.dart            # Welcome screen header
│   ├── location_info.dart             # Location display widget
│   ├── clock_display.dart             # Real-time clock widget
│   ├── shift_selection_modal.dart     # Shift picker modal
│   ├── form_text_field.dart           # Reusable text input
│   ├── form_dropdown.dart             # Reusable dropdown
│   ├── form_buttons.dart              # Reusable button group
│   └── index.dart                     # Barrel export
├── utils/
│   ├── image_utils.dart               # Image processing helpers
│   └── index.dart                     # Barrel export
└── assets/images/                     # App logos & images
```

## Key Features

### 1. Location Services
- Real-time GPS location tracking
- Mock location detection via `position.isMocked`
- Location permission handling
- Accuracy validation (future)

### 2. Camera & Photo Capture
- Front camera selfie mode
- Automatic photo mirroring normalization
- Public Pictures folder storage (visible in gallery)
- No microphone/audio permission required

### 3. Attendance Tracking
- Check In: Requires shift selection + photo
- Check Out: Direct photo capture
- Real-time clock display

### 4. Responsive UI
- Phone & tablet support
- Material Design components
- Reusable widgets

## Service Architecture (Singleton Pattern)

```dart
// Usage throughout app
final locationService = LocationService();
final cameraService = CameraService();
```

## Dependencies

```yaml
flutter, permission_handler, geolocator, intl, camera, path_provider, image
```

## Android Permissions

- `CAMERA` - Photo capture
- `ACCESS_FINE_LOCATION` - GPS
- `WRITE_EXTERNAL_STORAGE` - Photo storage
- Audio permission removed (enableAudio: false)

## Building

```bash
flutter pub get
flutter run
```
