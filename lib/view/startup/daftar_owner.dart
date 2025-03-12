import 'package:flutter/material.dart';
import 'package:ta_pos/view-model-flutter/startup_controller.dart';

bool _isValidEmail = false;

class daftar_owner extends StatefulWidget {
  const daftar_owner({super.key});

  @override
  State<daftar_owner> createState() => _daftar_owner_State();
}

class _daftar_owner_State extends State<daftar_owner> {
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  TextEditingController FnameOwner = TextEditingController();
  TextEditingController LnameOwner = TextEditingController();
  bool _isPasswordVisible = false;

  bool _validateEmail(String email) {
    RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    email.addListener(() {
      setState(() {
        _isValidEmail = _validateEmail(email.text);
        if (!_isValidEmail) {
          print('Invalid email format');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Langkah 1/3",
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  "Daftar Akun Owner",
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                _buildTextField(
                  context,
                  controller: email,
                  label: 'Enter Email',
                  icon: Icons.email,
                  hintText: 'example@domain.com',
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: pass,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock),
                    contentPadding: EdgeInsets.all(20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    labelText: 'Enter Password',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.background,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                _buildTextField(
                  context,
                  controller: FnameOwner,
                  label: 'Enter First Name',
                  icon: Icons.person,
                ),
                SizedBox(height: 16.0),
                _buildTextField(
                  context,
                  controller: LnameOwner,
                  label: 'Enter Last Name',
                  icon: Icons.person,
                ),
                SizedBox(height: 30),
                Text(
                  'Pastikan Data yang diinput benar!',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isValidEmail
                      ? () {
                          tambahOwner(
                            email.text.toString(),
                            pass.text.toString(),
                            FnameOwner.text.toString(),
                            LnameOwner.text.toString(),
                            context,
                          );
                          email.clear();
                          pass.clear();
                          FnameOwner.clear();
                          LnameOwner.clear();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: _isValidEmail
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    "Next",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context,
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      String? hintText,
      bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        filled: true,
        fillColor: Theme.of(context).colorScheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    );
  }
}
