import 'package:flutter/material.dart';
import 'package:aimapp/database_helper.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  String? _selectedSex;
  bool _isHelper = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isValidSingaporePostal(String code) {
    return RegExp(r'^\d{6}$').hasMatch(code);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Check if email already exists
      final emailExists = await DatabaseHelper().emailExists(_emailController.text.trim());
      if (emailExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email already in use')),
        );
        return;
      }


      final height = double.tryParse(_heightController.text) ?? 0;
      final weight = double.tryParse(_weightController.text) ?? 0;
      final bmi = weight / ((height / 100) * (height / 100));

      final userId = await DatabaseHelper().insertUser(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        sex: _selectedSex,
        height: height,
        weight: weight,
        bmi: bmi,
        isHelper: _isHelper,
      );

      if (!mounted) return;
      if (userId != -1) {
        Navigator.pushReplacementNamed(
          context,
          _isHelper ? '/assist' : '/need-help',
          arguments: {'userId': userId},
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildUsernameField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildConfirmPasswordField(),
              const SizedBox(height: 16),
              _buildPostalCodeField(),
              const SizedBox(height: 16),
              _buildAgeField(),
              const SizedBox(height: 16),
              _buildHeightField(),
              const SizedBox(height: 16),
              _buildWeightField(),
              const SizedBox(height: 16),
              _buildSexDropdown(),
              const SizedBox(height: 16),
              _buildHelperSwitch(),
              const SizedBox(height: 32),
              _buildRegisterButton(),
              const SizedBox(height: 16),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(labelText: 'Email'),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email is required';
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Enter a valid email';
        }
        return null;
      },
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(labelText: 'Username'),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Username is required';
        if (value.length < 3) return 'Minimum 3 characters';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password is required';
        if (value.length < 6) return 'Minimum 6 characters';
        return null;
      },
      obscureText: _obscurePassword,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please confirm password';
        if (value != _passwordController.text) return 'Passwords do not match';
        return null;
      },
      obscureText: _obscureConfirmPassword,
    );
  }

  Widget _buildPostalCodeField() {
    return TextFormField(
      controller: _postalCodeController,
      decoration: const InputDecoration(labelText: 'Postal Code'),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Postal code is required';
        if (!_isValidSingaporePostal(value)) {
          return 'Enter a valid 6-digit Singapore postal code';
        }
        return null;
      },
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      decoration: const InputDecoration(labelText: 'Age'),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Age is required';
        final age = int.tryParse(value);
        if (age == null || age < 18 || age > 120) return 'Enter a valid age (18-120)';
        return null;
      },
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildHeightField() {
    return TextFormField(
      controller: _heightController,
      decoration: const InputDecoration(labelText: 'Height (cm)'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your height';
        final height = double.tryParse(value);
        if (height == null || height <= 0 || height > 300) {
          return 'Enter a valid height (1-300 cm)';
        }
        return null;
      },
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      decoration: const InputDecoration(labelText: 'Weight (kg)'),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your weight';
        final weight = double.tryParse(value);
        if (weight == null || weight <= 0 || weight > 300) {
          return 'Enter a valid weight (1-300 kg)';
        }
        return null;
      },
    );
  }

  Widget _buildSexDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSex,
      decoration: const InputDecoration(labelText: 'Gender'),
      items: ['Male', 'Female'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) => setState(() => _selectedSex = newValue),
      validator: (value) => value == null ? 'Please select gender' : null,
    );
  }

  Widget _buildHelperSwitch() {
    return Card(
      child: SwitchListTile(
        title: const Text('Register as a Helper'),
        subtitle: const Text('Check this if you can provide assistance to others'),
        value: _isHelper,
        onChanged: (value) => setState(() => _isHelper = value),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('REGISTER'),
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
      child: const Text('Already have an account? Sign in'),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _postalCodeController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}