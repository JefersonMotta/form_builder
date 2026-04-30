import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'builder_controller.dart';
import '../../models/form_field_model.dart';
import '../../models/form_model.dart';
import '../../services/template_service.dart';
import '../home/home_view.dart';

class BuilderView extends StatelessWidget {
  final BuilderController controller;

  BuilderView({super.key, FormModel? formToEdit}) 
    : controller = Get.put(BuilderController()..initEdit(formToEdit));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Construtor de Formulário'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final form = controller.formModel.value;
              if (form.title.trim().isEmpty) {
                 Get.snackbar('Aviso', 'O formulário precisa de um título.');
                 return;
              }
              
              // Mostra carregamento
              Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
              
              final isUpdate = Get.find<TemplateService>().templates.any((t) => t.id == form.id);
              bool success;
              if (isUpdate) {
                success = await Get.find<TemplateService>().updateTemplate(form);
              } else {
                success = await Get.find<TemplateService>().addTemplate(form);
              }
              
              if (success) {
                Get.offAll(() => const HomeView());
                Get.snackbar('Sucesso', 'Formulário salvo!', backgroundColor: Colors.green, colorText: Colors.white);
              } else {
                Get.back(); // fecha o loading
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        final form = controller.formModel.value;
        return ReorderableListView(
          padding: const EdgeInsets.all(16),
          onReorder: controller.reorderFields,
          header: Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 24),
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('CONFIGURAÇÕES DO MODELO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: form.title,
                    decoration: const InputDecoration(labelText: 'Título do Formulário', border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                    onChanged: controller.updateTitle,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: form.description,
                    decoration: const InputDecoration(labelText: 'Descrição / Finalidade', border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                    onChanged: controller.updateDescription,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          footer: Column(
            children: [
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: SwitchListTile(
                  title: const Text('Exigir Assinatura no Final?', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: form.requireSignature,
                  onChanged: controller.toggleRequireSignature,
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
          children: form.fields.map((field) => _buildFieldCard(field)).toList(),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFieldModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Campo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFieldCard(FormFieldModel field) {
    return Card(
      key: ValueKey(field.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: const Icon(Icons.drag_handle, color: Colors.grey),
        title: Text(field.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(field.type.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.teal)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => controller.removeField(field.id),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  initialValue: field.label,
                  decoration: const InputDecoration(labelText: 'Pergunta / Título do Campo', border: OutlineInputBorder()),
                  onChanged: (val) => controller.updateFieldLabel(field.id, val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Obrigatório'),
                    Switch(
                      value: field.isRequired,
                      onChanged: (val) => controller.updateFieldRequired(field.id, val),
                    ),
                  ],
                ),
                if (field.type == FieldType.multipleChoice || field.type == FieldType.checkbox || field.type == FieldType.dynamicTable) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(field.type == FieldType.dynamicTable ? 'Colunas da Tabela:' : 'Opções:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () => controller.addFieldOption(field.id),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar'),
                      ),
                    ],
                  ),
                  ...(field.options ?? []).asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: entry.value,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                            onChanged: (val) => controller.updateFieldOption(field.id, entry.key, val),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => controller.removeFieldOption(field.id, entry.key),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
                const SizedBox(height: 8),
                _buildMockInput(field),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockInput(FormFieldModel field) {
    switch (field.type) {
      case FieldType.text:
        return const TextField(decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Ex: Resposta curta...'));
      case FieldType.longText:
        return const TextField(maxLines: 2, decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Ex: Resposta detalhada...'));
      case FieldType.date:
        return const ListTile(leading: Icon(Icons.calendar_today), title: Text('DD/MM/AAAA'), dense: true);
      case FieldType.employeeSearch:
        return const TextField(decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Buscar colaborador...', prefixIcon: Icon(Icons.badge)));
      case FieldType.departmentDropdown:
        return const ListTile(leading: Icon(Icons.domain), title: Text('Lista de Setores...'), dense: true);
      case FieldType.dynamicTable:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
          child: Column(
            children: [
              Row(
                children: (field.options ?? []).map((o) => Expanded(child: Text(o, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))).toList(),
              ),
              const Divider(),
              const Center(child: Text('Mock da Tabela', style: TextStyle(fontSize: 10, color: Colors.grey))),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  void _showAddFieldModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(title: Text('Modelos Prontos (Presets)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                ListTile(
                  leading: const Icon(Icons.business, color: Colors.blue), 
                  title: const Text('Campo: Empresa'), 
                  onTap: () { controller.addField(FieldType.multipleChoice, presetLabel: 'Empresa', presetOptions: ['Empresa 01', 'Empresa 02']); Get.back(); }
                ),
                ListTile(
                  leading: const Icon(Icons.factory, color: Colors.blue), 
                  title: const Text('Campo: Fábrica'), 
                  onTap: () { controller.addField(FieldType.multipleChoice, presetLabel: 'Fábrica', presetOptions: ['01', '02', '03', '04', '05', 'K1 Colchões', 'K1 BP', 'K1 ND']); Get.back(); }
                ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.blue), 
                  title: const Text('Campo: Turno'), 
                  onTap: () { controller.addField(FieldType.multipleChoice, presetLabel: 'Turno', presetOptions: ['1º Turno', '2º Turno', '3º Turno']); Get.back(); }
                ),
                const Divider(),
                const ListTile(title: Text('Tipo de Campo Personalizado', style: TextStyle(fontWeight: FontWeight.bold))),
                ListTile(leading: const Icon(Icons.short_text), title: const Text('Texto Curto'), onTap: () { controller.addField(FieldType.text); Get.back(); }),
                ListTile(leading: const Icon(Icons.wrap_text), title: const Text('Texto Longo'), onTap: () { controller.addField(FieldType.longText); Get.back(); }),
                ListTile(leading: const Icon(Icons.calendar_today), title: const Text('Data'), onTap: () { controller.addField(FieldType.date); Get.back(); }),
                ListTile(leading: const Icon(Icons.radio_button_checked), title: const Text('Múltipla Escolha'), onTap: () { controller.addField(FieldType.multipleChoice); Get.back(); }),
                ListTile(leading: const Icon(Icons.check_box), title: const Text('Checklist (Manual)'), onTap: () { controller.addField(FieldType.checkbox); Get.back(); }),
                const Divider(),
                const ListTile(title: Text('Listas Inteligentes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                ListTile(leading: const Icon(Icons.badge, color: Colors.teal), title: const Text('Pesquisa de Colaborador'), onTap: () { controller.addField(FieldType.employeeSearch); Get.back(); }),
                ListTile(leading: const Icon(Icons.domain, color: Colors.teal), title: const Text('Lista de Setores'), onTap: () { controller.addField(FieldType.departmentDropdown); Get.back(); }),
                ListTile(leading: const Icon(Icons.table_chart, color: Colors.indigo), title: const Text('Tabela de Itens (Grade)'), onTap: () { controller.addField(FieldType.dynamicTable); Get.back(); }),
              ],
            ),
          ),
        );
      },
    );
  }
}
