import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';

class AuthenticateWithOAuthOffline extends StatefulWidget {
  const AuthenticateWithOAuthOffline({super.key});

  @override
  State<AuthenticateWithOAuthOffline> createState() => _AuthenticateWithOAuthOfflineState();
}

class _AuthenticateWithOAuthOfflineState extends State<AuthenticateWithOAuthOffline> implements ArcGISAuthenticationChallengeHandler {
  final _mapViewController = ArcGISMapView.createController();

  final _oauthUserConfiguration = OAuthUserConfiguration(
    portalUri: Uri.parse('https://gis.mjpdpms.in/agportal/'),      // Use your portal if needed
    clientId: 'ozfJbEjPm5MbOsNq',                        // Your registered clientId
    redirectUri: Uri.parse('my-ags-flutter-app://auth'), // Your scheme
  );

  late ArcGISMap _map;
  late OfflineMapTask _offlineMapTask;
  GenerateOfflineMapJob? _generateOfflineMapJob;

  int? _progress;
  var _offline = false;
  var _ready = false;

  // Outline keys for selecting download area
  final _mapKey = GlobalKey();
  final _outlineKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Set this class to the arcGISAuthenticationChallengeHandler property on the authentication manager.
    // This class implements the ArcGISAuthenticationChallengeHandler interface,
    // which allows it to handle authentication challenges via calls to its
    // handleArcGISAuthenticationChallenge() method.
    ArcGISEnvironment
        .authenticationManager
        .arcGISAuthenticationChallengeHandler = this;
  }

  @override
  void dispose() {
    // We do not want to handle authentication challenges outside of this sample,
    // so we remove this as the challenge handler.
    ArcGISEnvironment
        .authenticationManager
        .arcGISAuthenticationChallengeHandler = null;

    // Revoke OAuth tokens and remove all credentials to log out.
    Future.wait(
      ArcGISEnvironment.authenticationManager.arcGISCredentialStore
          .getCredentials()
          .whereType<OAuthUserCredential>()
          .map((credential) => credential.revokeToken()),
    )
        .catchError((error) {
      // This sample has been disposed, so we can only report errors to the console.
      // ignore: avoid_print
      print('Error revoking tokens: $error');
      return [];
    })
        .whenComplete(() {
      ArcGISEnvironment.authenticationManager.arcGISCredentialStore
          .removeAll();
    });

    super.dispose();
  }

  @override
  Future<void> handleArcGISAuthenticationChallenge(
      ArcGISAuthenticationChallenge challenge,
      ) async {
    try {
      // Initiate the sign in process to the OAuth server using the defined user configuration.
      final credential = await OAuthUserCredential.create(
        configuration: _oauthUserConfiguration,
      );

      // Sign in was successful, so continue with the provided credential.
      challenge.continueWithCredential(credential);
    } on ArcGISException catch (error) {
      // Sign in was canceled, or there was some other error.
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
      body: SafeArea(
        top: false, left: false, right: false,
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
                    ],
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: _progress != null || _offline ? null : takeOffline,
                    child: const Text('Take Map Offline'),
                  ),
                ),
              ],
            ),
            // Display job progress indicator
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
                      Text('${_progress ?? 0}%'),
                      LinearProgressIndicator(
                        value: _progress != null ? _progress! / 100.0 : 0.0,
                      ),
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
    );
  }

  Future<void> onMapViewReady() async {
    // Replace with your secured web map item ID as needed
    // final portalItem = PortalItem.withPortalAndItemId(
    //   portal: Portal.arcGISOnline(connection: PortalConnection.authenticated),
    //   itemId: 'e5039444ef3c48b8a8fdc9227f9be7c1',
    // );
    // await portalItem.load();
    final portal = Portal(
      Uri.parse('https://gis.mjpdpms.in/agportal/'),
      connection: PortalConnection.authenticated,
    );
    await portal.load();
    final portalItem = PortalItem.withPortalAndItemId(
      portal: portal,
      itemId: "e8e7e57251f04268a74bef95768071da",
    );
    await portalItem.load();

    // _map = ArcGISMap.withItem(portalItem);
    // await _map?.load();
    _map = ArcGISMap.withItem(portalItem);
    await _map.load();
    _mapViewController.arcGISMap = _map;
    _mapViewController.interactionOptions.rotateEnabled = false;

    _offlineMapTask = OfflineMapTask.withOnlineMap(_map);

    setState(() => _ready = true);
  }

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

  Future<void> takeOffline() async {
    final envelope = outlineEnvelope();
    if (envelope == null) return;
    setState(() => _progress = 0);

    const minScale = 1e4;
    final parameters = await _offlineMapTask.createDefaultGenerateOfflineMapParameters(
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
      _mapViewController.arcGISMap = result.offlineMap;
      _generateOfflineMapJob = null;
    } on ArcGISException catch (e) {
      _generateOfflineMapJob = null;
      setState(() => _progress = null);
      debugPrint('ArcGISException: ${e.message}, code=${e.code}, type=${e.errorType} additionalMessage=${e.additionalMessage}');
      if (e.errorType != ArcGISExceptionType.commonUserCanceled && mounted) {
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
      builder: (_) => AlertDialog(
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
