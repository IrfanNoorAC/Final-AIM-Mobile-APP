
import 'package:flutter/material.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIM', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        'assets/logo.png',
        width: 250, 
        height: 250,
      ),
      const SizedBox(height: 30),
      const Text(
        'Redefining Independence for Millions,',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const Text(
        'one person at a time',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 40),
      SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Sign In'),
        ),
      ),
      const SizedBox(height: 20),
      TextButton(
        onPressed: () => Navigator.pushNamed(context, '/register'),
        child: const Text('Create account'),
      ),
    ],
  ),
),

    );
  }
}
