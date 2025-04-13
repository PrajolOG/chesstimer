// lib/home.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for input formatters
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'timer.dart'; // Import your timer.dart file

// Constants for SharedPreferences keys
const String _prefsKeySelectedTime = 'selectedTime';
const String _prefsKeyCustomWhite = 'customWhite';
const String _prefsKeyCustomBlack = 'customBlack';
const String _prefsKeyCustomIncrement = 'customIncrement';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedTime = ''; // Holds preset ('5 | 3') or 'custom'
  Map<String, String> _savedCustomTime = {}; // Stores custom values as strings
  final TextEditingController _whiteController = TextEditingController();
  final TextEditingController _blackController = TextEditingController();
  // Note: _selectedIncrement is primarily managed within _savedCustomTime for custom
  String _selectedTimeDetails = ''; // To display selected time details

  bool _isLoading = true; // To show loading indicator while prefs load

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Load saved settings on startup
  }

  @override
  void dispose() {
    _whiteController.dispose();
    _blackController.dispose();
    super.dispose();
  }

  // --- Preference Management ---

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true); // Show loading indicator
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTime = prefs.getString(_prefsKeySelectedTime);

      if (savedTime != null && savedTime.isNotEmpty) {
        // Check if not empty
        _selectedTime = savedTime;
        if (_selectedTime == 'custom') {
          // Load custom settings, providing defaults if keys don't exist yet
          _savedCustomTime = {
            'white': prefs.getString(_prefsKeyCustomWhite) ?? '5',
            'black': prefs.getString(_prefsKeyCustomBlack) ?? '5',
            'increment': prefs.getString(_prefsKeyCustomIncrement) ?? '0',
          };
          // Pre-fill controllers for the dialog
          _whiteController.text = _savedCustomTime['white']!;
          _blackController.text = _savedCustomTime['black']!;
          _updateSelectedDetails(); // Update display
        } else {
          // It's a preset, just update the display
          _updateSelectedDetails();
        }
      } else {
        // No saved preference or it was empty, reset state
        _selectedTime = '';
        _savedCustomTime = {};
        _updateSelectedDetails();
      }
    } catch (e) {
      print("Error loading preferences: $e");
      // Handle error, maybe set defaults
      _selectedTime = '';
      _savedCustomTime = {};
      _updateSelectedDetails();
    } finally {
      if (mounted) {
        // Check if widget is still in the tree
        setState(() => _isLoading = false); // Hide loading indicator
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeySelectedTime, _selectedTime);

      if (_selectedTime == 'custom') {
        // Ensure we save valid values, even if map is somehow empty
        await prefs.setString(
          _prefsKeyCustomWhite,
          _savedCustomTime['white'] ?? '5',
        );
        await prefs.setString(
          _prefsKeyCustomBlack,
          _savedCustomTime['black'] ?? '5',
        );
        await prefs.setString(
          _prefsKeyCustomIncrement,
          _savedCustomTime['increment'] ?? '0',
        );
      } else {
        // Clear custom prefs when a preset is selected or when selection is cleared
        await prefs.remove(_prefsKeyCustomWhite);
        await prefs.remove(_prefsKeyCustomBlack);
        await prefs.remove(_prefsKeyCustomIncrement);
      }
    } catch (e) {
      print("Error saving preferences: $e");
      // Optionally show a message to the user
    }
  }

  // --- UI Building ---

  void _updateSelectedDetails() {
    if (_selectedTime.isEmpty) {
      _selectedTimeDetails = '';
    } else if (_selectedTime == 'custom') {
      if (_savedCustomTime.isNotEmpty) {
        // Use '??' to provide defaults if any value is unexpectedly null
        final white = _savedCustomTime['white'] ?? '?';
        final black = _savedCustomTime['black'] ?? '?';
        final increment = _savedCustomTime['increment'] ?? '?';
        _selectedTimeDetails =
            'White: $white min\nBlack: $black min\nIncrement: $increment sec';
      } else {
        _selectedTimeDetails = 'Custom (Tap to configure)'; // Guide user
      }
    } else {
      // It's a preset like "M | I"
      final parsed = _parsePresetTime(_selectedTime);
      _selectedTimeDetails =
          'Time: ${parsed['time']} min\nIncrement: ${parsed['increment']} sec';
    }
    // Update UI after changing details
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define common button style for consistency
    final ButtonStyle timeButtonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      elevation: 2, // Subtle elevation
    );

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Chess Clock Setup', // Descriptive title
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.grey[900], // Consistent dark theme
        elevation: 0, // Flat app bar
      ),
      backgroundColor: Colors.grey[900],
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: Colors.green[700]),
              ) // Loading indicator
              : Stack(
                children: [
                  SingleChildScrollView(
                    // Ensure content scrolls if screen is small
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'Select Time Control',
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // --- Time Preset Buttons Container ---
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    Colors
                                        .grey[850], // Slightly lighter background
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Wrap(
                                // Automatically wraps buttons
                                spacing: 12.0, // Horizontal space
                                runSpacing: 12.0, // Vertical space
                                alignment:
                                    WrapAlignment
                                        .center, // Center buttons horizontally
                                children: [
                                  // Popular Presets (M | I format)
                                  ...[
                                        '1 | 0',
                                        '1 | 1',
                                        '2 | 1',
                                        '3 | 0',
                                        '3 | 2',
                                        '5 | 0',
                                        '5 | 3',
                                        '10 | 0',
                                        '10 | 5',
                                        '15 | 10',
                                        '30 | 0',
                                        '60 | 0',
                                      ]
                                      .map(
                                        (time) => _buildTimeButton(
                                          time,
                                          timeButtonStyle,
                                        ),
                                      )
                                      .toList(),
                                  // Custom Button
                                  _buildCustomButton(timeButtonStyle),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            // --- Selected Details Display ---
                            AnimatedOpacity(
                              opacity:
                                  _selectedTimeDetails.isNotEmpty ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child:
                                  _selectedTimeDetails.isNotEmpty
                                      ? _buildSelectedDetailsDisplay()
                                      // Placeholder to prevent layout jump when details hide
                                      : const SizedBox(
                                        height: 70,
                                      ), // Match approx height of details box
                            ),
                            const SizedBox(height: 30),
                            // --- Start Game Button ---
                            ElevatedButton.icon(
                              icon: Icon(
                                Icons.play_arrow_rounded,
                                size: 28,
                                color:
                                    (_selectedTime.isNotEmpty &&
                                            !(_selectedTime == 'custom' &&
                                                _savedCustomTime.isEmpty))
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                              ),
                              label: Text(
                                'Start Game',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color:
                                      (_selectedTime.isNotEmpty &&
                                              !(_selectedTime == 'custom' &&
                                                  _savedCustomTime.isEmpty))
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                ),
                              ),
                              // Disable button if no time is selected OR if custom is selected but not configured
                              onPressed:
                                  (_selectedTime.isNotEmpty &&
                                          !(_selectedTime == 'custom' &&
                                              _savedCustomTime.isEmpty))
                                      ? _startGame
                                      : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 18,
                                ),
                                backgroundColor:
                                    Colors.green[700], // Active color
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                                // Style for disabled state
                                disabledBackgroundColor: Colors.grey[700]
                                    ?.withOpacity(0.7),
                                disabledForegroundColor: Colors.white
                                    .withOpacity(0.5),
                              ).copyWith(
                                overlayColor: MaterialStateProperty.resolveWith<
                                  Color?
                                >((Set<MaterialState> states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return Colors.green[800];
                                  }
                                  return null;
                                }),
                              ),
                            ),
                            const SizedBox(
                              height: 60,
                            ), // Bottom spacing before dev text
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  // --- Widget Builders ---

  Widget _buildSelectedDetailsDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(
        minHeight: 70,
      ), // Min height for consistency
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1.5,
        ), // Subtle border
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take only needed vertical space
        mainAxisAlignment:
            MainAxisAlignment.center, // Center content vertically
        children: [
          Text(
            "Current Selection:",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _selectedTimeDetails,
            textAlign: TextAlign.center, // Center the detail lines
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 1.4, // Improve line spacing for readability
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String timeValue, ButtonStyle baseStyle) =>
      ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedTime = timeValue; // Set the selected preset
            _updateSelectedDetails(); // Update the display text
          });
          _savePreferences(); // Save the new selection
        },
        // Apply base style and override background color based on selection
        style: baseStyle.copyWith(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((
            Set<MaterialState> states,
          ) {
            // Use green if this button's value matches the selected time
            return _selectedTime == timeValue
                ? Colors.green[700]!
                : Colors.grey[700]!;
          }),
        ),
        child: Text(timeValue), // Display the preset value (e.g., "5 | 3")
      );

  Widget _buildCustomButton(ButtonStyle baseStyle) => ElevatedButton.icon(
    icon: Icon(
      _selectedTime == 'custom' ? Icons.tune : Icons.add_circle_outline,
      size: 22, // Slightly larger icon
      color: Colors.white, // Explicit icon color
    ),
    label: const Text(
      'Custom',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white, // Explicit text color
      ),
    ),
    onPressed: () async {
      if (_selectedTime == 'custom') {
        // --- Toggle Off Custom ---
        // If custom is already selected, clicking again deselects it
        setState(() {
          _selectedTime = ''; // Clear the selection type
          // Keep _savedCustomTime data but don't display it
          _updateSelectedDetails(); // Update display to show nothing selected
        });
        _savePreferences(); // Save the cleared selection state
      } else {
        // --- Toggle On Custom / Show Dialog ---
        // If a preset or nothing was selected, switch to custom and show dialog
        final result = await showDialog<Map<String, String>>(
          context: context,
          barrierDismissible: false, // User must explicitly save or cancel
          builder:
              (context) => CustomTimeDialog(
                // Pass existing custom values (if any) or null
                initialWhiteTime: _savedCustomTime['white'],
                initialBlackTime: _savedCustomTime['black'],
                initialIncrement: _savedCustomTime['increment'],
                // Pass controllers for the dialog to use and potentially update
                whiteController: _whiteController,
                blackController: _blackController,
              ),
        );

        // --- Handle Dialog Result ---
        if (result != null) {
          // If dialog returned data (Save was pressed)
          setState(() {
            _selectedTime = 'custom'; // Set selection type to custom
            _savedCustomTime = result; // Store the returned custom values
            // Ensure controllers reflect the saved values (important if dialog modified them)
            _whiteController.text = result['white'] ?? '';
            _blackController.text = result['black'] ?? '';
            _updateSelectedDetails(); // Update the details display
          });
          _savePreferences(); // Save the new custom configuration
        } else {
          // If dialog was cancelled (returned null), do nothing to the selection state.
          // The user might have had a preset selected before clicking custom,
          // and cancelling shouldn't change that.
        }
      }
    },
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      backgroundColor:
          _selectedTime == 'custom' ? Colors.green[700] : Colors.blueGrey[600],
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.white.withOpacity(0.6),
      elevation: _selectedTime == 'custom' ? 3 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color?>((
        Set<MaterialState> states,
      ) {
        if (states.contains(MaterialState.pressed)) {
          return _selectedTime == 'custom'
              ? Colors.green[800]
              : Colors.blueGrey[700];
        }
        return null;
      }),
    ),
  );

  // --- Logic ---

  // Parses preset strings like "5 | 3" into time and increment integers
  Map<String, int> _parsePresetTime(String preset) {
    final parts = preset.split('|').map((e) => e.trim()).toList();
    if (parts.length == 2) {
      return {
        'time': int.tryParse(parts[0]) ?? 5, // Default to 5 min if parse fails
        'increment':
            int.tryParse(parts[1]) ?? 0, // Default to 0 sec if parse fails
      };
    }
    // Fallback for unexpected format
    return {'time': 5, 'increment': 0};
  }

  // Validates selected time and navigates to TimerPage
  void _startGame() {
    int whiteMinutes = 0;
    int blackMinutes = 0;
    int incrementSeconds = 0;

    // Handle case where no time is selected (should be prevented by button state, but check anyway)
    if (_selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time control first!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Determine time values based on selection type
    if (_selectedTime != 'custom') {
      // Preset selected
      final parsedTime = _parsePresetTime(_selectedTime);
      whiteMinutes = parsedTime['time']!;
      blackMinutes = parsedTime['time']!;
      incrementSeconds = parsedTime['increment']!;
    } else {
      // Custom selected
      // Ensure custom data is actually available before parsing
      if (_savedCustomTime.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Custom time not configured. Tap "Custom" to set times.',
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }
      whiteMinutes = int.tryParse(_savedCustomTime['white'] ?? '0') ?? 0;
      blackMinutes = int.tryParse(_savedCustomTime['black'] ?? '0') ?? 0;
      incrementSeconds =
          int.tryParse(_savedCustomTime['increment'] ?? '0') ?? 0;
    }

    // --- Final Validation Before Starting ---
    if (whiteMinutes <= 0 || blackMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Time must be greater than 0 minutes for both players.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (incrementSeconds < 0) {
      // Should be impossible with dropdown, but check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Increment cannot be negative.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // If all checks pass, navigate to TimerPage
    print(
      'Starting Game -> White: $whiteMinutes min, Black: $blackMinutes min, Increment: $incrementSeconds sec',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the validated and determined times to the TimerPage
        builder:
            (context) => TimerPage(
              whiteTime: whiteMinutes,
              blackTime: blackMinutes,
              increment: incrementSeconds,
            ),
      ),
    );
  }
}

// =========================================================================
// Custom Time Dialog Widget (Refined Styling & Logic)
// =========================================================================

class CustomTimeDialog extends StatefulWidget {
  // Initial values passed from HomePage (can be null)
  final String? initialWhiteTime;
  final String? initialBlackTime;
  final String? initialIncrement;
  // Controllers are managed by HomePage but used here
  final TextEditingController whiteController;
  final TextEditingController blackController;

  const CustomTimeDialog({
    Key? key,
    this.initialWhiteTime,
    this.initialBlackTime,
    this.initialIncrement,
    required this.whiteController,
    required this.blackController,
  }) : super(key: key);

  @override
  _CustomTimeDialogState createState() => _CustomTimeDialogState();
}

class _CustomTimeDialogState extends State<CustomTimeDialog> {
  // Local state for the selected increment within the dialog
  late String _selectedIncrement;
  // Local state for validation errors
  String? _whiteError;
  String? _blackError;
  // Available increment options
  final List<String> _incrementOptions = [
    "0",
    "1",
    "2",
    "3",
    "5",
    "10",
    "15",
    "20",
    "30",
    "60",
  ];

  @override
  void initState() {
    super.initState();
    // --- Initialize Dialog State ---
    // Set text in controllers based on initial values passed from HomePage
    // Use existing text if available (e.g., user opened dialog, edited, cancelled, reopened)
    // Fallback to initial values if controller is empty
    widget.whiteController.text =
        widget.whiteController.text.isNotEmpty
            ? widget.whiteController.text
            : widget.initialWhiteTime ?? '';
    widget.blackController.text =
        widget.blackController.text.isNotEmpty
            ? widget.blackController.text
            : widget.initialBlackTime ?? '';

    // Set the initial dropdown selection. Prioritize the value passed in.
    // Default to "0" if the passed value is null or not in the options list.
    _selectedIncrement = widget.initialIncrement ?? "0";
    if (!_incrementOptions.contains(_selectedIncrement)) {
      _selectedIncrement = "0"; // Ensure a valid default
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor:
          Colors.grey[850], // Dark background consistent with theme
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ), // Smooth corners
      titlePadding: const EdgeInsets.only(top: 20, bottom: 5),
      title: const Text(
        "Custom Time Settings",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      content: SingleChildScrollView(
        // Allow scrolling if content overflows
        child: Column(
          mainAxisSize: MainAxisSize.min, // Take minimum vertical space
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch children horizontally
          children: [
            // White Time Input Field
            _buildTimeField(
              "White Time (min)",
              widget.whiteController,
              _whiteError,
            ),
            const SizedBox(height: 15),
            // Black Time Input Field
            _buildTimeField(
              "Black Time (min)",
              widget.blackController,
              _blackError,
            ),
            const SizedBox(height: 20),
            // Increment Dropdown Label
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Increment (seconds)",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // Increment Dropdown
            _buildIncrementDropdown(),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        15,
      ), // Padding around buttons
      actionsAlignment: MainAxisAlignment.spaceBetween, // Space out buttons
      actions: [
        // --- Cancel Button ---
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: BorderSide(color: Colors.grey[600]!), // Subtle border
            foregroundColor: Colors.white.withOpacity(
              0.8,
            ), // Less prominent text color
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: () {
            // Don't revert controllers here; HomePage handles state on null result
            Navigator.of(context).pop(); // Return null to indicate cancellation
          },
          child: const Text("Cancel"),
        ),
        // --- Save Button ---
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700], // Primary action color
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            foregroundColor: Colors.white, // Text color
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            // Validate fields before closing
            if (_validateFields()) {
              // Pop with the current values if valid
              Navigator.of(context).pop({
                'white': widget.whiteController.text,
                'black': widget.blackController.text,
                'increment':
                    _selectedIncrement, // Use the dialog's selected increment
              });
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }

  // Validates the time input fields
  bool _validateFields() {
    // Clear previous errors
    setState(() {
      _whiteError = null;
      _blackError = null;
    });
    bool isValid = true;
    final whiteText = widget.whiteController.text.trim(); // Trim whitespace
    final blackText = widget.blackController.text.trim();

    // Validate White Time
    if (whiteText.isEmpty) {
      setState(() => _whiteError = "Time required");
      isValid = false;
    } else {
      int? whiteTime = int.tryParse(whiteText);
      if (whiteTime == null) {
        setState(() => _whiteError = "Invalid number");
        isValid = false;
      } else if (whiteTime <= 0) {
        setState(() => _whiteError = "Must be > 0 min");
        isValid = false;
      } else if (whiteTime > 240) {
        // Max limit (e.g., 4 hours)
        setState(() => _whiteError = "Max 240 min");
        isValid = false;
      }
    }

    // Validate Black Time
    if (blackText.isEmpty) {
      setState(() => _blackError = "Time required");
      isValid = false;
    } else {
      int? blackTime = int.tryParse(blackText);
      if (blackTime == null) {
        setState(() => _blackError = "Invalid number");
        isValid = false;
      } else if (blackTime <= 0) {
        setState(() => _blackError = "Must be > 0 min");
        isValid = false;
      } else if (blackTime > 240) {
        setState(() => _blackError = "Max 240 min");
        isValid = false;
      }
    }

    // No need to validate increment selection as dropdown enforces valid options

    return isValid; // Return overall validity
  }

  // Builds a styled TextField for time input
  Widget _buildTimeField(
    String label,
    TextEditingController controller,
    String? errorText,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number, // Show numeric keyboard
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ], // Allow only numbers
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        hintText: "e.g., 10", // Example hint
        hintStyle: TextStyle(color: Colors.grey[600]),
        errorText: errorText, // Display validation error message
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
        // Consistent border styling for all states
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          // Highlight when focused
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green[600]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          // Border style when error exists
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          // Border style when error exists and focused
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        filled: true, // Fill the background
        fillColor: Colors.grey[800], // Background color of the field
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        isDense: true, // Make field slightly more compact
      ),
      // Clear the specific error message when the user types
      onChanged:
          (_) => setState(() {
            if (controller == widget.whiteController && _whiteError != null)
              _whiteError = null;
            if (controller == widget.blackController && _blackError != null)
              _blackError = null;
          }),
    );
  }

  // Builds a styled DropdownButtonFormField for increment selection
  Widget _buildIncrementDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedIncrement, // Current selection in the dialog state
      dropdownColor: Colors.grey[800], // Background color of the dropdown menu
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        // Match TextField styling for consistency
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[800], // Field background
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ), // Internal padding
        isDense: true, // Compact style
      ),
      items:
          _incrementOptions.map((String option) {
            // Create a dropdown item for each option
            return DropdownMenuItem<String>(
              value: option,
              // Display "0 sec" for clarity, otherwise add " sec" suffix
              child: Text(
                option == "0" ? "0 sec" : "$option sec",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
      // Update the dialog's local state when a new option is selected
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedIncrement = newValue;
          });
        }
      },
    );
  }
}
