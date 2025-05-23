import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/constant/constant.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/formatter/avatar.dart';
import 'package:shepherd_mo/models/user.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/services/get_login.dart';
import 'package:shepherd_mo/utils/toast.dart';
import 'package:shepherd_mo/widgets/photo_viewer.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  UpdateProfilePageState createState() => UpdateProfilePageState();
}

class UpdateProfilePageState extends State<UpdateProfilePage> {
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  var roleController = TextEditingController();
  var emailController = TextEditingController();
  var fullNameController = TextEditingController();
  var phoneController = TextEditingController();
  final FocusNode roleFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode fullNameFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  bool isApiCallProcess = false;
  User? user; // To store the fetched user data
  late Future<User?> userFuture; // For storing the Future
  File? image;
  String? imageURL;
  String? imageName;

  @override
  void initState() {
    super.initState();
    // Fetch the user details on initialization
    userFuture = fetchUserDetails();
  }

  @override
  void dispose() {
    roleController.dispose();
    emailController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RefreshController refreshController = Get.find();
      refreshController.setShouldRefresh(true);
    });
  }

  Future<bool> requestPermission(Permission permission) async {
    if (await permission.isGranted || await permission.isLimited) {
      return true;
    } else {
      final result = await permission.request();
      return result.isGranted;
    }
  }

  Future<void> pickImage(
      ImageSource source, AppLocalizations localizations) async {
    try {
      // Check for the required permission based on the source
      Permission permission =
          source == ImageSource.camera ? Permission.camera : Permission.photos;

      PermissionStatus status = await permission.status;

      if (status.isDenied) {
        // First time request
        status = await permission.request();
        if (status.isDenied) {
          showToast(localizations.permissionDenied);
          return;
        }
      }

      if (status.isPermanentlyDenied) {
        // Show dialog to open settings
        final bool openSettings = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(localizations.permissionRequired),
                content: Text(source == ImageSource.camera
                    ? localizations.cameraPermissionMessage
                    : localizations.galleryPermissionMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(localizations.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(localizations.openSettings),
                  ),
                ],
              ),
            ) ??
            false;

        if (openSettings) {
          await openAppSettings();
          // Wait for user to return from settings
          status = await permission.status;
          if (!status.isGranted) {
            showToast(localizations.permissionDenied);
            return;
          }
        } else {
          showToast(localizations.permissionDenied);
          return;
        }
      }

      // Proceed to pick an image only if permission is granted
      if (status.isGranted || status.isLimited) {
        final image = await ImagePicker().pickImage(source: source);
        if (image == null) return;

        final imageTemporary = File(image.path);
        setState(() {
          this.image = imageTemporary;
          this.imageName = image.name;
        });
      }
    } on PlatformException {
      showToast(localizations.errorPickingImage);
    }
  }

  Future uploadFile(String imageName, File image) async {
    final file = image;
    final apiService = ApiService();
    String? url = await apiService.uploadImage(file);

    if (url != null) {
      setState(() {
        imageURL = url;
      });
    } else {
      showToast("Error");
    }
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
      fullNameController.text = userDetails.name ?? '';
      phoneController.text = userDetails.phone != null
          ? formatPhoneNumber(userDetails.phone!)
          : '';
      setState(() {
        user = userDetails; // Update the local user state
      });
      imageURL = userDetails.imageURL;
    }
    return userDetails;
  }

  void _viewCurrentPhoto() {
    if (imageURL == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: PhotoViewer(
          imageUrl: imageURL!,
        ),
      ),
    );
  }

  Future<ImageSource?> showImageSource(
      BuildContext context, AppLocalizations localizations) async {
    if (Platform.isIOS) {
      return showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              child: Text(localizations.camera),
              onPressed: () {
                pickImage(ImageSource.camera, localizations);
                Navigator.of(context).pop();
              },
            ),
            CupertinoActionSheetAction(
              child: Text(localizations.gallery),
              onPressed: () {
                pickImage(ImageSource.gallery, localizations);
                Navigator.of(context).pop();
              },
            ),
            CupertinoActionSheetAction(
              child: Text(localizations.viewAvatar),
              onPressed: () {
                _viewCurrentPhoto();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(localizations.camera),
              onTap: () {
                Navigator.of(context).pop();
                pickImage(ImageSource.camera, localizations);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(localizations.gallery),
              onTap: () {
                Navigator.of(context).pop();
                pickImage(ImageSource.gallery, localizations);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(localizations.viewAvatar),
              onTap: () {
                Navigator.of(context).pop();
                _viewCurrentPhoto();
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          localizations.editProfile,
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
    ApiService apiService = ApiService();
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;

    String getLocalizedRole(BuildContext context, String roleKey) {
      final role = dotenv.env[roleKey.toUpperCase()];
      if (role == null) {
        return localizations.noData; // Fallback for unknown roles
      }
      switch (role.toLowerCase()) {
        case 'admin':
          return localizations.admin;
        case 'priest':
          return localizations.priest;
        case 'council':
          return localizations.council;
        case 'accountant':
          return localizations.accountant;
        case 'member':
          return localizations.member;
        default:
          return localizations.noData;
      }
    }

    roleController.text = getLocalizedRole(context, loginInfo.role!);
    final defaultAvatar = AvatarFormat().getRandomAvatarColor();

    return ProgressHUD(
        inAsyncCall: isApiCallProcess,
        opacity: 0.3,
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => showImageSource(context, localizations),
                    child: Stack(
                      children: [
                        image != null
                            ? CircleAvatar(
                                backgroundImage: FileImage(image!),
                                radius: screenHeight * 0.065,
                              )
                            : imageURL != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(imageURL!),
                                    radius: screenHeight * 0.065,
                                  )
                                : CircleAvatar(
                                    backgroundColor: defaultAvatar,
                                    radius: screenHeight * 0.065,
                                    child: Text(
                                      AvatarFormat().getInitials(user!.name!,
                                          twoLetters: true),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.1,
                                      ),
                                    ),
                                  ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            width: screenHeight * 0.04,
                            height: screenHeight * 0.04,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Const.primaryGoldenColor,
                            ),
                            child: Center(
                              child: IconButton(
                                icon: Icon(Icons.edit_square),
                                onPressed: () =>
                                    showImageSource(context, localizations),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Form(
                    key: globalFormKey,
                    child: Column(
                      children: [
                        SizedBox(
                          width: screenWidth * 0.8,
                          child: TextFormField(
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            focusNode: roleFocus,
                            controller: roleController,
                            readOnly: true,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: localizations.role,
                              hintText:
                                  '${localizations.enter} ${localizations.role.toLowerCase()}',
                              prefixIcon: Icon(Icons.person,
                                  color: isDark ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        SizedBox(
                          width: screenWidth * 0.8,
                          child: TextFormField(
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            focusNode: emailFocus,
                            controller: emailController,
                            readOnly: true,
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
                          width: screenWidth * 0.8,
                          child: // Track dynamic validation error
                              TextFormField(
                            keyboardType: TextInputType.phone,
                            focusNode: phoneFocus,
                            controller: phoneController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              // Validate the phone number dynamically
                              if (value!.trim().isEmpty) {
                                return localizations.required;
                              } else if (!isPhoneNumberValid(value!.trim())) {
                                return localizations.invalidPhone;
                              } else {
                                return null; // Clear error if valid
                              }
                            },
                            onChanged: (value) {
                              // Dynamically format the number

                              final formattedNumber = formatPhoneNumber(value);
                              phoneController.value = TextEditingValue(
                                text: formattedNumber,
                                selection: TextSelection.collapsed(
                                    offset: formattedNumber.length),
                              );
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: localizations.phone,
                              hintText:
                                  '${localizations.enter} ${localizations.phone.toLowerCase()}',
                              prefixIcon: Icon(Icons.phone,
                                  color: isDark ? Colors.white : Colors.black),
                              suffixIcon: phoneController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        phoneController.clear();
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        SizedBox(
                          width: screenWidth * 0.8,
                          child: TextFormField(
                            focusNode: fullNameFocus,
                            controller: fullNameController,
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
                              labelText: localizations.fullName,
                              hintText:
                                  '${localizations.enter} ${localizations.fullName.toLowerCase()}',
                              prefixIcon: Icon(LineAwesomeIcons.user,
                                  color: isDark ? Colors.white : Colors.black),
                              suffixIcon: fullNameController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        fullNameController.clear();
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        SizedBox(
                          width: screenWidth * 0.8,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (validateAndSave()) {
                                if (imageName != null && image != null) {
                                  await uploadFile(imageName!, image!);
                                }
                                if (loginInfo.name == fullNameController.text &&
                                    loginInfo.phone ==
                                        phoneController.text.trim() &&
                                    imageURL == user!.imageURL) {
                                  showToast(localizations.notChange);
                                  return;
                                }
                                setState(() {
                                  isApiCallProcess = true;
                                });

                                final id = loginInfo.id;
                                final updatedUser = User(
                                  name: fullNameController.text.trim(),
                                  phone: phoneController.text,
                                  role: roleController.text,
                                  email: emailController.text,
                                  id: id,
                                  imageURL: imageURL,
                                );

                                final result =
                                    await apiService.updateUser(updatedUser);
                                final success = result.$1;
                                final message = result.$2;

                                setState(() {
                                  isApiCallProcess = false;
                                });

                                if (success) {
                                  showToast(
                                      '${localizations.editProfile} ${localizations.success.toLowerCase()}');
                                  Get.back(id: 3);
                                } else {
                                  if (message != null) {
                                    showToast(
                                        '${localizations.editProfile} ${localizations.unsuccess.toLowerCase()}');
                                  } else {
                                    showToast(
                                        message ?? localizations.errorOccurred);
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
                              localizations.editProfile,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 20),
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

  bool isPhoneNumberValid(String phoneNumber) {
    final RegExp regex = RegExp(r'^\d{3}-?\d{3}-?\d{4}$');
    return regex.hasMatch(phoneNumber);
  }

  String formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Ensure there are exactly 10 digits
    if (digitsOnly.length != 10) {
      return phoneNumber; // Return the original input if not valid
    }

    // Format as 000-000-0000
    return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
  }
}
