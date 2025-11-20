import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

import '../widget/custom_floating_appbar.dart';

class DetailsPage extends StatelessWidget {
  final List<Field> fields;
  final Map<String, dynamic> data;

  DetailsPage({required this.fields, required this.data, super.key});

  @override
  Widget build(BuildContext context) {
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
          children: fields.map((field) {
            final fieldName = field.name;
            final fieldAlias = field.alias ?? field.name;
            final value = data[fieldName];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: '$fieldAlias: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: value != null ? value.toString() : '',
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
