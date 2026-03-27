// ignore_for_file: prefer_final_fields, use_build_context_synchronously
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/core/app_providers.dart';
import 'http_override.dart';
import 'login_screen.dart';
import 'versionservice.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _deleteCacheDir() async {
  final cacheDir = await getTemporaryDirectory();

  if (cacheDir.existsSync()) {
    cacheDir.deleteSync(recursive: true);
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:
          Colors.transparent, // Set the status bar to be transparent
    ),
  );

  runApp(
    MultiProvider(providers: AppProviders.providers, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      debugShowCheckedModeBanner: false,
      title: 'Optima',
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF2CA9DF),
          contentTextStyle: TextStyle(color: Colors.white, fontSize: 16),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2CA9DF)),
        useMaterial3: true,
      ),
      home: const VersionCheckPage(title: 'Amaryllis Healthcare'),
    );
  }
}

class VersionCheckPage extends StatefulWidget {
  const VersionCheckPage({super.key, required this.title});
  final String title;

  @override
  State<VersionCheckPage> createState() => _VersionCheckPageState();
}

class _VersionCheckPageState extends State<VersionCheckPage> {
  bool _isPermissionChecked = false;
  bool locationGranted = false;
  bool storageGranted = false;
  bool audioGranted = false;
  bool _showLogo = true;
  bool _updateRequired = false;
  String currentVersion = "";
  String latestVersion = "";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _deleteCacheDir();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _startTimer();
    await _checkLocationPermission();
    if (!kIsWeb) {
      await _checkStoragePermission();
    } else {
      storageGranted = true;
    }
    await _checkVersion();
    await _checkMicPermissions();
    setState(() {
      if (locationGranted && storageGranted) {
        _isPermissionChecked = true;
      }
    });
  }

  Future<void> _startTimer() async {
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showLogo = false;
        });
      }
    });
  }

  Future<void> _checkLocationPermission() async {
    if (kIsWeb) {
      // Web: do NOT use permission_handler logic
      try {
        await Permission.location.request();
        locationGranted = true;
      } catch (_) {
        locationGranted = false;
      }
      return;
    }

    // Mobile (Android / iOS)
    final status = await Permission.location.request();

    if (status == PermissionStatus.granted) {
      locationGranted = true;
    } else {
      locationGranted = false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required to continue'),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        SystemNavigator.pop(); // OK for mobile
      });
    }
  }

  Future<void> _checkStoragePermission() async {
    final plugin = DeviceInfoPlugin();
    final android = await plugin.androidInfo;
    var status = android.version.sdkInt < 33
        ? await Permission.storage.request()
        : PermissionStatus.granted;
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('You can\'t use this app without storage permission.'),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        SystemNavigator.pop();
      });
    } else {
      storageGranted = true;
    }
  }

  Future<void> _checkVersion() async {
    final versionService = VersionService(
      versionUrl: '${ApiHelper.baseUrl}getlatestversion',
    );

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;

      latestVersion = await versionService.fetchLatestVersion();
      bool updateRequired = true;

      if (_isVersionLower(currentVersion, latestVersion) && updateRequired) {
        setState(() {
          _updateRequired = true;
        });
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  bool _isVersionLower(String currentVersion, String latestVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> latest = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latest.length; i++) {
      if (current.length <= i || current[i] < latest[i]) {
        return true;
      } else if (current[i] > latest[i]) {
        return false;
      }
    }
    return false;
  }

  Future<void> _checkMicPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_updateRequired) {
      return Scaffold(
        body: Center(
          child: PopScope(
            canPop: false,
            child: AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              // This keeps dialog responsive on all screen sizes
              title: const Text('Update Required'),
              content: Text(
                'A new version ($latestVersion) of the app is available. Please update to continue.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.example.optima',
                    );

                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      SystemNavigator.pop();
                    }
                  },
                  child: const Text('Update'),
                ),
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('Exit'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      body: _showLogo
          ? LayoutBuilder(
              builder: (context, constraints) {
                // SAFE VALUES (never infinity)
                final screenHeight = MediaQuery.of(context).size.height;
                final screenWidth = MediaQuery.of(context).size.width;

                return Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight, // SAFE
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // --- Company Logo ---
                          Image.asset(
                            'assets/images/${ApiHelper.projectName}/companyName.png',
                            width: screenWidth * 0.6,
                            height: 100,
                            fit: BoxFit.contain,
                          ),

                          // const SizedBox(height: 20),

                          // --- Splash Image ---
                          Image.asset(
                            'assets/images/${ApiHelper.projectName}/splashscreen.png',
                            width: screenWidth * 0.7,
                            height: screenHeight * 0.35,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 20),

                          Column(
                            children: [
                              Text(
                                'v $currentVersion',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF878787),
                                ),
                              ),
                              const Text(
                                "Powered By LyonIT",
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF878787),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : _isPermissionChecked
          ? const LoginScreen()
          : kIsWeb && !locationGranted
          ? const WebLocationPermissionHelp()
          : const Center(child: CircularProgressIndicator()),
      // : _isPermissionChecked
      // ? const LoginScreen()
      // : const Center(child: CircularProgressIndicator()),
    );
  }
}

class WebLocationPermissionHelp extends StatelessWidget {
  const WebLocationPermissionHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.location_off, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Location Permission Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'You previously denied location access.\n\n'
              'To enable it:\n'
              '1. Click the 🔒 lock icon in the browser address bar\n'
              '2. Set Location to "Allow"\n'
              '3. Refresh the page',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
