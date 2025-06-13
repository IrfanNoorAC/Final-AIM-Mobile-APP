
import 'package:flutter/material.dart';
import 'package:aimapp/database_helper.dart';
import 'package:aimapp/home_page.dart';

class SettingsPage extends StatefulWidget {
  final int userId;
  const SettingsPage({required this.userId, Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? _isDeaf;
  bool? _isBlind;
  bool? _isWheelchairBound;
  bool? _canAssistDeaf;
  bool? _canAssistBlind;
  bool? _canAssistWheelchair;
  bool? _isHelper;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DatabaseHelper().getUser(widget.userId);
    if (user != null) {
      setState(() {
        _isDeaf = user['isDeaf'] == 1;
        _isBlind = user['isBlind'] == 1;
        _isWheelchairBound = user['isWheelchairBound'] == 1;
        _canAssistDeaf = user['canAssistDeaf'] == 1;
        _canAssistBlind = user['canAssistBlind'] == 1;
        _canAssistWheelchair = user['canAssistWheelchair'] == 1;
        _isHelper = user['isHelper'] == 1;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper().updateUserCapabilities(
        userId: widget.userId,
        // Only update disabilities if not helper or PWD
        isDeaf: _isHelper == true ? null : _isDeaf, 
        isBlind: _isHelper == true ? null : _isBlind,
        isWheelchairBound: _isHelper == true ? null : _isWheelchairBound,
        canAssistDeaf: _canAssistDeaf,
        canAssistBlind: _canAssistBlind,
        canAssistWheelchair: _canAssistWheelchair,
      );
      
      await DatabaseHelper().updateUserHelperStatus(
        userId: widget.userId,
        isHelper: _isHelper ?? false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
      
      // Navigate to home page 
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomePage(userId: widget.userId),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to home page when back button is pressed
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomePage(userId: widget.userId),
          ),
          (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate to home page when back button is pressed
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => HomePage(userId: widget.userId),
                ),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Only show disabilities section if not a helper or PWD
              if (_isHelper != true) ...[
                const Text(
                  'Your Disabilities:',
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
              ],
              
              // Always show assistance capabilities
              const Text(
                'Your Assistance Capabilities:',
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
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

