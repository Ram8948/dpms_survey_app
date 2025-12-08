import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../widget/custom_floating_appbar.dart';

class AddRelatedFeaturePage extends StatefulWidget {
  final ArcGISFeatureTable relatedFeatureTable;
  final ArcGISFeature parentFeature;
  final int maxPrevProgress;

  const AddRelatedFeaturePage({
    required this.relatedFeatureTable,
    required this.parentFeature,
    required this.maxPrevProgress,
    super.key,
  });

  @override
  _AddRelatedFeaturePageState createState() => _AddRelatedFeaturePageState();
}

class _AddRelatedFeaturePageState extends State<AddRelatedFeaturePage> {
  final _formKey = GlobalKey<FormState>();
  List<PlatformFile> attachedFiles = [];
  String? attachmentError;
  bool isLoading = false;
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _officerNameController = TextEditingController();

  final DateTime defaultDate = DateTime.now();

  // Controllers for all field types - NO LONGER NEEDED FOR DROPDOWNS, BUT KEPT FOR REMAINING TEXTFIELDS
  // final TextEditingController _physCivilUncCtrl = TextEditingController();
  // final TextEditingController _finCivilUncCtrl = TextEditingController();
  // final TextEditingController _physMechUncCtrl = TextEditingController();
  // final TextEditingController _finMechUncCtrl = TextEditingController();
  // final TextEditingController _physCivilConCtrl = TextEditingController();
  // final TextEditingController _finCivilConCtrl = TextEditingController();
  // final TextEditingController _physMechConCtrl = TextEditingController();
  // final TextEditingController _finMechConCtrl = TextEditingController();

  // Selected codes for the main physical/financial progress
  int? selectedCodeP;
  int? selectedCodeF;

  // Selected codes for the subtype progress fields (Physical/Financial, Civil/Mech, Con/Uncon)
  int? selectedCodePhysCivilCon;
  int? selectedCodeFinCivilCon;
  int? selectedCodePhysMechCon;
  int? selectedCodeFinMechCon;
  int? selectedCodePhysCivilUnc;
  int? selectedCodeFinCivilUnc;
  int? selectedCodePhysMechUnc;
  int? selectedCodeFinMechUnc;

  // Field names for the main physical/financial progress
  late final String intpProgressField;
  late final String? intfProgressField;

  // Field names for the subtype progress fields
  late final String physCivilConField;
  late final String finCivilConField;
  late final String physMechConField;
  late final String finMechConField;
  late final String physCivilUncField;
  late final String finCivilUncField;
  late final String physMechUncField;
  late final String finMechUncField;

  // Coded values for the main physical/financial progress
  late final List<Map<String, dynamic>> codedValuesP;
  late final List<Map<String, dynamic>> codedValuesF;

  // Coded values for the subtype progress fields
  late final List<Map<String, dynamic>> codedValuesPhysCivilCon;
  late final List<Map<String, dynamic>> codedValuesFinCivilCon;
  late final List<Map<String, dynamic>> codedValuesPhysMechCon;
  late final List<Map<String, dynamic>> codedValuesFinMechCon;
  late final List<Map<String, dynamic>> codedValuesPhysCivilUnc;
  late final List<Map<String, dynamic>> codedValuesFinCivilUnc;
  late final List<Map<String, dynamic>> codedValuesPhysMechUnc;
  late final List<Map<String, dynamic>> codedValuesFinMechUnc;

  // Subtype determination
  int? _subtype;
  bool get isConventional => _subtype == 1;
  bool get isUnconventional => _subtype == 2;

