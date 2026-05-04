import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../builder/builder_view.dart';
import '../responder/responder_view.dart';
import '../../services/template_service.dart';
import '../admin/admin_view.dart';
import '../reports/report_dashboard_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final templateService = Get.find<TemplateService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Inspeções'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Painel Administrativo Superior
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_task),
                  label: const Text('Novo Modelo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Get.to(() => BuilderView()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Listas Inteligentes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Get.to(() => const AdminView()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.table_chart),
              label: const Text('Central de Relatórios Avançados'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Get.to(() => const ReportDashboardView()),
            ),
          ),

          const SizedBox(height: 32),
          const Text(
            'Formulários Prontos para Preencher',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 12),

          Obx(() {
            if (templateService.templates.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Nenhum formulário cadastrado ainda.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return Column(
              children: templateService.templates
                  .map(
                    (form) => Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.assignment, color: Colors.white),
                        ),
                        title: Text(
                          form.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          form.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueGrey,
                              ),
                              tooltip: 'Editar Estrutura',
                              onPressed: () =>
                                  Get.to(() => BuilderView(formToEdit: form)),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Excluir Modelo',
                              onPressed: () {
                                Get.defaultDialog(
                                  title: 'Excluir Modelo',
                                  middleText:
                                      'Deseja apagar o modelo "${form.title}"?',
                                  textConfirm: 'Sim, Apagar',
                                  textCancel: 'Cancelar',
                                  confirmTextColor: Colors.white,
                                  buttonColor: Colors.redAccent,
                                  onConfirm: () {
                                    Get.back();
                                    templateService.deleteTemplate(form.id);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Get.to(() => ResponderView(form: form));
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}
