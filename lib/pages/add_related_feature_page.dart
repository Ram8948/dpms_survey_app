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
  int? selectedCode;
  int? selectedCodeF;
  List<PlatformFile> attachedFiles = [];
  String? attachmentError;
  bool isLoading = false;
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _officerNameController = TextEditingController();

  final DateTime defaultDate = DateTime.now();

  late final intpProgressField;
  late final List<Map<String, dynamic>> codedValues;
  late final List<Map<String, dynamic>> codedValuesF;

  @override
  void initState() {
    super.initState();
    debugPrint("widget.relatedFeatureTable.fields ${widget.relatedFeatureTable.fields}");
    final intpProgressFieldObj = widget.relatedFeatureTable.fields.firstWhere(
          (f) => f.name.toLowerCase() == 'intpprogress',
      orElse: () => throw Exception('intpprogress field not found'),
    );
    intpProgressField = intpProgressFieldObj.name;

    final List<dynamic> codedValuesJson =
        intpProgressFieldObj.domain?.toJson()['codedValues'] ?? [];
    codedValues = codedValuesJson.map((cv) {
      return {'code': cv['code'], 'name': cv['name']};
    }).toList();

    final intfProgressFieldObj = widget.relatedFeatureTable.fields.firstWhere(
          (f) => f.name.toLowerCase() == 'intfprogress',
      orElse: () => throw Exception('intpprogress field not found'),
    );

    final List<dynamic> codedValuesJsonF =
        intfProgressFieldObj.domain?.toJson()['codedValues'] ?? [];
    codedValuesF = codedValuesJsonF.map((cv) {
      return {'code': cv['code'], 'name': cv['name']};
    }).toList();

    if (widget.parentFeature.attributes.containsKey("subtype")) {
      int subtype = widget.parentFeature.attributes['subtype'];
      if (subtype == 1) {
        intpProgressField = "intpprogressc";
      }
    }
  }

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
        intpProgressField: selectedCode,
        if (selectedCodeF != null) 'intfprogress': selectedCodeF,
        'surveyordate': defaultDate,
        'schemename': widget.parentFeature.attributes["name"],
        'schemeid': widget.parentFeature.attributes["id"],
        'remarks': _remarkController.text,
        'officername': _officerNameController.text,
      };

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
        final serviceFeatureTable =
        widget.relatedFeatureTable as ServiceFeatureTable;
        await serviceFeatureTable.updateFeature(newFeature);
        final applyEditsResult = await serviceFeatureTable.applyEdits();
        if (applyEditsResult.isEmpty) {
          throw Exception(
              'ApplyEdits returned no results, attachment may not be added');
        }
      } else if (widget.relatedFeatureTable is GeodatabaseFeatureTable) {
        final geodatabaseFeatureTable =
        widget.relatedFeatureTable as GeodatabaseFeatureTable;
        await geodatabaseFeatureTable.updateFeature(newFeature);
      } else {
        throw Exception('Unsupported feature table type for updating features');
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Create failed: $e')));
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
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Add Progress Entry'),
      // ),
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
                    DropdownButtonFormField<int>(
                      isExpanded: true,
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
                        if (val! <= widget.maxPrevProgress) {
                          return 'Progress must be higher than last recorded (${widget.maxPrevProgress})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Financial Progress',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCodeF,
                      items: codedValuesF.map((cv) {
                        return DropdownMenuItem<int>(
                          value: cv['code'],
                          child: Text(cv['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedCodeF = val),
                      // validator: (val) {
                      //   if (val == null) {
                      //     return 'Please select a financial progress status';
                      //   }
                      //   // if (val! <= widget.maxPrevProgress) {
                      //   //   return 'Progress must be higher than last recorded (${widget.maxPrevProgress})';
                      //   // }
                      //   return null;
                      // },
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
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Add Photos'),
                      onPressed: () async {
                        await pickImageFromCamera();
                        // Or pickAttachments();
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