  /// Helper to find a field by name (case-insensitive)
  Field? findField(String name) {
    try {
      return widget.relatedFeatureTable.fields.firstWhere(
            (f) => f.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Helper to get coded values from a field, returns empty list if field or domain is missing
  List<Map<String, dynamic>> getCodedValues(String fieldName) {
    final field = findField(fieldName);
    if (field == null || field.domain == null) return [];
    final List<dynamic> codedValuesJson = field.domain!.toJson()['codedValues'] ?? [];
    return codedValuesJson.map((cv) {
      debugPrint("fieldName cv['name'] $fieldName : ${cv['name']}");
      return {'code': cv['code'], 'name': cv['name']};
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    // Print all fields and domains for debugging
    debugPrint("=== ALL FIELDS AND DOMAINS ===");
    for (final field in widget.relatedFeatureTable.fields) {
      final fieldName = field.name;
      final domainName = field.domain?.name ?? 'No domain';
      debugPrint('Field Name: $fieldName, Domain: $domainName');
    }
    debugPrint("================================");

    // Determine subtype from parent feature
    _subtype = widget.parentFeature.attributes['subtype'] as int?;
    debugPrint("Subtype: $_subtype (Conventional: $isConventional, Unconventional: $isUnconventional)");

    // --- 1. Determine and fetch main progress fields ---

    // Physical Progress (with fallback)
    intpProgressField = 'intpprogress';
    codedValuesP = getCodedValues(intpProgressField);

    intfProgressField = 'intfprogress';
    codedValuesF = getCodedValues(intfProgressField!);


    // --- 2. Determine and fetch subtype progress fields ---
    // Conventional - Civil
    physCivilConField = 'intpprogressccon'; // Assuming 'intpprogresscon' was a typo/general field name
    finCivilConField = 'intfprogressccon';
    codedValuesPhysCivilCon = getCodedValues(physCivilConField);
    codedValuesFinCivilCon = getCodedValues(finCivilConField);

    // Conventional - Mechanical
    physMechConField = 'intpprogressmcon';
    finMechConField = 'intfprogressmcon';
    codedValuesPhysMechCon = getCodedValues(physMechConField);
    codedValuesFinMechCon = getCodedValues(finMechConField);

    // Unconventional - Civil
    physCivilUncField = 'intpprogresscunc';
    finCivilUncField = 'intfprogresscunc';
    codedValuesPhysCivilUnc = getCodedValues(physCivilUncField);
    codedValuesFinCivilUnc = getCodedValues(finCivilUncField);

    // Unconventional - Mechanical
    physMechUncField = 'intpprogressmunc';
    finMechUncField = 'intfprogressmunc';
    codedValuesPhysMechUnc = getCodedValues(physMechUncField);
    codedValuesFinMechUnc = getCodedValues(finMechUncField);

    // NOTE: The original logic for field names in initState was slightly complex and seemed to point to generic fields.
    // The new logic assumes specific field names for each component based on the fields used in the build method.
  }

  bool hasField(String name) {
    return widget.relatedFeatureTable.fields.any((f) => f.name.toLowerCase() == name.toLowerCase());
  }

  // Conventional field getters - CIVIL
  bool get hasPhysProg => codedValuesP.isNotEmpty;
  bool get hasFinProg => codedValuesF.isNotEmpty;

  // Conventional field getters - CIVIL
  bool get hasPhysProgCivilCon => codedValuesPhysCivilCon.isNotEmpty;
  bool get hasFinProgCivilCon => codedValuesFinCivilCon.isNotEmpty;
  // Conventional field getters - MECHANICAL
  bool get hasPhysProgMechCon => codedValuesPhysMechCon.isNotEmpty;
  bool get hasFinProgMechCon => codedValuesFinMechCon.isNotEmpty;
  // Unconventional field getters - CIVIL
  bool get hasPhysProgCivilUnc => codedValuesPhysCivilUnc.isNotEmpty;
  bool get hasFinProgCivilUnc => codedValuesFinCivilUnc.isNotEmpty;
  // Unconventional field getters - MECHANICAL
  bool get hasPhysProgMechUnc => codedValuesPhysMechUnc.isNotEmpty;
  bool get hasFinProgMechUnc => codedValuesFinMechUnc.isNotEmpty;
  // Generic fallback (already handled by main codedValuesP/F)

  Future<void> pickAttachments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'txt'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        attachedFiles.addAll(result.files);
        attachmentError = null;
      });
    }
  }

  Future<void> pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final File file = File(photo.path);
      final int fileSize = await file.length();

      setState(() {
        attachedFiles.add(
          PlatformFile(
            name: photo.name,
            path: photo.path,
            size: fileSize,
            bytes: null,
          ),
        );
        attachmentError = null;
      });
    }
  }

  void removeAttachment(int index) {
    setState(() {
      attachedFiles.removeAt(index);
      if (attachedFiles.isEmpty) {
        attachmentError = 'Please add at least one attachment';
      } else {
        attachmentError = null;
      }
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

    if (attachedFiles.isEmpty) {
      setState(() {
        attachmentError = 'Please add at least one attachment';
      });
      return;
    } else {
      setState(() {
        attachmentError = null;
      });
    }

    _formKey.currentState!.save();

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> newAttributes = {
        'GUID': widget.parentFeature.attributes['globalid'],
        'surveyordate': defaultDate,
        'schemename': widget.parentFeature.attributes["name"],
        'schemeid': widget.parentFeature.attributes["id"],
        'remarks': _remarkController.text,
        'officername': _officerNameController.text,
      };

      // Add main progress dropdown values
      if (selectedCodeP != null) {
        newAttributes[intpProgressField] = selectedCodeP;
      }
      if (selectedCodeF != null && intfProgressField != null) {
        newAttributes[intfProgressField!] = selectedCodeF;
      }

      // Add subtype-specific Dropdown values
      if (isConventional) {
        // CIVIL Conventional
        if (hasPhysProgCivilCon && selectedCodePhysCivilCon != null) {
          newAttributes[physCivilConField] = selectedCodePhysCivilCon;
        }
        if (hasFinProgCivilCon && selectedCodeFinCivilCon != null) {
          newAttributes[finCivilConField] = selectedCodeFinCivilCon;
        }

        // MECHANICAL Conventional
        if (hasPhysProgMechCon && selectedCodePhysMechCon != null) {
          newAttributes[physMechConField] = selectedCodePhysMechCon;
        }
        if (hasFinProgMechCon && selectedCodeFinMechCon != null) {
          newAttributes[finMechConField] = selectedCodeFinMechCon;
        }
      } else if (isUnconventional) {
        // CIVIL Unconventional
        if (hasPhysProgCivilUnc && selectedCodePhysCivilUnc != null) {
          newAttributes[physCivilUncField] = selectedCodePhysCivilUnc;
        }
        if (hasFinProgCivilUnc && selectedCodeFinCivilUnc != null) {
          newAttributes[finCivilUncField] = selectedCodeFinCivilUnc;
        }

        // MECHANICAL Unconventional
        if (hasPhysProgMechUnc && selectedCodePhysMechUnc != null) {
          newAttributes[physMechUncField] = selectedCodePhysMechUnc;
        }
        if (hasFinProgMechUnc && selectedCodeFinMechUnc != null) {
          newAttributes[finMechUncField] = selectedCodeFinMechUnc;
        }
      }

      final newFeature = widget.relatedFeatureTable.createFeature(
        attributes: newAttributes,
      ) as ArcGISFeature;
      await widget.relatedFeatureTable.addFeature(newFeature);

      for (final attachedFile in attachedFiles) {
        File file = File(attachedFile.path!);
        final ext = path.extension(file.path).toLowerCase();
        final name = path.basename(file.path);
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          file.path,
          quality: 50,
          format: ext == ".jpg" || ext == ".jpeg"
              ? CompressFormat.jpeg
              : CompressFormat.png,
        );

        await newFeature.addAttachment(
          name: name,
          contentType: mimeTypeForExtension(ext),
          data: compressedBytes!,
        );
      }

      if (widget.relatedFeatureTable is ServiceFeatureTable) {
        final serviceFeatureTable = widget.relatedFeatureTable as ServiceFeatureTable;
        await serviceFeatureTable.updateFeature(newFeature);
        final applyEditsResult = await serviceFeatureTable.applyEdits();
        if (applyEditsResult.isEmpty) {
          throw Exception('ApplyEdits returned no results, attachment may not be added');
        }
      } else if (widget.relatedFeatureTable is GeodatabaseFeatureTable) {
        final geodatabaseFeatureTable = widget.relatedFeatureTable as GeodatabaseFeatureTable;
        await geodatabaseFeatureTable.updateFeature(newFeature);
      } else {
        throw Exception('Unsupported feature table type for updating features');
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _officerNameController.dispose();
    super.dispose();
  }

  // Helper function to create a DropdownButtonFormField for subtype progress
  Widget _buildSubtypeDropdown({
    required String labelText,
    required List<Map<String, dynamic>> codedValues,
    required int? selectedValue,
    required ValueChanged<int?> onChanged,
  }) {
    if (codedValues.isEmpty) return const SizedBox.shrink(); // Hide if no coded values available

    return Column(
      children: [
        DropdownButtonFormField<int>(
          isExpanded: true,
          decoration: InputDecoration(
            labelText: labelText,
            border: OutlineInputBorder(),
          ),
          value: selectedValue,
          items: codedValues.map((cv) {
            return DropdownMenuItem<int>(
              value: cv['code'],
              child: Text(cv['name']),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomFloatingAppBar(
        title: 'Add Progress Entry',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AbsorbPointer(
              absorbing: isLoading,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      readOnly: true,
                      initialValue: widget.parentFeature.attributes["name"],
                      decoration: const InputDecoration(
                        labelText: 'Scheme Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      initialValue: widget.parentFeature.attributes["id"].toString(),
                      decoration: const InputDecoration(
                        labelText: 'Scheme Id',
                        border: OutlineInputBorder(),
                      ),
                    ),
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

                    // // Main Physical Progress Dropdown (always show)
                    // DropdownButtonFormField<int>(
                    //   isExpanded: true,
                    //   decoration: InputDecoration(
                    //     labelText: 'Physical Progress',
                    //     border: OutlineInputBorder(),
                    //   ),
                    //   value: selectedCodeP,
                    //   items: codedValuesP.map((cv) {
                    //     return DropdownMenuItem<int>(
                    //       value: cv['code'],
                    //       child: Text(cv['name']),
                    //     );
                    //   }).toList(),
                    //   onChanged: (val) => setState(() => selectedCodeP = val),
                    //   validator: (val) {
                    //     if (val == null) {
                    //       return 'Please select a progress status';
                    //     }
                    //     if (val! <= widget.maxPrevProgress) {
                    //       return 'Progress must be higher than last recorded (${widget.maxPrevProgress})';
                    //     }
                    //     return null;
                    //   },
                    // ),
                    // const SizedBox(height: 16),
                    //
                    // // Financial Progress Dropdown (if available)
                    // if (intfProgressField != null) ...[
                    //   DropdownButtonFormField<int>(
                    //     isExpanded: true,
                    //     decoration: const InputDecoration(
                    //       labelText: 'Financial Progress',
                    //       border: OutlineInputBorder(),
                    //     ),
                    //     value: selectedCodeF,
                    //     items: codedValuesF.map((cv) {
                    //       return DropdownMenuItem<int>(
                    //         value: cv['code'],
                    //         child: Text(cv['name']),
                    //       );
                    //     }).toList(),
                    //     onChanged: (val) => setState(() => selectedCodeF = val),
                    //   ),
                    //   const SizedBox(height: 16),
                    // ],


                    _buildSubtypeDropdown(
                      labelText: 'Physical Progress',
                      codedValues: codedValuesP,
                      selectedValue: selectedCodeP,
                      onChanged: (val) => setState(() => selectedCodeP = val),
                    ),

                    _buildSubtypeDropdown(
                      labelText: 'Financial Progress',
                      codedValues: codedValuesF,
                      selectedValue: selectedCodeF,
                      onChanged: (val) => setState(() => selectedCodeF = val),
                    ),

                    // Conventional subtype fields
                    if (isConventional) ...[
                      // CIVIL FIELDS
                      _buildSubtypeDropdown(
                        labelText: 'Physical Progress Civil (Con)',
                        codedValues: codedValuesPhysCivilCon,
                        selectedValue: selectedCodePhysCivilCon,
                        onChanged: (val) => setState(() => selectedCodePhysCivilCon = val),
                      ),
                      _buildSubtypeDropdown(
                        labelText: 'Financial Progress Civil (Con)',
                        codedValues: codedValuesFinCivilCon,
                        selectedValue: selectedCodeFinCivilCon,
                        onChanged: (val) => setState(() => selectedCodeFinCivilCon = val),
                      ),

                      // MECHANICAL FIELDS
                      _buildSubtypeDropdown(
                        labelText: 'Physical Progress Mech (Con)',
                        codedValues: codedValuesPhysMechCon,
                        selectedValue: selectedCodePhysMechCon,
                        onChanged: (val) => setState(() => selectedCodePhysMechCon = val),
                      ),
                      _buildSubtypeDropdown(
                        labelText: 'Financial Progress Mech (Con)',
                        codedValues: codedValuesFinMechCon,
                        selectedValue: selectedCodeFinMechCon,
                        onChanged: (val) => setState(() => selectedCodeFinMechCon = val),
                      ),
                    ],

                    // Unconventional subtype fields
                    if (isUnconventional) ...[
                      // CIVIL FIELDS
                      _buildSubtypeDropdown(
                        labelText: 'Physical Progress Civil (Unc)',
                        codedValues: codedValuesPhysCivilUnc,
                        selectedValue: selectedCodePhysCivilUnc,
                        onChanged: (val) => setState(() => selectedCodePhysCivilUnc = val),
                      ),
                      _buildSubtypeDropdown(
                        labelText: 'Financial Progress Civil (Unc)',
                        codedValues: codedValuesFinCivilUnc,
                        selectedValue: selectedCodeFinCivilUnc,
                        onChanged: (val) => setState(() => selectedCodeFinCivilUnc = val),
                      ),

                      // MECHANICAL FIELDS
                      _buildSubtypeDropdown(
                        labelText: 'Physical Progress Mech (Unc)',
                        codedValues: codedValuesPhysMechUnc,
                        selectedValue: selectedCodePhysMechUnc,
                        onChanged: (val) => setState(() => selectedCodePhysMechUnc = val),
                      ),
                      _buildSubtypeDropdown(
                        labelText: 'Financial Progress Mech (Unc)',
                        codedValues: codedValuesFinMechUnc,
                        selectedValue: selectedCodeFinMechUnc,
                        onChanged: (val) => setState(() => selectedCodeFinMechUnc = val),
                      ),
                    ],

                    TextFormField(
                      controller: _officerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Officer Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Officer Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _remarkController,
                      decoration: const InputDecoration(
                        labelText: 'Remark',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (attachedFiles.isNotEmpty)
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
                    if (attachmentError != null)
                      Text(
                        attachmentError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Add Photos'),
                      onPressed: () async {
                        await pickImageFromCamera();
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
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
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}