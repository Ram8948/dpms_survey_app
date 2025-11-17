import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../common/bottom_sheet_settings.dart';
import '../common/sample_state_support.dart';
import '../widget/custom_floating_appbar.dart';

class SnapGeometryEdits extends StatefulWidget {
  final Uri portalUri;
  final String webMapItemId;
  final bool isOffline;
  final Viewpoint viewPoint;

  const SnapGeometryEdits({
    super.key,
    required this.portalUri,
    required this.webMapItemId,
    required this.isOffline,
    required this.viewPoint,
  });

  @override
  State<SnapGeometryEdits> createState() => _SnapGeometryEditsState();
}

class _SnapGeometryEditsState extends State<SnapGeometryEdits>
    with SampleStateSupport {
  final _mapViewController = ArcGISMapView.createController();
  final _graphicsOverlay = GraphicsOverlay();
  final _geometryEditor = GeometryEditor();
  final _geometryEditorStyle = GeometryEditorStyle();

  var _ready = false;
  final List<DropdownMenuItem<FeatureLayer>> _layerMenuItems = [];
  final _vertexTool = VertexTool();
  final _reticleVertexTool = ReticleVertexTool();
  final _toolMenuItems = <DropdownMenuItem<GeometryEditorTool>>[];
  final _pointLayerSnapSources = <SnapSourceSettings>[];
  final _polylineLayerSnapSources = <SnapSourceSettings>[];
  final _graphicsOverlaySnapSources = <SnapSourceSettings>[];

  FeatureLayer? _selectedLayer;
  ArcGISFeatureTable? _selectedtable;
  GeometryType? _selectedGeometryType;
  GeometryEditorTool? _selectedTool;
  Graphic? _selectedGraphic;
  var _geometryEditorCanUndo = false;
  var _geometryEditorIsStarted = false;
  var _geometryEditorHasSelectedElement = false;
  var _snappingEnabled = false;
  var _geometryGuidesEnabled = false;
  var _featureSnappingEnabled = true;

  var _showEditToolbar = true;
  var _snapSettingsVisible = false;
  late ArcGISMap _map;

  bool _loadingFeature = false;
  FeatureLayer? _selectedFeatureLayer;

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
    try {
      if (_selectedFeatureLayer != null) {
        _selectedFeatureLayer!.clearSelection();
      }
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
      appBar: CustomFloatingAppBar(
        title: "Add New Feature",
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        rightIcon: Icons.search,
        onRightIconPressed: () => _showSearchDialog(),
      ),
      // appBar: AppBar(
      //   iconTheme: IconThemeData(
      //     color: Colors.white, // Set your desired color here
      //   ),
      //   title: const Text(
      //     'Add New Feature',
      //     style: TextStyle(color: Colors.white),
      //   ),
      //   centerTitle: true,
      //   backgroundColor: Colors.black38,
      //   elevation: 0,
      //   systemOverlayStyle:
      //   SystemUiOverlayStyle.light,
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.search, color: Colors.white),
      //       onPressed: () async {
      //         _showSearchDialog();
      //       },
      //     ),
      //   ],// For light status bar icons
      // ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    onTap: !_geometryEditorIsStarted ? onTap : null,
                  ),
                ),
                buildBottomMenu(),
              ],
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
            if (_showEditToolbar)
              Positioned(bottom: 120, right: 5, child: buildEditingToolbar()),
            if (_snapSettingsVisible) buildSnapSettings(context),
            if (_loadingFeature)
              Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a URL to a web map.
    // const webMapUri =
    //     'https://www.arcgis.com/home/item.html?id=b95fe18073bc4f7788f0375af2bb445e';
    // final map = ArcGISMap.withUri(Uri.parse(webMapUri));
    // Set the feature tiling mode on the map.
    // Snapping is used to maintain data integrity between different sources of data when editing,
    // so full resolution is needed for valid snapping.
    if (!widget.isOffline) {
      final portal = Portal(widget.portalUri);
      await portal.load();

      // final licenseInfo = await portal.fetchLicenseInfo();
      // final licenseResult = ArcGISEnvironment.setLicenseUsingInfo(licenseInfo);

      final portalItem = PortalItem.withPortalAndItemId(
        portal: portal,
        itemId: widget.webMapItemId,
      );
      await portalItem.load();

      _map = ArcGISMap.withItem(portalItem);
      // await _map.load();
      // _map = widget.map;

      // _map.loadSettings.featureTilingMode =
      //     FeatureTilingMode.enabledWithFullResolutionWhenSupported;

      // Set the map to the map view controller.
      _mapViewController.arcGISMap = _map;
    } else {
      final documentsDir = await getApplicationDocumentsDirectory();
      // final mmpkFilePath = path.join(documentsDir.path, 'offline_map', 'p13', 'mobile_map.mmap');
      final offlineMapFolderUri = documentsDir.uri.resolve('offline_map/');
      final mobileMapPackage = MobileMapPackage.withFileUri(
        offlineMapFolderUri,
      );
      // Note: Some SDK versions accept folder URI; if not, load layers individually
      await mobileMapPackage.load();

      if (mobileMapPackage.maps.isNotEmpty) {
        final map = mobileMapPackage.maps.first;
        _mapViewController.arcGISMap = map;
        setState(() {
          _map = map;
        });
      } else {
        throw Exception('No maps found in the mobile map package.');
      }
    }
    _mapViewController.setViewpoint(widget.viewPoint);
    // _initializeLocation();
    hardcodedLocation(_mapViewController,_statusSubscription,_status,_autoPanModeSubscription,_autoPanMode);
    _map.loadSettings.featureTilingMode =
        FeatureTilingMode.enabledWithFullResolutionWhenSupported;
    // Add the graphics overlay to the map view.
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);

    // Do some initial configuration of the geometry editor.
    // Initially set the created reticle vertex tool as the current tool.
    // Note that the reticle vertex tool makes visibility of snapping easier on touchscreen devices.
    setState(() => _selectedTool = _reticleVertexTool);
    _geometryEditor.tool = _reticleVertexTool;
    // Listen to changes in canUndo in order to enable/disable the UI.
    _geometryEditor.onCanUndoChanged.listen(
      (canUndo) => setState(() => _geometryEditorCanUndo = canUndo),
    );
    // Listen to changes in isStarted in order to enable/disable the UI.
    _geometryEditor.onIsStartedChanged.listen(
      (isStarted) => setState(() => _geometryEditorIsStarted = isStarted),
    );
    // Listen to changes in the selected element in order to enable/disable the UI.
    _geometryEditor.onSelectedElementChanged.listen(
      (selectedElement) => ()
      {
        debugPrint("onSelectedElementChanged");
        setState(
              () => _geometryEditorHasSelectedElement = selectedElement != null,
        );
      },
    );

    // Set the geometry editor to the map view controller.
    _mapViewController.geometryEditor = _geometryEditor;

    // Ensure the map and each layer loads in order to synchronize snap settings.
    debugPrint('before loading await _map.load()');
    await _map.load();
    await Future.wait(_map.operationalLayers.map((layer) => layer.load()));

    // Sync snap settings.
    synchronizeSnapSettings();

    // Configure menu items for selecting tools and geometry types.
    _toolMenuItems.addAll(configureToolMenuItems());
    // _geometryTypeMenuItems.addAll(configureGeometryTypeMenuItems());
    // Build the FeatureLayer dropdown menu
    debugPrint('_map.operationalLayers ${_map.operationalLayers}');
    _layerMenuItems.clear();
    // for (var layer in _map.operationalLayers.whereType<FeatureLayer>()) {
    //   _layerMenuItems.add(DropdownMenuItem(
    //     value: layer,
    //     child: Text(layer.name),
    //   ));
    // }
    for (var layer in _map.operationalLayers) {
      if (layer is GroupLayer) {
        // iterate through all sublayers inside GroupLayer
        for (var subLayer in layer.layers) {
          if (subLayer is FeatureLayer) {
            _layerMenuItems.add(
              DropdownMenuItem(value: subLayer, child: Text(subLayer.name)),
            );
          }
        }
      } else if (layer is FeatureLayer) {
        _layerMenuItems.add(
          DropdownMenuItem(value: layer, child: Text(layer.name)),
        );
      }
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Create the system location data source.
  final _locationDataSource = SystemLocationDataSource();

  // A subscription to receive status changes of the location data source.
  StreamSubscription? _statusSubscription;
  var _status = LocationDataSourceStatus.stopped;

  // A subscription to receive changes to the auto-pan mode.
  StreamSubscription? _autoPanModeSubscription;
  var _autoPanMode = LocationDisplayAutoPanMode.recenter;

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
          () => _autoPanMode = _mapViewController.locationDisplay.autoPanMode,
    );

    // Attempt to start the location data source (this will prompt the user for permission).
    try {
      await _locationDataSource.start();
    } on ArcGISException catch (e) {
      showMessageDialog(e.message);
    }
  }

  @override
  void dispose() {
    // When exiting, stop the location data source and cancel subscriptions.
    _locationDataSource.stop();
    _statusSubscription?.cancel();
    _autoPanModeSubscription?.cancel();

    super.dispose();
  }

  Future<void> onTap(Offset localPosition) async {
    // Perform an identify operation on the graphics overlay at the tapped location.
    debugPrint("onTap ${_selectedLayer!.name}");

    final identifyResult = await _mapViewController.identifyGraphicsOverlay(
      _graphicsOverlay,
      screenPoint: localPosition,
      tolerance: 12,
    );

    // Get the graphics from the identify result.
    final graphics = identifyResult.graphics;
    if (graphics.isNotEmpty) {
      final graphic = graphics.first;
      if (graphic.geometry != null) {
        final geometry = graphic.geometry!;
        // Hide the selected graphic so that only the version of the graphic that is being edited is visible.
        graphic.isVisible = false;
        // Set the graphic as the selected graphic and also set the selected geometry type to update the UI.
        _selectedGraphic = graphic;
        setState(() => _selectedGeometryType = geometry.geometryType);
        // Start the geometry editor using the geometry of the graphic.
        _geometryEditor.startWithGeometry(geometry);
      }
    }
  }

  void synchronizeSnapSettings() {
    // Synchronize the snap source collection with the map's operational layers.
    _geometryEditor.snapSettings.syncSourceSettings();
    // Enable snapping on the geometry editor.
    _geometryEditor.snapSettings.isEnabled = true;
    setState(() => _snappingEnabled = true);
    // Enable geometry guides on the geometry editor.
    _geometryEditor.snapSettings.isGeometryGuidesEnabled = true;
    setState(() => _geometryGuidesEnabled = true);
    // Create a list of snap source settings for each geometry type and graphics overlay.
    for (final sourceSettings in _geometryEditor.snapSettings.sourceSettings) {
      // Enable all the source settings initially.
      setState(() => sourceSettings.isEnabled = true);
      if (sourceSettings.source is FeatureLayer) {
        final featureLayer = sourceSettings.source as FeatureLayer;
        if (featureLayer.featureTable != null) {
          final geometryType = featureLayer.featureTable!.geometryType;
          if (geometryType == GeometryType.point) {
            _pointLayerSnapSources.add(sourceSettings);
          } else if (geometryType == GeometryType.polyline) {
            _polylineLayerSnapSources.add(sourceSettings);
          }
        }
      } else if (sourceSettings.source is GraphicsOverlay) {
        _graphicsOverlaySnapSources.add(sourceSettings);
      }
    }
  }

  void startEditingWithGeometryType(GeometryType geometryType) {
    // Set the selected geometry type and start editing.
    setState(() => _selectedGeometryType = geometryType);
    _geometryEditor.startWithGeometryType(geometryType);
  }

  ArcGISPoint? getGeometryCenter(Geometry? geometry) {
    // Check if geometry is Envelope type
    if (geometry is Envelope) {
      return geometry.center;
    }
    // For polygon or polyline, get the extent and then center
    if (geometry?.extent != null) {
      return geometry?.extent.center;
    }
    // Fallback: Calculate centroid manually for polygons if needed
    // or return null if not supported
    return null;
  }

  Future<void> stopAndSave() async {
    // Get the geometry from the geometry editor.
    final geometry = _geometryEditor.stop();

    // ArcGISPoint? mapPoint = _mapViewController.screenToLocation(screen: );
    ArcGISPoint? mapPoint = getGeometryCenter(geometry);
    ArcGISPoint? currentLocation = _mapViewController.locationDisplay.mapLocation;
    if (mapPoint != null && currentLocation != null) {
      double distance = await calculateDistanceBetweenPoints(currentLocation: currentLocation, tappedPoint: mapPoint);
      if(distance>20)
      {
        showMessageDialog("You are not within the range of 20 Meter");
        return;
      }
    }

    if (geometry != null) {
      if (_selectedGraphic != null) {
        // If there was a selected graphic being edited, update it.
        _selectedGraphic!.geometry = geometry;
        _selectedGraphic!.isVisible = true;
        // Reset the selected graphic to null.
        _selectedGraphic = null;
      }
      // else {
      //   // If there was no existing graphic, create a new one and add to the graphics overlay.
      //   final graphic = Graphic(geometry: geometry);
      //   // Apply a symbol to the graphic from the geometry editor style depending on the geometry type.
      //   final geometryType = geometry.geometryType;
      //   if (geometryType == GeometryType.point ||
      //       geometryType == GeometryType.multipoint) {
      //     graphic.symbol = _geometryEditorStyle.vertexSymbol;
      //   } else if (geometryType == GeometryType.polyline) {
      //     graphic.symbol = _geometryEditorStyle.lineSymbol;
      //   } else if (geometryType == GeometryType.polygon) {
      //     graphic.symbol = _geometryEditorStyle.fillSymbol;
      //   }
      //   _graphicsOverlay.graphics.add(graphic);
      // }
      createFeature(geometry);
    }

    // Reset the selected geometry type to null.
    setState(() => _selectedGeometryType = null);
  }

  final List<String> wtpLayerNames = [
    'Aeration Fountain',
    'Clariflocculator',
    'Rapid Sand Filter and Filter House',
    'Admin Block and Labortary Items',
    'Wash Water Tank',
    'Bypass Arrangement',
    'Pure Water Sump and Pump House',
    'Channel in Meter',
    'Drainage Arrangement',
  ];

  bool isLayerPresent(String layerName) {
    return wtpLayerNames.contains(layerName);
  }

  Future<void> createFeature(Geometry? geometry) async {
    // Disable the UI while the async operations are in progress.
    setState(() => _ready = false);
    if (_selectedtable != null) {
      // Create the feature.
      final feature = _selectedtable?.createFeature();

      // Get the normalized geometry for the tapped location and use it as the feature's geometry.
      // final geometry = _mapViewController.screenToLocation(
      //     screen: localPosition);
      // final geometry = _geometryEditor.geometry;

      if (geometry != null) {
        final normalizedGeometry = GeometryEngine.normalizeCentralMeridian(
          geometry,
        );
        feature?.geometry = normalizedGeometry;

        // Add the feature to the local table.
        await _selectedtable!.addFeature(feature!);

        // Update the feature to get the updated objectid - a temporary ID is used before the feature is added.
        feature.refresh();
        debugPrint("Attribute keys: ${feature.attributes.keys.toList()}");
        debugPrint("_selectedLayer!.name: ${_selectedLayer!.name}");
        if (isLayerPresent(_selectedLayer!.name.trim())) {
          Feature? interceptedFeature = await checkFeatureInterceptWTP(
            feature.geometry,
          );
          if (interceptedFeature != null) {

            final selectedSubtype = await showDialog<int>(
              context: context,
              builder: (BuildContext context) {
                return SimpleDialog(
                  title: Text('Select Feature Subtype'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, 1),
                      child: Text('Conventional'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, 2),
                      child: Text('Un-Conventional'),
                    ),
                  ],
                );
              },
            );

            // User cancelled dialog or did not select
            if (selectedSubtype == null) {
              return;
            }
            feature.attributes['subtype'] = selectedSubtype;
            if (!await processNewFeature(interceptedFeature, feature)) {
              return;
            }
          } else {
            showMessageDialog(
              'This feature can not be draw outside the WTP Layer',
            );
            await _selectedtable!.deleteFeature(feature);
            feature.refresh();
            return;
          }
        } else {
          debugPrint("Not LayerPresent ${_selectedLayer!.name}");
        }
        final attributes = await getSchemeNameFromExtent(feature.geometry);
        if (attributes != null) {
          debugPrint("Attribute keys: ${attributes.keys.toList()}");
          debugPrint("Attribute keys: ${attributes["regionname"]}");
          debugPrint("Attribute keys: ${attributes["circlename"]}");
          debugPrint("Attribute keys: ${attributes["division_name"]}");

          feature.attributes['name'] = attributes["schemename"];
          feature.attributes['id'] = attributes["schemeid"];
          feature.attributes['region'] = attributes["regionname"];
          feature.attributes['circle'] = attributes["circlename"];
          feature.attributes['division'] = attributes["division_name"];
        }
        // Confirm feature addition.
        showMessageDialog('Created feature ${feature.attributes['objectid']}');
        Popup? featurePopup;

        // Assuming: you have ArcGISFeature 'feature' and FeatureLayer '_selectedLayer'
        final popupDefinition =
            _selectedLayer?.popupDefinition; // get template/definition

        if (popupDefinition != null) {
          featurePopup = Popup(
            geoElement: feature, // the selected ArcGISFeature
            popupDefinition: popupDefinition, // layer's popup config
            // You may provide additional options if needed (title, etc.)
          );
        }
        await showFeatureActionPopup(
          context,
          feature as ArcGISFeature,
          _selectedLayer!,
          featurePopup!,
          widget.isOffline,
          () async {
            final Viewpoint? sourceViewpoint = await _mapViewController
                .getCurrentViewpoint(ViewpointType.centerAndScale);
            if (!mounted) return;

            Navigator.pop(context, sourceViewpoint);
            Navigator.pop(context, sourceViewpoint);
          },
          schemeList,
        );
      } else {
        showMessageDialog('Error creating feature, geometry was null.');
      }
      setState(() => _ready = true);
    }
  }

  void stopAndDiscardEdits() {
    // Stop the geometry editor. No need to capture the geometry as we are discarding.
    _geometryEditor.stop();
    if (_selectedGraphic != null) {
      // If editing a previously existing geometry, reset the selectedGraphic.
      _selectedGraphic!.isVisible = true;
      _selectedGraphic = null;
    }
    // Reset the selected geometry type.
    setState(() => _selectedGeometryType = null);
  }

  // Widget buildBottomMenu() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: DropdownButton<FeatureLayer>(
  //           isExpanded: true,
  //           alignment: Alignment.center,
  //           hint: Text(
  //             'Select Layer',
  //             style: Theme.of(context).textTheme.labelMedium,
  //           ),
  //           icon: const Icon(Icons.arrow_drop_down),
  //           iconEnabledColor: Theme.of(context).primaryColor,
  //           iconDisabledColor: Theme.of(context).disabledColor,
  //           style: Theme.of(context).textTheme.labelMedium,
  //           value: _selectedLayer,
  //           items: _layerMenuItems,
  //           onChanged:
  //               !_geometryEditorIsStarted
  //                   ? (layer) async {
  //                     setState(() => _selectedLayer = layer);
  //                     await layer?.load();
  //                     _selectedtable =
  //                         layer?.featureTable as ArcGISFeatureTable?;
  //                     setState(() {
  //                       _selectedGeometryType =
  //                           layer?.featureTable?.geometryType;
  //                       if (_selectedGeometryType != null) {
  //                         startEditingWithGeometryType(_selectedGeometryType!);
  //                       }
  //                     });
  //                   }
  //                   : null,
  //           isDense: true,
  //         ),
  //       ),
  //       Expanded(
  //         child: DropdownButton(
  //           isExpanded: true,
  //           alignment: Alignment.center,
  //           hint: Text('Tool', style: Theme.of(context).textTheme.labelMedium),
  //           iconEnabledColor: Theme.of(context).colorScheme.primary,
  //           style: Theme.of(context).textTheme.labelMedium,
  //           value: _selectedTool,
  //           items: _toolMenuItems,
  //           onChanged: (tool) {
  //             if (tool != null) {
  //               setState(() => _selectedTool = tool);
  //               _geometryEditor.tool = tool;
  //             }
  //           },
  //           isDense: true,
  //         ),
  //       ),
  //       IconButton(
  //         onPressed: () => setState(() => _showEditToolbar = !_showEditToolbar),
  //         icon: const Icon(Icons.edit),
  //       ),
  //     ],
  //   );
  // }

  Widget buildBottomMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F7FF), // Same as AppBar gradient start
          border: Border.all(
            color: const Color(0xFF8DCAFF), // AppBar border color
            width: 1,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FeatureLayer>(
                  isExpanded: true,
                  alignment: Alignment.center,
                  hint: Text(
                    'Select Layer',
                    style: TextStyle(
                      color: const Color(0xFF0A4F87), // dark blue for text
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0A4F87)),
                  dropdownColor: const Color(0xFFE8F7FF), // menu background
                  style: const TextStyle(
                    color: Color(0xFF0A4F87),
                    fontWeight: FontWeight.w500,
                  ),
                  value: _selectedLayer,
                  items: _layerMenuItems,
                  onChanged: !_geometryEditorIsStarted
                      ? (layer) async {
                    setState(() => _selectedLayer = layer);
                    await layer?.load();
                    _selectedtable = layer?.featureTable as ArcGISFeatureTable?;
                    setState(() {
                      _selectedGeometryType = layer?.featureTable?.geometryType;
                      if (_selectedGeometryType != null) {
                        startEditingWithGeometryType(_selectedGeometryType!);
                      }
                    });
                  }
                      : null,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  isExpanded: true,
                  alignment: Alignment.center,
                  hint: const Text(
                    'Tool',
                    style: TextStyle(
                      color: Color(0xFF0A4F87),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0A4F87)),
                  dropdownColor: const Color(0xFFE8F7FF),
                  style: const TextStyle(
                    color: Color(0xFF0A4F87),
                    fontWeight: FontWeight.w500,
                  ),
                  value: _selectedTool,
                  items: _toolMenuItems,
                  onChanged: (tool) {
                    if (tool != null) {
                      setState(() => _selectedTool = tool);
                      _geometryEditor.tool = tool;
                    }
                  },
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8DCAFF),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => setState(() => _showEditToolbar = !_showEditToolbar),
                icon: const Icon(Icons.edit, color: Color(0xFF0A4F87)),
                tooltip: "Edit",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEditingToolbar() {
    // A toolbar of buttons with icons for editing functions. Tooltips are used to aid the user experience.
    return Padding(
      padding: const EdgeInsets.only(bottom: 100, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // A button to toggle the visibility of the snap settings.
              // ElevatedButton(
              //   onPressed: () => setState(() => _snapSettingsVisible = true),
              //   child: const Text('Show snap settings'),
              // ),
              Row(
                spacing: 12,
                children: [
                  // A button to call undo on the geometry editor, if enabled.
                  Tooltip(
                    message: 'Undo',
                    child: ElevatedButton(
                      onPressed:
                          _geometryEditorIsStarted && _geometryEditorCanUndo
                              ? _geometryEditor.undo
                              : null,
                      child: const Icon(Icons.undo),
                    ),
                  ),
                  // A button to delete the selected element on the geometry editor.
                  Tooltip(
                    message: 'Delete selected element',
                    child: ElevatedButton(
                      onPressed:
                          _geometryEditorIsStarted &&
                                  _geometryEditorHasSelectedElement &&
                                  _geometryEditor.selectedElement != null &&
                                  _geometryEditor.selectedElement!.canDelete
                              ? _geometryEditor.deleteSelectedElement
                              : null,
                      child: const Icon(Icons.clear),
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 12,
                children: [
                  // A button to stop and save edits.
                  Tooltip(
                    message: 'Stop and save edits',
                    child: ElevatedButton(
                      onPressed: _geometryEditorIsStarted ? stopAndSave : null,
                      child: const Icon(Icons.save),
                    ),
                  ),
                  // A button to stop the geometry editor and discard all edits.
                  Tooltip(
                    message: 'Stop and discard edits',
                    child: ElevatedButton(
                      onPressed:
                          _geometryEditorIsStarted ? stopAndDiscardEdits : null,
                      // onPressed: ()
                      // {
                      //   Navigator.pop(context);
                      // },
                      child: const Icon(Icons.not_interested_sharp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSnapSettings(BuildContext context) {
    return BottomSheetSettings(
      onCloseIconPressed: () => setState(() => _snapSettingsVisible = false),
      settingsWidgets:
          (context) => [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                maxWidth: MediaQuery.sizeOf(context).height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Snap Settings',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        // Add a checkbox to toggle all snapping options.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Enable all'),
                            Checkbox(
                              value:
                                  _snappingEnabled &&
                                  _geometryGuidesEnabled &&
                                  _featureSnappingEnabled,
                              onChanged: (allEnabled) {
                                if (allEnabled != null) {
                                  _geometryEditor.snapSettings.isEnabled =
                                      allEnabled;
                                  _geometryEditor
                                      .snapSettings
                                      .isGeometryGuidesEnabled = allEnabled;
                                  _geometryEditor
                                      .snapSettings
                                      .isFeatureSnappingEnabled = allEnabled;
                                  setState(() {
                                    _snappingEnabled = allEnabled;
                                    _geometryGuidesEnabled = allEnabled;
                                    _featureSnappingEnabled = allEnabled;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Add a checkbox to toggle whether snapping is enabled.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Snapping enabled'),
                        Checkbox(
                          value: _snappingEnabled,
                          onChanged: (snappingEnabled) {
                            if (snappingEnabled != null) {
                              _geometryEditor.snapSettings.isEnabled =
                                  snappingEnabled;
                              setState(
                                () => _snappingEnabled = snappingEnabled,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    // Add a checkbox to toggle whether geometry guides are enabled.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Geometry guides'),
                        Checkbox(
                          value: _geometryGuidesEnabled,
                          onChanged: (geometryGuidesEnabled) {
                            if (geometryGuidesEnabled != null) {
                              _geometryEditor
                                      .snapSettings
                                      .isGeometryGuidesEnabled =
                                  geometryGuidesEnabled;
                              setState(
                                () =>
                                    _geometryGuidesEnabled =
                                        geometryGuidesEnabled,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    // Add a checkbox to toggle whether feature snapping is enabled.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Feature snapping'),
                        Checkbox(
                          value: _featureSnappingEnabled,
                          onChanged: (featureSnappingEnabled) {
                            if (featureSnappingEnabled != null) {
                              _geometryEditor
                                      .snapSettings
                                      .isFeatureSnappingEnabled =
                                  featureSnappingEnabled;
                              setState(
                                () =>
                                    _featureSnappingEnabled =
                                        featureSnappingEnabled,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Select snap sources',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Add checkboxes for enabling the point layers as snap sources.
                    buildSnapSourcesSelection(
                      'Point layers',
                      _pointLayerSnapSources,
                    ),
                    // Add checkboxes for the polyline layers as snap sources.
                    buildSnapSourcesSelection(
                      'Polyline layers',
                      _polylineLayerSnapSources,
                    ),
                    // Add checkboxes for the graphics overlay as snap sources.
                    buildSnapSourcesSelection(
                      'Graphics Overlay',
                      _graphicsOverlaySnapSources,
                    ),
                  ],
                ),
              ),
            ),
          ],
    );
  }

  Widget buildSnapSourcesSelection(
    String label,
    List<SnapSourceSettings> allSourceSettings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                const Text('Enable all'),
                // A checkbox to enable all source settings in the category.
                Checkbox(
                  value: allSourceSettings.every(
                    (snapSourceSettings) => snapSourceSettings.isEnabled,
                  ),
                  onChanged: (allEnabled) {
                    if (allEnabled != null) {
                      allSourceSettings
                          .map(
                            (snapSourceSettings) => setState(
                              () => snapSourceSettings.isEnabled = allEnabled,
                            ),
                          )
                          .toList();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        Column(
          children:
              allSourceSettings.map((sourceSetting) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Display the layer name, or set default text for graphics overlay.
                    Text(
                      allSourceSettings == _pointLayerSnapSources ||
                              allSourceSettings == _polylineLayerSnapSources
                          ? (sourceSetting.source as FeatureLayer).name
                          : 'Editor Graphics Overlay',
                    ),
                    // A checkbox to toggle whether this source setting is enabled.
                    Checkbox(
                      value: sourceSetting.isEnabled,
                      onChanged: (isEnabled) {
                        if (isEnabled != null) {
                          setState(() => sourceSetting.isEnabled = isEnabled);
                        }
                      },
                    ),
                  ],
                );
              }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<DropdownMenuItem<GeometryType>> configureGeometryTypeMenuItems() {
    // Create a list of geometry types to make available for editing.
    final geometryTypes = [
      GeometryType.point,
      GeometryType.multipoint,
      GeometryType.polyline,
      GeometryType.polygon,
    ];
    // Returns a list of drop down menu items for each geometry type.
    return geometryTypes
        .map(
          (type) => DropdownMenuItem(
            value: type,
            child: Text(type.name.capitalize()),
          ),
        )
        .toList();
  }

  List<DropdownMenuItem<GeometryEditorTool>> configureToolMenuItems() {
    // Returns a list of drop down menu items for the required tools.
    return [
      DropdownMenuItem(value: _vertexTool, child: const Text('Vertex Tool')),
      DropdownMenuItem(
        value: _reticleVertexTool,
        child: const Text('Reticle Vertex Tool'),
      ),
    ];
  }

  FeatureSubtype? getSubtype(Feature newFeature) {
    // Get the feature table
    final featureTable = newFeature.featureTable;

    if (featureTable is ArcGISFeatureTable) {
      // Get the field name used for subtype
      final subtypeField = featureTable.subtypeField;

      if (subtypeField.isNotEmpty) {
        // Get the subtype code from the feature's attributes
        debugPrint("newFeature.attributes : ${newFeature.attributes}");
        final subtypeCode = newFeature.attributes[subtypeField];
        debugPrint("subtypeCode : $subtypeCode");
        // Get the Subtype from the table definition
        try {
          return featureTable.featureSubtypes.firstWhere(
            (s) => s.code == subtypeCode,
          );
        } catch (e) {
          debugPrint("ERROR : ${e.toString()}");
          return null;
        }
      }
    }
  }

  Future<List<String>> findIntersectingLayers(
    Feature feature,
    ArcGISMap map,
  ) async {
    final geometry = feature.geometry;
    if (geometry == null) return [];

    final List<String> layerNames = [];

    for (final layer in map.operationalLayers) {
      if (layer is FeatureLayer) {
        final queryParams =
            QueryParameters()
              ..geometry = geometry
              ..spatialRelationship = SpatialRelationship.intersects;

        final result = await layer.featureTable?.queryFeatures(queryParams);

        if (result != null && result.features().isNotEmpty) {
          layerNames.add(layer.name); // ✅ collect layer name
        }
      }
    }

    return layerNames;
  }

  Future<bool> processNewFeature(
    Feature? wtpFeature,
    Feature newFeature,
  ) async {
    try {
      FeatureSubtype? newFeatureSubtype = await getSubtype(newFeature);
      FeatureSubtype? wtpFeatureSubtype = await getSubtype(wtpFeature!);

      List<String> interceptedLayerName = await findIntersectingLayers(
        wtpFeature,
        _map,
      );

      // ——— FEATURE DEPENDENCY CHECK (Sequence) ———
      // Find index of new layer name, if > 0, its dependency is previous one in the list
      debugPrint("wtpLayerNames $wtpLayerNames");
      debugPrint("_selectedLayer!.name ${_selectedLayer!.name}");
      int currentIdx = wtpLayerNames.indexOf(_selectedLayer!.name);
      if (currentIdx > 0) {
        String requiredName = wtpLayerNames[currentIdx - 1];
        if (!interceptedLayerName.contains(requiredName)) {
          // Dependency missing, show dialog
          showMessageDialog(
            'You need to add "$requiredName" first before "${_selectedLayer!.name}".',
          );
          await _selectedtable!.deleteFeature(newFeature);
          newFeature.refresh();
          return false;
        }
      }

      // // ——— SUBTYPE CHECK ———
      debugPrint("wtpFeatureSubtype ${wtpFeatureSubtype}");
      debugPrint("newFeatureSubtype ${newFeatureSubtype}");
      debugPrint("wtpFeatureSubtype!.name ${wtpFeatureSubtype!.name}");
      debugPrint("newFeatureSubtype!.name ${newFeatureSubtype!.name}");
      debugPrint("wtpFeatureSubtype!.name ${wtpFeatureSubtype.code}");
      debugPrint("newFeatureSubtype!.name ${newFeatureSubtype.code}");
      // bool? subtypeMatched = wtpFeatureSubtype.code.contains(newFeatureSubtype.code);
      bool? subtypeMatched = wtpFeatureSubtype.code == newFeatureSubtype.code;
      if (!subtypeMatched) {
        showMessageDialog(
          'Subtype mismatch. WTP layer has subtype: ${wtpFeatureSubtype!.name}.\n'
          'New feature subtype is: ${newFeatureSubtype!.name}',
        );
        await _selectedtable!.deleteFeature(newFeature);
        newFeature.refresh();
        return false;
      } else {
        debugPrint("Feature Subtype Match");
      }
      return true;
    } catch (e) {
      // Handle errors (query, dialog, etc.)
      debugPrint('Error: ${e.toString()}');
      showMessageDialog('Error: ${e.toString()}');
      await _selectedtable!.deleteFeature(newFeature);
      newFeature.refresh();
      return false;
    }
  }

  Future<Feature?> checkFeatureInterceptWTP(Geometry? featureGeometry) async {
    debugPrint("LayerPresent ${_selectedLayer!.name}");

    debugPrint("checkFeatureInterceptWTP ");
    final wtpLayer = _map.operationalLayers
        .whereType<FeatureLayer>()
        .firstWhere(
          (layer) => layer.name == 'WTP',
          orElse: () => throw Exception('WTP layer not found'),
        );
    debugPrint("checkFeatureInterceptWTP  $wtpLayer");
    // Create QueryParameters with spatial relationship 'intersects' and no geometry return
    final queryParams =
        QueryParameters()
          ..geometry = featureGeometry
          ..spatialRelationship = SpatialRelationship.intersects
          ..returnGeometry = false;
    debugPrint("checkFeatureInterceptWTP queryParams $queryParams");
    // Use the featureTable from the layer, cast as ServiceFeatureTable
    ArcGISFeatureTable? featureTable;
    if (wtpLayer.featureTable is ServiceFeatureTable) {
      featureTable = wtpLayer.featureTable as ServiceFeatureTable;
      debugPrint("checkFeatureInterceptWTP featureTable $featureTable");
    } else if (wtpLayer.featureTable is GeodatabaseFeatureTable) {
      featureTable = wtpLayer.featureTable as GeodatabaseFeatureTable;
      debugPrint("checkFeatureInterceptWTP featureTable $featureTable");
    }
    // Perform the query on the feature table
    // final queryResult = await featureTable.queryFeatures(queryParams);
    FeatureQueryResult? queryResult;
    if (featureTable is ServiceFeatureTable) {
      queryResult = await featureTable.queryFeaturesWithFieldOptions(
        parameters: queryParams,
        queryFeatureFields:
            QueryFeatureFields.loadAll, // Option to load all fields
      );
      debugPrint("checkFeatureInterceptWTP queryResult $queryResult");
    } else if (wtpLayer.featureTable is GeodatabaseFeatureTable) {
      queryResult = await (featureTable as GeodatabaseFeatureTable)
          .queryFeatures(queryParams);
      debugPrint("checkFeatureInterceptWTP queryResult $queryResult");
    }

    // Get the features from the query result
    final features = queryResult?.features();
    debugPrint(
      "checkFeatureInterceptWTP features.isNotEmpty ${features?.isNotEmpty}",
    );
    if (features != null && features.isNotEmpty) {
      final firstFeature = features.first;
      return firstFeature;
    } else {
      return null;
    }
  }

  List<Map<String, dynamic>> schemeList = [];

  Future<Map<String, dynamic>?> getSchemeNameFromExtent(
    Geometry? featureGeometry,
  ) async {
    // Find the FeatureLayer named 'SchemeExtent' from the map's operational layers
    debugPrint("getSchemeNameFromExtent ");
    schemeList = [];
    final schemeExtentLayer = _map.operationalLayers
        .whereType<FeatureLayer>()
        .firstWhere(
          (layer) => layer.name == 'SchemeExtent',
          orElse: () => throw Exception('SchemeExtent layer not found'),
        );
    debugPrint("getSchemeNameFromExtent schemeExtentLayer $schemeExtentLayer");
    // Create QueryParameters with spatial relationship 'intersects' and no geometry return
    final queryParams =
        QueryParameters()
          ..geometry = featureGeometry
          ..spatialRelationship = SpatialRelationship.intersects
          ..returnGeometry = false;
    debugPrint("getSchemeNameFromExtent queryParams $queryParams");
    // Use the featureTable from the layer, cast as ServiceFeatureTable
    ArcGISFeatureTable? featureTable;
    if (schemeExtentLayer.featureTable is ServiceFeatureTable) {
      featureTable = schemeExtentLayer.featureTable as ServiceFeatureTable;
      debugPrint("getSchemeNameFromExtent featureTable $featureTable");
    } else if (schemeExtentLayer.featureTable is GeodatabaseFeatureTable) {
      featureTable = schemeExtentLayer.featureTable as GeodatabaseFeatureTable;
      debugPrint("getSchemeNameFromExtent featureTable $featureTable");
    }
    // Perform the query on the feature table
    // final queryResult = await featureTable.queryFeatures(queryParams);
    FeatureQueryResult? queryResult;
    if (featureTable is ServiceFeatureTable) {
      queryResult = await featureTable.queryFeaturesWithFieldOptions(
        parameters: queryParams,
        queryFeatureFields:
            QueryFeatureFields.loadAll, // Option to load all fields
      );
      debugPrint("getSchemeNameFromExtent queryResult $queryResult");
    } else if (schemeExtentLayer.featureTable is GeodatabaseFeatureTable) {
      queryResult = await (featureTable as GeodatabaseFeatureTable)
          .queryFeatures(queryParams);
      debugPrint("getSchemeNameFromExtent queryResult $queryResult");
    }

    // Get the features from the query result
    final features = queryResult?.features();
    debugPrint(
      "getSchemeNameFromExtent features.isNotEmpty ${features?.isNotEmpty}",
    );
    if (features != null && features.isNotEmpty) {
      for (final f in features) {
        final attributes = f.attributes;
        final schemename = attributes['schemename']?.toString();
        final schemeid = attributes['schemeid'];

        if (schemename != null && schemeid != null) {
          schemeList.add({"schemeid": schemeid, "schemename": schemename});
        }
      }
      final firstFeature = features.first;
      final attributes = firstFeature.attributes;
      debugPrint('getSchemeNameFromExtent attributes: $attributes');
      // Safely extract schemename and schemeid attributes
      final schemename = attributes['schemename'] as String?;
      final schemeid = attributes['schemeid'] as int?;

      debugPrint('Scheme Name: $schemename');
      debugPrint('Scheme ID: $schemeid');

      // Return the attributes map
      return attributes;
    }
    return null;
  }
}

extension on String {
  // An extension on String to capitalize the first character of the String.
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
