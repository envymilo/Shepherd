import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/formatter/avatar.dart';
import 'package:shepherd_mo/models/user.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/services/get_login.dart';
import 'package:shepherd_mo/utils/toast.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ChangePasswordPageState createState() => ChangePasswordPageState();
}

class ChangePasswordPageState extends State<ChangePasswordPage> {
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  var emailController = TextEditingController();
  var currentPasswordController = TextEditingController();
  var newPasswordController = TextEditingController();
  var confirmPasswordController = TextEditingController();
  final FocusNode emailFocus = FocusNode();
  final FocusNode currentPasswordFocus = FocusNode();
  final FocusNode newPasswordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  bool isApiCallProcess = false;
  User? user; // To store the fetched user data
  late Future<User?> userFuture; // For storing the Future
  bool hideCurrentPassword = true;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;
  bool isPasswordMatch = true;

  void toggleCurrentPasswordView() {
    setState(() {
      hideCurrentPassword = !hideCurrentPassword;
    });
  }

  void toggleNewPasswordView() {
    setState(() {
      hideNewPassword = !hideNewPassword;
    });
  }

  void toggleConfirmPasswordView() {
    setState(() {
      hideConfirmPassword = !hideConfirmPassword;
    });
  }

  @override
  void initState() {
    super.initState();
    userFuture = fetchUserDetails();
    currentPasswordController.addListener(() {
      setState(() {}); // Rebuild when title changes
    });

    newPasswordController.addListener(() {
      setState(() {}); // Rebuild when description changes
    });

    confirmPasswordController.addListener(() {
      setState(() {}); // Rebuild when cost changes
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<User?> fetchUserDetails() async {
    final loginInfo = await getLoginInfoFromPrefs();
    if (loginInfo == null) {
      return null;
    }

    ApiService apiService = ApiService();
    final userDetails = await apiService.getUserDetails(loginInfo.id!);
    if (userDetails != null) {
      // Initialize controllers here
      emailController.text = userDetails.email ?? '';
      setState(() {
        user = userDetails; // Update the local user state
      });
    }
    return userDetails;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          localizations.changePassword,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: FutureBuilder<User?>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(localizations.errorOccurred));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text(localizations.noData));
          } else {
            // Pass the user data to the UI setup
            return _uiSetup(snapshot.data!, context);
          }
        },
      ),
    );
  }

  Widget _uiSetup(User loginInfo, BuildContext context) {
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;
    final defaultAvatar = AvatarFormat().getRandomAvatarColor();

    return ProgressHUD(
        inAsyncCall: isApiCallProcess,
        opacity: 0.3,
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.1),
              child: Column(
                children: [
                  loginInfo.imageURL != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(loginInfo.imageURL!),
                          radius: screenHeight * 0.065,
                        )
                      : CircleAvatar(
                          backgroundColor: defaultAvatar,
                          radius: screenHeight * 0.065,
                          child: Text(
                            AvatarFormat()
                                .getInitials(user!.name!, twoLetters: true),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.1,
                            ),
                          ),
                        ),
                  SizedBox(height: screenHeight * 0.025),
                  Form(
                    key: globalFormKey,
                    child: Column(
                      children: [
                        SizedBox(
                          child: TextFormField(
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            focusNode: emailFocus,
                            controller: emailController,
                            readOnly: true,
                            validator: (value) {
                              if (value!.trim().isEmpty) {
                                return localizations.required;
                              }

                              return null;
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'Email',
                              hintText: '${localizations.enter} Email}',
                              prefixIcon: Icon(Icons.email,
                                  color: isDark ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        SizedBox(
                          child: TextFormField(
                            focusNode: currentPasswordFocus,
                            controller: currentPasswordController,
                            obscureText: hideCurrentPassword,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value!.trim().isEmpty) {
                                return localizations.required;
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: localizations.currentPassword,
                              hintText:
                                  '${localizations.enter} ${localizations.currentPassword.toLowerCase()}',
                              prefixIcon: Icon(Icons.lock,
                                  color: isDark ? Colors.white : Colors.black),
                              suffixIcon: IconButton(
                                onPressed: toggleCurrentPasswordView,
                                icon: Icon(hideCurrentPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                color: isDark
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        SizedBox(
                          child: TextFormField(
                            focusNode: newPasswordFocus,
                            controller: newPasswordController,
                            obscureText: hideNewPassword,
                            validator: (value) {
                              if (value!.trim().isEmpty) {
                                return localizations.required;
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                isPasswordMatch = value ==
                                    confirmPasswordController
                                        .text; // Check if passwords match
                              });
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: localizations.newPassword,
                              hintText:
                                  '${localizations.enter} ${localizations.newPassword.toLowerCase()}',
                              prefixIcon: Icon(Icons.lock,
                                  color: isDark ? Colors.white : Colors.black),
                              suffixIcon: IconButton(
                                onPressed: toggleNewPasswordView,
                                icon: Icon(hideNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                color: isDark
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        SizedBox(
                          child: TextFormField(
                            focusNode: confirmPasswordFocus,
                            controller: confirmPasswordController,
                            obscureText: hideConfirmPassword,
                            onChanged: (value) {
                              setState(() {
                                // Check if passwords match
                                isPasswordMatch =
                                    value == newPasswordController.text;
                              });
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value!.trim().isEmpty) {
                                return localizations.required;
                              }

                              return null;
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: localizations.confirmPassword,
                              hintText: localizations.enterConfirmPassword,
                              prefixIcon: Icon(Icons.lock,
                                  color: isDark ? Colors.white : Colors.black),
                              suffixIcon: IconButton(
                                onPressed: toggleConfirmPasswordView,
                                icon: Icon(hideConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                color: isDark
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                        if (confirmPasswordController.text.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                                left: screenWidth * 0.025,
                                top: screenHeight * 0.0025),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                textAlign: TextAlign.start,
                                isPasswordMatch
                                    ? localizations.passwordMatch
                                    : localizations.passwordNotMatch,
                                style: TextStyle(
                                  fontSize: screenHeight * 0.013,
                                  color: isPasswordMatch
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: screenHeight * 0.02),
                        SizedBox(
                          width: screenWidth * 0.8,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (validateAndSave() && isPasswordMatch) {
                                setState(() {
                                  isApiCallProcess = true;
                                });

                                final apiService = ApiService();
                                final id = loginInfo.id!;
                                final oldPassword =
                                    currentPasswordController.text;
                                final newPassword = newPasswordController.text;

                                final result = await apiService.changePassword(
                                    id, oldPassword, newPassword);
                                final success = result.$1;
                                final message = result.$2;

                                setState(() {
                                  isApiCallProcess = false;
                                });

                                if (success) {
                                  showToast(
                                      '${localizations.changePassword} ${localizations.success.toLowerCase()}');
                                  Get.back(id: 3);
                                } else {
                                  if (message.isEmpty) {
                                    showToast(
                                        '${localizations.changePassword} ${localizations.unsuccess.toLowerCase()}');
                                  } else {
                                    showToast(message);
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              side: BorderSide.none,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              localizations.changePassword,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenHeight * 0.02),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  bool validateAndSave() {
    final form = globalFormKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }
}
