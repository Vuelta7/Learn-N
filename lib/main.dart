import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_n/B%20home%20page/notification_body.dart';
import 'package:learn_n/firebase_options.dart';
import 'package:learn_n/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const MyApp());
}

//Mighty Creation of Uriel
//fix
// Fullscreen for DnD and stopping students from distraction (Can manually turn off and on)
// UX redesign
// enhance the UX of the Answering experience 
// Leader boards based on score
// points to change the UI color
// points to change the background music