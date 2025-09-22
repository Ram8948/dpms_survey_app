import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AuthenticateAndExportOffline extends StatefulWidget {
  const AuthenticateAndExportOffline({super.key});

  @override
  State<AuthenticateAndExportOffline> createState() => _AuthenticateAndExportOfflineState();
}

class _AuthenticateAndExportOfflineState extends State<AuthenticateAndExportOffline> implements ArcGISAuthenticationChallengeHandler {
  final _mapViewController = ArcGISMapView.createController();

  // OAuth configuration - update with your portal/clientId/redirectUri
  final _oauthUserConfiguration = OAuthUserConfiguration(
    portalUri: Uri.parse('https://gis.mjpdpms.in/agportal/'), // Your portal URL
    clientId: 'ozfJbEjPm5MbOsNq',                            // Your client ID
    redirectUri: Uri.parse('my-ags-flutter-app://auth'),     // Your app redirect scheme
  );

  ExportVectorTilesJob? _exportVectorTilesJob;
  double _progress = 0.0;
  bool _jobRunning = false;
  bool _showRedOutline = true;

  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _outlineKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Set the authentication challenge handler for OAuth sign-in
    ArcGISEnvironment.authenticationManager.arcGISAuthenticationChallengeHandler = this;
  }

  @override
  void dispose() {
    // Remove the challenge handler when done
    ArcGISEnvironment.authenticationManager.arcGISAuthenticationChallengeHandler = null;
    // Cancel any running export job
    _exportVectorTilesJob?.cancel();

    // Revoke OAuth tokens and clear credentials on dispose
    Future.wait(
        ArcGISEnvironment.authenticationManager.arcGISCredentialStore
            .getCredentials()
            .whereType<OAuthUserCredential>()
            .map((cred) => cred.revokeToken())
    ).catchError((error) {
      print('Error revoking tokens: $error');
      return [];
    }).whenComplete(() {
      ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();
    });

    super.dispose();
  }

  @override
  Future<void> handleArcGISAuthenticationChallenge(
      ArcGISAuthenticationChallenge challenge) async {
    try {
      final credential = await OAuthUserCredential.create(
        configuration: _oauthUserConfiguration,
      );
      challenge.continueWithCredential(credential);
    } on ArcGISException catch (error) {
      final e = (error.wrappedException as ArcGISException?) ?? error;
      if (e.errorType == ArcGISExceptionType.commonUserCanceled) {
        challenge.cancel();
      } else {
        challenge.continueAndFail();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authenticate and Export Offline')),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ArcGISMapView(
                        key: _mapKey,
                        controllerProvider: () => _mapViewController,
                        onMapViewReady: onMapViewReady,
                      ),
                      if (_showRedOutline)
                        IgnorePointer(
                          child: SafeArea(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(30, 30, 30, 50),
                              child: Container(
                                key: _outlineKey,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: _jobRunning ? null : startExportVectorTiles,
                    child: const Text('Export Vector Tiles'),
                  ),
                ),
                if (_jobRunning)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text('Export Progress: ${(_progress * 100).toStringAsFixed(1)}%'),
                        LinearProgressIndicator(value: _progress),
                        TextButton(
                          onPressed: () => _exportVectorTilesJob?.cancel(),
                          child: const Text('Cancel Export'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Load a secure web map item using the authenticated portal
    final portal = Portal(
      Uri.parse('https://gis.mjpdpms.in/agportal/'),
      connection: PortalConnection.authenticated,
    );
    await portal.load();

    final portalItem = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: "e8e7e57251f04268a74bef95768071da", // Your secured web map item
    );
    await portalItem.load();

    final map = ArcGISMap.withItem(portalItem);
    await map.load();

    _mapViewController.arcGISMap = map;
  }

  Envelope? _calculateDownloadArea() {
    final outlineContext = _outlineKey.currentContext;
    final mapContext = _mapKey.currentContext;
    if (outlineContext == null || mapContext == null) return null;

    final outlineBox = outlineContext.findRenderObject() as RenderBox?;
    final outlineGlobalRect = outlineBox!.localToGlobal(Offset.zero) & outlineBox.size;

    final mapBox = mapContext.findRenderObject() as RenderBox?;
    final mapLocalRect = outlineGlobalRect.shift(-mapBox!.localToGlobal(Offset.zero));

    final topLeft = _mapViewController.screenToLocation(screen: mapLocalRect.topLeft);
    final bottomRight = _mapViewController.screenToLocation(screen: mapLocalRect.bottomRight);

    if (topLeft == null || bottomRight == null) return null;

    return Envelope.fromPoints(topLeft, bottomRight);
  }

  Future<void> startExportVectorTiles() async {
    final envelope = _calculateDownloadArea();
    if (envelope == null) {
      _showMessage('Invalid selection area.');
      return;
    }

    final baseLayer = _mapViewController.arcGISMap?.basemap?.baseLayers.first;
    if (baseLayer == null || baseLayer is! ArcGISVectorTiledLayer || baseLayer.uri == null) {
      _showMessage('No vector tiled base layer available for export.');
      return;
    }

    setState(() {
      _jobRunning = true;
      _progress = 0.0;
      _showRedOutline = false;
    });

    try {
      final exportTask = ExportVectorTilesTask.withUri(baseLayer.uri!);
      await exportTask.load();

      final parameters = await exportTask.createDefaultExportVectorTilesParameters(
        areaOfInterest: envelope,
        maxScale: 0, // 0 means export all detail levels (no tile limits)
      );

      final documentsDir = await getApplicationDocumentsDirectory();
      final saveFile = File('${documentsDir.path}/exportedVectorTiles.vtpk');

      _exportVectorTilesJob = exportTask.exportVectorTilesWithItemResourceCache(
        parameters: parameters,
        vectorTileCacheUri: saveFile.uri,
        itemResourceCacheUri: Uri.directory(documentsDir.path),
      );

      _exportVectorTilesJob!.onProgressChanged.listen((progress) {
        setState(() {
          _progress = progress * 0.01;
        });
      });

      _exportVectorTilesJob!.onStatusChanged.listen((status) {
        if (status == JobStatus.succeeded) {
          _loadDownloadedVectorTiles(_exportVectorTilesJob!.result);
          _showMessage('Export completed successfully');
          setState(() {
            _jobRunning = false;
          });
        } else if (status == JobStatus.failed) {
          _showMessage('Export failed');
          setState(() {
            _jobRunning = false;
          });
        }
      });

      await _exportVectorTilesJob!.run();
    } on ArcGISException catch (e) {
      _showMessage('Error during export: ${e.message}');
      setState(() {
        _jobRunning = false;
      });
    }
  }

  void _loadDownloadedVectorTiles(ExportVectorTilesResult? result) {
    if (result == null || result.vectorTileCache == null || result.itemResourceCache == null) {
      _showMessage('Invalid exported vector tiles result');
      return;
    }

    final vectorTileLayer = ArcGISVectorTiledLayer.withVectorTileCache(
      result.vectorTileCache!,
      itemResourceCache: result.itemResourceCache!,
    );

    final basemap = Basemap.withBaseLayer(vectorTileLayer);
    final offlineMap = ArcGISMap.withBasemap(basemap);
    _mapViewController.arcGISMap = offlineMap;

    setState(() {
      _showRedOutline = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
