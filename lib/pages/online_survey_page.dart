import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:dpmssurveyapp/common/sample_state_support.dart';
import 'package:dpmssurveyapp/pages/snap_geometry_edits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import 'attribute_edit_form.dart';

class OnlineSurveyPage extends StatefulWidget {
  final Uri portalUri;
  final String webMapItemId;

  const OnlineSurveyPage({
    super.key,
    required this.portalUri,
    required this.webMapItemId,
  });

  @override
  State<OnlineSurveyPage> createState() => _OnlineSurveyPageState();
}

class _OnlineSurveyPageState extends State<OnlineSurveyPage> with SampleStateSupport {
  final _mapViewController = ArcGISMapView.createController();

  bool _loadingFeature = false;
  FeatureLayer? _selectedFeatureLayer;
  ArcGISFeature? _selectedFeature;
  ArcGISMap? _map;

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  Future<void> _loadMap() async {
    debugPrint("_loadMap : ${widget.portalUri}");
    final portal = Portal(
      widget.portalUri,
      connection: PortalConnection.authenticated,
    );
    await portal.load();
    final portalItem = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: widget.webMapItemId,
    );

    await portalItem.load();

    _map = ArcGISMap.withItem(portalItem);
    await _map?.load();

    if (mounted) {
      debugPrint("_loadMap map : ${_map}");
      _mapViewController.arcGISMap = _map;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Online Survey'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light, // For light status bar icons
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            ArcGISMapView(
              controllerProvider: () => _mapViewController,
              onTap: _handleMapTap,
            ),
            if (_loadingFeature)
              Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_map != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SnapGeometryEdits(
                    portalUri: widget.portalUri,
                    webMapItemId: widget.webMapItemId,
                    isOffline: false,
                  ),
                ),
              );
            }
          },
          tooltip: 'Add Survey',
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white,  // Icon color set explicitly to white
          child: const Icon(Icons.add),
        ),
    );
  }

  Future<void> _handleMapTap(Offset screenPoint) async {
    debugPrint("_handleMapTap map : $screenPoint");
    setState(() => _loadingFeature = true);
    try {
      if (_selectedFeatureLayer != null) {
        _selectedFeatureLayer!.clearSelection();
      }

      final identifyResults = await _mapViewController.identifyLayers(
        screenPoint: screenPoint,
        tolerance: 12,
        maximumResultsPerLayer: 1,
        returnPopupsOnly: false,
      );

      for (var result in identifyResults) {
        if (result.geoElements.isNotEmpty && result.layerContent is FeatureLayer) {
          final featureLayer = result.layerContent as FeatureLayer;
          final feature = result.geoElements.first as ArcGISFeature;

          featureLayer.selectFeatures([feature]);

          // Showing popup or feature editing UI
          showFeatureActionPopup(feature, featureLayer, result.popups.first,false);

          break;
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Identify failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Identify error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingFeature = false);
    }
  }
}
