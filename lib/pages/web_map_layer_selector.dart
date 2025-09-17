// import 'package:arcgis_maps/arcgis_maps.dart';
// import 'package:dpmssurveyapp/pages/snap_geometry_edits.dart';
// import 'package:flutter/material.dart';
// class WebMapLayerSelector extends StatefulWidget {
//   final Uri portalUri;
//   final String webMapItemId;
//
//   const WebMapLayerSelector({
//     super.key,
//     required this.portalUri,
//     required this.webMapItemId,
//   });
//
//   @override
//   State<WebMapLayerSelector> createState() => _WebMapLayerSelectorState();
// }
//
// class _WebMapLayerSelectorState extends State<WebMapLayerSelector> {
//   late Future<List<Layer>> _layersFuture;
//   late ArcGISMap _map;
//   Layer? _selectedLayer;
//
//   @override
//   void initState() {
//     super.initState();
//     _layersFuture = _loadLayers();
//   }
//
//   Future<List<Layer>> _loadLayers() async {
//     final portal = Portal(widget.portalUri);
//     await portal.load();
//
//     final portalItem = PortalItem.withPortalAndItemId(
//       portal: portal,
//       itemId: widget.webMapItemId,
//     );
//     await portalItem.load();
//
//     _map = ArcGISMap.withItem(portalItem);
//     await _map.load();
//
//     return _map.operationalLayers;
//   }
//
//   void _onLayerSelected(Layer layer) {
//     setState(() {
//       _selectedLayer = layer;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Select Layer')),
//       body: FutureBuilder<List<Layer>>(
//         future: _layersFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error loading layers: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No layers found'));
//           }
//           final layers = snapshot.data!;
//           return Column(
//             children: [
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: layers.length,
//                   itemBuilder: (context, index) {
//                     final layer = layers[index];
//                     return ListTile(
//                       title: Text(layer.name ?? 'Unnamed Layer'),
//                       onTap: () => _onLayerSelected(layer),
//                       selected: _selectedLayer == layer,
//                     );
//                   },
//                 ),
//               ),
//               if (_selectedLayer != null)
//                 ElevatedButton(
//                   child: const Text("Start Drawing"),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => SnapGeometryEdits(
//                           layer: _selectedLayer!,
//                           map: _map,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }