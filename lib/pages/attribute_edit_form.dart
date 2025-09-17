import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class AttributeEditForm extends StatefulWidget {
  final ArcGISFeature feature;
  final ArcGISFeatureTable featureTable;
  final Popup featurePopup;
  final VoidCallback onFormSaved;
  final BuildContext parentScaffoldContext;

  const AttributeEditForm({
    required this.feature,
    required this.featureTable,
    required this.featurePopup,
    required this.onFormSaved,
    required this.parentScaffoldContext,
    Key? key,
  }) : super(key: key);

  @override
  _AttributeEditFormState createState() => _AttributeEditFormState();
}

class _AttributeEditFormState extends State<AttributeEditForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _editedAttributes;
  List<Attachment> _attachments = [];
  List<File> _newAttachments = [];
  bool _attachmentsLoading = true;

  @override
  void initState() {
    super.initState();
    final popupFields = widget.featurePopup.popupDefinition.fields.where((pf) =>
    (pf.isVisible ?? true));

    final popupFieldList = popupFields.toList();

    final popupFieldNames = popupFieldList
        .map((pf) => pf.fieldName.toLowerCase())
        .toSet();

    // Filter feature table fields to only popup fields and exclude system fields
    // final filteredFields = widget.featureTable.fields
    //     .where((field) {
    //   final fname = field.name.toLowerCase();
    //   return popupFieldNames.contains(fname) &&
    //       !['objectid', 'globalid', 'shape'].contains(fname);
    // })
    //     .toList();

    // Sort filtered fields in popup configured order
    // filteredFields.sort((a, b) {
    //   final aIndex = popupFieldList.indexWhere((pf) => pf.fieldName.toLowerCase() == a.name.toLowerCase());
    //   final bIndex = popupFieldList.indexWhere((pf) => pf.fieldName.toLowerCase() == b.name.toLowerCase());
    //   return aIndex.compareTo(bIndex);
    // });

    // Filter original attributes map to keep only popup-visible fields
    _editedAttributes = Map<String, dynamic>.fromEntries(
      widget.feature.attributes.entries.where((entry) =>
          popupFieldNames.contains(entry.key.toLowerCase())),
    );
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    try {
      final attachments = await widget.feature.fetchAttachments();
      setState(() {
        _attachments = attachments;
        _attachmentsLoading = false;
      });
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
    if (widget.feature.attributes.containsKey('Name')) {
      final val = widget.feature.attributes['Name'];
      if (val != null && val.toString().isNotEmpty) {
        return val.toString();
      }
    }
    final layerName =
        widget.featureTable.layerInfo?.serviceLayerName ?? 'Feature Layer';

    if (widget.feature.attributes.containsKey('OBJECTID')) {
      return '$layerName #${widget.feature.attributes['OBJECTID']}';
    }

    return layerName;
  }

  @override
  Widget build(BuildContext context) {
    // Filter popup fields by visibility if supported, default true otherwise
    final popupFields = widget.featurePopup.popupDefinition.fields.where((pf) =>
    (pf.isVisible ?? true));

    final popupFieldList = popupFields.toList();

    final popupFieldNames = popupFieldList
        .map((pf) => pf.fieldName.toLowerCase())
        .toSet();

    // Filter feature table fields to only popup fields and exclude system fields
    final filteredFields = widget.featureTable.fields
        .where((field) {
      final fname = field.name.toLowerCase();
      return popupFieldNames.contains(fname) &&
          !['objectid', 'globalid', 'shape'].contains(fname);
    })
        .toList();

    // Sort filtered fields in popup configured order
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
                // Attachments section unchanged
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
                  icon: const Icon(Icons.save),
                  onPressed: _saveAttributes,
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds form field with popup field's label if available
  Widget _buildFieldCard(Field field, List<PopupField> popupFields) {
    final isEditable = field.editable;
    final value = _editedAttributes[field.name];
    final isValueBlank = (value == null || (value is String && value.isEmpty));
    final shouldBeEditable = isEditable || isValueBlank;
    final readOnlyColor = Colors.grey[200];

    // Find popup field for alias/label
    PopupField? findPopupField(String fieldName, List<PopupField> popupFields) {
      for (final pf in popupFields) {
        if (pf.fieldName.toLowerCase() == fieldName.toLowerCase()) {
          return pf;
        }
      }
      return null;
    }

// Usage
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

    if (field.type == FieldType.date && shouldBeEditable) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () async {
              DateTime initialDate = DateTime.now();
              DateTime firstDate = DateTime(1900);
              DateTime lastDate = DateTime(2100);

              if (value != null) {
                DateTime? parsedDate;
                if (value is DateTime) {
                  parsedDate = value;
                } else if (value is String) {
                  parsedDate = DateTime.tryParse(value);
                }
                if (parsedDate != null) {
                  initialDate = parsedDate;
                }
              }

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
                controller: TextEditingController(text: formatDate(value)),
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
    debugPrint('_saveAttributes');
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
            debugPrint('_saveAttributes integer');
            if (typedValue == null && value.toString().isNotEmpty) {
              throw FormatException('Invalid integer');
            }
            break;
          case FieldType.float32:
          case FieldType.float64:
            typedValue = double.tryParse(value.toString());
            debugPrint('_saveAttributes double');
            if (typedValue == null && value.toString().isNotEmpty) {
              throw FormatException('Invalid double');
            }
            break;
          case FieldType.text:
            typedValue = value.toString();
            debugPrint('_saveAttributes text');
            break;
          case FieldType.date:
            if (value is String) {
              typedValue = DateTime.tryParse(value);
            } else if (value is DateTime) {
              typedValue = value;
            }
            debugPrint('_saveAttributes date');
            break;
          default:
            typedValue = value;
        }
        if (typedValue != null && typedValue!="null") {
          debugPrint('_saveAttributes typedValue $typedValue');
          widget.feature.attributes[key] = typedValue;
        }
      } catch (e) {
        debugPrint('_saveAttributes conversionErrors $e');
        conversionErrors.add('${field.alias} (${field.name})');
      }
    }

    if (conversionErrors.isNotEmpty) {
      debugPrint('_saveAttributes conversionErrors');
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
      await widget.feature.load();
      await widget.featureTable.updateFeature(widget.feature);
      if (widget.featureTable is ServiceFeatureTable) {
        await (widget.featureTable as ServiceFeatureTable).serviceGeodatabase!.applyEdits();
      }
      widget.onFormSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }
}
