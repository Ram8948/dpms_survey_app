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
    setState(() {
      // Trigger rebuild to update button enabled state
    });
  }

  Future<void> _authenticateUser() async {
    FocusScope.of(context).unfocus();
    setState(() => _loginInProgress = true);
    try {
      final credential = await TokenCredential.create(
        // uri: Uri.parse('https://www.arcgis.com/'),
        uri: Uri.parse('https://gis.mjpdpms.in/agportal/'),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      ArcGISEnvironment.authenticationManager.arcGISCredentialStore.addForUri(
        credential: credential,
        // uri: Uri.parse('https://www.arcgis.com/'),
        uri: Uri.parse('https://gis.mjpdpms.in/agportal/'),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', _usernameController.text.trim());

      await credential.getTokenInfo().then((TokenInfo tokenInfo) async {
        // Access properties of TokenInfo
        final DateTime? expiration = tokenInfo.expirationDate;
        final String? accessToken = tokenInfo.accessToken;


        if (expiration != null) {
          // Convert DateTime to ISO8601 string for storage
          await prefs.setString('tokenExpiration', expiration.toIso8601String());
        }

        if (accessToken != null) {
          await prefs.setString('accessToken', accessToken);
        }

        print('Token expires at: $expiration');
        print('User accessToken: $accessToken');

        // await prefs.setInt('tokenExpiry', expiration);
        // await prefs.setInt('tokenExpiry', credential.tokenExpirationInterval);

        // Example: Check if token is expired
        if (expiration != null && DateTime.now().isAfter(expiration)) {
          print('Token has expired');
          // Handle re-authentication
        } else {
          print('Token is valid');
          // Continue with authenticated session
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
    // Calculate button enabled state on every build
    final bool canLogin = !_loginInProgress &&
        _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade900.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  width: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Welcome Back!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Username',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Password',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    canLogin ? Colors.blue.shade700 : Colors.blue.shade200,
                    elevation: canLogin ? 8 : 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: canLogin ? _authenticateUser : null,
                  child: _loginInProgress
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Login',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
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
