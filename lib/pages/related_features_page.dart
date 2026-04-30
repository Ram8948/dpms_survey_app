import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widget/custom_floating_appbar.dart';
import 'add_related_feature_page_new.dart';
import 'details_page.dart';

class RelatedFeaturesPage extends StatefulWidget {
  final ArcGISFeature feature;
  final ArcGISFeatureTable relatedFeatureTable;
  final ArcGISFeatureTable mainFeatureTable;

  const RelatedFeaturesPage({
    required this.feature,
    required this.relatedFeatureTable,
    required this.mainFeatureTable,
    super.key,
  });

  @override
  _RelatedFeaturesPageState createState() => _RelatedFeaturesPageState();
}

class _RelatedFeaturesPageState extends State<RelatedFeaturesPage> {
  late List<Feature> _relatedFeatures;
  bool _relatedFeaturesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRelatedFeatures();
  }

  Future<void> _loadRelatedFeatures() async {
    setState(() => _relatedFeaturesLoading = true);
    final freshRelated = await _queryRelatedFeatures(widget.feature,widget.mainFeatureTable);
    setState(() {
      _relatedFeatures = freshRelated;
      _relatedFeaturesLoading = false;
    });
  }

  Future<List<ArcGISFeature>> _queryRelatedFeatures(ArcGISFeature feature, ArcGISFeatureTable mainFeatureTable) async {
    List<ArcGISFeature> allRelatedFeatures = [];
    try {
      final relationshipInfoList = (mainFeatureTable is GeodatabaseFeatureTable)
          ? mainFeatureTable.layerInfo?.relationshipInfos
          : (mainFeatureTable is ServiceFeatureTable)
              ? mainFeatureTable.layerInfo?.relationshipInfos
              : null;

      if (relationshipInfoList == null || relationshipInfoList.isEmpty) {
        debugPrint("No relationship infos found.");
        return [];
      }

      final relationshipInfo = relationshipInfoList.firstWhere(
        (info) => info.keyField.toLowerCase() == "globalid",
        orElse: () => relationshipInfoList.first,
      );

      final relatedResults;
      if (mainFeatureTable is GeodatabaseFeatureTable) {
        relatedResults = await mainFeatureTable.queryRelatedFeatures(
          feature: feature,
          parameters: RelatedQueryParameters.withRelationshipInfo(relationshipInfo),
        );
      } else if (mainFeatureTable is ServiceFeatureTable) {
        relatedResults = await mainFeatureTable.queryRelatedFeaturesWithFieldOptions(
          feature: feature,
          queryFeatureFields: QueryFeatureFields.loadAll,
          parameters: RelatedQueryParameters.withRelationshipInfo(relationshipInfo),
        );
      } else {
        return [];
      }

      // // 3. Process the results
      // int totalRelatedFeatures = 0;
      // final resultMessages = <String>[];

      // for (final result in relatedResults) {
      //   final relatedFeatureTable = result.relatedFeatureTable;
      //   final relatedFeatures = await result.features().toList();
      //   final count = relatedFeatures.length;
      //   totalRelatedFeatures += count;
      //
      //   resultMessages.add(
      //       'Table "${relatedFeatureTable.tableName}": $count related features found.'
      //   );
      //
      //   // Example of accessing the first related feature's attributes
      //   if (count > 0) {
      //     final firstFeature = relatedFeatures.first;
      //     final attributeKey = firstFeature.attributes.keys.firstWhere((k) => k.toLowerCase() != 'objectid', orElse: () => 'OBJECTID');
      //     resultMessages.add('   - First related feature attribute ($attributeKey): ${firstFeature.attributes[attributeKey]}');
      //   }
      // }

      for (final result in relatedResults) {
        for (final feature in result.features()) {
          final relatedFeature = feature as ArcGISFeature;
          debugPrint("relatedFeature; $relatedFeature");
          allRelatedFeatures.add(relatedFeature);
        }
      }
      debugPrint("allRelatedFeatures; ${allRelatedFeatures.length}");
      return allRelatedFeatures;

      // setState(() {
      //   _relatedFeaturesStatus =
      //   'Query complete. Found $totalRelatedFeatures related feature(s):\n${resultMessages.join('\n')}';
      // });
    } catch (e) {
      debugPrint("allRelatedFeatures; ${e.toString()}");
      return allRelatedFeatures;
      // setState(() {
      //   _relatedFeaturesStatus = 'Error querying related features: $e';
      // });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Related Features'),
      //   leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      // ),
      appBar: CustomFloatingAppBar(
        title: 'Related Features',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: _relatedFeaturesLoading
          ? const Center(child: CircularProgressIndicator())
          : RelatedFeaturesTable(
        relatedFeatures: _relatedFeatures,
        relatedFeatureTable: widget.relatedFeatureTable,
        refreshParent: _loadRelatedFeatures,
        feature: widget.feature,
        onAddFeaturePressed: () async {
          // Calculate maxPrevProgress:
          final maxPrevProgress = _relatedFeatures.isNotEmpty
              ? _relatedFeatures
              .map((f) => f.attributes['intpprogress'] as int? ?? 0)
              .reduce((a, b) => a > b ? a : b)
              : 0;

          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => AddRelatedFeaturePage(
                relatedFeatureTable: widget.relatedFeatureTable,
                parentFeature: widget.feature,
                maxPrevProgress: maxPrevProgress,
              ),
            ),
          );
          if (added == true) {
            await _loadRelatedFeatures();
          }
        },
      ),
    );
  }
}

