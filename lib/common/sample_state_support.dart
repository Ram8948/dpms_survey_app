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

  void showFeatureActionPopup(ArcGISFeature feature, FeatureLayer featureLayer,Popup featurePopup) {
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
                  openAttributeEditForm(feature, featureLayer,featurePopup);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Feature', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _deleteFeature(feature, featureLayer);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteFeature(ArcGISFeature feature, FeatureLayer featureLayer) async {
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
          },
          parentScaffoldContext: context,
        ),
      ),
    );
  }
}
