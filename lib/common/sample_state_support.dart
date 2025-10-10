import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../pages/attribute_edit_form.dart';
import 'dialogs.dart';

/// A mixin that overrides `setState` to first check if the widget is mounted.
/// (Calling `setState` on an unmounted widget causes an exception.)
mixin SampleStateSupport<T extends StatefulWidget> on State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  /// Shows an alert dialog with the given [message].
  void showMessageDialog(
    String message, {
    String title = 'Info',
    bool showOK = false,
  }) {
    if (mounted) {
      showAlertDialog(context, message, title: title, showOK: showOK);
    }
  }

  Future<void> showFeatureActionPopup(ArcGISFeature feature, FeatureLayer featureLayer,Popup featurePopup,bool isOffline,VoidCallback onFormSaved,List<Map<String, dynamic>> schemeList) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Update Feature'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  openAttributeEditForm(feature, featureLayer,featurePopup,isOffline,onFormSaved,schemeList);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Feature', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _deleteFeature(feature, featureLayer,isOffline);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteFeature(ArcGISFeature feature, FeatureLayer featureLayer, bool isOffline) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this feature? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmed) {
      return;
    }

    try {
      if (featureLayer.featureTable is ServiceFeatureTable) {
        // setState(() => _loadingFeature = true);
        final serviceFeatureTable = featureLayer.featureTable as ServiceFeatureTable;
        await serviceFeatureTable.deleteFeature(feature);

        if (serviceFeatureTable.serviceGeodatabase != null) {
          final geodatabase = serviceFeatureTable.serviceGeodatabase!;
          await geodatabase.applyEdits();
        }

        // Clear selection and notify user
        featureLayer.clearSelection();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feature deleted successfully.')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Deletion is not supported for this layer.')));
        }
      }
    } catch (e) {
      debugPrint("Delete failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete feature: $e')));
      }
    } finally {
      // setState(() => _loadingFeature = false);
    }
  }

  Future<void> openAttributeEditForm(
      ArcGISFeature feature,
      FeatureLayer layer,
      Popup featurePopup,
      bool isOffline,
      VoidCallback onFormSaved,
      List<Map<String, dynamic>> schemeList
      ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: AttributeEditForm(
          feature: feature,
          featureTable: layer.featureTable as ArcGISFeatureTable,
          featurePopup: featurePopup,
          onFormSaved: () {
            Navigator.pop(context);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feature successfully updated'),
                ),
              );
            }
            onFormSaved.call();
          },
          // onFormSaved: onFormSaved,
          parentScaffoldContext: context,
          isOffline: isOffline,
          schemeList: schemeList,
        ),
      ),
    );
  }

  Future<double> calculateDistanceBetweenPoints({
    required ArcGISPoint currentLocation,
    required ArcGISPoint tappedPoint,
    LinearUnit? distanceUnit,
    AngularUnit? azimuthUnit,
    GeodeticCurveType curveType = GeodeticCurveType.geodesic,
  }) async {
    try {
      distanceUnit ??= LinearUnit(unitId: LinearUnitId.meters);
      azimuthUnit ??= AngularUnit(unitId: AngularUnitId.degrees);
      // Call the distanceGeodetic function with given parameters
      GeodeticDistanceResult result = GeometryEngine.distanceGeodetic(
        point1: currentLocation,
        point2: tappedPoint,
        distanceUnit: distanceUnit,
        azimuthUnit: azimuthUnit,
        curveType: curveType,
      );

      final geographicPoint = GeometryEngine.project(
        tappedPoint,
        outputSpatialReference: SpatialReference.wgs84,
      ) as ArcGISPoint;

      final latitude = geographicPoint.y;
      final longitude = geographicPoint.x;
      // Return the distance value from the result
      debugPrint("Calculated distance : ${result.distance} tappedPoint latitude $latitude longitude $longitude");
      return result.distance;
    } catch (e) {
      debugPrint('Error calculating geodetic distance: $e');
      return 0;
    }
  }

  final hardcodedPoint = ArcGISPoint(
    x: 73.53089564728866,
    y: 18.582662615818467,
    spatialReference: SpatialReference.wgs84,
  );
  late SimulatedLocationDataSource _simulatedLocationDataSource;

  ArcGISLocation createHardcodedLocation({
    required ArcGISPoint position,
    double horizontalAccuracy = 5.0,
    double verticalAccuracy = 5.0,
    double speed = 0.0,
    double course = 0.0,
    DateTime? timestamp,
    bool lastKnown = false,
    Map<String, dynamic> additionalSourceProperties = const {},
  }) {
    return ArcGISLocation(
      timestamp: timestamp ?? DateTime.now(),
      position: position,
      horizontalAccuracy: horizontalAccuracy,
      verticalAccuracy: verticalAccuracy,
      speed: speed,
      course: course,
      lastKnown: lastKnown,
      additionalSourceProperties: additionalSourceProperties,
    );
  }

  Future<void> hardcodedLocation(ArcGISMapViewController mapViewController, StreamSubscription? statusSubscription,var status,StreamSubscription? autoPanModeSubscription,var autoPanMode) async {
    final hardcodedLocation = createHardcodedLocation(
      position: hardcodedPoint,
    );
    _simulatedLocationDataSource = SimulatedLocationDataSource.withLocations([hardcodedLocation]);
    _simulatedLocationDataSource.currentLocationIndex = 0;

    mapViewController.locationDisplay.dataSource = _simulatedLocationDataSource;
    mapViewController.locationDisplay.autoPanMode =
        LocationDisplayAutoPanMode.recenter;

    // Subscribe to status changes and changes to the auto-pan mode.
    statusSubscription = _simulatedLocationDataSource.onStatusChanged.listen((status) {
      setState(() => status = status);
    });
    setState(() => status = _simulatedLocationDataSource.status);
    autoPanModeSubscription = mapViewController
        .locationDisplay
        .onAutoPanModeChanged
        .listen((mode) {
      setState(() => autoPanMode = mode);
    });
    setState(()
    {
      autoPanMode = mapViewController.locationDisplay.autoPanMode;
    }
    );

    // Attempt to start the location data source (this will prompt the user for permission).
    try {
      await _simulatedLocationDataSource.start();
    } on ArcGISException catch (e) {
      showMessageDialog(e.message);
    }
  }

  // // Create a key to access the scaffold state.
  // final scaffoldStateKey = GlobalKey<ScaffoldState>();
  //
  // final _arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);
  // // Create a dictionary to store basemaps.
  // final basemapsList = <Basemap, Image>{};
  // // Create a default image.
  // final defaultImage = Image.asset('assets/basemap_default.png');
  // // Create a future to load basemaps.
  // late Future loadBasemapsFuture;
  // // Create a variable to store the selected basemap.
  // Basemap? selectedBasemap;
  // final arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);
  //
  // Future loadBasemaps(Portal objPortal) async {
  //   // Create a portal to access online items.
  //   final portal = objPortal;
  //   // Load basemaps from portal.
  //   final basemaps = await portal.developerBasemaps();
  //   await Future.wait(basemaps.map((basemap) => basemap.load()));
  //   basemaps.sort((a, b) => a.name.compareTo(b.name));
  //
  //   // Load each basemap to access and display attribute data in the UI.
  //   for (final basemap in basemaps) {
  //     if (basemap.item != null) {
  //       final thumbnail = basemap.item!.thumbnail;
  //       if (thumbnail != null) {
  //         await thumbnail.load();
  //         basemapsList[basemap] = Image.network(thumbnail.uri.toString());
  //       }
  //     } else {
  //       // If the basemap does not have a thumbnail, use the default image.
  //       basemapsList[basemap] = defaultImage;
  //     }
  //   }
  // }

}
