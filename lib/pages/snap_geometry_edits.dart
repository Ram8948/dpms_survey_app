import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../common/bottom_sheet_settings.dart';
import '../common/sample_state_support.dart';
class SnapGeometryEdits extends StatefulWidget {
  final Uri portalUri;
  final String webMapItemId;
  final bool isOffline;
  const SnapGeometryEdits({
    super.key,
    required this.portalUri,
    required this.webMapItemId,
    required this.isOffline,
  });

  @override
  State<SnapGeometryEdits> createState() => _SnapGeometryEditsState();
}

class _SnapGeometryEditsState extends State<SnapGeometryEdits> with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a graphics overlay.
  final _graphicsOverlay = GraphicsOverlay();
  // Create a geometry editor.
  final _geometryEditor = GeometryEditor();
  // Create a geometry editor style for accessing symbol styles.
  final _geometryEditorStyle = GeometryEditorStyle();
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  // Create a list of menu items for each geometry type.
  // final _geometryTypeMenuItems = <DropdownMenuItem<GeometryType>>[];
  final List<DropdownMenuItem<FeatureLayer>> _layerMenuItems = [];

  // Create a selection of tools to make available to the geometry editor.
  final _vertexTool = VertexTool();
  final _reticleVertexTool = ReticleVertexTool();
  final _toolMenuItems = <DropdownMenuItem<GeometryEditorTool>>[];

  // Create lists to hold different types of snap source settings to make available to the geometry editor.
  final _pointLayerSnapSources = <SnapSourceSettings>[];
  final _polylineLayerSnapSources = <SnapSourceSettings>[];
  final _graphicsOverlaySnapSources = <SnapSourceSettings>[];

  // Create variables for holding state relating to the geometry editor for controlling the UI.
  FeatureLayer? _selectedLayer;
  ArcGISFeatureTable? _selectedtable;
  GeometryType? _selectedGeometryType;
  GeometryEditorTool? _selectedTool;
  Graphic? _selectedGraphic;
  // Initial values are based on defaults.
  var _geometryEditorCanUndo = false;
  var _geometryEditorIsStarted = false;
  var _geometryEditorHasSelectedElement = false;
  var _snappingEnabled = false;
  var _geometryGuidesEnabled = false;
  var _featureSnappingEnabled = true;

  // A flag for controlling the visibility of the editing toolbar.
  var _showEditToolbar = true;
  // A flag for controlling the visibility of the snap settings.
  var _snapSettingsVisible = false;
  late ArcGISMap _map;
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
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    // Only select existing graphics to edit if the geometry editor is not started
                    // i.e. editing is not already in progress.
                    onTap: !_geometryEditorIsStarted ? onTap : null,
                  ),
                ),
                // Build the bottom menu.
                buildBottomMenu(),
              ],
            ),
            Visibility(
              visible: _showEditToolbar,
              // Build the editing toolbar.
              child: buildEditingToolbar(),
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            // LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
      // The snap settings bottom sheet.
      bottomSheet: _snapSettingsVisible ? buildSnapSettings(context) : null,
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
    if(!widget.isOffline) {
      final portal = Portal(widget.portalUri);
      await portal.load();

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
    }
    else {
      final documentsDir = await getApplicationDocumentsDirectory();
      // final mmpkFilePath = path.join(documentsDir.path, 'offline_map', 'p13', 'mobile_map.mmap');
      final offlineMapFolderUri = documentsDir.uri.resolve('offline_map/');
      final mobileMapPackage = MobileMapPackage.withFileUri(offlineMapFolderUri);
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
          (selectedElement) => setState(
            () => _geometryEditorHasSelectedElement = selectedElement != null,
      ),
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
            _layerMenuItems.add(DropdownMenuItem(
              value: subLayer,
              child: Text(subLayer.name),
            ));
          }
        }
      } else if (layer is FeatureLayer) {
        _layerMenuItems.add(DropdownMenuItem(
          value: layer,
          child: Text(layer.name),
        ));
      }
    }


    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
    }

  Future<void> onTap(Offset localPosition) async {
    // Perform an identify operation on the graphics overlay at the tapped location.
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

  void stopAndSave() {
    // Get the geometry from the geometry editor.
    final geometry = _geometryEditor.stop();

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

  Future<void> createFeature(Geometry? geometry) async {
    // Disable the UI while the async operations are in progress.
    setState(() => _ready = false);
    if(_selectedtable!=null) {
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

        // // Set feature attributes.
        // feature.attributes['typdamage'] = 'Minor';
        // feature.attributes['primcause'] = 'Earthquake';

        // Add the feature to the local table.
        await _selectedtable!.addFeature(feature!);

        // // Apply the edits to the service on the service geodatabase.
        // if(_selectedtable is ServiceFeatureTable)
        // {
        //   await (_selectedtable as ServiceFeatureTable).serviceGeodatabase!.applyEdits();
        // }
        // else if(_selectedtable is GeodatabaseFeatureTable)
        // {
        //   await (_selectedtable as GeodatabaseFeatureTable).geodatabase!.applyEdits();
        // }

        // Update the feature to get the updated objectid - a temporary ID is used before the feature is added.
        feature.refresh();

        // Confirm feature addition.
        showMessageDialog('Created feature ${feature.attributes['objectid']}');
        // openAttributeEditForm(feature as ArcGISFeature,_selectedLayer!);
        // final List<Popup> popups = identifyResults
        //     .where((result) => result.popups.isNotEmpty)
        //     .expand((result) => result.popups)
        //     .toList();
        // Popup featurePopup = popups.first;
        // debugPrint("featurePopup.title ${featurePopup.title}");
        // debugPrint("featurePopup.popupDefinition.title ${featurePopup.popupDefinition.title}");
        // for (var field in featurePopup.popupDefinition.fields) {
        //   // if ((field.isVisible ?? true)) {
        //   debugPrint('Editable & Visible PopupField:');
        //   debugPrint('  fieldName: ${field.fieldName}');
        //   debugPrint('  label: ${field.label}');
        //   debugPrint('  visible: ${field.isVisible}');
        //   debugPrint('  editable: ${field.isEditable}');
        //   debugPrint('  type: ${field.runtimeType}');
        //   debugPrint('  type: ${field.tooltip}');
        //   debugPrint('  type: ${field.stringFieldOption}');
        //   // }
        // }
        Popup? featurePopup;

// Assuming: you have ArcGISFeature 'feature' and FeatureLayer '_selectedLayer'
        final popupDefinition = _selectedLayer?.popupDefinition; // get template/definition

        if (popupDefinition != null) {
          featurePopup = Popup(
            geoElement: feature,            // the selected ArcGISFeature
            popupDefinition: popupDefinition, // layer's popup config
            // You may provide additional options if needed (title, etc.)
          );
        }
        showFeatureActionPopup(feature as ArcGISFeature,_selectedLayer!,featurePopup!);
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

  Widget buildBottomMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // A drop down button for selecting geometry type.
        // DropdownButton(
        //   alignment: Alignment.center,
        //   hint: Text(
        //     'Geometry Type',
        //     style: Theme.of(context).textTheme.labelMedium,
        //   ),
        //   icon: const Icon(Icons.arrow_drop_down),
        //   iconEnabledColor: Theme.of(context).primaryColor,
        //   iconDisabledColor: Theme.of(context).disabledColor,
        //   style: Theme.of(context).textTheme.labelMedium,
        //   value: _selectedGeometryType,
        //   items: _geometryTypeMenuItems,
        //   // If the geometry editor is already started then we fully disable the DropDownButton and prevent editing with another geometry type.
        //   onChanged:
        //   !_geometryEditorIsStarted
        //       ? (GeometryType? geometryType) {
        //     if (geometryType != null) {
        //       startEditingWithGeometryType(geometryType);
        //     }
        //   }
        //       : null,
        // ),
        DropdownButton<FeatureLayer>(
          alignment: Alignment.center,
          hint: Text(
            'Select Layer',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          icon: const Icon(Icons.arrow_drop_down),
          iconEnabledColor: Theme.of(context).primaryColor,
          iconDisabledColor: Theme.of(context).disabledColor,
          style: Theme.of(context).textTheme.labelMedium,
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
        ),
        // A drop down button for selecting a tool.
        DropdownButton(
          alignment: Alignment.center,
          hint: Text('Tool', style: Theme.of(context).textTheme.labelMedium),
          iconEnabledColor: Theme.of(context).colorScheme.primary,
          style: Theme.of(context).textTheme.labelMedium,
          value: _selectedTool,
          items: _toolMenuItems,
          onChanged: (tool) {
            if (tool != null) {
              setState(() => _selectedTool = tool);
              _geometryEditor.tool = tool;
            }
          },
        ),
        // A button to toggle the visibility of the editing toolbar.
        IconButton(
          onPressed: () => setState(() => _showEditToolbar = !_showEditToolbar),
          icon: const Icon(Icons.edit),
        ),
      ],
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
              ElevatedButton(
                onPressed: () => setState(() => _snapSettingsVisible = true),
                child: const Text('Show snap settings'),
              ),
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
}

extension on String {
  // An extension on String to capitalize the first character of the String.
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}