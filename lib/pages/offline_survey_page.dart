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
                      Visibility(
                        visible: _progress == null && !_offline,
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
                      // Add a red outline that marks the region to be taken offline.
        // Visibility(
        //   visible: _progress == null && !_offline && !_hasLocalMap,
        //   child: IgnorePointer(
        //     child: SafeArea(
        //       child: LayoutBuilder(
        //         builder: (context, constraints) {
        //           // Optionally you can log or interact with the widget size here
        //           final double containerSize = 200.0; // Or any dynamic size you want to use here
        //
        //           return Center(
        //             child: Container(
        //               key: _outlineKey,
        //               width: containerSize,
        //               height: containerSize,
        //               decoration: BoxDecoration(
        //                 border: Border.all(
        //                   color: Colors.red,
        //                   width: 2,
        //                 ),
        //               ),
        //             ),
        //           );
        //         },
        //       ),
        //     ),
        //   ),
        // ),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab1',
            onPressed: () async {
              if (_map != null) {
                final Viewpoint? sourceViewpoint = await _mapViewController.getCurrentViewpoint(ViewpointType.centerAndScale);
                final result = Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SnapGeometryEdits(
                      portalUri: widget.portalUri,
                      webMapItemId: widget.webMapItemId,
                      isOffline: true, viewPoint:sourceViewpoint!,
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
            child: const Icon(Icons.add),
          ),
          SizedBox(height: 16), // spacing between buttons
          FloatingActionButton(
            heroTag: 'fab2',
            onPressed: _syncOfflineData,
            tooltip: 'Sync Data',
            child: const Icon(Icons.sync),
          ),
        ],
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

  Future<void> _syncOfflineData() async {
    setState(() {
      _loadingFeature = true;
    });
    try {
      if (_map == null) throw Exception("Map not loaded");
      Geodatabase? geodatabase;
      for (var table in _map!.tables) {
        if (table is GeodatabaseFeatureTable) {
          geodatabase = table.geodatabase;
          break;
        }
      }
      if (geodatabase == null) throw Exception("No geodatabase found in map");

      final serviceUrl = Uri.parse("https://gis.mjpdpms.in/agserver/rest/services/DPMSTEST/CN1_Web_Actual_Testing/FeatureServer");
      if (serviceUrl.toString().isEmpty) throw Exception("Service URL is empty");

      final syncTask = GeodatabaseSyncTask.withUri(serviceUrl);
      final syncParams = await syncTask.createDefaultSyncGeodatabaseParameters(geodatabase);
      if (syncParams == null) throw Exception("Sync parameters are null");

      final syncJob = syncTask.syncGeodatabase(parameters: syncParams, geodatabase: geodatabase);


      debugPrint("SyncJob $syncJob");

      syncJob.onStatusChanged.listen((status) {
        debugPrint('Sync status: $status');

        if (status == JobStatus.succeeded) {
          setState(() {
            _progress = null;
            _loadingFeature = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Offline data synchronized successfully.')),
          );
        } else if (status == JobStatus.failed) {
          setState(() {
            _loadingFeature = false;
            _progress = null;
          });
          debugPrint('Sync failed: ${syncJob.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sync failed: ${syncJob.error?.message ?? 'Unknown error'}')),
          );
        }
      });

      // Listen to progress optionally
      syncJob.onProgressChanged.listen((progress) {
        debugPrint("Sync progress: $progress%");
        setState(() {
          _progress = progress;
        });
      });

      syncJob.start();

      // if (syncJob.status == JobStatus.succeeded) {
      //   debugPrint("Sync completed successfully.");
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Offline data synchronized successfully.')),
      //   );
      // } else {
      //   debugPrint("Sync failed: ${syncJob.error}");
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Sync failed: ${syncJob.error?.message ?? "Unknown error"}')),
      //   );
      // }
    } catch (e) {
      debugPrint("Sync error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync error: $e')),
      );
    } finally {
      setState(() {
        _loadingFeature = false;
        _progress = null;
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

          showFeatureActionPopup(feature, featureLayer, featurePopup, false,() {
            // Navigator.pop(context);
            // if (mounted) {
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     const SnackBar(
            //       content: Text('Feature successfully updated'),
            //     ),
            //   );
            // }
          },[]);
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

    _mapViewController.interactionOptions.rotateEnabled = false;
    _offlineMapTask = OfflineMapTask.withOnlineMap(_map!);
    // _offlineMapTask = OfflineMapTask.withPortalItem(portalItem);

    setState(() => _ready = true);
  }

  Envelope? outlineEnvelopeFixedSize({double size = 200}) {
    final outlineContext = _outlineKey.currentContext;
    final mapContext = _mapKey.currentContext;
    if (outlineContext == null || mapContext == null) return null;

    final outlineRenderBox = outlineContext.findRenderObject() as RenderBox?;
    final outlineGlobalScreenRect =
    outlineRenderBox!.localToGlobal(Offset.zero) & outlineRenderBox.size;

    final mapRenderBox = mapContext.findRenderObject() as RenderBox?;
    final mapLocalScreenRect = outlineGlobalScreenRect.shift(
      -mapRenderBox!.localToGlobal(Offset.zero),
    );

    final locationTopLeft = _mapViewController.screenToLocation(
      screen: mapLocalScreenRect.topLeft,
    );
    final locationBottomRight = _mapViewController.screenToLocation(
      screen: mapLocalScreenRect.bottomRight,
    );
    if (locationTopLeft == null || locationBottomRight == null) return null;

    // Calculate center point from current envelope
    final centerX = (locationTopLeft.x + locationBottomRight.x) / 2;
    final centerY = (locationTopLeft.y + locationBottomRight.y) / 2;

    final halfSize = size / 2;

    // Create new envelope with fixed size centered on the center point
    return Envelope.fromXY(
      xMin: centerX - halfSize,
      yMin: centerY - halfSize,
      xMax: centerX + halfSize,
      yMax: centerY + halfSize,
      spatialReference: locationTopLeft.spatialReference,
    );
  }


  // Calculate the Envelope of the outlined region.
  Envelope? outlineEnvelope() {
    final outlineContext = _outlineKey.currentContext;
    final mapContext = _mapKey.currentContext;
    if (outlineContext == null || mapContext == null) return null;

    final outlineRenderBox = outlineContext.findRenderObject() as RenderBox?;
    final outlineGlobalScreenRect =
    outlineRenderBox!.localToGlobal(Offset.zero) & outlineRenderBox.size;

    final mapRenderBox = mapContext.findRenderObject() as RenderBox?;
    final mapLocalScreenRect = outlineGlobalScreenRect.shift(
      -mapRenderBox!.localToGlobal(Offset.zero),
    );

    final locationTopLeft = _mapViewController.screenToLocation(
      screen: mapLocalScreenRect.topLeft,
    );
    final locationBottomRight = _mapViewController.screenToLocation(
      screen: mapLocalScreenRect.bottomRight,
    );
    if (locationTopLeft == null || locationBottomRight == null) return null;

    return Envelope.fromPoints(locationTopLeft, locationBottomRight);
  }

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

  // Utility to split envelope into grid of smaller envelopes (chunks)
  List<Envelope> splitEnvelopeIntoChunks(Envelope envelope, int rows, int cols) {
    double width = (envelope.xMax - envelope.xMin) / cols;
    double height = (envelope.yMax - envelope.yMin) / rows;

    List<Envelope> chunks = [];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        double xmin = envelope.xMin + col * width;
        double ymin = envelope.yMin + row * height;
        double xmax = xmin + width;
        double ymax = ymin + height;
        chunks.add(Envelope.fromXY(xMin: xmin, yMin: ymin, xMax: xmax, yMax: ymax, spatialReference: envelope.spatialReference));
      }
    }
    return chunks;
  }

  // Future<void> takeOfflineChunked() async {
  //   final fullEnvelope = outlineEnvelopeFixedSize(size: 400); // or your full area
  //
  //   if (fullEnvelope == null) {
  //     await showAlertDialog(context, "Envelope couldn't be determined.");
  //     return;
  //   }
  //
  //   // Split into 4x4 grid (adjust rows/cols for chunk size)
  //   int rows = 4;
  //   int cols = 4;
  //   List<Envelope> chunks = splitEnvelopeIntoChunks(fullEnvelope, rows, cols);
  //
  //   setState(() {
  //     _progress = 0;
  //   });
  //
  //   // Directory to save all offline chunks
  //   final documentsUri = (await getApplicationDocumentsDirectory()).uri;
  //   final baseDownloadDirUri = documentsUri.resolve('offline_map_chunks/');
  //   final baseDownloadDir = Directory.fromUri(baseDownloadDirUri);
  //   if (baseDownloadDir.existsSync()) {
  //     baseDownloadDir.deleteSync(recursive: true);
  //   }
  //   baseDownloadDir.createSync();
  //
  //   int completed = 0;
  //
  //   for (int i = 0; i < chunks.length; i++) {
  //     Envelope chunkEnvelope = chunks[i];
  //     final minScale = calculateMinScaleFromEnvelope(chunkEnvelope);
  //     if (minScale <= 0) {
  //       await showAlertDialog(context, "Invalid minScale calculated for chunk.");
  //       return;
  //     }
  //
  //     final parameters = await _offlineMapTask.createDefaultGenerateOfflineMapParameters(
  //       areaOfInterest: chunkEnvelope,
  //       minScale: minScale,
  //     );
  //     parameters.continueOnErrors = false;
  //
  //     final chunkDirUri = baseDownloadDirUri.resolve('chunk_$i/');
  //     final chunkDir = Directory.fromUri(chunkDirUri);
  //     if (chunkDir.existsSync()) chunkDir.deleteSync(recursive: true);
  //     chunkDir.createSync();
  //
  //     _generateOfflineMapJob = _offlineMapTask.generateOfflineMap(
  //       parameters: parameters,
  //       downloadDirectoryUri: chunkDirUri,
  //     );
  //
  //     // Listen to progress for this chunk
  //     _generateOfflineMapJob!.onProgressChanged.listen((progress) {
  //       // Calculate overall progress across all chunks
  //       int overallProgress = ((completed + progress / 100) / chunks.length * 100).toInt();
  //       setState(() {
  //         _progress = overallProgress;
  //       });
  //     });
  //
  //     try {
  //       final result = await _generateOfflineMapJob!.run();
  //       _map = result.offlineMap!;
  //       // Optionally combine or load chunk offline maps later as needed
  //       completed++;
  //     } on ArcGISException catch (e) {
  //       debugPrint('Chunk $i failed: ${e.message}');
  //       await showAlertDialog(context, 'Chunk $i failed: ${e.message}');
  //       return;
  //     }
  //   }
  //
  //   setState(() {
  //     _progress = null;
  //     _offline = true;
  //   });
  //
  //   await showAlertDialog(context, "All chunks downloaded successfully.");
  // }

  // Take the selected region offline.
  Future<void> takeOffline() async {
    final envelope = outlineEnvelope();
    // final envelope = outlineEnvelopeFixedSize();
    if (envelope == null) {
      await showAlertDialog(context, "Envelope couldn't be determined.");
      return;
    }
    if (envelope.xMin >= envelope.xMax || envelope.yMin >= envelope.yMax) {
      await showAlertDialog(context, "Invalid envelope coordinates.");
      return;
    }
    const minScale = 1e5;
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

    _generateOfflineMapJob!.onStatusChanged.listen((status) {
      debugPrint('status value: $status');
      if (status == JobStatus.succeeded) {
        // handle success - get .result.offlineMap etc.
      }
      else if (status == JobStatus.failed) {
        if(_generateOfflineMapJob!=null) {
          final error = _generateOfflineMapJob?.error;
          if (error != null) {
            // If error is ArcGISException, print message property
            debugPrint('Offline map job failed: ${error.message}');
                    } else {
            debugPrint('Offline map job failed with unknown error');
          }
        }



        // Try to get failed region if available
        // final failedRegion = _generateOfflineMapJob!.failedArea;
        // if (failedRegion != null) {
        //   debugPrint('Failed region envelope: $failedRegion');
        //   // Use the envelope extents for diagnostics or UI
        // }
      }
    });

    try {
    final result = await _generateOfflineMapJob!.run();
    // final result = await _generateOfflineMapJob!.start();
    if(!result.hasErrors) {
      _map = result.offlineMap;
      _mapViewController.arcGISMap = result.offlineMap;
      _generateOfflineMapJob = null;
    } else {
      result.layerErrors.forEach((layer, e) {
        // Report any error(s) for each layer ...
        debugPrint('e.message ${e.message} ERROR: -- $e');
      });

      result.tableErrors.forEach((featureTable, e) {
        // Report any error(s) for each table ...
        debugPrint('e.message ${e.message} ERROR: -- $e');
      });
    }
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
