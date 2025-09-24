import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final String _webMapItemId = '920addf59d734bdca9146ae20315fb5b';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,  // To allow gradient behind app bar
      appBar: AppBar(
        title: const Text('Survey Mode'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent, // Transparent app bar to show gradient behind
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
            splashRadius: 26,
            color: Colors.white,
            hoverColor: Colors.blue.shade300.withOpacity(0.3),
          ),
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light, // For light icons on status bar
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                backgroundColor: Colors.lightBlue.shade100,
                foregroundColor: Colors.blue.shade900,
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
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
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
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28, color: foregroundColor),
        label: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            label,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
              letterSpacing: 1.1,
            ),
          ),
        ),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return backgroundColor.withOpacity(0.85);
            }
            if (states.contains(MaterialState.hovered)) {
              return backgroundColor.withOpacity(0.95);
            }
            return backgroundColor;
          }),
          elevation: MaterialStateProperty.resolveWith<double>((states) {
            if (states.contains(MaterialState.pressed)) return 3;
            return 8;
          }),
          shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.25)),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: BorderSide(color: foregroundColor.withOpacity(0.85), width: 2),
            ),
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          ),
          overlayColor: MaterialStateProperty.all(foregroundColor.withOpacity(0.12)),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),
    );
  }
}
