
import 'package:flutter/material.dart';
import 'package:aimapp/database_helper.dart';

class NeedHelpPage extends StatefulWidget {
  final int userId;
  const NeedHelpPage({required this.userId, Key? key}) : super(key: key);

  @override
  _NeedHelpPageState createState() => _NeedHelpPageState();
}

class _NeedHelpPageState extends State<NeedHelpPage> {
  bool? _isDeaf;
  bool? _isBlind;
  bool? _isWheelchairBound;
  bool? _canAssistDeaf;
  bool? _canAssistBlind;
  bool? _canAssistWheelchair;

  Future<void> _saveAndContinue() async {
    if (_isDeaf == null || _isBlind == null || _isWheelchairBound == null ||
        _canAssistDeaf == null || _canAssistBlind == null || _canAssistWheelchair == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    await DatabaseHelper().updateUserCapabilities(
      userId: widget.userId,
      isDeaf: _isDeaf,
      isBlind: _isBlind,
      isWheelchairBound: _isWheelchairBound,
      canAssistDeaf: _canAssistDeaf,
      canAssistBlind: _canAssistBlind,
      canAssistWheelchair: _canAssistWheelchair,
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
      appBar: AppBar(title: const Text('Your Needs & Capabilities')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Please indicate your needs:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildQuestion(
              'Are you deaf or hard of hearing?',
              _isDeaf,
              (value) => setState(() => _isDeaf = value),
            ),
            _buildQuestion(
              'Are you blind or visually impaired?',
              _isBlind,
              (value) => setState(() => _isBlind = value),
            ),
            _buildQuestion(
              'Do you use a wheelchair or have mobility challenges?',
              _isWheelchairBound,
              (value) => setState(() => _isWheelchairBound = value),
            ),
            const Divider(height: 40),
            const Text(
              'Can you also assist others with:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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


