import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widget/custom_floating_appbar.dart';
import 'offline_survey_page.dart';
import 'online_survey_page.dart';

class OnlineOfflineModePage extends StatefulWidget {
  final VoidCallback onLogout;
  const OnlineOfflineModePage({required this.onLogout, super.key});

  @override
  State<OnlineOfflineModePage> createState() => _OnlineOfflineModePageState();
}

class _OnlineOfflineModePageState extends State<OnlineOfflineModePage> {
  final Uri _portalUri = Uri.parse('https://gis.mjpdpms.in/agportal/');
  // final String _webMapItemId = '920addf59d734bdca9146ae20315fb5b';
  // final String _webMapItemId = '23ee738f611f430fbadc1ebafc59f4e3';
  // final String _webMapItemId = 'bbae968f056040fba787effd38a8aa62';
  // final String _webMapItemId = '55cf4a2adf2d470a955cd0d812642e98';
  // final String _webMapItemId = 'f3aca9ce375e493a81e2563bcde00d9e';
  // final String _webMapItemId = '5075cc7ebb2b4f8bbc82043c7119f002';
  // final String _webMapItemId = '96d5cd61cd46480eac71dedc392bc7c1';
  // final String _webMapItemId = '5627b093bf5d49318254890f4e08d481';
  // final String _webMapItemId = 'f96835ba2c3645bfbdb02ef03f7506a2';
  final String _webMapItemId = 'af5d8e822b094eb49541cec3d6b2e51d';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,  // To allow gradient behind app bar
      // appBar: AppBar(
      //   title: const Text('Survey Mode',style: TextStyle(color: Colors.white),),
      //   centerTitle: true,
      //   elevation: 0,
      //   backgroundColor: Colors.black38, // Transparent app bar to show gradient behind
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       onPressed: widget.onLogout,
      //       tooltip: 'Logout',
      //       splashRadius: 26,
      //       color: Colors.white,
      //       hoverColor: Colors.blue.shade300.withOpacity(0.3),
      //     ),
      //   ],
      //   systemOverlayStyle: const SystemUiOverlayStyle(
      //     statusBarIconBrightness: Brightness.light, // For light icons on status bar
      //     statusBarBrightness: Brightness.dark,
      //   ),
      // ),
      appBar: CustomFloatingAppBar(
        title: "Survey Mode",
        showBackButton: false,
        onBackPressed: () => Navigator.of(context).pop(),
        rightIcon: Icons.power_settings_new,
        onRightIconPressed: widget.onLogout,
      ),
      body: Container(
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [Colors.blue.shade400, Colors.blue.shade700],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        // ),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/waterdrop_mobile.jpg'),
            repeat: ImageRepeat.repeat,
            // fit: BoxFit.cover, // Ensures image covers the container
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: kToolbarHeight + 40),  // Space below AppBar
              _buildModeButton(
                icon: Icons.cloud,
                label: 'Online Survey',
                backgroundColor: const Color(0xFFE8F7FF),  // Same as AppBar gradient start
                foregroundColor: const Color(0xFF0A4F87),  // Complementary dark blue for text/icon
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OnlineSurveyPage(
                        portalUri: _portalUri,
                        webMapItemId: _webMapItemId,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              _buildModeButton(
                icon: Icons.cloud_off,
                label: 'Offline Survey',
                backgroundColor: const Color(0xFFE8F7FF),  // Same as AppBar gradient start
                foregroundColor: const Color(0xFF0A4F87),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OfflineSurveyPage(
                        portalUri: _portalUri,
                        webMapItemId: _webMapItemId,
                      ),
                    ),
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8DCAFF), width: 1), // Border color from AppBar
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      onPressed: onPressed,
    );
  }
}
