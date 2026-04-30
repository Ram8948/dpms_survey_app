import 'dart:typed_data';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../widget/custom_floating_appbar.dart';

class DetailsPage extends StatefulWidget {
  final List<Field> fields;
  final ArcGISFeature feature;

  DetailsPage({required this.fields, required this.feature, super.key});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  List<Attachment> _attachments = [];
  bool _attachmentsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    try {
      if (widget.feature.loadStatus != LoadStatus.loaded) {
        await widget.feature.load();
      }
      final attachments = await widget.feature.fetchAttachments();
      if (mounted) {
        setState(() {
          _attachments = attachments;
          _attachmentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _attachmentsLoading = false);
        debugPrint('Failed to load attachments: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.feature.attributes;
    const visibleFieldNames = [
      'Scheme Name',
      'Scheme Id',
      'Surveyor Date',
      'Remarks',
      'Officer Name',
      'Physical Progress',
      'Financial Progress',
    ];

    final visibleFields = widget.fields
        .where((f) => visibleFieldNames.contains(f.alias))
        .toList();

    return Scaffold(
      appBar: CustomFloatingAppBar(
        title: 'Related Record Details',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...visibleFields.map((field) {
              final fieldName = field.name;
              final fieldAlias = field.alias ?? field.name;

              String displayValue;

              final Map<String, dynamic>? domainJson = field.domain?.toJson();
              final List<dynamic>? codedValues = domainJson?['codedValues'];

              if (codedValues != null) {
                final match = codedValues.firstWhere(
                  (cv) => cv['code'] == data[fieldName],
                  orElse: () => null,
                );

                if (match != null) {
                  displayValue = match['name'] ?? data[fieldName].toString();
                } else {
                  displayValue = data[fieldName].toString();
                }
              } else {
                displayValue = data[fieldName]?.toString() ?? '-';
              }

              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        "$fieldAlias : ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        displayValue,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            Text(
              "Attachments",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _attachmentsLoading
                ? const Center(child: CircularProgressIndicator())
                : _attachments.isEmpty
                    ? const Text("No attachments found.")
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _attachments.length,
                        itemBuilder: (context, index) {
                          final attachment = _attachments[index];
                          return GestureDetector(
                            onTap: () => _showAttachmentPreview(attachment),
                            child: Stack(
                              children: [
                                FutureBuilder<Uint8List>(
                                  future: attachment.fetchData(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    }
                                    if (snapshot.hasError || !snapshot.hasData) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error),
                                      );
                                    }

                                    if (attachment.contentType
                                        .startsWith('image/')) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      );
                                    } else {
                                      return Container(
                                        color: Colors.blue[50],
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.insert_drive_file,
                                                  size: 32, color: Colors.blue),
                                              const SizedBox(height: 4),
                                              Text(
                                                attachment.name,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 10),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentPreview(Attachment attachment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(attachment.name, style: const TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: FutureBuilder<Uint8List>(
                future: attachment.fetchData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Could not load preview."),
                    );
                  }

                  if (attachment.contentType.startsWith('image/')) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.insert_drive_file,
                              size: 64, color: Colors.blue),
                          const SizedBox(height: 16),
                          Text(attachment.name),
                          const SizedBox(height: 8),
                          Text(attachment.contentType,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
