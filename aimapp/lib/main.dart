import 'package:aimapp/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:aimapp/sign_in_page.dart';
import 'package:aimapp/home_page.dart';
import 'package:aimapp/helper_details_page.dart';
import 'package:aimapp/chat_page.dart';
import 'package:aimapp/registration_page.dart';
import 'package:aimapp/need_help_page.dart';
import 'package:aimapp/assist_page.dart';
import 'package:aimapp/login_page.dart';
import 'package:aimapp/request_help_page.dart';
import 'package:aimapp/offer_help_page.dart';
import 'package:aimapp/select_datetime_page.dart';
import 'package:aimapp/select_location_page.dart';
import 'package:aimapp/available_helpers_page.dart';
import 'package:aimapp/profile_page.dart';  
import 'package:aimapp/database_helper.dart';
import 'package:aimapp/csv_data_loader.dart';
import 'package:aimapp/community_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbHelper = DatabaseHelper();
  await dbHelper.initialize();
   // Only load CSV if database is empty
  final userCount = await dbHelper.getUserCount();
  if (userCount == 0) {
    await CSVDataLoader.loadCSVData();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIM App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SignInPage(),
        '/register': (context) => const RegistrationPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return HomePage(userId: args['userId']);
        },
        '/profile': (context) {  
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ProfilePage(userId: args['userId']);
        },
        '/settings': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return SettingsPage(userId: args['userId']);
        },
        '/need-help': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return NeedHelpPage(userId: args['userId']);
        },
        '/assist': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return AssistPage(userId: args['userId']);
        },
        '/helper-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return HelperDetailsPage(
            helper: args['helper'],
            service: args['service'],
            date: args['date'],
            time: args['time'],
            location: args['location'],
            isRequestingHelp: args['isRequestingHelp'],
            userId: args['userId'],
            requestType: args['requestType'] ?? 'immediate',
          );
        },
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ChatPage(
            otherUser: args['otherUser'],
            service: args['service'],
            date: args['date'],
            time: args['time'],
            location: args['location'],
            isRequestingHelp: args['isRequestingHelp'],
            userId: args['userId'],
            requestType: args['requestType'] ?? 'immediate',
          );
        },
        '/request-help': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return RequestHelpPage(userId: args['userId']);
        },
        '/offer-help': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return OfferHelpPage(userId: args['userId']);
        },
        '/select-datetime': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return SelectDateTimePage(
            service: args['service'],
            isRequestingHelp: args['isRequestingHelp'],
            userId: args['userId'],
            requestType: args['requestType'] ?? 'immediate',
          );
        },
        '/select-location': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return SelectLocationPage(
            service: args['service'],
            date: args['date'],
            time: args['time'],
            isRequestingHelp: args['isRequestingHelp'],
            userId: args['userId'],
            requestType: args['requestType'] ?? 'immediate',
          );
        },
        '/available-helpers': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return AvailableHelpersPage(
            service: args['service'],
            date: args['date'],
            time: args['time'],
            location: args['location'],
            postalCode: args['postalCode'],
            isRequestingHelp: args['isRequestingHelp'],
            userId: args['userId'],
            requestType: args['requestType'] ?? 'immediate',
          );
        },
        '/community': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return CommunityPage(userId: args['userId']);
        },
      },
    );
  }
}