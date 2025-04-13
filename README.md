# Chess Timer

A modern, feature-rich chess timer application built with Flutter. This app provides a sleek and intuitive interface for managing time controls in chess games.

## Features

### Time Controls
- Multiple preset time controls (1|0, 3|2, 5|0, etc.)
- Custom time settings with increment support
- Time display in minutes and seconds
- Move counter for both players

### Game Controls
- Start/Pause functionality
- Reset game option
- Player resignation
- Settings access during game

### Visual Feedback
- Active player highlighting
- Low time warning with animation
- Game over status display
- Pause overlay
- Rotated display for opposite player

### Audio & Haptic Feedback
- Move confirmation sounds
- Game over sound
- Haptic feedback on moves
- Low latency sound processing

## Technical Details

### Dependencies
```yaml
flutter:
  sdk: flutter
audioplayers: ^5.2.1
```

### Core Components
- Stateful timer management
- Custom animations for low time warning
- Sound effect handling with AudioPlayer
- Haptic feedback integration
- Responsive layout design

## Installation

1. Clone the repository:
```bash
git clone https://github.com/PrajolOG/chesstimer.git
```

2. Navigate to project directory:
```bash
cd chesstimer
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Usage

1. **Select Time Control**
   - Choose from preset time controls
   - Or create custom time settings

2. **During Game**
   - Tap player's area to start/switch turns
   - Use control bar for game management
   - Monitor moves and remaining time

3. **Game End**
   - Automatic timeout detection
   - Manual resignation option
   - Clear winner indication

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)
