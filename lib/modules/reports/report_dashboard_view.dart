import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/submission_service.dart';
import '../../services/template_service.dart';

class ReportDashboardView extends StatefulWidget {
  const ReportDashboardView({super.key});

  @override
  State<ReportDashboardView> createState() => _ReportDashboardViewState();
}

class _ReportDashboardViewState extends State<ReportDashboardView> {
  final templateService = Get.find<TemplateService>();
  final submissionService = Get.find<SubmissionService>();

  String? selectedTemplateId;
  DateTimeRange? selectedDateRange;
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Relatórios'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final filtered = _getFilteredSubmissions();
              
              if (filtered.isEmpty) {
                return const Center(
                  child: Text('Nenhum relatório encontrado para estes filtros.', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final sub = filtered[index];
                  return _buildSubmissionCard(sub);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedTemplateId,
                  decoration: const InputDecoration(
                    labelText: 'Selecione o Modelo',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos os Modelos')),
                    ...templateService.templates.map((t) => DropdownMenuItem(
                      value: t.id, 
                      child: Text(t.title, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (val) => setState(() => selectedTemplateId = val),
                )),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.date_range, color: Colors.teal),
                onPressed: _pickDateRange,
                tooltip: 'Filtrar por Data',
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por colaborador, setor ou resposta...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
          ),
          if (selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Chip(
                label: Text('Período: ${selectedDateRange!.start.toString().substring(0,10)} - ${selectedDateRange!.end.toString().substring(0,10)}'),
                onDeleted: () => setState(() => selectedDateRange = null),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredSubmissions() {
    return submissionService.submissions.where((sub) {
      // Filtro por Modelo
      if (selectedTemplateId != null && sub['formId'] != selectedTemplateId) {
        return false;
      }

      // Filtro por Data
      if (selectedDateRange != null) {
        final subDate = DateTime.parse(sub['date']);
        if (subDate.isBefore(selectedDateRange!.start) || subDate.isAfter(selectedDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Filtro por Texto (Search)
      if (searchQuery.isNotEmpty) {
        final titleMatch = sub['formTitle'].toString().toLowerCase().contains(searchQuery);
        final answersMatch = sub['answers'].toString().toLowerCase().contains(searchQuery);
        if (!titleMatch && !answersMatch) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildSubmissionCard(Map<String, dynamic> sub) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        leading: const Icon(Icons.description, color: Colors.teal),
        title: Text(sub['formTitle'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Data: ${sub['date'].toString().substring(0, 16)}'),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Respostas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 8),
                ...((sub['answers'] ?? {}) as Map).entries.map((e) {
                  final key = e.key.toString();
                  final value = e.value;
                  
                  if (value is List && value.isNotEmpty && value.first is Map) {
                    // Renderizar Tabela Dinâmica
                    final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(value);
                    final columns = rows.first.keys.toList();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 30,
                              dataRowMinHeight: 30,
                              columns: columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                              rows: rows.map((r) => DataRow(
                                cells: columns.map((c) => DataCell(Text(r[c]?.toString() ?? '', style: const TextStyle(fontSize: 12)))).toList(),
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(text: '$key: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '$value'),
                        ],
                      ),
                    ),
                  );
                }),
                const Divider(),
                if (sub['signatureBase64'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assinatura:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.white),
                        child: Image.memory(base64Decode(sub['signatureBase64']), height: 100, fit: BoxFit.contain),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: Colors.teal.shade800),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() => selectedDateRange = range);
    }
  }
}
