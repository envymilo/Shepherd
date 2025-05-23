import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/models/auth.dart';
import 'package:shepherd_mo/pages/login_page.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/widgets/auth_input_field.dart';
import 'package:shepherd_mo/widgets/gradient_text.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  late RegisterRequestModel requestModel = RegisterRequestModel();
  bool isApiCallProcess = false;
  var emailController = TextEditingController();
  var phoneController = TextEditingController();
  var passwordController = TextEditingController();
  var confirmPassController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPassFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    requestModel = RegisterRequestModel();
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                  child: Column(children: [
                    Expanded(
                      child: Column(
                        children: <Widget>[
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
                            alignment: Alignment.center,
                            child: Text(
                              localizations.accountForYou,
                              style: TextStyle(
                                fontSize: screenHeight * 0.02,
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
                                  labelText: 'Email',
                                  hintText: '${localizations.enter} email',
                                  prefixIcon: Icons.person,
                                  isDark: isDark,
                                  width: screenWidth,
                                  onSaved: (input) =>
                                      requestModel.email = input!,
                                  focusNode: _emailFocus,
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                AuthInputField(
                                  controller: phoneController,
                                  labelText: localizations.phone,
                                  hintText:
                                      '${localizations.enter} ${localizations.phone.toLowerCase()}',
                                  prefixIcon: Icons.phone,
                                  isDark: isDark,
                                  width: screenWidth,
                                  onSaved: (input) =>
                                      requestModel.phone = input!,
                                  focusNode: _phoneFocus,
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                AuthInputField(
                                  controller: passwordController,
                                  labelText: localizations.password,
                                  hintText:
                                      '${localizations.enter} ${localizations.password.toLowerCase()}',
                                  prefixIcon: Icons.key,
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
                                SizedBox(height: screenHeight * 0.02),
                                AuthInputField(
                                  controller: confirmPassController,
                                  labelText: localizations.confirmPassword,
                                  hintText: localizations.enterConfirmPassword,
                                  prefixIcon: Icons.key,
                                  isPasswordField: true,
                                  hidePassword: hideConfirmPassword,
                                  width: screenWidth,
                                  isDark: isDark,
                                  focusNode: _passwordFocus,
                                  togglePasswordView: () {
                                    setState(() {
                                      hideConfirmPassword =
                                          !hideConfirmPassword;
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
                                        width: 0.5,
                                        color: Colors.grey.shade400),
                                  ),
                                  onPressed: () async {
                                    _emailFocus.unfocus();
                                    _passwordFocus.unfocus();
                                  },
                                  child: Center(
                                    child: Text(localizations.signup,
                                        style: TextStyle(
                                            fontSize: screenHeight * 0.025,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          SizedBox(
                            width: screenWidth,
                            child: Row(children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(localizations.or,
                                  style: TextStyle(color: Colors.grey[600])),
                              Expanded(
                                child: Divider(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ]),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black,
                              minimumSize:
                                  Size(screenWidth, screenHeight * 0.06),
                              shape: const RoundedRectangleBorder(),
                              elevation: 3,
                              shadowColor: isDark ? Colors.white : Colors.black,
                              side: BorderSide(
                                  width: 0.5, color: Colors.grey.shade400),
                            ),
                            icon: Image.asset('assets/images/google_icon.png',
                                width: screenWidth * 0.06,
                                height: screenWidth * 0.06),
                            label: Text(localizations.google,
                                style: TextStyle(fontSize: 20)),
                            onPressed: () {
                              //function
                            },
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(localizations.alreadyHaveAccount,
                            style: TextStyle(fontSize: screenHeight * 0.018)),
                        TextButton(
                          onPressed: () {
                            Get.off(const LoginPage(),
                                transition: Transition.leftToRightWithFade);
                          },
                          child: Text(
                            localizations.loginNow,
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: screenHeight * 0.018),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
