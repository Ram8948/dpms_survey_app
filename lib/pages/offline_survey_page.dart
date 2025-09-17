import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:dpmssurveyapp/pages/snap_geometry_edits.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../common/sample_state_support.dart';
import 'attribute_edit_form.dart';
import 'package:path/path.dart' as path;
import 'dart:math';

class OfflineSurveyPage extends StatefulWidget {
  final Uri portalUri;
  final String webMapItemId;

  const OfflineSurveyPage({
    super.key,
    required this.portalUri,
    required this.webMapItemId,
  });

  @override
  State<OfflineSurveyPage> createState() => _OfflineSurveyPageState();
}

class _OfflineSurveyPageState extends State<OfflineSurveyPage>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Declare a map to be loaded later.
  ArcGISMap? _map;
  // Declare the OfflineMapTask.
  late final OfflineMapTask _offlineMapTask;
  // Declare the OfflineSurveyPageJob.
  GenerateOfflineMapJob? _generateOfflineMapJob;
  // Progress of the OfflineSurveyPageJob.
  int? _progress;
  // A flag for when the map is viewing offline data.
  var _offline = false;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // Declare global keys to be used when converting screen locations to map coordinates.
  final _mapKey = GlobalKey();
  final _outlineKey = GlobalKey();

  bool _loadingFeature = false;
  FeatureLayer? _selectedFeatureLayer;
  ArcGISFeature? _selectedFeature;

  // New flag to track if a local map is available
  bool _hasLocalMap = false;

  @override
  void initState() {
    super.initState();
    _checkLocalMap();
  }

  Future<void> _checkLocalMap() async {
    final documentsUri = (await getApplicationDocumentsDirectory()).uri;
    final localMapDirectory = Directory.fromUri(
      documentsUri.resolve('offline_map'),
    );
    setState(() {
      _hasLocalMap = localMapDirectory.existsSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Add a map view to the widget tree and set a controller.
                      ArcGISMapView(
                        key: _mapKey,
                        controllerProvider: () => _mapViewController,
                        onMapViewReady: onMapViewReady,
                        onTap: _handleMapTap,
                      ),
                      // Add a red outline that marks the region to be taken offline.
                      Visibility(
                        visible:
                            _progress == null && !_offline && !_hasLocalMap,
                        child: IgnorePointer(
                          child: SafeArea(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(30, 30, 30, 50),
                              child: Container(
                                key: _outlineKey,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Display the appropriate button based on map state
                if (_hasLocalMap && !_offline)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: loadLocalMap,
                        child: const Text('Load Offline Map'),
                      ),
                      ElevatedButton(
                        onPressed: downloadNewMap,
                        child: const Text('Download New Map'),
                      ),
                    ],
                  )
                else if (!_offline && !_hasLocalMap)
                  Center(
                    child: ElevatedButton(
                      onPressed: _progress != null ? null : takeOffline,
                      child: const Text('Take Map Offline'),
                    ),
                  )
                else
                  const SizedBox.shrink(), // No buttons if map is offline or downloading
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            // LoadingIndicator(visible: !_ready),
            // Display a progress indicator and a cancel button during the offline map generation.
            Visibility(
              visible: _progress != null,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width / 2,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Add a progress indicator.
                      Text('$_progress%'),
                      LinearProgressIndicator(
                        value: _progress != null ? _progress! / 100.0 : 0.0,
                      ),
                      // Add a button to cancel the job.
                      ElevatedButton(
                        onPressed: () => _generateOfflineMapJob?.cancel(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action when plus button is pressed.
          if (_map != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => SnapGeometryEdits(
                      portalUri: widget.portalUri,
                      webMapItemId: widget.webMapItemId,
                      isOffline: true,
                    ),
              ),
            );
          }
        },
        tooltip: 'Add Survey',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> loadLocalMap() async {
    setState(() {
      _loadingFeature = true;
    });
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      // final mmpkFilePath = path.join(documentsDir.path, 'offline_map', 'p13', 'mobile_map.mmap');
      final offlineMapFolderUri = documentsDir.uri.resolve('offline_map/');
      final mobileMapPackage = MobileMapPackage.withFileUri(
        offlineMapFolderUri,
      );
      // Note: Some SDK versions accept folder URI; if not, load layers individually
      await mobileMapPackage.load();

      // final file = File(mmpkFilePath);
      // if (!await file.exists()) {
      //   throw Exception('Mobile map package file does not exist at $mmpkFilePath');
      // }
      //
      // final mmpkFileUri = Uri.file(mmpkFilePath);
      // final mobileMapPackage = MobileMapPackage.withFileUri(mmpkFileUri);
      // await mobileMapPackage.load();

      if (mobileMapPackage.maps.isNotEmpty) {
        final map = mobileMapPackage.maps.first;

        _mapViewController.arcGISMap = map;
        setState(() {
          _map = map;
          _offline = true;
        });
      } else {
        throw Exception('No maps found in the mobile map package.');
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Failed to load local map: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load local map: $e')));
      }
    } finally {
      setState(() {
        _loadingFeature = false;
      });
    }
  }

  Future<void> downloadNewMap() async {
    setState(() {
      _hasLocalMap = false;
      _offline = false;
      // Load the online map again to enable the download button
      _mapViewController.arcGISMap = _map;
    });
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

          final List<Popup> popups =
              identifyResults
                  .where((result) => result.popups.isNotEmpty)
                  .expand((result) => result.popups)
                  .toList();
          Popup featurePopup = popups.first;
          debugPrint("featurePopup.title ${featurePopup.title}");
          debugPrint(
            "featurePopup.popupDefinition.title ${featurePopup.popupDefinition.title}",
          );
          for (var field in featurePopup.popupDefinition.fields) {
            // if ((field.isVisible ?? true)) {
            debugPrint('Editable & Visible PopupField:');
            debugPrint('  fieldName: ${field.fieldName}');
            debugPrint('  label: ${field.label}');
            debugPrint('  visible: ${field.isVisible}');
            debugPrint('  editable: ${field.isEditable}');
            debugPrint('  type: ${field.runtimeType}');
            debugPrint('  type: ${field.tooltip}');
            debugPrint('  type: ${field.stringFieldOption}');
            // }
          }
          _selectedFeatureLayer = featureLayer;
          _selectedFeature = feature;

          showFeatureActionPopup(feature, featureLayer, featurePopup);
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

  // void _showFeatureActionPopup(ArcGISFeature feature, FeatureLayer featureLayer) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return SafeArea(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: <Widget>[
  //             ListTile(
  //               leading: const Icon(Icons.edit),
  //               title: const Text('Update Feature'),
  //               onTap: () {
  //                 Navigator.pop(context); // Close the bottom sheet
  //                 // _openAttributeEditForm(feature, featureLayer);
  //               },
  //             ),
  //             ListTile(
  //               leading: const Icon(Icons.delete, color: Colors.red),
  //               title: const Text('Delete Feature', style: TextStyle(color: Colors.red)),
  //               onTap: () {
  //                 Navigator.pop(context); // Close the bottom sheet
  //                 _deleteFeature(feature, featureLayer);
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }
  //
  // Future<void> _deleteFeature(ArcGISFeature feature, FeatureLayer featureLayer) async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Confirm Deletion'),
  //         content: const Text('Are you sure you want to delete this feature? This action cannot be undone.'),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Cancel'),
  //             onPressed: () {
  //               Navigator.of(context).pop(false);
  //             },
  //           ),
  //           TextButton(
  //             style: TextButton.styleFrom(
  //               foregroundColor: Colors.red,
  //             ),
  //             child: const Text('Delete'),
  //             onPressed: () {
  //               Navigator.of(context).pop(true);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   ) ?? false;
  //
  //   if (!confirmed) {
  //     return;
  //   }
  //
  //   try {
  //     if (featureLayer.featureTable is GeodatabaseFeatureTable) {
  //       setState(() => _loadingFeature = true);
  //       final geodatabaseFeatureTable =
  //       featureLayer.featureTable as GeodatabaseFeatureTable;
  //       await geodatabaseFeatureTable.deleteFeature(feature);
  //
  //       // Clear selection and notify user
  //       featureLayer.clearSelection();
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Feature deleted successfully.')));
  //       }
  //     } else {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //             content: Text('Deletion is not supported for this layer.')));
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint("Delete failed: $e");
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Failed to delete feature: $e')));
  //     }
  //   } finally {
  //     setState(() => _loadingFeature = false);
  //   }
  // }

  // Future<void> _openAttributeEditForm(
  //     ArcGISFeature feature,
  //     FeatureLayer layer,
  //     ) async {
  //   await showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (context) => Padding(
  //       padding: MediaQuery.of(context).viewInsets,
  //       child: AttributeEditForm(
  //         feature: feature,
  //         featureTable: layer.featureTable! as GeodatabaseFeatureTable,
  //         onFormSaved: () {
  //           Navigator.pop(context);
  //           if (mounted) {
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               const SnackBar(
  //                 content: Text('Feature successfully updated'),
  //               ),
  //             );
  //           }
  //         },
  //         parentScaffoldContext: context,
  //       ),
  //     ),
  //   );
  // }

  Future<void> onMapViewReady() async {
    // final portalItem = PortalItem.withPortalAndItemId(
    //   portal: Portal.arcGISOnline(),
    //   itemId: 'acc027394bc84c2fb04d1ed317aac674',
    // );
    // _map = ArcGISMap.withItem(portalItem);
    // _mapViewController.arcGISMap = _map;
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

    _mapViewController.interactionOptions.rotateEnabled = false;
    _offlineMapTask = OfflineMapTask.withOnlineMap(_map!);

    setState(() => _ready = true);
  }

  // Calculate the Envelope of the outlined region.
  Envelope? outlineEnvelope() {
    final outlineContext = _outlineKey.currentContext;
    final mapContext = _mapKey.currentContext;
    if (outlineContext == null || mapContext == null) return null;

    // Get the global screen rect of the outlined region.
    final outlineRenderBox = outlineContext.findRenderObject() as RenderBox?;
    final outlineGlobalScreenRect =
        outlineRenderBox!.localToGlobal(Offset.zero) & outlineRenderBox.size;

    // Convert the global screen rect to a rect local to the map view.
    final mapRenderBox = mapContext.findRenderObject() as RenderBox?;
    final mapLocalScreenRect = outlineGlobalScreenRect.shift(
      -mapRenderBox!.localToGlobal(Offset.zero),
    );

    // Convert the local screen rect to map coordinates.
    final locationTopLeft = _mapViewController.screenToLocation(
      screen: mapLocalScreenRect.topLeft,
    );
    final locationBottomRight = _mapViewController.screenToLocation(
      screen: mapLocalScreenRect.bottomRight,
    );
    if (locationTopLeft == null || locationBottomRight == null) return null;

    // Create an Envelope from the map coordinates.
    return Envelope.fromPoints(locationTopLeft, locationBottomRight);
  }

  // Calculate the Envelope of the outlined region.
  // Envelope? outlineEnvelope() {
  //   final outlineContext = _outlineKey.currentContext;
  //   final mapContext = _mapKey.currentContext;
  //   if (outlineContext == null || mapContext == null) return null;
  //
  //   final outlineRenderBox = outlineContext.findRenderObject() as RenderBox?;
  //   final outlineGlobalScreenRect =
  //   outlineRenderBox!.localToGlobal(Offset.zero) & outlineRenderBox.size;
  //
  //   final mapRenderBox = mapContext.findRenderObject() as RenderBox?;
  //   final mapLocalScreenRect = outlineGlobalScreenRect.shift(
  //     -mapRenderBox!.localToGlobal(Offset.zero),
  //   );
  //
  //   final locationTopLeft = _mapViewController.screenToLocation(
  //     screen: mapLocalScreenRect.topLeft,
  //   );
  //   final locationBottomRight = _mapViewController.screenToLocation(
  //     screen: mapLocalScreenRect.bottomRight,
  //   );
  //   if (locationTopLeft == null || locationBottomRight == null) return null;
  //
  //   return Envelope.fromPoints(locationTopLeft, locationBottomRight);
  // }

  double calculateMinScaleFromEnvelope(Envelope envelope) {
    // Approximate display width in pixels (adjust this to your map widget size)
    const int screenWidthPx = 400;
    // Common screen DPI for most devices
    const double dpi = 96.0;
    // Conversion factor from meters to inches
    const double inchesPerMeter = 39.37;

    // Calculate envelope width in map units (typically meters)
    final double envelopeWidth = envelope.xMax - envelope.xMin;

    // Calculate map units per pixel
    final double mapUnitsPerPixel = envelopeWidth / screenWidthPx;

    // Calculate scale denominator
    final double scale = mapUnitsPerPixel * dpi * inchesPerMeter;

    return scale;
  }

  // double minScale = 5e5;
  //
  // Future<void> zoomToMinScale() async {
  //   try {
  //     // Get current viewpoint asynchronously
  //     final currentViewpoint = await _mapViewController.getCurrentViewpoint();
  //
  //     // Extract center point geometry from viewpoint
  //     final center = currentViewpoint.targetGeometry as Point;
  //
  //     // Create a viewpoint with center and scale using named constructor
  //     final viewpoint = Viewpoint.centerScale(center, minScale);
  //
  //     // Set viewpoint on the controller
  //     await _mapViewController.setViewpoint(viewpoint);
  //   } catch (e) {
  //     debugPrint('Failed to zoom to minScale: $e');
  //   }
  // }

  // Take the selected region offline.
  Future<void> takeOffline() async {
    final envelope = outlineEnvelope();
    if (envelope == null) {
      await showAlertDialog(context, "Envelope couldn't be determined.");
      return;
    }
    if (envelope.xMin >= envelope.xMax || envelope.yMin >= envelope.yMax) {
      await showAlertDialog(context, "Invalid envelope coordinates.");
      return;
    }
    const minScale = 1e4;
    // final minScale = calculateMinScaleFromEnvelope(envelope);
    if (minScale <= 0) {
      await showAlertDialog(context, "Invalid minScale calculated.");
      return;
    }

    setState(() => _progress = 0);

    // const minScale = 5e5;
    // const minScale = 1e5;
    // final minScale = calculateMinScaleFromEnvelope(envelope);
    debugPrint(
      'Envelope: xmin=${envelope.xMin}, ymin=${envelope.yMin}, xmax=${envelope.xMax}, ymax=${envelope.yMax}',
    );
    debugPrint(
      'Envelope spatial reference: ${envelope.spatialReference?.wkid}',
    );
    debugPrint('MinScale value: $minScale');

    final parameters = await _offlineMapTask
        .createDefaultGenerateOfflineMapParameters(
          areaOfInterest: envelope,
          minScale: minScale,
        );
    parameters.continueOnErrors = false;
    final documentsUri = (await getApplicationDocumentsDirectory()).uri;
    final downloadDirectoryUri = documentsUri.resolve('offline_map');
    final downloadDirectory = Directory.fromUri(downloadDirectoryUri);
    if (downloadDirectory.existsSync()) {
      downloadDirectory.deleteSync(recursive: true);
    }
    downloadDirectory.createSync();

    _generateOfflineMapJob = _offlineMapTask.generateOfflineMap(
      parameters: parameters,
      downloadDirectoryUri: downloadDirectoryUri,
    );

    _generateOfflineMapJob!.onProgressChanged.listen((progress) {
      setState(() => _progress = progress);
    });

    try {
    final result = await _generateOfflineMapJob!.run();

    _map = result.offlineMap;
    _mapViewController.arcGISMap = result.offlineMap;
    _generateOfflineMapJob = null;
    } on ArcGISException catch (e) {
    debugPrint('ArcGISException: ${e.message}, code=${e.code}, type=${e.errorType} additionalMessage=${e.additionalMessage}');
    _generateOfflineMapJob = null;
    setState(() => _progress = null);

    if (e.errorType != ArcGISExceptionType.commonUserCanceled && mounted) {
      debugPrint('e.message ${e.message} ERROR: -- $e');
      await showAlertDialog(context, e.message);
    }
    return;
    }

    setState(() {
      _progress = null;
      _offline = true;
    });
  }

  Future<void> showAlertDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
