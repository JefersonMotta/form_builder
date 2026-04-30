import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  
  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Relatórios'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Exportar PDF da Página Atual',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          _buildSummaryBar(),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final allFiltered = _getFilteredSubmissions();
              final totalCount = allFiltered.length;
              
              if (allFiltered.isEmpty) {
                return const Center(
                  child: Text('Nenhum relatório encontrado.', style: TextStyle(color: Colors.grey)),
                );
              }

              // Apply pagination
              final startIndex = (currentPage - 1) * itemsPerPage;
              final endIndex = startIndex + itemsPerPage;
              final paginatedList = allFiltered.sublist(
                startIndex, 
                endIndex > totalCount ? totalCount : endIndex
              );

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: paginatedList.length,
                      itemBuilder: (context, index) {
                        final sub = paginatedList[index];
                        return _buildSubmissionCard(sub);
                      },
                    ),
                  ),
                  _buildPaginationControls(totalCount),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Obx(() {
      final count = _getFilteredSubmissions().length;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.teal.shade100.withOpacity(0.3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Encontrado: $count',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            if (count > itemsPerPage)
              Text(
                'Página $currentPage de ${(count / itemsPerPage).ceil()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildPaginationControls(int totalCount) {
    final totalPages = (totalCount / itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
          ),
          Text('Página $currentPage de $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
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
                  onChanged: (val) {
                    setState(() {
                      selectedTemplateId = val;
                      currentPage = 1;
                    });
                  },
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
            onChanged: (val) {
              setState(() {
                searchQuery = val.toLowerCase();
                currentPage = 1;
              });
            },
          ),
          if (selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Chip(
                label: Text('Período: ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}'),
                onDeleted: () {
                  setState(() {
                    selectedDateRange = null;
                    currentPage = 1;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredSubmissions() {
    return submissionService.submissions.where((sub) {
      if (selectedTemplateId != null && sub['formId'] != selectedTemplateId) return false;

      if (selectedDateRange != null) {
        final subDate = DateTime.parse(sub['date']);
        if (subDate.isBefore(selectedDateRange!.start) || subDate.isAfter(selectedDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      if (searchQuery.isNotEmpty) {
        final answersStr = sub['answers'].toString().toLowerCase();
        final titleMatch = sub['formTitle'].toString().toLowerCase().contains(searchQuery);
        if (!titleMatch && !answersStr.contains(searchQuery)) return false;
      }

      return true;
    }).toList();
  }

  String _findValueByKeywords(Map<String, dynamic> answers, List<String> keywords) {
    for (var keyword in keywords) {
      // Busca exata primeiro
      if (answers.containsKey(keyword)) return answers[keyword].toString();
      
      // Busca parcial (case insensitive)
      for (var key in answers.keys) {
        if (key.toLowerCase().contains(keyword.toLowerCase())) {
          return answers[key].toString();
        }
      }
    }
    return 'N/A';
  }

  Widget _buildSubmissionCard(Map<String, dynamic> sub) {
    final answers = sub['answers'] as Map<String, dynamic>? ?? {};
    
    // Tenta encontrar campos chave para o título de forma mais robusta
    final colaborador = _findValueByKeywords(answers, ['Colaborador', 'Nome', 'Inspetor', 'Funcionário']);
    final setor = _findValueByKeywords(answers, ['Setor', 'Fábrica', 'Departamento', 'Área']);
    final empresa = _findValueByKeywords(answers, ['Empresa', 'Unidade', 'Filial']);
    if (empresa == 'N/A') empresa.replaceAll('N/A', 'K1-ERP'); // Default se não achar

    final rawDate = DateTime.parse(sub['date']);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(rawDate);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        leading: const Icon(Icons.person, color: Colors.teal),
        title: Text(
          '$colaborador - $setor',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Empresa: ${empresa == 'N/A' ? 'K1-ERP' : empresa} | Data: $formattedDate',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Relatório Original: ${sub['formTitle']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(),
                const Text('Respostas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 8),
                ...answers.entries.map((e) {
                  final key = e.key;
                  final value = e.value;
                  
                  if (value is List && value.isNotEmpty && value.first is Map) {
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
                              columns: columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
                              rows: rows.map((r) => DataRow(
                                cells: columns.map((c) => DataCell(Text(r[c]?.toString() ?? '', style: const TextStyle(fontSize: 11)))).toList(),
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
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                        children: [
                          TextSpan(text: '$key: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '$value'),
                        ],
                      ),
                    ),
                  );
                }),
                if (sub['signatureBase64'] != null) ...[
                  const Divider(),
                  const Text('Assinatura:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.white),
                    child: Image.memory(base64Decode(sub['signatureBase64']), height: 100, fit: BoxFit.contain),
                  ),
                ],
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
      setState(() {
        selectedDateRange = range;
        currentPage = 1;
      });
    }
  }

  Future<void> _exportToPDF() async {
    final filtered = _getFilteredSubmissions();
    final totalCount = filtered.length;
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    final dataForPdf = filtered.sublist(
      startIndex, 
      endIndex > totalCount ? totalCount : endIndex
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Relatório de Inspeções', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Total de registros nesta filtragem: $totalCount', style: pw.TextStyle(color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              data: <List<String>>[
                <String>['Colaborador', 'Setor', 'Empresa', 'Data'],
                ...dataForPdf.map((sub) {
                  final ans = sub['answers'] as Map<String, dynamic>? ?? {};
                  return [
                    _findValueByKeywords(ans, ['Colaborador', 'Nome', 'Inspetor', 'Funcionário']),
                    _findValueByKeywords(ans, ['Setor', 'Fábrica', 'Departamento', 'Área']),
                    _findValueByKeywords(ans, ['Empresa', 'Unidade', 'Filial']),
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(sub['date'])),
                  ];
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'relatorio_inspecoes_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}


