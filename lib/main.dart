import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ta_pos/view/loginpage/login.dart';
import 'package:ta_pos/view-model-flutter/user_controller.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the window manager
  await windowManager.ensureInitialized();

  // Set the window properties
  // Retrieve the screen size
  final screenSize = await windowManager.getBounds();

  // Set the window properties
  WindowOptions windowOptions = WindowOptions(
    size: Size(screenSize.width, screenSize.height),
    titleBarStyle: TitleBarStyle.normal,
    minimumSize: Size(1000, 800),
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setFullScreen(false);
    await windowManager.setResizable(false);
    await windowManager.setMinimizable(true);
    await windowManager.setMaximizable(true);
  });

  await GetStorage.init();
  await getOwner().then((value) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyPOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black87,
        primaryColor: Colors.grey[500] ?? Colors.grey,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[400] ?? Colors.grey,
          secondary: Colors.grey[300] ?? Colors.grey,
        ),
      ),
      home: const loginscreen(),
    );
  }
}
