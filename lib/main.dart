import 'package:dpmssurveyapp/pages/login_and_home_manager.dart';
import 'package:dpmssurveyapp/pages/authenticate_with_o_auth_offline.dart';
import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

void main() {
  const apiKey = 'AAPK02c8ef93a9984180bbebab60498ccd5eFkjYiIVXsIc4VFPBm0Bu82nzFI6eIJDNHBBiRUlRmuyNxfvjf_MKL30fVpuRcmlA';
  if (apiKey.isEmpty) {
    throw Exception('API key undefined');
  } else {
    ArcGISEnvironment.apiKey = apiKey;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  // Widget build(BuildContext context) => const MaterialApp(home: LoginAndHomeManager());
  Widget build(BuildContext context) => MaterialApp(home: AuthenticateWithOAuthOffline());
}

// Entry widget: determine initial screen
// class LoginAndHomeManager extends StatefulWidget {
//   const LoginAndHomeManager({super.key});
//   @override
//   State<LoginAndHomeManager> createState() => _LoginAndHomeManagerState();
// }
//
// class _LoginAndHomeManagerState extends State<LoginAndHomeManager> {
//   bool? _isAuthenticated;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkLoginStatus();
//   }
//
//   Future<void> _checkLoginStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     final loggedIn = prefs.getBool('isLoggedIn') ?? false;
//     setState(() => _isAuthenticated = loggedIn);
//   }
//
//   void _onLoginSuccess() {
//     setState(() => _isAuthenticated = true);
//   }
//
//   void _onLogout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//
//     ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();
//
//     setState(() => _isAuthenticated = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isAuthenticated == null) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_isAuthenticated == false) {
//       return LoginPage(onLoginSuccess: _onLoginSuccess);
//     }
//     return HomePage(onLogout: _onLogout);
//   }
// }

// Login screen
// class LoginPage extends StatefulWidget {
//   final VoidCallback onLoginSuccess;
//   const LoginPage({required this.onLoginSuccess, super.key});
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _loginInProgress = false;
//
//   Future<void> _authenticateUser() async {
//     setState(() => _loginInProgress = true);
//     try {
//       final credential = await TokenCredential.create(
//         uri: Uri.parse('https://www.arcgis.com/'),
//         username: _usernameController.text.trim(),
//         password: _passwordController.text,
//       );
//       ArcGISEnvironment.authenticationManager.arcGISCredentialStore.addForUri(
//         credential: credential,
//         uri: Uri.parse('https://www.arcgis.com/'),
//       );
//
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool('isLoggedIn', true);
//       await prefs.setString('username', _usernameController.text.trim());
//
//       widget.onLoginSuccess();
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
//       }
//     } finally {
//       if (mounted) setState(() => _loginInProgress = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade700,
//                   shape: BoxShape.circle,
//                   boxShadow: [BoxShadow(color: Colors.blue.shade900.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 10))],
//                 ),
//                 child: Image.asset('assets/images/logo.png', height: 80, width: 80, color: Colors.white),
//               ),
//               const SizedBox(height: 36),
//               Text(
//                 'Welcome Back!',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.blue.shade900, fontWeight: FontWeight.w700),
//               ),
//               const SizedBox(height: 32),
//               TextField(
//                 controller: _usernameController,
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: Colors.white,
//                   labelText: 'Username',
//                   prefixIcon: const Icon(Icons.person_outline),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//                 textInputAction: TextInputAction.next,
//               ),
//               const SizedBox(height: 20),
//               TextField(
//                 controller: _passwordController,
//                 obscureText: _obscurePassword,
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: Colors.white,
//                   labelText: 'Password',
//                   prefixIcon: const Icon(Icons.lock_outline),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
//                     onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                   ),
//                 ),
//                 textInputAction: TextInputAction.done,
//               ),
//               const SizedBox(height: 40),
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue.shade700,
//                     elevation: 8,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//                   ),
//                   onPressed: (_loginInProgress || _usernameController.text.isEmpty || _passwordController.text.isEmpty) ? null : _authenticateUser,
//                   child: _loginInProgress ? const CircularProgressIndicator(color: Colors.white) : const Text('Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// Home Screen with Existing/New Survey buttons
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
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => WebMapLayerSelector(portalUri: _portalUri,
//                   webMapItemId: _webMapItemId,)));
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Online/Offline selection page for chosen survey mode
// class OnlineOfflineModePage extends StatefulWidget {
//   final String mode;
//   const OnlineOfflineModePage({required this.mode, super.key});
//
//   @override
//   State<OnlineOfflineModePage> createState() => _OnlineOfflineModePageState();
// }
//
// class _OnlineOfflineModePageState extends State<OnlineOfflineModePage> {
//   bool? _offlineMode;
//   final Uri _portalUri = Uri.parse('https://www.arcgis.com/');
//   final String _webMapItemId = 'acc027394bc84c2fb04d1ed317aac674';
//
//   @override
//   Widget build(BuildContext context) {
//     if (_offlineMode == null) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.mode)),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.cloud),
//                 label: const Text('Online Survey'),
//                 onPressed: () => setState(() => _offlineMode = false),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.cloud_off),
//                 label: const Text('Offline Survey'),
//                 onPressed: () => setState(() => _offlineMode = true),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     if (_offlineMode == true) {
//       return GenerateOfflineMap(
//         portalUri: _portalUri,
//         webMapItemId: _webMapItemId,
//       );
//     }
//
//     return OnlineSurveyPage(
//       portalUri: _portalUri,
//       webMapItemId: _webMapItemId,
//     );
//   }
// }

// Online Survey Page
// class OnlineSurveyPage extends StatefulWidget {
//   final Uri portalUri;
//   final String webMapItemId;
//
//   const OnlineSurveyPage({
//     super.key,
//     required this.portalUri,
//     required this.webMapItemId,
//   });
//
//   @override
//   State<OnlineSurveyPage> createState() => _OnlineSurveyPageState();
// }
//
// class _OnlineSurveyPageState extends State<OnlineSurveyPage> {
//   final _mapViewController = ArcGISMapView.createController();
//
//   bool _loadingFeature = false;
//   FeatureLayer? _selectedFeatureLayer;
//   ArcGISFeature? _selectedFeature;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadMap();
//   }
//
//   Future<void> _loadMap() async {
//     debugPrint("_loadMap : ${widget.portalUri}");
//     final portal = Portal(
//       widget.portalUri,
//       connection: PortalConnection.authenticated,
//     );
//     await portal.load();
//     final portalItem = PortalItem.withPortalAndItemId(
//       portal: portal,
//       itemId: widget.webMapItemId,
//     );
//     await portalItem.load();
//
//     final map = ArcGISMap.withItem(portalItem);
//     await map.load();
//
//     if (mounted) {
//       debugPrint("_loadMap map : ${map}");
//       _mapViewController.arcGISMap = map;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Online Survey Map')),
//       body: Stack(
//         children: [
//           ArcGISMapView(
//             controllerProvider: () => _mapViewController,
//             onTap: _handleMapTap,
//           ),
//           if (_loadingFeature)
//             Container(
//               color: Colors.black45,
//               child: const Center(child: CircularProgressIndicator()),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _handleMapTap(Offset screenPoint) async {
//     debugPrint("_handleMapTap map : ${screenPoint}");
//     setState(() => _loadingFeature = true);
//     try {
//       if (_selectedFeatureLayer != null && _selectedFeature != null) {
//         _selectedFeatureLayer!.clearSelection();
//       }
//       final identifyResults = await _mapViewController.identifyLayers(
//         screenPoint: screenPoint,
//         tolerance: 12,
//         maximumResultsPerLayer: 1,
//         returnPopupsOnly: false,
//       );
//       for (var result in identifyResults) {
//         if (result.geoElements.isNotEmpty &&
//             result.layerContent is FeatureLayer) {
//           final featureLayer = result.layerContent as FeatureLayer;
//           final feature = result.geoElements.first as ArcGISFeature;
//
//           featureLayer.selectFeatures([feature]);
//
//           _selectedFeatureLayer = featureLayer;
//           _selectedFeature = feature;
//           await _openAttributeEditForm(feature, featureLayer);
//           break;
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         debugPrint("Identify failed: $e");
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Identify error: $e')));
//       }
//     } finally {
//       if (mounted) setState(() => _loadingFeature = false);
//     }
//   }
//
//   Future<void> _openAttributeEditForm(
//     ArcGISFeature feature,
//     FeatureLayer layer,
//   ) async {
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder:
//           (context) => Padding(
//             padding: MediaQuery.of(context).viewInsets,
//             child: AttributeEditForm(
//               feature: feature,
//               featureTable: layer.featureTable! as ServiceFeatureTable,
//               onFormSaved: () {
//                 Navigator.pop(context);
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Feature successfully updated'),
//                     ),
//                   );
//                 }
//               },
//               parentScaffoldContext: context,
//             ),
//           ),
//     );
//   }
// }

// Offline Survey Page
// class GenerateOfflineMap extends StatefulWidget {
//   final Uri portalUri;
//   final String webMapItemId;
//
//   const GenerateOfflineMap({
//     super.key,
//     required this.portalUri,
//     required this.webMapItemId,
//   });
//
//
//   @override
//   State<GenerateOfflineMap> createState() => _GenerateOfflineMapState();
// }
//
// class _GenerateOfflineMapState extends State<GenerateOfflineMap>
//      {
//   // Create a controller for the map view.
//   final _mapViewController = ArcGISMapView.createController();
//   // Declare a map to be loaded later.
//   late final ArcGISMap _map;
//   // Declare the OfflineMapTask.
//   late final OfflineMapTask _offlineMapTask;
//   // Declare the GenerateOfflineMapJob.
//   GenerateOfflineMapJob? _generateOfflineMapJob;
//   // Progress of the GenerateOfflineMapJob.
//   int? _progress;
//   // A flag for when the map is viewing offline data.
//   var _offline = false;
//   // A flag for when the map view is ready and controls can be used.
//   var _ready = false;
//   // Declare global keys to be used when converting screen locations to map coordinates.
//   final _mapKey = GlobalKey();
//   final _outlineKey = GlobalKey();
//
//   bool _loadingFeature = false;
//   FeatureLayer? _selectedFeatureLayer;
//   ArcGISFeature? _selectedFeature;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         top: false,
//         left: false,
//         right: false,
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 Expanded(
//                   child: Stack(
//                     children: [
//                       // Add a map view to the widget tree and set a controller.
//                       ArcGISMapView(
//                         key: _mapKey,
//                         controllerProvider: () => _mapViewController,
//                         onMapViewReady: onMapViewReady,
//                         onTap: _handleMapTap,
//                       ),
//                       // Add a red outline that marks the region to be taken offline.
//                       Visibility(
//                         visible: _progress == null && !_offline,
//                         child: IgnorePointer(
//                           child: SafeArea(
//                             child: Container(
//                               margin: const EdgeInsets.fromLTRB(30, 30, 30, 50),
//                               child: Container(
//                                 key: _outlineKey,
//                                 decoration: BoxDecoration(
//                                   border: Border.all(
//                                     color: Colors.red,
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Center(
//                   // Add a button to take the outlined region offline.
//                   child: ElevatedButton(
//                     onPressed:
//                     _progress != null || _offline ? null : takeOffline,
//                     child: const Text('Take Map Offline'),
//                   ),
//                 ),
//               ],
//             ),
//             // Display a progress indicator and prevent interaction until state is ready.
//             // LoadingIndicator(visible: !_ready),
//             // Display a progress indicator and a cancel button during the offline map generation.
//             Visibility(
//               visible: _progress != null,
//               child: Center(
//                 child: Container(
//                   width: MediaQuery.of(context).size.width / 2,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     spacing: 20,
//                     children: [
//                       // Add a progress indicator.
//                       Text('$_progress%'),
//                       LinearProgressIndicator(
//                         value: _progress != null ? _progress! / 100.0 : 0.0,
//                       ),
//                       // Add a button to cancel the job.
//                       ElevatedButton(
//                         onPressed: () => _generateOfflineMapJob?.cancel(),
//                         child: const Text('Cancel'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _handleMapTap(Offset screenPoint) async {
//     debugPrint("_handleMapTap map : ${screenPoint}");
//     setState(() => _loadingFeature = true);
//     try {
//       if (_selectedFeatureLayer != null && _selectedFeature != null) {
//         _selectedFeatureLayer!.clearSelection();
//       }
//       final identifyResults = await _mapViewController.identifyLayers(
//         screenPoint: screenPoint,
//         tolerance: 12,
//         maximumResultsPerLayer: 1,
//         returnPopupsOnly: false,
//       );
//       for (var result in identifyResults) {
//         if (result.geoElements.isNotEmpty &&
//             result.layerContent is FeatureLayer) {
//           final featureLayer = result.layerContent as FeatureLayer;
//           final feature = result.geoElements.first as ArcGISFeature;
//
//           featureLayer.selectFeatures([feature]);
//
//           _selectedFeatureLayer = featureLayer;
//           _selectedFeature = feature;
//           await _openAttributeEditForm(feature, featureLayer);
//           break;
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         debugPrint("Identify failed: $e");
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Identify error: $e')));
//       }
//     } finally {
//       if (mounted) setState(() => _loadingFeature = false);
//     }
//   }
//   Future<void> _openAttributeEditForm(
//       ArcGISFeature feature,
//       FeatureLayer layer,
//       ) async {
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder:
//           (context) => Padding(
//         padding: MediaQuery.of(context).viewInsets,
//         child: AttributeEditForm(
//           feature: feature,
//           featureTable: layer.featureTable! as GeodatabaseFeatureTable,
//           onFormSaved: () {
//             Navigator.pop(context);
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Feature successfully updated'),
//                 ),
//               );
//             }
//           },
//             parentScaffoldContext:context,
//         ),
//       ),
//     );
//   }
//   Future<void> onMapViewReady() async {
//     // Create the map from a portal item.
//     final portalItem = PortalItem.withPortalAndItemId(
//       portal: Portal.arcGISOnline(),
//       itemId: 'acc027394bc84c2fb04d1ed317aac674',
//     );
//     _map = ArcGISMap.withItem(portalItem);
//     _mapViewController.arcGISMap = _map;
//
//     // Offline map generation does not consider rotation, so disable it.
//     _mapViewController.interactionOptions.rotateEnabled = false;
//
//     // Create an OfflineMapTask for the map.
//     _offlineMapTask = OfflineMapTask.withOnlineMap(_map);
//
//     setState(() => _ready = true);
//   }
//
//   // Calculate the Envelope of the outlined region.
//   Envelope? outlineEnvelope() {
//     final outlineContext = _outlineKey.currentContext;
//     final mapContext = _mapKey.currentContext;
//     if (outlineContext == null || mapContext == null) return null;
//
//     // Get the global screen rect of the outlined region.
//     final outlineRenderBox = outlineContext.findRenderObject() as RenderBox?;
//     final outlineGlobalScreenRect =
//     outlineRenderBox!.localToGlobal(Offset.zero) & outlineRenderBox.size;
//
//     // Convert the global screen rect to a rect local to the map view.
//     final mapRenderBox = mapContext.findRenderObject() as RenderBox?;
//     final mapLocalScreenRect = outlineGlobalScreenRect.shift(
//       -mapRenderBox!.localToGlobal(Offset.zero),
//     );
//
//     // Convert the local screen rect to map coordinates.
//     final locationTopLeft = _mapViewController.screenToLocation(
//       screen: mapLocalScreenRect.topLeft,
//     );
//     final locationBottomRight = _mapViewController.screenToLocation(
//       screen: mapLocalScreenRect.bottomRight,
//     );
//     if (locationTopLeft == null || locationBottomRight == null) return null;
//
//     // Create an Envelope from the map coordinates.
//     return Envelope.fromPoints(locationTopLeft, locationBottomRight);
//   }
//
//   // Take the selected region offline.
//   Future<void> takeOffline() async {
//     // Get the Envelope of the outlined region.
//     final envelope = outlineEnvelope();
//     if (envelope == null) return;
//
//     // Cause the progress indicator to appear.
//     setState(() => _progress = 0);
//
//     // Create parameters specifying the region to take offline.
//     // Provides a min scale to avoid requesting a huge download. Note maxScale defaults to 0.0.
//     const minScale = 1e4;
//     final parameters = await _offlineMapTask
//         .createDefaultGenerateOfflineMapParameters(
//       areaOfInterest: envelope,
//       minScale: minScale,
//     );
//     parameters.continueOnErrors = false;
//
//     // Prepare an empty directory to store the offline map.
//     final documentsUri = (await getApplicationDocumentsDirectory()).uri;
//     final downloadDirectoryUri = documentsUri.resolve('offline_map');
//     final downloadDirectory = Directory.fromUri(downloadDirectoryUri);
//     if (downloadDirectory.existsSync()) {
//       downloadDirectory.deleteSync(recursive: true);
//     }
//     downloadDirectory.createSync();
//
//     // Create a job to generate the offline map.
//     _generateOfflineMapJob = _offlineMapTask.generateOfflineMap(
//       parameters: parameters,
//       downloadDirectoryUri: downloadDirectoryUri,
//     );
//
//     // Listen for progress updates.
//     _generateOfflineMapJob!.onProgressChanged.listen((progress) {
//       setState(() => _progress = progress);
//     });
//
//     try {
//       // Run the job.
//       final result = await _generateOfflineMapJob!.run();
//
//       // Get the offline map and display it.
//       _mapViewController.arcGISMap = result.offlineMap;
//       _generateOfflineMapJob = null;
//     } on ArcGISException catch (e) {
//       // If an error happens (such as cancellation), reset state.
//       _generateOfflineMapJob = null;
//       setState(() => _progress = null);
//
//       // If the exception is not due to user cancellation (code 17), show the details of the error in a dialog.
//       if (e.errorType != ArcGISExceptionType.commonUserCanceled && mounted) {
//         await showAlertDialog(context, e.message);
//       }
//       return;
//     }
//
//     // The job was successful and we are now viewing the offline amp.
//     setState(() {
//       _progress = null;
//       _offline = true;
//     });
//   }
// }

// class AttributeEditForm extends StatefulWidget {
//   final ArcGISFeature feature;
//   final ArcGISFeatureTable featureTable;
//   final VoidCallback onFormSaved;
//   final BuildContext parentScaffoldContext;
//
//   const AttributeEditForm({
//     required this.feature,
//     required this.featureTable,
//     required this.onFormSaved,
//     required this.parentScaffoldContext,
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   _AttributeEditFormState createState() => _AttributeEditFormState();
// }
//
// class _AttributeEditFormState extends State<AttributeEditForm> {
//   final _formKey = GlobalKey<FormState>();
//   late Map<String, dynamic> _editedAttributes;
//   List<Attachment> _attachments = [];
//   List<File> _newAttachments = [];
//   bool _attachmentsLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _editedAttributes = Map<String, dynamic>.from(widget.feature.attributes);
//     _loadAttachments();
//   }
//
//   Future<void> _loadAttachments() async {
//     try {
//       final attachments = await widget.feature.fetchAttachments();
//       setState(() {
//         _attachments = attachments;
//         _attachmentsLoading = false;
//       });
//     } catch (e) {
//       setState(() => _attachmentsLoading = false);
//       if (mounted) {
//         debugPrint("Failed to load attachments: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load attachments: $e')),
//         );
//       }
//     }
//   }
//
//   Future<void> _addAttachment() async {
//     // final result = await FilePicker.platform.pickFiles(allowMultiple: false);
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'txt'],
//         allowMultiple: false
//     );
//     if (result != null && result.files.single.path != null) {
//       setState(() {
//         _newAttachments.add(File(result.files.single.path!));
//       });
//     }
//   }
//
//   Future<void> _removeNewAttachment(int index) async {
//     setState(() => _newAttachments.removeAt(index));
//   }
//
//   Future<void> _deleteAttachment(Attachment attachment) async {
//     try {
//       await widget.feature.deleteAttachment(attachment);
//       await _loadAttachments();
//     } catch (e) {
//       if (mounted) {
//         debugPrint("Failed to delete attachment: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to delete attachment: $e')),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final fields = widget.featureTable.fields.where(
//           (field) =>
//       field.editable &&
//           field.name != (widget.featureTable as ArcGISFeatureTable).objectIdField,
//     );
//
//     return Padding(
//       padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
//       child: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ...fields.map((field) {
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: TextFormField(
//                     initialValue: _editedAttributes[field.name]?.toString() ?? '',
//                     decoration: InputDecoration(
//                       labelText: field.alias,
//                       border: const OutlineInputBorder(),
//                     ),
//                     onSaved: (value) {
//                       _editedAttributes[field.name] = value;
//                     },
//                     validator: (value) {
//                       if (!field.nullable && (value == null || value.isEmpty)) {
//                         return '${field.alias} is required';
//                       }
//                       return null;
//                     },
//                   ),
//                 );
//               }).toList(),
//               const SizedBox(height: 24),
//               const Text(
//                 "Attachments (mandatory):",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               if (_attachmentsLoading)
//                 const Center(child: CircularProgressIndicator())
//               else
//                 Column(
//                   children: [
//                     ..._attachments.map((attachment) {
//                       return ListTile(
//                         leading: const Icon(Icons.attach_file),
//                         title: Text(attachment.name),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () => _deleteAttachment(attachment),
//                         ),
//                         onTap: () {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('Open attachment: ${attachment.name}'),
//                             ),
//                           );
//                         },
//                       );
//                     }),
//                     ..._newAttachments.asMap().entries.map((entry) {
//                       int idx = entry.key;
//                       File file = entry.value;
//                       return ListTile(
//                         leading: const Icon(Icons.insert_drive_file),
//                         title: Text(file.path.split('/').last),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.remove_circle, color: Colors.red),
//                           onPressed: () => _removeNewAttachment(idx),
//                         ),
//                       );
//                     }),
//                     const SizedBox(height: 8),
//                     ElevatedButton.icon(
//                       icon: const Icon(Icons.add),
//                       label: const Text('Add Attachment'),
//                       onPressed: _addAttachment,
//                     ),
//                   ],
//                 ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: _saveAttributes,
//                 child: const Text('Save'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _saveAttributes() async {
//     debugPrint("_saveAttributes");
//     if (!(_formKey.currentState?.validate() ?? false)) return;
//     _formKey.currentState?.save();
//     debugPrint("_saveAttributes1 _attachments.isEmpty ${_attachments.isEmpty} _newAttachments.isEmpty ${_newAttachments.isEmpty}");
//     // if (_attachments.isEmpty && _newAttachments.isEmpty) {
//     //   ScaffoldMessenger.of(widget.parentScaffoldContext).showSnackBar(
//     //     const SnackBar(content: Text('Please add at least one attachment')),
//     //   );
//     //   debugPrint("_saveAttributes Please add at least one attachment");
//     //   return;
//     // }
//
//     _editedAttributes.forEach((key, value) {
//       // widget.feature.attributes[key] = value;
//       // Convert to proper type based on field.type
//       final field = widget.featureTable.fields.firstWhere((f) => f.name == key);
//       if (field.name.toLowerCase() == 'globalid' ||
//           field.name.toLowerCase() == 'objectid' ||
//           !field.editable) {
//         return; // skip
//       }
//       dynamic typedValue = value;
//       switch (field.type) {
//         case FieldType.int16:
//         case FieldType.int32:
//         case FieldType.int64:
//           typedValue = int.tryParse(value.toString()) ?? value;
//           break;
//         case FieldType.float32:
//         case FieldType.float64:
//           typedValue = double.tryParse(value.toString()) ?? value;
//           break;
//         case FieldType.text:
//           typedValue = value.toString();
//           break;
//         case FieldType.date:
//           if (value is String) {
//             typedValue = DateTime.tryParse(value);
//           }
//           break;
//         default:
//         // Use original value
//           typedValue = value;
//       }
//
//       widget.feature.attributes[key] = typedValue;
//     });
//
//     try {
//       // Ensure feature is loaded fully
//       await widget.feature.load();
//
//       // Update feature attributes if needed
//       await widget.featureTable.updateFeature(widget.feature);
//
//       // // Add attachments sequentially
//       // for (final file in _newAttachments) {
//       //   final ext = p.extension(file.path).toLowerCase(); // Using path package
//       //   final bytes = await file.readAsBytes();
//       //   final name = file.path.split('/').last;
//       //   print('File extension: $ext');
//       //   bool attachmentsEnabled = widget.featureTable.hasAttachments ?? false;
//       //   debugPrint("attachmentsEnabled $attachmentsEnabled");
//       //   await widget.feature.addAttachment(
//       //     name: name,
//       //     contentType: _mimeTypeForExtension(ext), // optionally map to mime type
//       //     data: bytes,
//       //   );
//       // }
//       // bool attachmentsEnabled = widget.featureTable.hasAttachments ?? false;
//       // debugPrint("attachmentsEnabled $attachmentsEnabled");
//       // // If working with online service, apply edits to commit attachments
//       // if (widget.featureTable is ServiceFeatureTable) {
//       //   await (widget.featureTable as ServiceFeatureTable).applyEdits();
//       // }
//
//       widget.onFormSaved();
//     } catch (e) {
//       if (mounted) {
//         debugPrint("Update failed: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Update failed: $e')),
//         );
//       }
//     }
//   }
// }

// String _mimeTypeForExtension(String ext) {
//   switch (ext) {
//     case '.jpg':
//     case '.jpeg':
//       return 'image/jpeg';
//     case '.png':
//       return 'image/png';
//     case '.pdf':
//       return 'application/pdf';
//     default:
//       return 'application/octet-stream';
//   }
// }
//
// // Helper alert dialog
// Future<void> showAlertDialog(BuildContext context, String message) {
//   return showDialog(
//     context: context,
//     builder: (_) => AlertDialog(
//       title: const Text('Error'),
//       content: Text(message),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('OK'),
//         ),
//       ],
//     ),
//   );
// }

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
//                         builder: (_) => DrawingAndFormPage(
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


// class DrawingAndFormPage extends StatefulWidget {
//   final Layer layer;
//   final ArcGISMap map;
//
//   const DrawingAndFormPage({
//     super.key,
//     required this.layer,
//     required this.map,
//   });
//
//   @override
//   State<DrawingAndFormPage> createState() => _DrawingAndFormPageState();
// }
//
// enum DrawingMode { none, point, polyline, polygon }
//
// class _DrawingAndFormPageState extends State<DrawingAndFormPage> {
//   late ArcGISMapViewController _mapViewController;
//   DrawingMode _drawingMode = DrawingMode.none;
//   bool _isDrawing = false;
//   List<ArcGISPoint> _currentPoints = [];
//   Geometry? _drawnGeometry;
//
//   @override
//   void initState() {
//     super.initState();
//     _mapViewController = ArcGISMapView.createController();
//   }
//
//   void _startDrawing() {
//     var featureTable = (widget.layer as FeatureLayer).featureTable;
//
//     if (featureTable == null) {
//       debugPrint('Selected layer has no feature table.');
//       return;
//     }
//
//     var geometryType = featureTable.geometryType;
//
//     switch (geometryType) {
//       case GeometryType.point:
//         _enablePointDrawing();
//         break;
//       case GeometryType.polyline:
//         _enablePolylineDrawing();
//         break;
//       case GeometryType.polygon:
//         _enablePolygonDrawing();
//         break;
//       default:
//         debugPrint('Unsupported geometry type for drawing: $geometryType');
//     }
//   }
//
//   void _enablePointDrawing() {
//     setState(() {
//       _drawingMode = DrawingMode.point;
//       _isDrawing = true;
//       _currentPoints.clear();
//     });
//   }
//
//   void _enablePolylineDrawing() {
//     setState(() {
//       _drawingMode = DrawingMode.polyline;
//       _isDrawing = true;
//       _currentPoints.clear();
//     });
//   }
//
//   void _enablePolygonDrawing() {
//     setState(() {
//       _drawingMode = DrawingMode.polygon;
//       _isDrawing = true;
//       _currentPoints.clear();
//     });
//   }
//
//   Future<void> _onDrawingCompleted(Geometry geometry) async {
//     setState(() {
//       _drawnGeometry = geometry;
//       _isDrawing = false;
//       _drawingMode = DrawingMode.none;
//       _currentPoints.clear();
//     });
//
//     // Open attribute form after drawing complete
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (_) => AttributeEditFormPage(
//         geometry: geometry,
//         layer: widget.layer,
//         onFormSaved: () {
//           Navigator.of(context).pop(); // close form
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Feature saved')),
//           );
//         },
//       ),
//     );
//   }
//
//   void _handleMapTap(Offset screenPoint) {
//     debugPrint("_isDrawing $_isDrawing");
//
//     if (!_isDrawing) return;
//
//     final mapPoint = _mapViewController.screenToLocation(screen: screenPoint);
//     debugPrint("mapPoint $mapPoint");
//     if (mapPoint == null) return;
//
//     setState(() {
//       switch (_drawingMode) {
//         case DrawingMode.point:
//           _currentPoints = [mapPoint];
//           _finishDrawing();
//           break;
//         case DrawingMode.polyline:
//         case DrawingMode.polygon:
//           _currentPoints.add(mapPoint);
//           break;
//         case DrawingMode.none:
//           break;
//       }
//     });
//   }
//
//   void _finishDrawing() {
//     Geometry? geometry;
//     if (_drawingMode == DrawingMode.point && _currentPoints.length == 1) {
//       geometry = _currentPoints.first;
//     } else if (_drawingMode == DrawingMode.polyline && _currentPoints.length >= 2) {
//       final polylineBuilder = PolylineBuilder(spatialReference: SpatialReference.wgs84);
//       for (var pt in _currentPoints) {
//         polylineBuilder.addPoint(pt);
//       }
//       geometry = polylineBuilder.toGeometry();
//     } else if (_drawingMode == DrawingMode.polygon && _currentPoints.length >= 3) {
//       final polygonBuilder = PolygonBuilder(spatialReference: SpatialReference.wgs84);
//       for (var pt in _currentPoints) {
//         polygonBuilder.addPoint(pt);
//       }
//       geometry = polygonBuilder.toGeometry();
//     }
//
//     if (geometry != null) {
//       _onDrawingCompleted(geometry);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Draw Geometry & Add Attributes'),
//         actions: [
//           if (_isDrawing && (_drawingMode == DrawingMode.polyline || _drawingMode == DrawingMode.polygon))
//             TextButton(
//               onPressed: _finishDrawing,
//               child: const Text(
//                 "Finish Drawing",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//       body: ArcGISMapView(
//         controllerProvider: () => _mapViewController,
//         onMapViewReady: () {
//           _mapViewController.arcGISMap = widget.map;
//         },
//         onTap: _handleMapTap,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _startDrawing,
//         child: const Icon(Icons.edit),
//       ),
//     );
//   }
// }

// Placeholder for attribute editing form linked with layer and geometry
// class AttributeEditFormPage extends StatelessWidget {
//   final Geometry geometry;
//   final Layer layer;
//   final VoidCallback onFormSaved;
//
//   const AttributeEditFormPage({
//     super.key,
//     required this.geometry,
//     required this.layer,
//     required this.onFormSaved,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     // Build input form to capture attributes
//     return Scaffold(
//       appBar: AppBar(title: const Text('Feature Attributes')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: onFormSaved,
//           child: const Text('Save Feature'),
//         ),
//       ),
//     );
//   }
// }

