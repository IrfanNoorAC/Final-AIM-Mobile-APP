import 'package:flutter/material.dart';
import 'package:aimapp/database_helper.dart';

class AssistPage extends StatefulWidget {
  final int userId;
  const AssistPage({required this.userId, Key? key}) : super(key: key);

  @override
  _AssistPageState createState() => _AssistPageState();
}

class _AssistPageState extends State<AssistPage> {
  bool? _canAssistDeaf;
  bool? _canAssistBlind;
  bool? _canAssistWheelchair;

  Future<void> _saveAndContinue() async {
    if (_canAssistDeaf == null || _canAssistBlind == null || _canAssistWheelchair == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    await DatabaseHelper().updateUserCapabilities(
      userId: widget.userId,
      canAssistDeaf: _canAssistDeaf,
      canAssistBlind: _canAssistBlind,
      canAssistWheelchair: _canAssistWheelchair,
    );

    await DatabaseHelper().updateUserHelperStatus(
      userId: widget.userId,
      isHelper: true,
    );

    Navigator.pushReplacementNamed(
      context, 
      '/home',
      arguments: {'userId': widget.userId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Capabilities')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildQuestion(
              'Can you assist someone who is deaf or hard of hearing?',
              _canAssistDeaf,
              (value) => setState(() => _canAssistDeaf = value),
            ),
            _buildQuestion(
              'Can you assist someone who is blind or visually impaired?',
              _canAssistBlind,
              (value) => setState(() => _canAssistBlind = value),
            ),
            _buildQuestion(
              'Can you assist someone who uses a wheelchair?',
              _canAssistWheelchair,
              (value) => setState(() => _canAssistWheelchair = value),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveAndContinue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(String text, bool? value, ValueChanged<bool?> onChanged) {
    return Column(
      children: [
        Text(text, style: const TextStyle(fontSize: 16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<bool>(
              value: true,
              groupValue: value,
              onChanged: onChanged,
            ),
            const Text('Yes'),
            const SizedBox(width: 20),
            Radio<bool>(
              value: false,
              groupValue: value,
              onChanged: onChanged,
            ),
            const Text('No'),
          ],
        ),
        const Divider(),
      ],
    );
  }
}


