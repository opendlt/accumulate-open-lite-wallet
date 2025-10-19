import 'package:flutter/material.dart';
import 'dart:math' as math; // Import math library for pi

class CustomNavBar extends StatefulWidget {
  final Function(bool) onToggle1Changed;
  final Function(bool) onToggle2Changed;
  final Function(bool) onToggle3Changed;
  final Function(bool) onToggle4Changed; // New callback for the Sign toggle

  const CustomNavBar({
    super.key,
    required this.onToggle1Changed,
    required this.onToggle2Changed,
    required this.onToggle3Changed,
    required this.onToggle4Changed, // Add new required parameter
  });

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  bool toggle1 = false;
  bool toggle2 = false;
  bool toggle3 = false; // State for the Vote toggle
  bool toggle4 = false; // State for the Sign toggle

  @override
  Widget build(BuildContext context) {
    final paddingBottom = MediaQuery.of(context).padding.bottom +
        20; // Additional padding for visibility
    const double navBarHeight =
        90; // Adjusted nav bar height to accommodate four toggles

    return Container(
      height: navBarHeight + paddingBottom,
      padding: EdgeInsets.only(bottom: paddingBottom),
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle Switch 1 for Tokens
          _buildToggleColumn(
              toggle1, widget.onToggle1Changed, Icons.transform, 'Tokens'),
          // Toggle Switch 2 for Data
          _buildToggleColumn(
              toggle2, widget.onToggle2Changed, Icons.data_usage, 'Data'),
          // Toggle Switch 3 for Vote
          // Hiding Vote - TODO - IN DEV -
          // Comment out the line below to hide the vote screen
          // _buildToggleColumn(toggle3, widget.onToggle3Changed, Icons.how_to_vote, 'Vote'),
          // Toggle Switch 4 for Sign - New addition
          _buildToggleColumn(
              toggle4, widget.onToggle4Changed, Icons.edit, 'Sign'),
        ],
      ),
    );
  }

  // Helper method to build each toggle column
  Widget _buildToggleColumn(
      bool toggle, Function(bool) onChanged, IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -math.pi / 2,
          child: Switch(
            value: toggle,
            onChanged: (value) => setState(() {
              onChanged(value);
              // Reset other toggles to false when one is turned on
              if (label == 'Tokens') {
                toggle1 = value;
                toggle2 = false;
                toggle3 = false;
                toggle4 = false;
              } else if (label == 'Data') {
                toggle2 = value;
                toggle1 = false;
                toggle3 = false;
                toggle4 = false;
              } else if (label == 'Vote') {
                toggle3 = value;
                toggle1 = false;
                toggle2 = false;
                toggle4 = false;
              } else if (label == 'Sign') {
                toggle4 = value;
                toggle1 = false;
                toggle2 = false;
                toggle3 = false;
              }
            }),
          ),
        ),
        Text(label),
      ],
    );
  }
}
