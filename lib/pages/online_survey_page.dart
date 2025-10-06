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

class _OnlineSurveyPageState extends State<OnlineSurveyPage>
    with SampleStateSupport {
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
    // final licenseInfo = await portal.fetchLicenseInfo();
    // final licenseResult = ArcGISEnvironment.setLicenseUsingInfo(licenseInfo);
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
        iconTheme: IconThemeData(
          color: Colors.white, // Set your desired color here
        ),
        title: const Text('Online Survey',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.black38,
        elevation: 0,
        systemOverlayStyle:
            SystemUiOverlayStyle.light, // For light status bar icons
      ),
      body: Stack(
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
      floatingActionButton:Padding(
    padding: const EdgeInsets.only(bottom: 32.0),
    child: FloatingActionButton(
        onPressed: () async {
          if (_map != null) {
            final Viewpoint? sourceViewpoint = await _mapViewController.getCurrentViewpoint(ViewpointType.centerAndScale);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => SnapGeometryEdits(
                      portalUri: widget.portalUri,
                      webMapItemId: widget.webMapItemId,
                      isOffline: false,
                        viewPoint:sourceViewpoint!
                    ),
              ),
            );
            if (result != null) {
              print('Received result: $result');
              _mapViewController.setViewpoint(result as Viewpoint);
              // Handle the result data
            }
          }
        },
        tooltip: 'Add Survey',
        // backgroundColor: Colors.blue.shade900,
        // foregroundColor: Colors.white, // Icon color set explicitly to white
        child: const Icon(Icons.add),
      ),
      )
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
        if (result.geoElements.isNotEmpty &&
            result.layerContent is FeatureLayer) {
          final featureLayer = result.layerContent as FeatureLayer;
          final feature = result.geoElements.first as ArcGISFeature;

          featureLayer.selectFeatures([feature]);

          // Showing popup or feature editing UI
          showFeatureActionPopup(
            feature,
            featureLayer,
            result.popups.first,
            false, () {
                // Navigator.pop(context);
            //                 // if (mounted) {
            //                 //   ScaffoldMessenger.of(context).showSnackBar(
            //                 //     const SnackBar(
            //                 //       content: Text('Feature successfully updated'),
            //                 //     ),
            //                 //   );
            //                 // }
          },[]
          );

          break;
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Identify failed: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Identify error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingFeature = false);
    }
  }
}
