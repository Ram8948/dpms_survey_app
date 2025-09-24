import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({required this.onLoginSuccess, super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loginInProgress = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onTextChanged);
    _passwordController.removeListener(_onTextChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _authenticateUser() async {
    FocusScope.of(context).unfocus();
    setState(() => _loginInProgress = true);
    try {
      final credential = await TokenCredential.create(
        uri: Uri.parse('https://gis.mjpdpms.in/agportal/'),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      ArcGISEnvironment.authenticationManager.arcGISCredentialStore.addForUri(
        credential: credential,
        uri: Uri.parse('https://gis.mjpdpms.in/agportal/'),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', _usernameController.text.trim());

      await credential.getTokenInfo().then((TokenInfo tokenInfo) async {
        final DateTime? expiration = tokenInfo.expirationDate;
        final String? accessToken = tokenInfo.accessToken;

        if (expiration != null) {
          await prefs.setString('tokenExpiration', expiration.toIso8601String());
        }

        if (accessToken != null) {
          await prefs.setString('accessToken', accessToken);
        }
      }).catchError((e) {
        print('Failed to get token info: $e');
      });

      widget.onLoginSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loginInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canLogin = !_loginInProgress &&
        _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade900.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      )
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 88,
                    width: 88,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 36),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter username',
                    prefixIcon: const Icon(Icons.person_outline),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (canLogin) _authenticateUser();
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      canLogin ? Colors.blue.shade700 : Colors.blue.shade300,
                      elevation: canLogin ? 8 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      shadowColor: Colors.blue.shade900.withOpacity(0.4),
                    ),
                    onPressed: canLogin ? _authenticateUser : null,
                    child: _loginInProgress
                        ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () {
                    // Add Forgot Password logic here
                  },
                  child: Text(
                    'Forgot your login details?',
                    style: TextStyle(
                      color: Colors.blue.shade100,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
