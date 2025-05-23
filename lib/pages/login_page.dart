import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/models/auth.dart';
import 'package:shepherd_mo/pages/change_password_page.dart';
import 'package:shepherd_mo/pages/first_login_page.dart';
import 'package:shepherd_mo/pages/home_page.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/utils/toast.dart';
import 'package:shepherd_mo/widgets/auth_input_field.dart';
import 'package:shepherd_mo/widgets/gradient_text.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  bool hidePassword = true;
  late LoginRequestModel requestModel = LoginRequestModel();
  bool isApiCallProcess = false;
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    requestModel = LoginRequestModel();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      inAsyncCall: isApiCallProcess,
      opacity: 0.3,
      child: _uiSetup(context),
    );
  }

  Widget _uiSetup(BuildContext context) {
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: scaffoldKey,
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.0765),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.1),

                    Column(children: <Widget>[
                      Image.asset(
                        'assets/images/shepherd.png',
                        width: screenWidth * 0.3,
                        height: screenWidth * 0.3,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: GradientText(
                          'Shepherd',
                          style: TextStyle(
                              fontSize: screenWidth * 0.1,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800]),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.2, 0.8],
                            colors: [
                              Colors.orange.shade900,
                              Colors.orange.shade600,
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          localizations.welcomeBack,
                          style: TextStyle(
                            fontSize: screenHeight * 0.025,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          localizations.pleaseLogin,
                          style: TextStyle(
                            fontSize: screenHeight * 0.015,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.grey : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Form(
                        key: globalFormKey,
                        child: Column(
                          children: <Widget>[
                            AuthInputField(
                              controller: emailController,
                              labelText:
                                  'Email ${localizations.or.toLowerCase()} ${localizations.phone}',
                              hintText:
                                  '${localizations.enter} email ${localizations.or.toLowerCase()} ${localizations.phone.toLowerCase()}',
                              prefixIcon: Icons.email,
                              isPasswordField: false,
                              hidePassword: false,
                              isDark: isDark,
                              width: screenWidth,
                              onSaved: (input) =>
                                  requestModel.username = input!,
                              focusNode: _emailFocus,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            AuthInputField(
                              controller: passwordController,
                              labelText: localizations.password,
                              hintText:
                                  '${localizations.enter} ${localizations.password.toLowerCase()}',
                              prefixIcon: Icons.lock,
                              isPasswordField: true,
                              hidePassword: hidePassword,
                              width: screenWidth,
                              isDark: isDark,
                              onSaved: (input) =>
                                  requestModel.password = input!,
                              focusNode: _passwordFocus,
                              togglePasswordView: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[800],
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(),
                                minimumSize:
                                    Size(screenWidth, screenHeight * 0.06),
                                elevation: 3,
                                shadowColor:
                                    isDark ? Colors.white : Colors.black,
                                side: BorderSide(
                                    width: 0.5, color: Colors.grey.shade400),
                              ),
                              onPressed: () async {
                                _emailFocus.unfocus();
                                _passwordFocus.unfocus();

                                if (validateAndSave()) {
                                  setState(() {
                                    isApiCallProcess = true;
                                  });
                                  login(requestModel, localizations)
                                      .then((value) {});
                                }
                              },
                              child: Center(
                                child: Text(localizations.login,
                                    style: TextStyle(
                                        fontSize: screenHeight * 0.025,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // SizedBox(height: screenHeight * 0.03),
                      // SizedBox(
                      //   width: screenWidth,
                      //   child: Row(children: [
                      //     Expanded(
                      //       child: Divider(
                      //         color: Colors.grey[600],
                      //       ),
                      //     ),
                      //     Text(localizations.or,
                      //         style: TextStyle(color: Colors.grey[600])),
                      //     Expanded(
                      //       child: Divider(
                      //         color: Colors.grey[500],
                      //       ),
                      //     ),
                      //   ]),
                      // ),
                      // SizedBox(height: screenHeight * 0.03),
                      // ElevatedButton.icon(
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.grey.shade200,
                      //     foregroundColor: Colors.black,
                      //     minimumSize: Size(screenWidth, screenHeight * 0.06),
                      //     shape: const RoundedRectangleBorder(),
                      //     elevation: 3,
                      //     shadowColor: isDark ? Colors.white : Colors.black,
                      //     side: BorderSide(
                      //         width: 0.5, color: Colors.grey.shade400),
                      //   ),
                      //   icon: Image.asset('assets/images/google_icon.png',
                      //       width: screenWidth * 0.06,
                      //       height: screenWidth * 0.06),
                      //   label:  Text(localizations.google,
                      //       style: TextStyle(fontSize: 20)),
                      //   onPressed: () {
                      //     //function
                      //   },
                      // ),
                    ]),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text(
                    //       localizations.notMember,
                    //       style: TextStyle(fontSize: screenHeight * 0.018),
                    //     ),
                    //     TextButton(
                    //       onPressed: () {
                    //         Get.off(const RegisterPage(),
                    //             transition: Transition.rightToLeftWithFade);
                    //       },
                    //       child: Text(
                    //         localizations.registerNow,
                    //         style: TextStyle(
                    //             color: Colors.blue,
                    //             fontWeight: FontWeight.bold,
                    //             fontSize: screenHeight * 0.018),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  bool validateAndSave() {
    final form = globalFormKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> login(
      LoginRequestModel requestModel, AppLocalizations localizations) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FlutterSecureStorage storage = const FlutterSecureStorage();
    final apiService = ApiService();
    final Uri uri = Uri.parse("${apiService.baseUrl}/Login");
    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestModel),
      );
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Parse the response to the LoginResponseModel
        final loginResponse = LoginResponseModel.fromJson(responseData);
        final isActive = loginResponse.isActive;

        // Show success snackbar
        showToast(localizations.loginSuccess);

        await storage.write(key: 'token', value: loginResponse.token);

        // Save user information to SharedPreferences
        if (loginResponse.user != null) {
          prefs.setString('loginInfo', jsonEncode(loginResponse.user));
          final firebaseMessaging = FirebaseMessaging.instance;
          final deviceId = await firebaseMessaging.getToken();
          final user = loginResponse.user;
          final id = user!.id;
          if (deviceId != null && id != null) {
            await apiService.sendDeviceId(id, deviceId);
          }
        }
        if (loginResponse.listGroupRole != null) {
          prefs.setString(
              'loginUserGroups', jsonEncode(loginResponse.listGroupRole));
        }
        setState(() {
          isApiCallProcess = false;
        });
        // Navigate to HomePage

        if (isActive != "Active") {
          Get.to(() => const FirstLoginPage(),
              transition: Transition.rightToLeftWithFade);
          showToast(localizations.pleaseUpdate);
        } else {
          Get.off(() => const HomePage());
        }
      } else {
        // Handle error message
        final errorMessage =
            responseData['message'] ?? localizations.loginUnsuccess;
        setState(() {
          isApiCallProcess = false;
        });
        showToast(errorMessage);
      }
    } catch (error) {
      setState(() {
        isApiCallProcess = false;
      });
      showToast(localizations.loginUnsuccess);
      throw Exception('Error: $error');
    }
  }
}
