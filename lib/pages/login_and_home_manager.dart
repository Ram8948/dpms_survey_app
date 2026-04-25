import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'online_offline_mode_page.dart';
class LoginAndHomeManager extends StatefulWidget {
  const LoginAndHomeManager({super.key});
  @override
  State<LoginAndHomeManager> createState() => _LoginAndHomeManagerState();
}

class _LoginAndHomeManagerState extends State<LoginAndHomeManager> {
  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      debugPrint("Checking login status...");
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool('isLoggedIn') ?? false;
      final expirationString = prefs.getString('tokenExpiration');
      final expiration = expirationString != null ? DateTime.tryParse(expirationString) : null;
      final accessToken = prefs.getString('accessToken');
      debugPrint("loggedIn: $loggedIn, expiration: $expiration, hasToken: ${accessToken != null}");

      if (expiration != null && DateTime.now().isAfter(expiration)) {
        debugPrint('Token has expired');
        _isAuthenticated = false;
      } else if (expiration != null && accessToken != null) {
        final tokenInfo = TokenInfo.create(
          accessToken: accessToken,
          expirationDate: expiration,
          isSslRequired: true,
        );

        if (tokenInfo != null) {
          ArcGISEnvironment.authenticationManager.arcGISCredentialStore.addForUri(
            credential: PregeneratedTokenCredential(
              uri: Uri.parse('https://dpmsportal.ceinsys.com/portal/'),
              tokenInfo: tokenInfo,
              referer: "",
            ),
            uri: Uri.parse('https://dpmsportal.ceinsys.com/portal/'),
          );
          debugPrint('Access token restored in ArcGIS environment');
          _isAuthenticated = true;
        } else {
          debugPrint('Failed to create tokenInfo');
          _isAuthenticated = false;
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e, stack) {
      debugPrint("Error in _checkLoginStatus: $e");
      debugPrint(stack.toString());
      _isAuthenticated = false;
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onLoginSuccess() {
    setState(() => _isAuthenticated = true);
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();

    setState(() => _isAuthenticated = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isAuthenticated == false) {
      return LoginPage(onLoginSuccess: _onLoginSuccess);
      // return LoginPageCopy(onLoginSuccess: _onLoginSuccess);
    }
    return OnlineOfflineModePage(onLogout: _onLogout);
  }
}