import 'package:flutter/material.dart';
import 'package:junior_app/services/localization_extension.dart';
import 'package:provider/provider.dart';
import '../../view_model/signup_view_model.dart';
import '../../view_model/auth_view_model.dart';

class SignupV extends StatefulWidget {
  const SignupV({super.key});

  @override
  State<SignupV> createState() => _SignupVState();
}

class _SignupVState extends State<SignupV> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final signupVM = Provider.of<SignupViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('signup')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                Text(context.tr('signup'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                
                const SizedBox(height: 8),
                Text(
                  'Fill in your details to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // First Name
                TextFormField(
                  onChanged: signupVM.setFirstName,
                  decoration: InputDecoration(
                    labelText: context.tr('first_name'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: signupVM.firstNameError,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Last Name
                TextFormField(
                  onChanged: signupVM.setLastName,
                  decoration: InputDecoration(
                    labelText: context.tr('last_name'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: signupVM.lastNameError,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Email
                TextFormField(
                  onChanged: signupVM.setEmail,
                  decoration: InputDecoration(
                    labelText: context.tr('email'),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: signupVM.emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: 16),
                
                // Password
                TextFormField(
                  obscureText: _obscurePassword,
                  onChanged: signupVM.setPassword,
                  decoration: InputDecoration(
                    labelText: context.tr('password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: signupVM.passwordError,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Confirm Password
                TextFormField(
                  obscureText: _obscureConfirmPassword,
                  onChanged: signupVM.setConfirmPassword,
                  decoration: InputDecoration(
                    labelText: context.tr('confirm_password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: signupVM.confirmPasswordError,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Error Message
                if (signupVM.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            signupVM.error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (signupVM.error != null) const SizedBox(height: 16),
                
                // Create Account Button - FIXED
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: signupVM.isLoading
                        ? null
                        : () async {
                            print('ðŸŽ¯ Create Account button pressed');
                            signupVM.debugState();
                            
                            final success = await signupVM.signup();
                            print('ðŸŽ¯ Signup result: $success');
                            
                            if (success) {
                              print('ðŸŽ¯ Updating global auth state and navigating...');
                              // Update global AuthViewModel
                              await authVM.login(signupVM.email);
                              
                              // Force navigation to main page
                              // This is needed because your main.dart might not be reacting immediately
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context, 
                                  '/main', 
                                  (route) => false,
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: signupVM.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(context.tr('signup'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                       child: Text(context.tr('login'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
