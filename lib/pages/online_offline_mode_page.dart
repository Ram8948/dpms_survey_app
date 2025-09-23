import 'package:flutter/material.dart';

import 'offline_survey_page.dart';
import 'online_survey_page.dart';
class OnlineOfflineModePage extends StatefulWidget {
  final VoidCallback onLogout;
  const OnlineOfflineModePage({required this.onLogout, super.key});

  @override
  State<OnlineOfflineModePage> createState() => _OnlineOfflineModePageState();
}

class _OnlineOfflineModePageState extends State<OnlineOfflineModePage> {
  bool? _offlineMode;
  // final Uri _portalUri = Uri.parse('https://www.arcgis.com/');
  // final String _webMapItemId = 'acc027394bc84c2fb04d1ed317aac674';
  final Uri _portalUri = Uri.parse('https://gis.mjpdpms.in/agportal/');
  final String _webMapItemId = '920addf59d734bdca9146ae20315fb5b';
  // final String _webMapItemId = 'e8e7e57251f04268a74bef95768071da';
  // final String _webMapItemId = 'f6d825906df147e7b850d47a77b6b25b';
  // final String _webMapItemId = 'bc8cf0f385e647e7be6fed33c88a3167';
  // final String _webMapItemId = '3f8a0c86cffc4b1c9ad5e1dfee5179b2';


  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
              tooltip: 'Logout',
            )
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud),
                label: const Text('Online Survey'),
                onPressed: () =>
                {
                Navigator.push(context, MaterialPageRoute(builder: (_) => OnlineSurveyPage(
                portalUri: _portalUri,
                webMapItemId: _webMapItemId,
                )))
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_off),
                label: const Text('Offline Survey'),
                  onPressed: () =>
                  {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => OfflineSurveyPage(
                      portalUri: _portalUri,
                      webMapItemId: _webMapItemId,
                    )))
                  },
              ),
            ],
          ),
        ),
      );
    }
}