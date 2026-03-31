import 'package:flutter/material.dart';
import 'package:mobile/features/auth/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isPasswordVisible = false; 
  
  // Default role is 'customer' as per your backend model
  String _selectedRole = 'customer'; 

  // List of roles based on your project requirements
  final List<String> _roles = ['customer', 'organizer', 'photographer', 'caterer', 'designer', 'mehendi', 'hall_owner'];

  final AuthService _authService = AuthService();
  bool _isLoading = false;

void _handleRegister() async {
  print("DEBUG: Register Button Clicked!");

  // 1. Check if controllers are actually getting text
  print("DEBUG: Name: ${_nameController.text}");
  print("DEBUG: Email: ${_emailController.text}");
  print("DEBUG: Role Selected: $_selectedRole");

  if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
    print("DEBUG: Validation failed - fields are empty");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill in all fields")),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    print("DEBUG: Calling AuthService.register now...");
    
    final res = await _authService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _phoneController.text.trim(),
      _selectedRole,
    );

    print("DEBUG: AuthService returned a response");

    if (res != null && res.statusCode == 201) {
      print("DEBUG: Registration Success!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account Created! Please Login")),
      );
      Navigator.pop(context);
    } else {
      print("DEBUG: Registration Failed with status: ${res?.statusCode}");
      print("DEBUG: Error Data: ${res?.data}");
      String error = res?.data['message'] ?? "Registration failed";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  } catch (e) {
    print("DEBUG: A CRASH OCCURRED: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Connection Error: $e")),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView( // Allows scrolling if keyboard covers fields
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 15),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 15),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),const SizedBox(height: 20),
            
            // ROLE DROPDOWN
            DropdownButtonFormField(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: "Register As"),
              items: _roles.map((role) => DropdownMenuItem(
                value: role, 
                child: Text(role.toUpperCase())
              )).toList(),
              onChanged: (val) => setState(() => _selectedRole = val as String),
            ),
            
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator() 
              : ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text("Register"),
                ),
          ],
        ),
      ),
    );
  }
}
