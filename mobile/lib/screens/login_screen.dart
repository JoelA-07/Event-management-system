import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add this
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import 'register_screen.dart';
import 'dashboard_selector.dart'; // Add this

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
   bool _isPasswordVisible = false; 

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    print("Attempting login for: $email"); // Debugging line

    String? error = await authProvider.login(email, password);

    if (error == null) {
      const storage = FlutterSecureStorage();
      String? role = await storage.read(key: "role");
      print("Login success! Role: $role");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardSelector(role: role ?? 'customer')),
        );
      }
    } else {
      print("Login failed: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Brand Icon/Logo Area
            const Icon(Icons.event_available, size: 80, color: AppTheme.accentColor),
            const SizedBox(height: 10),
            const Text(
              "Jireh Events",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const Text("- WITH YOU IN ALL OCCASIONS - ", style: TextStyle(color: Colors.white70 , fontSize: 15)),
            const SizedBox(height: 10),
            const Text("MAKING YOUR VISION INTO EXECUTION", style: TextStyle(color: Colors.white70 , fontSize: 10)),
            const SizedBox(height: 65),
            
            // Login Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible, // 2. Toggle visibility here
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          // 3. Add the Eye Icon Button
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: AppTheme.primaryColor.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ), 
                      const SizedBox(height: 40),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _handleLogin,
                              child: const Text("LOGIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                        },
                        child: const Text("New here? Create an Account", style: TextStyle(color: AppTheme.secondaryColor)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}