class RelatedFeaturesTable extends StatefulWidget {
  final List<Feature> relatedFeatures;
  final ArcGISFeatureTable relatedFeatureTable;
  final VoidCallback refreshParent;
  final ArcGISFeature feature;
  final VoidCallback onAddFeaturePressed;

  const RelatedFeaturesTable({
    required this.relatedFeatures,
    required this.relatedFeatureTable,
    required this.refreshParent,
    required this.feature,
    required this.onAddFeaturePressed,
    super.key,
  });

  @override
  State<RelatedFeaturesTable> createState() => _RelatedFeaturesTableState();
}

class _RelatedFeaturesTableState extends State<RelatedFeaturesTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.relatedFeatures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('No related features found.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onAddFeaturePressed,
              child: const Text('Add Related Feature'),
            ),
          ],
        ),
      );
    }

    final fields = widget.relatedFeatureTable.fields;

    // Names as they come in attributes / field.name
    const visibleFieldNames = [
      'surveyordate',
      'intpprogress',
      'intfprogress',
      'schemename',
      'schemeid',
      'intpprogressc',
      'intfprogressc',
      'intpprogresscconv',
      'intpprogressmconv',
      'intpprogresscunconv',
      'intpprogressmunconv',
      'intfprogressccon',
      'intfprogressmcon',
      'intpprogressccon',
      'intpprogressmcon',
      'intfprogresscunc',
      'intfprogressmunc',
    ];

    final visibleFields = fields
        .where((f) => visibleFieldNames.contains(f.name.toLowerCase()))
        .toList();
    // Sort visibleFields based on the order of names in visibleFieldNames
    visibleFields.sort((a, b) => visibleFieldNames.indexOf(a.name.toLowerCase()).compareTo(visibleFieldNames.indexOf(b.name.toLowerCase())));

    return Column(
      children: [
        Expanded(
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: MaterialStateProperty.all(Colors.lightBlue),
              thickness: MaterialStateProperty.all(4),
              radius: const Radius.circular(8),
            ),
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: visibleFields.map(
                    (field) => DataColumn(
                      label: Text(field.alias.isNotEmpty ? field.alias : field.name),
                    ),
                  ).toList(),
                  rows: widget.relatedFeatures.map((feature) {
                    return DataRow(
                      cells: visibleFields.map((field) {
                        final rawValue = feature.attributes[field.name];
                        String displayValue = rawValue?.toString() ?? '-';

                        if (field.domain is CodedValueDomain) {
                          final domain = field.domain as CodedValueDomain;
                          for (final cv in domain.codedValues) {
                            if (cv.code == rawValue) {
                              displayValue = cv.name;
                              break;
                            }
                          }
                        } else if (field.type == FieldType.date && rawValue is DateTime) {
                          displayValue = DateFormat('yyyy-MM-dd').format(rawValue);
                        }

                        return DataCell(
                          Text(displayValue),
                        );
                      }).toList(),
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsPage(
                                fields: fields,
                                feature: feature as ArcGISFeature,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: widget.onAddFeaturePressed,
          child: const Text('Add Related Feature'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
