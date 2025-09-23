import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_toolkit/arcgis_maps_toolkit.dart';
import 'package:dpmssurveyapp/common/sample_state_support.dart';
import 'package:dpmssurveyapp/pages/snap_geometry_edits.dart';
import 'package:flutter/material.dart';

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

    // final portalItem = PortalItem.withPortalAndItemId(
    //   portal: Portal.arcGISOnline(),
    //   itemId: widget.webMapItemId,
    // );

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
      appBar: AppBar(title: const Text('Online Survey Map')),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action when plus button is pressed.
          if(_map!=null)
          {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SnapGeometryEdits(
              portalUri: widget.portalUri,
              webMapItemId: widget.webMapItemId,
            isOffline: false)));
          }

        },
        tooltip: 'Add Survey',
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
        if (result.geoElements.isNotEmpty &&
            result.layerContent is FeatureLayer) {
          final featureLayer = result.layerContent as FeatureLayer;
          final feature = result.geoElements.first as ArcGISFeature;

          featureLayer.selectFeatures([feature]);

          final List<Popup> popups = identifyResults
                        .where((result) => result.popups.isNotEmpty)
                        .expand((result) => result.popups)
                        .toList();
          Popup featurePopup = popups.first;
          debugPrint("featurePopup.title ${featurePopup.title}");
          debugPrint("featurePopup.popupDefinition.title ${featurePopup.popupDefinition.title}");
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
          showFeatureActionPopup(feature, featureLayer,featurePopup);
          // showDialog(
          //   context: context,
          //   builder: (context) => AlertDialog(
          //     title: Text('Popup'),
          //     content: SizedBox(
          //       width: double.maxFinite,
          //       height: 300, // constrain height
          //       child: PopupView(
          //         popup: featurePopup, // popup data passed to the PopupView widget
          //         // onActionTriggered: (action) {
          //         //   // Optional: handle popup actions like attachments, links, etc.
          //         // },
          //       ),
          //     ),
          //   ),
          // );

          // // Get all popups from the identify results.
          // final List<Popup> popups = identifyResults
          //     .where((result) => result.popups.isNotEmpty)
          //     .expand((result) => result.popups)
          //     .toList();final List<Popup> popups = identifyResults
          //           //     .where((result) => result.popups.isNotEmpty)
          //           //     .expand((result) => result.popups)
          //           //     .toList();
          //
          // if (popups.isNotEmpty) {
          //   if (popups.length == 1) {
          //     // If there is only one popup, show it directly.
          //     _showPopup(popups.last);
          //   } else {
          //     // If there are multiple popups, show a list for the user to select from.
          //     _showPopupList(popups);
          //   }
          // } else
          // if (result.layerContent is FeatureLayer) {
          //   // If no popup is configured, open the default attribute form.
          //   _selectedFeatureLayer = featureLayer;
          //   _selectedFeature = feature;
          //   await showDialog(
          //     context: context,
          //     builder: (context) => FeatureEditDialog(
          //       feature: feature,
          //       featureLayer: featureLayer,
          //     ),
          //   );
          //   // _showFeatureActionPopup(feature, featureLayer);
          //   break;
          // }
          break;
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Identify failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Identify error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingFeature = false);
    }
  }

  // void _showPopup(Popup popup) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (BuildContext context) {
  //       return SafeArea(
  //         child: SingleChildScrollView(
  //           child: Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   popup.title,
  //                   style: const TextStyle(
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 10),
  //                 for (var field in popup.popupDefinition.fields)
  //                   Padding(
  //                     padding: const EdgeInsets.symmetric(vertical: 4.0),
  //                     child: RichText(
  //                       text: TextSpan(
  //                         text: '${field.label}: ',
  //                         style: const TextStyle(
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.black,
  //                         ),
  //                         children: <TextSpan>[
  //                           TextSpan(
  //                             text: field.fieldName.toString() ?? 'No Data',
  //                             style: const TextStyle(
  //                               fontWeight: FontWeight.normal,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // void _showPopupList(List<Popup> popups) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return SafeArea(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Padding(
  //               padding: EdgeInsets.all(16.0),
  //               child: Text(
  //                 'Select a Feature',
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //             Expanded(
  //               child: ListView.builder(
  //                 shrinkWrap: true,
  //                 itemCount: popups.length,
  //                 itemBuilder: (context, index) {
  //                   final popup = popups[index];
  //                   return ListTile(
  //                     title: Text(popup.title),
  //                     onTap: () {
  //                       Navigator.pop(context); // Close the list bottom sheet
  //                       _showPopup(popup); // Open the detailed popup
  //                     },
  //                   );
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // void _showFeatureActionPopup(ArcGISFeature feature, FeatureLayer featureLayer,Popup featurePopup) {
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
  //                 openAttributeEditForm(feature, featureLayer,featurePopup);
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
  //     if (featureLayer.featureTable is ServiceFeatureTable) {
  //       setState(() => _loadingFeature = true);
  //       final serviceFeatureTable = featureLayer.featureTable as ServiceFeatureTable;
  //       await serviceFeatureTable.deleteFeature(feature);
  //
  //       if (serviceFeatureTable.serviceGeodatabase != null) {
  //         final geodatabase = serviceFeatureTable.serviceGeodatabase!;
  //         await geodatabase.applyEdits();
  //       }
  //
  //       // Clear selection and notify user
  //       featureLayer.clearSelection();
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Feature deleted successfully.')));
  //       }
  //     } else {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Deletion is not supported for this layer.')));
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

  // Future<void> _handleMapTap(Offset screenPoint) async {
  //   debugPrint("_handleMapTap map : ${screenPoint}");
  //   setState(() => _loadingFeature = true);
  //   try {
  //     if (_selectedFeatureLayer != null && _selectedFeature != null) {
  //       _selectedFeatureLayer!.clearSelection();
  //     }
  //     final identifyResults = await _mapViewController.identifyLayers(
  //       screenPoint: screenPoint,
  //       tolerance: 12,
  //       maximumResultsPerLayer: 1,
  //       returnPopupsOnly: false,
  //     );
  //     for (var result in identifyResults) {
  //       if (result.geoElements.isNotEmpty &&
  //           result.layerContent is FeatureLayer) {
  //         final featureLayer = result.layerContent as FeatureLayer;
  //         final feature = result.geoElements.first as ArcGISFeature;
  //
  //         featureLayer.selectFeatures([feature]);
  //
  //         _selectedFeatureLayer = featureLayer;
  //         _selectedFeature = feature;
  //         await openAttributeEditForm(feature, featureLayer);
  //         break;
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       debugPrint("Identify failed: $e");
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Identify error: $e')));
  //     }
  //   } finally {
  //     if (mounted) setState(() => _loadingFeature = false);
  //   }
  // }
}
class FeatureEditDialog extends StatefulWidget {
  final ArcGISFeature feature;
  final FeatureLayer featureLayer;

  FeatureEditDialog({required this.feature, required this.featureLayer});

  @override
  _FeatureEditDialogState createState() => _FeatureEditDialogState();
}

class _FeatureEditDialogState extends State<FeatureEditDialog> {
  late Map<String, dynamic> _editedAttributes;

  @override
  void initState() {
    super.initState();
    // Clone the attributes for editing
    _editedAttributes = Map<String, dynamic>.from(widget.feature.attributes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Feature Attributes'),
      content: SingleChildScrollView(
        child: Column(
          children: _editedAttributes.keys.map((key) {
            return TextFormField(
              initialValue: _editedAttributes[key]?.toString() ?? '',
              decoration: InputDecoration(labelText: key),
              onChanged: (value) {
                _editedAttributes[key] = value;
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Update the feature attributes with edited values
            widget.feature.attributes.clear();
            widget.feature.attributes.addAll(_editedAttributes);

            try {
              // Update feature on the server
              // await widget.featureLayer.updateFeature(widget.feature);

              Navigator.of(context).pop(true); // return true on success
            } catch (e) {
              // Handle errors (show toast/snackbar if needed)
              print('Error updating feature: $e');
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}