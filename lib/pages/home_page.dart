// import 'package:dpmssurveyapp/pages/snap_geometry_edits.dart';
// import 'package:dpmssurveyapp/pages/web_map_layer_selector.dart';
// import 'package:flutter/material.dart';
//
// import 'online_offline_mode_page.dart';
// class HomePage extends StatelessWidget {
//   final VoidCallback onLogout;
//   final Uri _portalUri = Uri.parse('https://www.arcgis.com/');
//   final String _webMapItemId = 'acc027394bc84c2fb04d1ed317aac674';
//   HomePage({required this.onLogout, super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Home'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: onLogout,
//             tooltip: 'Logout',
//           )
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               child: const Text('Existing Survey'),
//               onPressed: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineOfflineModePage(mode: 'Existing Survey')));
//               },
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               child: const Text('New Survey'),
//               onPressed: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => SnapGeometryEdits(portalUri: _portalUri,
//                   webMapItemId: _webMapItemId,)));
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }