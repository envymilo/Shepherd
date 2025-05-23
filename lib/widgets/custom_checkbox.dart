import 'package:flutter/material.dart';

class CustomCheckboxField extends StatefulWidget {
  final String enabledLabel;
  final String disabledLabel;
  final Icon enabledIcon;
  final Icon disabledIcon;
  final ValueChanged<bool>? onChanged; // Add callback for value changes

  const CustomCheckboxField({
    super.key,
    required this.enabledLabel,
    required this.disabledLabel,
    required this.enabledIcon,
    required this.disabledIcon,
    this.onChanged, // Optional callback for parent notification
  });

  @override
  CustomCheckboxFieldState createState() => CustomCheckboxFieldState();
}

class CustomCheckboxFieldState extends State<CustomCheckboxField> {
  bool isPublic = false;
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.0),
        border: isDark
            ? Border.all(
                color:
                    Colors.grey.withOpacity(0.3), // Border color in dark mode
                width: 1.5, // Border width
              )
            : null, // No border in light mode
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.grey
                      .withOpacity(0.2), // Shadow color in light mode
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(-2, 2), // Shadow on left and bottom
                ),
              ]
            : [], // No shadow in dark mode
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: TextFormField(
            enabled: false,
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(
              icon: isPublic ? widget.enabledIcon : widget.disabledIcon,
              border: InputBorder.none,
              labelText: isPublic ? widget.enabledLabel : widget.disabledLabel,
            ),
          ),
          value: isPublic,
          onChanged: (value) {
            setState(() {
              isPublic = value!;
              widget.onChanged?.call(isPublic); // Call the parent callback
            });
          },
          controlAffinity: ListTileControlAffinity.trailing,
          checkColor: Colors.white,
          activeColor: Colors.blue,
          tileColor: Colors.transparent,
        ),
      ),
    );
  }
}
