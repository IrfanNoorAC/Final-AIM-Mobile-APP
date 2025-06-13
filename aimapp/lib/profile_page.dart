
import 'package:flutter/material.dart';
import 'package:aimapp/database_helper.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  const ProfilePage({required this.userId, Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>?> _userData;
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _userData = DatabaseHelper().getUser(widget.userId);
    });
  }

  Future<void> _updateUsername() async {
    if (_usernameController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper().updateUser({
        'id': widget.userId,
        'username': _usernameController.text,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully!')),
      );
      
      setState(() => _isEditing = false);
      _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating username: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() {
    
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/', 
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading profile'),
                  ElevatedButton(
                    onPressed: _loadUserData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final user = snapshot.data!;
          if (!_isEditing) {
            _usernameController.text = user['username'];
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.person, size: 50, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isEditing
                        ? IconButton(
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.check),
                            onPressed: _updateUsername,
                          )
                        : null,
                  ),
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 10),
                
                if (!_isEditing)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _isEditing = true),
                      child: const Text('Edit Username'),
                    ),
                  ),
                
                const SizedBox(height: 30),
                const Text(
                  'Account Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                
                _buildDetailRow('Email', user['email']),
                _buildDetailRow('Account Type', user['isHelper'] == 1 ? 'Helper' : 'PWD'),
                
                if (user['postalCode'] != null) _buildDetailRow('Postal Code', user['postalCode']),
                if (user['age'] != null) _buildDetailRow('Age', user['age'].toString()),
                if (user['sex'] != null) _buildDetailRow('Gender', user['sex']),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}

