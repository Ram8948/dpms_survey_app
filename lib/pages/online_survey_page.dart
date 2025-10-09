import 'dart:async';
import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:dpmssurveyapp/common/sample_state_support.dart';
import 'package:dpmssurveyapp/pages/snap_geometry_edits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  ArcGISMap? _map;

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  @override
  void dispose() {
    // When exiting, stop the location data source and cancel subscriptions.
    _locationDataSource.stop();
    _statusSubscription?.cancel();
    _autoPanModeSubscription?.cancel();

    super.dispose();
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
      // Start device location display here
      _initializeLocation();
    }
  }

  // Create the system location data source.
  final _locationDataSource = SystemLocationDataSource();

  // A subscription to receive status changes of the location data source.
  StreamSubscription? _statusSubscription;
  var _status = LocationDataSourceStatus.stopped;

  // A subscription to receive changes to the auto-pan mode.
  StreamSubscription? _autoPanModeSubscription;
  var _autoPanMode = LocationDisplayAutoPanMode.recenter;

  // late ArcGISPoint? _currentLocation;

  Future<void> _initializeLocation() async {
      _mapViewController.locationDisplay.dataSource = _locationDataSource;
      _mapViewController.locationDisplay.autoPanMode =
          LocationDisplayAutoPanMode.recenter;

      // Subscribe to status changes and changes to the auto-pan mode.
      _statusSubscription = _locationDataSource.onStatusChanged.listen((status) {
        setState(() => _status = status);
      });
      setState(() => _status = _locationDataSource.status);
      _autoPanModeSubscription = _mapViewController
          .locationDisplay
          .onAutoPanModeChanged
          .listen((mode) {
        setState(() => _autoPanMode = mode);
      });
      setState(
            () {
                  _autoPanMode = _mapViewController.locationDisplay.autoPanMode;;
                  // _currentLocation = _mapViewController.locationDisplay.mapLocation;
                }
      );

      // Attempt to start the location data source (this will prompt the user for permission).
      try {
        await _locationDataSource.start();
      } on ArcGISException catch (e) {
        showMessageDialog(e.message);
      }
  }

  Future<void> _searchBySchemeName(String schemeName) async {
    setState(() => _loadingFeature = true);
    try {
      if (_selectedFeatureLayer != null) {
        _selectedFeatureLayer!.clearSelection();
      }
      final featureLayer = _map!.operationalLayers
          .whereType<FeatureLayer>()
          .firstWhere(
            (layer) => layer.name == 'SchemeExtent',
        orElse: () => throw Exception('SchemeExtent layer not found'),
      );
      _selectedFeatureLayer = featureLayer;
      debugPrint("_searchBySchemeName  featureLayer : ${featureLayer}");

      // Use QueryParameters with case-insensitive SQL like for name
      final queryParams = QueryParameters()
        ..whereClause = "UPPER(schemename) LIKE UPPER('%$schemeName%')";

      final queryResult = await featureLayer.featureTable!.queryFeatures(queryParams);
      final features = queryResult.features().toList();

      if (features.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No features found.')));
        return;
      }
      final geometries = features.first.geometry;

      await _mapViewController.setViewpointGeometry(geometries!);
      featureLayer.clearSelection();
      featureLayer.selectFeatures(features.cast<ArcGISFeature>());
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loadingFeature = false);
    }
  }

  Future<void> _searchBySchemeId(String schemeId) async {
    setState(() => _loadingFeature = true);
    if (_selectedFeatureLayer != null) {
      _selectedFeatureLayer!.clearSelection();
    }
    try {
      final featureLayer = _map!.operationalLayers
          .whereType<FeatureLayer>()
          .firstWhere(
            (layer) => layer.name == 'SchemeExtent',
        orElse: () => throw Exception('SchemeExtent layer not found'),
      );
      _selectedFeatureLayer = featureLayer;
      debugPrint("_searchBySchemeId  featureLayer : ${featureLayer}");
      // final queryParams = QueryParameters(queryWhere: "schemeid = $schemeId");
      final queryParams = QueryParameters()
        ..whereClause = "schemeid = $schemeId";
      final queryResult = await featureLayer.featureTable!.queryFeatures(queryParams);
      final features = queryResult.features().toList();
      if (features.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No features found.')));
        return;
      }
      final geometries = features.first.geometry;

      await _mapViewController.setViewpointGeometry(geometries!);
      featureLayer.clearSelection();
      featureLayer.selectFeatures(features.cast<ArcGISFeature>());
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loadingFeature = false);
    }
  }

  Future<void> _searchByObjectId(String objectId, String layerName) async {
    debugPrint("objectId $objectId layerName $layerName");
    setState(() => _loadingFeature = true);
    if (_selectedFeatureLayer != null) {
      _selectedFeatureLayer!.clearSelection();
    }
    try {
      final featureLayer = _map!.operationalLayers
          .whereType<FeatureLayer>()
          .firstWhere(
            (layer) => layer.name == layerName,
        orElse: () => throw Exception('$layerName layer not found'),
      );
      _selectedFeatureLayer = featureLayer;
      final queryParams = QueryParameters()
        ..whereClause = "objectid = $objectId";

      final queryResult = await featureLayer.featureTable!.queryFeatures(queryParams);

      final features = queryResult.features().toList();

      if (features.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No features found.')));
        return;
      }

      final geometry = features.first.geometry;

      await _mapViewController.setViewpointGeometry(geometry!);

      featureLayer.clearSelection();
      featureLayer.selectFeatures(features.cast<ArcGISFeature>());
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loadingFeature = false);
    }
  }

  Future<void> _showSearchDialog() async {
    final layers = _map!.operationalLayers.whereType<FeatureLayer>().toList();
    String? selectedLayerName = layers.isNotEmpty ? layers[0].name : null;
    final TextEditingController idController = TextEditingController();
    String searchType = 'Scheme ID'; // or 'Object ID'

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Search Features', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SegmentedButton<String>(
                    //   segments: const <ButtonSegment<String>>[
                    //     ButtonSegment(value: 'Scheme ID', label: Text('Scheme ID')),
                    //     ButtonSegment(value: 'Object ID', label: Text('Object ID')),
                    //   ],
                    //   selected: <String>{searchType},
                    //   onSelectionChanged: (Set<String> newSelection) {
                    //     if (newSelection.isNotEmpty) {
                    //       setState(() {
                    //         searchType = newSelection.first;
                    //       });
                    //     }
                    //   },
                    // ),
                    SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment(value: 'Scheme ID', label: Text('Scheme ID')),
                        ButtonSegment(value: 'Scheme Name', label: Text('Scheme Name')),
                        ButtonSegment(value: 'Object ID', label: Text('Object ID')),
                      ],
                      selected: <String>{searchType},
                      onSelectionChanged: (Set<String> newSelection) {
                        if (newSelection.isNotEmpty) {
                          setState(() {
                            searchType = newSelection.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    if (searchType == 'Object ID')
                      DropdownButtonFormField<String>(
                        value: selectedLayerName,
                        decoration: InputDecoration(
                          labelText: 'Select Layer',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        isExpanded: true,
                        onChanged: (val) => setState(() => selectedLayerName = val),
                        items: layers.map((layer) {
                          return DropdownMenuItem<String>(
                            value: layer.name,
                            child: Text(layer.name),
                          );
                        }).toList(),
                      ),
                    if (searchType == 'Object ID')
                      const SizedBox(height: 20),
                    TextField(
                      controller: idController,
                      keyboardType: (searchType == 'Scheme ID') ? TextInputType.number : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Enter $searchType',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final id = idController.text.trim();
                    if (id.isEmpty) return;

                    if (searchType == 'Scheme ID') {
                      await _searchBySchemeId(id);
                    } else if(searchType == 'Scheme Name') {
                      await _searchBySchemeName(id);
                    } else if (searchType == 'Object ID' && selectedLayerName != null) {
                      await _searchByObjectId(id, selectedLayerName!);
                    }
                  },
                  child: const Text('Search', style: TextStyle(fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
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
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              _showSearchDialog();
            },
          ),
        ],// For light status bar icons
      ),
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onTap: _handleMapTap,
          ),
          Compass(
            controllerProvider: () => _mapViewController,
            alignment: Alignment.topRight, // Position at top-right
            padding: const EdgeInsets.fromLTRB(0, 95, 10, 0),
            size: 50, // Diameter of compass icon
            automaticallyHides: true, // Hide if not rotated
            // Optionally provide a custom icon:
            // iconBuilder: (context, size, angleRadians) => YourCustomIcon(...),
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
    debugPrint("_handleMapTap map _selectedFeatureLayer : $_selectedFeatureLayer");
    setState(() => _loadingFeature = true);
    try {
      ArcGISPoint? mapPoint = await _mapViewController.screenToLocation(screen: screenPoint);
      ArcGISPoint? currentLocation = _mapViewController.locationDisplay.mapLocation;
      if (mapPoint != null && currentLocation != null) {
        double distance = await calculateDistanceBetweenPoints(currentLocation: currentLocation, tappedPoint: mapPoint);
        if(distance>20)
        {
          showMessageDialog("You are not within the range of 20 Meter");
          return;
        }
        // {
        //   showMessageDialog("You are within the range of 20 Meter");
        // }
      }

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
          _selectedFeatureLayer = featureLayer;
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
