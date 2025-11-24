import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../widget/custom_floating_appbar.dart';

class DetailsPage extends StatelessWidget {
  final List<Field> fields;
  final Map<String, dynamic> data;

  DetailsPage({required this.fields, required this.data, super.key});

  @override
  Widget build(BuildContext context) {

    const visibleFieldNames = [
      'Scheme Name',
      'Scheme Id',
      'Surveyor Date',
      'Remarks',
      'Officer Name',
      'Physical Progress',
      'Financial Progress',
    ];

    final visibleFields = fields
        .where((f) => visibleFieldNames.contains(f.alias))
        .toList();

    return Scaffold(
      // appBar: AppBar(title: const Text('Details')),
      appBar: CustomFloatingAppBar(
        title: 'Related Record Details',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: visibleFields.map((field) {
            final fieldName = field.name;
            final fieldAlias = field.alias ?? field.name;
            final value = data[fieldName];

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                      value != null ? value.toString() : '-',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

      ),
    );
  }
}
