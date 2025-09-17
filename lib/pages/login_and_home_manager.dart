import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    final expirationString = prefs.getString('tokenExpiration');
    final expiration = expirationString != null ? DateTime.tryParse(expirationString) : null;
    final accessToken = prefs.getString('accessToken');
    debugPrint("expirationString $expirationString accessToken $accessToken");
    if (expiration != null && DateTime.now().isAfter(expiration)) {
      print('Token has expired');
      _isAuthenticated = false;
      // Handle re-authentication
    } else if (expiration != null && accessToken!=null){

      final tokenInfo = TokenInfo.create(
        accessToken: accessToken,
        expirationDate: expiration,
        isSslRequired: true, // Adjust based on your token generation
      );
      // Create PregeneratedTokenCredential with portal URI and tokenInfo
      final credential = PregeneratedTokenCredential(
        uri: Uri.parse('https://gis.mjpdpms.in/agportal/'),
        tokenInfo: tokenInfo!,
        referer: "", // or your app referer string if required
      );

      // Add credential to ArcGISEnvironment credential store
      ArcGISEnvironment.authenticationManager.arcGISCredentialStore.addForUri(
        credential: credential,
        uri: Uri.parse('https://gis.mjpdpms.in/agportal/'),
      );
      print('Access token restored in ArcGIS environment');
      _isAuthenticated = true;
      print('Token is valid');
      // Continue with authenticated session
    }
    else
    {
        _isAuthenticated = false;
    }
    setState(() {

    });
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
    }
    return OnlineOfflineModePage(onLogout: _onLogout);
  }
}