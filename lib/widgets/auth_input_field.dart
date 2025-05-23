import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool isPasswordField;
  final bool hidePassword;
  final bool isDark;
  final Function(String?)? onSaved;
  final FocusNode focusNode;
  final Function()? togglePasswordView;
  final double width;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.isPasswordField = false,
    this.hidePassword = false,
    required this.isDark,
    this.onSaved,
    required this.focusNode,
    required this.width,
    this.togglePasswordView,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final localizations = AppLocalizations.of(context)!;
    return SizedBox(
      width: width,
      child: TextFormField(
        focusNode: focusNode,
        controller: controller,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        obscureText: isPasswordField ? hidePassword : false,
        validator: (value) {
          if (value!.trim().isEmpty) {
            return localizations.required;
          }

          return null;
        },
        onSaved: onSaved,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: labelText,
          hintText: hintText,
          prefixIcon:
              Icon(prefixIcon, color: isDark ? Colors.white : Colors.black),
          suffixIcon: isPasswordField
              ? IconButton(
                  onPressed: togglePasswordView,
                  icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility),
                  color: isDark
                      ? Colors.white.withOpacity(0.8)
                      : Colors.black.withOpacity(0.4),
                )
              : null,
        ),
      ),
    );
  }
}
