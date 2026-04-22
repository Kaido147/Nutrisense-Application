import 'package:flutter/material.dart';
import 'package:nutrisense/pages/register.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C4A73),
              Color(0xFF0F223A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // TOP LOGO
              Positioned(
                top: 20,
                right: 20,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/imgs/Nutrisense.png',
                      height: 40,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "NUTRISENSE",
                      style: TextStyle(
                        color: Color(0xFFD6B97B),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // CENTER CARD
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TITLE
                        const Text(
                          "Let's Sign you in",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Welcome back!\nyou've been missed!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // EMAIL FIELD
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Email Address",
                            hintStyle:
                                const TextStyle(color: Colors.white54),
                            prefixIcon:
                                const Icon(Icons.email, color: Colors.white54),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white38),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // PASSWORD FIELD
                        TextField(
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle:
                                const TextStyle(color: Colors.white54),
                            prefixIcon:
                                const Icon(Icons.lock, color: Colors.white54),
                            suffixIcon:
                                const Icon(Icons.visibility, color: Colors.white54),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white38),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // FORGOT PASSWORD
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Forgot password?",
                              style: TextStyle(color: Colors.white60),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(context, 
                              '/main', (route) => false);
                            },
                            child: const Text("Log In"),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // REGISTER TEXT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.white60),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Register",
                                style: TextStyle(
                                  color: Color(0xFFD6B97B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}