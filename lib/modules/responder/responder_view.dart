import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';
import '../../models/form_field_model.dart';
import '../../models/form_model.dart';
import '../../services/lookup_service.dart';
import '../../services/employee_service.dart';
import 'responder_controller.dart';

class ResponderView extends StatelessWidget {
  final FormModel form;
  final ResponderController controller;

  ResponderView({super.key, required this.form}) 
      : controller = Get.put(ResponderController(form), tag: form.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(form.title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (form.description.isNotEmpty) ...[
              Text(form.description, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
            ],
            ...form.fields.map((field) => _buildFieldWrapper(field)).toList(),
            const SizedBox(height: 24),
            if (form.requireSignature) ...[
              const Text('Assinatura Responsável:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Signature(
                      controller: controller.signatureController,
                      height: 200,
                      backgroundColor: Colors.white,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: controller.clearSignature,
                          icon: const Icon(Icons.clear, color: Colors.red),
                          label: const Text('Limpar', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: controller.submitForm,
                child: const Text('FINALIZAR E ENVIAR RELATÓRIO', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldWrapper(FormFieldModel field) {
    return Obx(() {
      final hasError = controller.errors.contains(field.id);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(hasError ? 12 : 0),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: hasError ? Colors.red.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: hasError ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    field.label, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: hasError ? Colors.red : Colors.black,
                    )
                  )
                ),
                if (field.isRequired) const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            if (hasError) ...[
              const SizedBox(height: 4),
              const Text('Este campo é obrigatório', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 12),
            _buildInput(field),
          ],
        ),
      );
    });
  }

  Widget _buildInput(FormFieldModel field) {
    switch (field.type) {
      case FieldType.text:
        return TextField(
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Sua resposta...'),
          onChanged: (val) => controller.updateAnswer(field.id, val),
        );
      case FieldType.longText:
        return TextField(
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Detalhes...'),
          onChanged: (val) => controller.updateAnswer(field.id, val),
        );
      case FieldType.date:
        return Obx(() {
          final ans = controller.answers[field.id];
          return ListTile(
            title: Text(ans ?? 'Toque para selecionar data'),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            onTap: () async {
              final date = await showDatePicker(
                context: Get.context!,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                controller.updateAnswer(field.id, "${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}");
              }
            },
          );
        });
      case FieldType.employeeSearch:
        return Autocomplete<String>(
          optionsBuilder: (textValue) {
            final employees = Get.find<EmployeeService>().colaboradores.map((e) => "${e.cracha} - ${e.nome}").toList();
            if (textValue.text.isEmpty) return const Iterable<String>.empty();
            return employees.where((e) => e.toLowerCase().contains(textValue.text.toLowerCase()));
          },
          onSelected: (val) => controller.updateAnswer(field.id, val),
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Nome ou Crachá...', prefixIcon: Icon(Icons.badge)),
              onChanged: (val) => controller.updateAnswer(field.id, val),
            );
          },
        );
      case FieldType.departmentDropdown:
        return Obx(() {
          final deps = Get.find<LookupService>().departments.map((d) => d['name'].toString()).toList();
          final ans = controller.answers[field.id];
          return DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Selecione...'),
            value: deps.contains(ans) ? ans : null,
            items: deps.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (val) => controller.updateAnswer(field.id, val),
          );
        });
      case FieldType.multipleChoice:
        return Obx(() {
          final ans = controller.answers[field.id];
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (field.options ?? []).map((opt) {
              final isSelected = ans == opt;
              return ChoiceChip(
                label: Text(opt),
                selected: isSelected,
                selectedColor: Colors.teal.shade100,
                onSelected: (selected) {
                  controller.updateAnswer(field.id, selected ? opt : null);
                },
              );
            }).toList(),
          );
        });
      case FieldType.checkbox:
        return Obx(() {
          final List<String> currentAns = List<String>.from(controller.answers[field.id] ?? []);
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (field.options ?? []).map((opt) {
              final isSelected = currentAns.contains(opt);
              return FilterChip(
                label: Text(opt),
                selected: isSelected,
                selectedColor: Colors.teal.shade100,
                onSelected: (selected) => controller.updateCheckbox(field.id, opt, selected),
              );
            }).toList(),
          );
        });
      case FieldType.equipmentCheckboxList:
        return Obx(() {
          final eqs = Get.find<LookupService>().equipments;
          final List<String> currentAns = List<String>.from(controller.answers[field.id] ?? []);
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: eqs.map((eq) {
              final name = eq['name'].toString();
              final isSelected = currentAns.contains(name);
              return FilterChip(
                label: Text(name),
                selected: isSelected,
                selectedColor: Colors.teal.shade100,
                onSelected: (selected) => controller.updateCheckbox(field.id, name, selected),
              );
            }).toList(),
          );
        });
      case FieldType.conditionRadioList:
        return Obx(() {
          final conditions = Get.find<LookupService>().conditions.map((c) => c['name'].toString()).toList();
          final ans = controller.answers[field.id];
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: conditions.map((c) {
              final isSelected = ans == c;
              return ChoiceChip(
                label: Text(c),
                selected: isSelected,
                selectedColor: isSelected 
                  ? (c.toLowerCase().contains('certo') ? Colors.green.shade100 : 
                     c.toLowerCase().contains('errado') ? Colors.red.shade100 : Colors.blue.shade100)
                  : null,
                onSelected: (selected) {
                  controller.updateAnswer(field.id, selected ? c : null);
                },
              );
            }).toList(),
          );
        });
      case FieldType.dynamicTable:
        return Obx(() {
          final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(controller.answers[field.id] ?? []);
          final columns = field.options ?? ['Item'];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
                  columns: [
                    ...columns.map((c) => DataColumn(label: Text(c))),
                    const DataColumn(label: Text('')),
                  ],
                  rows: rows.asMap().entries.map((entry) {
                    final rowIndex = entry.key;
                    final rowData = entry.value;
                    return DataRow(
                      cells: [
                        ...columns.map((col) => DataCell(
                          TextField(
                            decoration: const InputDecoration(border: InputBorder.none),
                            onChanged: (val) => controller.updateTableCell(field.id, rowIndex, col, val),
                            controller: TextEditingController(text: (rowData[col] ?? '').toString())
                              ..selection = TextSelection.fromPosition(TextPosition(offset: (rowData[col] ?? '').toString().length)),
                          ),
                        )),
                        DataCell(IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => controller.removeTableRow(field.id, rowIndex))),
                      ],
                    );
                  }).toList(),
                ),
              ),
              TextButton.icon(onPressed: () => controller.addTableRow(field.id, columns), icon: const Icon(Icons.add_circle), label: const Text('Adicionar Linha')),
            ],
          );
        });
      default:
        return const SizedBox();
    }
  }
}
