import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:path/path.dart' as path;

class AttributeEditForm extends StatefulWidget {
  final ArcGISFeature feature;
  final ArcGISFeatureTable featureTable;
  final Popup featurePopup;
  final VoidCallback onFormSaved;
  final BuildContext parentScaffoldContext;
  final bool isOffline;

  const AttributeEditForm({
    required this.feature,
    required this.featureTable,
    required this.featurePopup,
    required this.onFormSaved,
    required this.parentScaffoldContext,
    required this.isOffline,
    super.key,
  });

  @override
  _AttributeEditFormState createState() => _AttributeEditFormState();
}

class _AttributeEditFormState extends State<AttributeEditForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _editedAttributes;
  List<Attachment> _attachments = [];
  List<File> _newAttachments = [];
  bool _attachmentsLoading = true;
  List<Feature> _relatedFeatures = [];
  bool _relatedFeaturesLoading = false;
  ArcGISFeatureTable? _mainFeatureTable;
  bool showAttachmentError = false;
  int initProgress=0;
  bool isSaving = false;
  @override
  void initState() {
    super.initState();
    final popupFields = widget.featurePopup.popupDefinition.fields.where((pf) =>
    (pf.isVisible ?? true));

    final popupFieldList = popupFields.toList();

    final popupFieldNames = popupFieldList
        .map((pf) => pf.fieldName.toLowerCase())
        .toSet();

    _editedAttributes = Map<String, dynamic>.fromEntries(
      widget.feature.attributes.entries.where((entry) =>
          popupFieldNames.contains(entry.key.toLowerCase())),
    );
    debugPrint("_editedAttributes ${widget.feature.attributes}");
    debugPrint("_editedAttributes $_editedAttributes");
    debugPrint("widget.feature.featureTable ${widget.feature.featureTable}");
    if(widget.feature.featureTable is ServiceFeatureTable) {
      _mainFeatureTable = widget.feature.featureTable as ServiceFeatureTable;
      relatedTables = _mainFeatureTable?.getRelatedTables();
    }
    else  if(widget.feature.featureTable is GeodatabaseFeatureTable) {
      _mainFeatureTable = widget.feature.featureTable as GeodatabaseFeatureTable;
      relatedTables = _mainFeatureTable?.getRelatedTables();
    }
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    try {
      final attachments = await widget.feature.fetchAttachments();
      setState(() {
        _attachments = attachments;
        _attachmentsLoading = false;
      });
      for (final attachment in _attachments) {
        final String url = attachment.name; // remote URL to download or view
        final String contentType = attachment.contentType; // remote URL to download or view
        final int id = attachment.id; // remote URL to download or view
        print('Attachment URL: $url');
        print('Attachment contentType: $contentType');
        print('Attachment id: $id');
      }
    } catch (e) {
      setState(() => _attachmentsLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attachments: $e')),
        );
      }
    }
  }

  Future<void> _addAttachment() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'txt'],
        allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() => _newAttachments.add(File(result.files.single.path!)));
    }
  }

  Future<void> _removeNewAttachment(int index) async {
    setState(() => _newAttachments.removeAt(index));
  }

  Future<void> _deleteAttachment(Attachment attachment) async {
    try {
      await widget.feature.deleteAttachment(attachment);
      await _loadAttachments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete attachment: $e')),
        );
      }
    }
  }

  String getFeatureTitle() {
    final layerName = widget.featureTable.layerInfo?.serviceLayerName ?? 'Feature Layer';
    return layerName;
  }

  @override
  Widget build(BuildContext context) {
    final popupFields = widget.featurePopup.popupDefinition.fields.where((pf) =>
    (pf.isVisible ?? true));
    final popupFieldList = popupFields.toList();

    final popupFieldNames = popupFieldList
        .map((pf) => pf.fieldName.toLowerCase())
        .toSet();

    final filteredFields = widget.featureTable.fields
        .where((field) {
      final fname = field.name.toLowerCase();
      return popupFieldNames.contains(fname) &&
          !['objectid', 'globalid', 'shape'].contains(fname);
    })
        .toList();

    filteredFields.sort((a, b) {
      final aIndex = popupFieldList.indexWhere((pf) => pf.fieldName.toLowerCase() == a.name.toLowerCase());
      final bIndex = popupFieldList.indexWhere((pf) => pf.fieldName.toLowerCase() == b.name.toLowerCase());
      return aIndex.compareTo(bIndex);
    });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 10,
          right: 10,
          top: 10,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  getFeatureTitle(),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ...filteredFields.map((field) => _buildFieldCard(field, popupFieldList)).toList(),
                const SizedBox(height: 18),
                // Card(
                //   margin: const EdgeInsets.symmetric(vertical: 5),
                //   child: Padding(
                //     padding: const EdgeInsets.all(12),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(
                //           "Attachments",
                //           style: Theme.of(context)
                //               .textTheme
                //               .titleMedium
                //               ?.copyWith(fontWeight: FontWeight.bold),
                //         ),
                //         const SizedBox(height: 6),
                //         if (_attachmentsLoading) ...[
                //           const Center(
                //               child: Padding(
                //                 padding: EdgeInsets.all(8),
                //                 child: CircularProgressIndicator(),
                //               )),
                //         ] else ...[
                //           Column(
                //             children: [
                //               ..._attachments.map((attachment) {
                //                 return ListTile(
                //                   dense: true,
                //                   contentPadding: EdgeInsets.zero,
                //                   leading: const Icon(Icons.attach_file),
                //                   title:
                //                   Text(attachment.name, overflow: TextOverflow.ellipsis),
                //                   trailing: IconButton(
                //                     icon: const Icon(Icons.delete, color: Colors.red),
                //                     onPressed: () => _deleteAttachment(attachment),
                //                   ),
                //                   onTap: () {
                //                     ScaffoldMessenger.of(context).showSnackBar(
                //                       SnackBar(
                //                           content: Text(
                //                               'Open attachment: ${attachment.name}')),
                //                     );
                //                   },
                //                 );
                //               }),
                //               ..._newAttachments.asMap().entries.map((entry) {
                //                 int idx = entry.key;
                //                 File file = entry.value;
                //                 return ListTile(
                //                   dense: true,
                //                   contentPadding: EdgeInsets.zero,
                //                   leading: const Icon(Icons.insert_drive_file),
                //                   title:
                //                   Text(file.path.split('/').last, overflow: TextOverflow.ellipsis),
                //                   trailing: IconButton(
                //                     icon: const Icon(Icons.remove_circle, color: Colors.red),
                //                     onPressed: () => _removeNewAttachment(idx),
                //                   ),
                //                 );
                //               }),
                //               const SizedBox(height: 4),
                //               Align(
                //                 alignment: Alignment.centerRight,
                //                 child: ElevatedButton.icon(
                //                   icon: const Icon(Icons.add),
                //                   label: const Text('Add Attachment'),
                //                   onPressed: _addAttachment,
                //                 ),
                //               )
                //             ],
                //           ),
                //         ],
                //       ],
                //     ),
                //   ),
                // ),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Attachments",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        // ERROR MESSAGE INLINE
                        if (showAttachmentError)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  "Please add at least one attachment",
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        if (_attachmentsLoading) ...[
                          const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(),
                              )),
                        ] else ...[
                          Column(
                            children: [
                              ..._attachments.map((attachment) {
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.attach_file),
                                  title:
                                  Text(attachment.name, overflow: TextOverflow.ellipsis),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteAttachment(attachment),
                                  ),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Open attachment: ${attachment.name}')),
                                    );
                                  },
                                );
                              }),
                              ..._newAttachments.asMap().entries.map((entry) {
                                int idx = entry.key;
                                File file = entry.value;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.insert_drive_file),
                                  title:
                                  Text(file.path.split('/').last, overflow: TextOverflow.ellipsis),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => _removeNewAttachment(idx),
                                  ),
                                );
                              }),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Attachment'),
                                  onPressed: _addAttachment,
                                ),
                              )
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Show Related Features'),
                  onPressed: _showRelatedFeaturesDialog,
                ),
                // ElevatedButton.icon(
                //   icon: const Icon(Icons.save),
                //   onPressed: _saveAttributes,
                //   label: const Text('Save Changes'),
                //   style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                // ),
                Column(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text('Save Changes'),
                      onPressed: isSaving ? null : _saveAttributes,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                    if (isSaving)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRelatedFeaturesDialog() async {
    setState(() {
      _relatedFeaturesLoading = true;
    });
    try {
      final relatedFeatures = await getRelatedFeatures(widget.feature);
      setState(() {
        _relatedFeatures = relatedFeatures;
        _relatedFeaturesLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Related Features'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // fixed height for scrolling table
            child: _relatedFeaturesLoading
                ? const Center(child: CircularProgressIndicator())
                : RelatedFeaturesTable(
              relatedFeatures: _relatedFeatures,
              relatedFeatureTable: relatedTables!.first,
              refreshParent: () async {
                // Refresh list after CRUD
                final freshRelated = await getRelatedFeatures(widget.feature);
                setState(() {
                  debugPrint("refreshParent ${_relatedFeatures.length}");
                  debugPrint("refreshParent freshRelated ${freshRelated.length}");
                  _relatedFeatures = freshRelated;
                  debugPrint("refreshParent ${_relatedFeatures.length}");
                });
              },
              feature: widget.feature,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _relatedFeaturesLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load related features: $e')),
      );
    }
  }

  Widget _buildFieldCard(Field field, List<PopupField> popupFields) {
    final isEditable = field.editable;
    final value = _editedAttributes[field.name];
    final isValueBlank = (value == null || (value is String && value.isEmpty));
    final shouldBeEditable = isEditable || isValueBlank;
    final readOnlyColor = Colors.grey[200];

    PopupField? findPopupField(String fieldName, List<PopupField> popupFields) {
      for (final pf in popupFields) {
        if (pf.fieldName.toLowerCase() == fieldName.toLowerCase()) {
          debugPrint("pf.fieldName ${pf.fieldName}");
          return pf;
        }
      }
      return null;
    }

    final popupField = findPopupField(field.name, popupFields);
    final label = popupField?.label ?? field.alias;

    String formatDate(dynamic val) {
      if (val == null) return '';
      DateTime? date;
      if (val is DateTime) {
        date = val;
      } else if (val is String) {
        date = DateTime.tryParse(val);
      }
      return (date != null) ? DateFormat('yyyy-MM-dd').format(date) : '';
    }

    // Dropdown for coded value domain
    if (field.domain is CodedValueDomain && shouldBeEditable) {
      final domain = field.domain as CodedValueDomain;
      final codedValues = domain.codedValues;
      final selectedValue = _editedAttributes[field.name]?.toString();

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: codedValues.map((cv) {
              return DropdownMenuItem<String>(
                value: cv.code.toString(),
                child: Text(cv.name),
              );
            }).toList(),
            onChanged: shouldBeEditable
                ? (String? newValue) {
              debugPrint("field.name ${field.name}");
              if(field.name == "intpprogress")
              {
                  initProgress = int.tryParse(newValue!) ?? 0;
              }
              setState(() {
                _editedAttributes[field.name] = newValue;
              });
            }
                : null,
            validator: (val) {
              if (!field.nullable && (val == null || val.isEmpty)) {
                return '$label is required';
              }
              return null;
            },
          ),
        ),
      );
    }

    if (field.type == FieldType.date && shouldBeEditable) {
      final DateTime defaultDate = DateTime.now();
      DateTime initialDate = defaultDate;

      if (value != null && value.toString().isNotEmpty) {
        DateTime? parsedDate;
        if (value is DateTime) {
          parsedDate = value;
        } else if (value is String) {
          parsedDate = DateTime.tryParse(value);
        }
        if (parsedDate != null) {
          initialDate = parsedDate;
        }
      } else {
        // Set default current date for new feature
        _editedAttributes[field.name] = defaultDate.toIso8601String();
      }

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () async {
              DateTime firstDate = DateTime(1900);
              DateTime lastDate = DateTime(2100);

              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: lastDate,
              );

              if (picked != null) {
                setState(() {
                  _editedAttributes[field.name] = picked.toIso8601String();
                });
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: TextEditingController(text: formatDate(_editedAttributes[field.name])),
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                  filled: false,
                  isDense: true,
                ),
                validator: (val) {
                  if (!field.nullable && (val == null || val.isEmpty)) {
                    return '$label is required';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );
    }

    // Default text input field
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: shouldBeEditable ? null : readOnlyColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!shouldBeEditable)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 10),
                child: Icon(Icons.lock, color: Colors.grey[600], size: 16),
              ),
            Expanded(
              child: TextFormField(
                initialValue: value?.toString() ?? '',
                enabled: shouldBeEditable,
                readOnly: !shouldBeEditable,
                style: shouldBeEditable
                    ? null
                    : TextStyle(
                  color: Colors.grey[800],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: label + (shouldBeEditable ? '' : ' (Read Only)'),
                  labelStyle: TextStyle(color: shouldBeEditable ? null : Colors.grey[700]),
                  border: const OutlineInputBorder(),
                  filled: !shouldBeEditable,
                  fillColor: readOnlyColor,
                  isDense: true,
                ),
                onSaved: shouldBeEditable ? (val) => _editedAttributes[field.name] = val : null,
                validator: (val) {
                  if (!field.nullable && (val == null || val.isEmpty)) {
                    return '$label is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAttributes() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();
    // Show progress
    setState(() {
      isSaving = true;
    });
    debugPrint("_saveAttributes1 _attachments.isEmpty ${_attachments.isEmpty} _newAttachments.isEmpty ${_newAttachments.isEmpty}");
    if (_attachments.isEmpty && _newAttachments.isEmpty) {
      setState(() {
        showAttachmentError = true;
      });
      debugPrint("_saveAttributes Please add at least one attachment");
      return;
    } else {
      setState(() {
        showAttachmentError = false;
      });
    }

    List<String> conversionErrors = [];

    for (var entry in _editedAttributes.entries) {
      final key = entry.key;
      final value = entry.value;
      final field = widget.featureTable.fields.firstWhere((f) => f.name == key);
      if (!field.editable) continue;

      dynamic typedValue;
      try {
        switch (field.type) {
          case FieldType.int16:
          case FieldType.int32:
          case FieldType.int64:
            typedValue = int.tryParse(value.toString());
            if (typedValue == null && value.toString().isNotEmpty) {
              throw FormatException('Invalid integer');
            }
            break;
          case FieldType.float32:
          case FieldType.float64:
            typedValue = double.tryParse(value.toString());
            if (typedValue == null && value.toString().isNotEmpty) {
              throw FormatException('Invalid double');
            }
            break;
          case FieldType.text:
            typedValue = value.toString();
            break;
          case FieldType.date:
            if (value is String) {
              typedValue = DateTime.tryParse(value);
            } else if (value is DateTime) {
              typedValue = value;
            }
            break;
          default:
            typedValue = value;
        }
        if (typedValue != null && typedValue != "null") {
          widget.feature.attributes[key] = typedValue;
        }
      } catch (e) {
        conversionErrors.add('${field.alias} (${field.name})');
      }
    }

    if (conversionErrors.isNotEmpty) {
      final errorFields = conversionErrors.join(', ');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid input format for fields: $errorFields'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      for (final file in _newAttachments) {
        final ext = path.extension(file.path).toLowerCase(); // Using path package
        final bytes = await file.readAsBytes();
        final name = file.path.split('/').last;
        debugPrint('File extension: $ext');
        bool attachmentsEnabled = widget.featureTable.hasAttachments ?? false;
        debugPrint("attachmentsEnabled $attachmentsEnabled");
        await widget.feature.addAttachment(
          name: name,
          contentType: _mimeTypeForExtension(ext), // optionally map to mime type
          data: bytes,
        );
      }
      bool attachmentsEnabled = widget.featureTable.hasAttachments ?? false;
      debugPrint("1attachmentsEnabled $attachmentsEnabled");
      await _applyEdits(widget.feature);
      debugPrint("_applyEdits Done");

      // add first records on related table
      ArcGISFeatureTable arcGISFeatureTable = relatedTables!.first;
      await arcGISFeatureTable.load();
      debugPrint("arcGISFeatureTable.numberOfFeatures ${arcGISFeatureTable.numberOfFeatures}");
      final relatedFeatures = await getRelatedFeatures(widget.feature);
      debugPrint("relatedFeatures $relatedFeatures");
      if(relatedFeatures.isEmpty)
      {
        final DateTime defaultDate = DateTime.now();
        Map<String, dynamic> newAttributes = {
          'GUID': widget.feature.attributes['globalid'], // link to parent
          'intpprogress': initProgress,
          'surveyordate': defaultDate,// example physical progress code
          // other necessary attributes
        };
        final newFeature = arcGISFeatureTable.createFeature(attributes: newAttributes) as ArcGISFeature;
        await arcGISFeatureTable.addFeature(newFeature);
        debugPrint("applyEdits applyEdits2");
        for (final file in _newAttachments) {
          final ext = path.extension(file.path).toLowerCase(); // Using path package
          final bytes = await file.readAsBytes();
          final name = file.path.split('/').last;
          debugPrint('File extension: $ext');
          bool attachmentsEnabled = arcGISFeatureTable.hasAttachments ?? false;
          debugPrint("attachmentsEnabled $attachmentsEnabled");
          await newFeature.addAttachment(
            name: name,
            contentType: _mimeTypeForExtension(ext), // optionally map to mime type
            data: bytes,
          );
        }
        await _applyEdits(newFeature);
        debugPrint("arcGISFeatureTable.numberOfFeatures ${arcGISFeatureTable.numberOfFeatures}");
      }
      widget.onFormSaved();
    } catch (e) {
      if (mounted) {
        debugPrint("Error $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
    finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _applyEdits(ArcGISFeature selectedFeature) async {
    final featureTable = selectedFeature.featureTable;

    try {
      if (featureTable is ServiceFeatureTable) {
        // Online or service geodatabase case
        await featureTable.updateFeature(selectedFeature);
        await featureTable.serviceGeodatabase!.applyEdits();
      } else if (featureTable is GeodatabaseFeatureTable) {
        // Offline geodatabase case
        await featureTable.updateFeature(selectedFeature);
        // await featureTable.applyEdits();
      } else {
        throw Exception("Unsupported feature table type for applyEdits");
      }
    } on ArcGISException catch (e) {
      debugPrint("ArcGISException $e");
    }
    return Future.value();
  }


  String _mimeTypeForExtension(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
  List<ArcGISFeatureTable>? relatedTables;
  Future<List<Feature>> getRelatedFeatures(ArcGISFeature feature) async {
    debugPrint("getRelatedFeatures");
    if (_mainFeatureTable == null) return [];
    final relatedResults = await _mainFeatureTable!.queryRelatedFeatures(feature: feature);
    debugPrint("1getRelatedFeatures");
    relatedTables = _mainFeatureTable?.getRelatedTables();
    debugPrint("relatedTables; ${relatedTables?.length}");
    // for (final relatedTable in relatedTables!) {
    //   print('Related table name: ${relatedTable.tableName}');
    //   print('Related display name: ${relatedTable.displayName}');
    //   print('Related display name: ${relatedTable.getRelatedTables()}');
    //   for (final innerRelatedTable in relatedTable.getRelatedTables())
    //   {
    //     print('Related display name: ${innerRelatedTable.tableName}');
    //   }
    //   // You can create a ServiceFeatureTable for the related table by constructing its URL or using the map service's layer info
    // }

    List<Feature> allRelatedFeatures = [];

    for (final result in relatedResults) {
      debugPrint("result.features(); ${result.features()}");
      allRelatedFeatures.addAll(result.features());
    }
    return allRelatedFeatures;
  }




}

// class RelatedFeaturesTable extends StatefulWidget {
class RelatedFeaturesTable extends StatefulWidget {
  final List<Feature> relatedFeatures;
  final ArcGISFeatureTable relatedFeatureTable;
  final VoidCallback refreshParent;
  final ArcGISFeature feature;

  const RelatedFeaturesTable({
    required this.relatedFeatures,
    required this.relatedFeatureTable,
    required this.refreshParent,
    required this.feature,
    super.key,
  });

  @override
  _RelatedFeaturesTableState createState() => _RelatedFeaturesTableState();
}

class _RelatedFeaturesTableState extends State<RelatedFeaturesTable> {
  late List<Feature> features;
  late var maxPrevProgress;
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _newFeatureAttributes = {};
  // late ServiceFeatureTable _relatedFeatureTable;
  @override
  void initState() {
    super.initState();
    features = List.from(widget.relatedFeatures);
    debugPrint("features ${features.length}");
    // final relatedFeatures = widget.relatedFeatureTable.features;

// Extract all intpprogress values
    final progressValues = features.map((feature) {
      debugPrint("feature ${feature.attributes}");
      final rawValue = feature.attributes['intpprogress'];
      return (rawValue != null) ? rawValue as int : 0;
    }).toList();

// Find maximum, or default to 0 if list is empty
    maxPrevProgress = progressValues.isNotEmpty
        ? progressValues.reduce((a, b) => a > b ? a : b)
        : 0;

    debugPrint("maxPrevProgress $maxPrevProgress");

  }

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) {
      return Column(
        children: [
          const Text('No related features found.'),
          ElevatedButton(
          onPressed: () {
          _showCreateFeatureDialog(maxPrevProgress);
          },
            child: const Text('Add Related Feature'),
          )
        ],
      );
    }

    final fields = widget.relatedFeatureTable.fields;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              ...fields.map((field) => DataColumn(label: Text(field.alias ?? field.name))),
              const DataColumn(label: Text('Actions')),
            ],
            rows: features.map((feature) {
              return DataRow(cells: [
                ...fields.map((field) {
                  final value = feature.attributes[field.name];
                  return DataCell(
                    Text(value?.toString() ?? ''),
                    showEditIcon: true,
                    onTap: () async {
                      final newValue = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          String editedValue = value?.toString() ?? '';
                          return AlertDialog(
                            title: Text('Edit ${field.alias ?? field.name}'),
                            content: TextFormField(
                              initialValue: editedValue,
                              onChanged: (val) => editedValue = val,
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              ElevatedButton(
                                child: const Text('Save'),
                                onPressed: () => Navigator.of(context).pop(editedValue),
                              )
                            ],
                          );
                        },
                      );
                      if (newValue != null && newValue != value?.toString()) {
                        debugPrint("field.name ${field.name}");
                        setState(() {
                          feature.attributes[field.name] = newValue;
                        });
                        await _updateFeature(feature);
                      }
                    },
                  );
                }).toList(),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFeature(feature),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
        ElevatedButton(
        onPressed: () {
    _showCreateFeatureDialog(maxPrevProgress);
    },
          child: const Text('Add Related Feature'),
        ),
      ],
    );
  }
  Future<void> _deleteFeature(Feature feature) async {
    try {
      await widget.relatedFeatureTable.deleteFeature(feature);
      if (widget.relatedFeatureTable is ServiceFeatureTable) {
        final serviceFeatureTable = widget.relatedFeatureTable as ServiceFeatureTable;
        await serviceFeatureTable.serviceGeodatabase!.applyEdits();
      }
      setState(() {
        features.remove(feature);
      });
      widget.refreshParent();
    } catch (e) {
      debugPrint("_deleteFeature $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _updateFeature(Feature feature) async {
    try {
      await widget.relatedFeatureTable.updateFeature(feature);
      if (widget.relatedFeatureTable is ServiceFeatureTable) {
        final serviceFeatureTable = widget.relatedFeatureTable as ServiceFeatureTable;
        await serviceFeatureTable.serviceGeodatabase!.applyEdits();
      }
      widget.refreshParent();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  void _showCreateFeatureDialog(int maxPrevProgress) {
    final intpProgressField = widget.relatedFeatureTable.fields.firstWhere(
          (f) => f.name.toLowerCase() == 'intpprogress',
      orElse: () => throw Exception('intpprogress field not found'),
    );

    final List<dynamic> codedValuesJson = intpProgressField.domain?.toJson()['codedValues'] ?? [];
    final List<Map<String, dynamic>> codedValues = codedValuesJson.map((cv) {
      return {'code': cv['code'], 'name': cv['name']};
    }).toList();

    int? selectedCode;
    List<PlatformFile> attachedFiles = [];
    final DateTime defaultDate = DateTime.now();
    final _formKey = GlobalKey<FormState>();

    bool isLoading = false; // Loading indicator state

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal while loading
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickAttachments() async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'txt'],
                allowMultiple: true,
              );
              if (result != null) {
                setState(() {
                  attachedFiles.addAll(result.files);
                });
              }
            }

            void removeAttachment(int index) {
              setState(() {
                attachedFiles.removeAt(index);
              });
            }

            String mimeTypeForExtension(String ext) {
              switch (ext.toLowerCase()) {
                case '.jpg':
                case '.jpeg':
                  return 'image/jpeg';
                case '.png':
                  return 'image/png';
                case '.pdf':
                  return 'application/pdf';
                case '.txt':
                  return 'text/plain';
                default:
                  return 'application/octet-stream';
              }
            }

            Future<void> createFeatureWithAttachments() async {
              if (!_formKey.currentState!.validate()) return;
              _formKey.currentState!.save();

              setState(() {
                isLoading = true;
              });

              Map<String, dynamic> newAttributes = {
                'GUID': widget.feature.attributes['globalid'],
                intpProgressField.name: selectedCode,
                'surveyordate': defaultDate,
              };

              try {
                final newFeature =
                widget.relatedFeatureTable.createFeature(attributes: newAttributes) as ArcGISFeature;
                await widget.relatedFeatureTable.addFeature(newFeature);

                for (final attachedFile in attachedFiles) {
                  File file = File(attachedFile.path!);
                  final bytes = await file.readAsBytes();
                  final ext = path.extension(file.path).toLowerCase();
                  final name = path.basename(file.path);
                  await newFeature.addAttachment(
                    name: name,
                    contentType: mimeTypeForExtension(ext),
                    data: bytes,
                  );
                }

                // if (widget.relatedFeatureTable is ServiceFeatureTable) {
                //   await (widget.relatedFeatureTable as ServiceFeatureTable).updateFeature(newFeature);
                //   final applyEditsResult =
                //   await (widget.relatedFeatureTable as ServiceFeatureTable).applyEdits();
                //   if (applyEditsResult.isEmpty) {
                //     throw Exception('ApplyEdits returned no results, attachment may not be added');
                //   }
                // }
                if (widget.relatedFeatureTable is ServiceFeatureTable) {
                  // Online or offline service geodatabase case
                  final serviceFeatureTable = widget.relatedFeatureTable as ServiceFeatureTable;
                  await serviceFeatureTable.updateFeature(newFeature);
                  final applyEditsResult = await serviceFeatureTable.applyEdits();
                  if (applyEditsResult.isEmpty) {
                    throw Exception('ApplyEdits returned no results, attachment may not be added');
                  }
                } else if (widget.relatedFeatureTable is GeodatabaseFeatureTable) {
                  // Offline local geodatabase case
                  final geodatabaseFeatureTable = widget.relatedFeatureTable as GeodatabaseFeatureTable;
                  await geodatabaseFeatureTable.updateFeature(newFeature);
                  // No applyEdits() call needed for GeodatabaseFeatureTable offline mode,
                  // changes are saved immediately.
                } else {
                  throw Exception('Unsupported feature table type for updating features');
                }


                setState(() {
                  attachedFiles.clear();
                  features.add(newFeature);
                });

                widget.refreshParent();

                Navigator.of(context).pop(); // Close dialog on success
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Create failed: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });
                }
              }
            }

            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: AbsorbPointer(
                        absorbing: isLoading, // Disable form when loading
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Add Progress Entry', style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 16),
                              TextFormField(
                                readOnly: true,
                                initialValue: DateFormat('yyyy-MM-dd').format(defaultDate),
                                decoration: const InputDecoration(
                                  labelText: 'Survey Date',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                decoration: const InputDecoration(
                                  labelText: 'Physical Progress',
                                  border: OutlineInputBorder(),
                                ),
                                value: selectedCode,
                                items: codedValues.map((cv) {
                                  return DropdownMenuItem<int>(
                                    value: cv['code'],
                                    child: Text(cv['name']),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => selectedCode = val),
                                validator: (val) {
                                  if (val == null) {
                                    return 'Please select a physical progress status';
                                  }
                                  if (val <= maxPrevProgress) {
                                    return 'Progress must be higher than last recorded ($maxPrevProgress)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              if (attachedFiles.isNotEmpty) ...[
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: attachedFiles.length,
                                    itemBuilder: (context, index) {
                                      final file = attachedFiles[index];
                                      return ListTile(
                                        dense: true,
                                        title: Text(file.name, overflow: TextOverflow.ellipsis),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () => removeAttachment(index),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              ElevatedButton.icon(
                                icon: const Icon(Icons.attach_file),
                                label: const Text('Add Attachments'),
                                onPressed: pickAttachments,
                              ),

                              const SizedBox(height: 24),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      if (!isLoading) Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: isLoading ? null : createFeatureWithAttachments,
                                    child: const Text('Create'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.4),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}