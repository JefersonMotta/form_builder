import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/employee_service.dart';
import '../../services/lookup_service.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestão de Listas Inteligentes'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.tealAccent,
            tabs: [
              Tab(icon: Icon(Icons.badge), text: 'Colaboradores'),
              Tab(icon: Icon(Icons.domain), text: 'Setores'),
              Tab(icon: Icon(Icons.construction), text: 'EPIs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EmployeesTab(),
            _DepartmentsTab(),
            _EquipmentsTab(),
          ],
        ),
      ),
    );
  }
}

// Empregados
class _EmployeesTab extends StatelessWidget {
  final EmployeeService svc = Get.find<EmployeeService>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showEmployeeForm(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Novo Colaborador'),
          ),
        ),
        Expanded(
          child: Obx(() => ListView.builder(
            itemCount: svc.colaboradores.length,
            itemBuilder: (context, index) {
              final c = svc.colaboradores[index];
              return ListTile(
                leading: CircleAvatar(child: Text(c.cracha.substring(0, c.cracha.length < 2 ? c.cracha.length : 2))),
                title: Text(c.nome),
                subtitle: Text('Crachá: ${c.cracha}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEmployeeForm(context, c)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, () => svc.deleteEmployee(c.id))),
                  ],
                ),
              );
            },
          )),
        ),
      ],
    );
  }

  void _showEmployeeForm(BuildContext context, Colaborador? c) {
    final crachaCtrl = TextEditingController(text: c?.cracha ?? '');
    final nomeCtrl = TextEditingController(text: c?.nome ?? '');
    Get.defaultDialog(
      title: c == null ? 'Novo Colaborador' : 'Editar Colaborador',
      content: Column(
        children: [
          TextField(controller: crachaCtrl, decoration: const InputDecoration(labelText: 'Nº Crachá')),
          TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
        ],
      ),
      textConfirm: 'Salvar',
      textCancel: 'Cancelar',
      onConfirm: () {
        if (crachaCtrl.text.isEmpty || nomeCtrl.text.isEmpty) return;
        if (c == null) {
          svc.addEmployee(crachaCtrl.text, nomeCtrl.text);
        } else {
          svc.updateEmployee(c.id, crachaCtrl.text, nomeCtrl.text);
        }
        Get.back();
      }
    );
  }
}

// Departamentos
class _DepartmentsTab extends StatelessWidget {
  final LookupService svc = Get.find<LookupService>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showDeptForm(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Novo Setor'),
          ),
        ),
        Expanded(
          child: Obx(() => ListView.builder(
            itemCount: svc.departments.length,
            itemBuilder: (context, index) {
              final d = svc.departments[index];
              return ListTile(
                leading: const Icon(Icons.domain),
                title: Text(d['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDeptForm(context, d)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, () => svc.deleteDepartment(d['id']))),
                  ],
                ),
              );
            },
          )),
        ),
      ],
    );
  }

  void _showDeptForm(BuildContext context, Map? d) {
    final nomeCtrl = TextEditingController(text: d?['name'] ?? '');
    Get.defaultDialog(
      title: d == null ? 'Novo Setor' : 'Editar Setor',
      content: TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do Setor')),
      textConfirm: 'Salvar',
      textCancel: 'Cancelar',
      onConfirm: () {
        if (nomeCtrl.text.isEmpty) return;
        if (d == null) {
          svc.addDepartment(nomeCtrl.text);
        } else {
          svc.updateDepartment(d['id'], nomeCtrl.text);
        }
        Get.back();
      }
    );
  }
}

// EPIs
class _EquipmentsTab extends StatelessWidget {
  final LookupService svc = Get.find<LookupService>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showEqForm(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Novo EPI'),
          ),
        ),
        Expanded(
          child: Obx(() => ListView.builder(
            itemCount: svc.equipments.length,
            itemBuilder: (context, index) {
              final e = svc.equipments[index];
              return ListTile(
                leading: const Icon(Icons.construction),
                title: Text(e['name']),
                subtitle: Text('Categoria: ${e['category'] ?? 'Geral'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEqForm(context, e)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, () => svc.deleteEquipment(e['id']))),
                  ],
                ),
              );
            },
          )),
        ),
      ],
    );
  }

  void _showEqForm(BuildContext context, Map? e) {
    final nomeCtrl = TextEditingController(text: e?['name'] ?? '');
    final catCtrl = TextEditingController(text: e?['category'] ?? '');
    Get.defaultDialog(
      title: e == null ? 'Novo EPI' : 'Editar EPI',
      content: Column(
        children: [
          TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do EPI')),
          TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Categoria (Ex: Cabeça, Olhos)')),
        ],
      ),
      textConfirm: 'Salvar',
      textCancel: 'Cancelar',
      onConfirm: () {
        if (nomeCtrl.text.isEmpty) return;
        if (e == null) {
          svc.addEquipment(nomeCtrl.text, catCtrl.text);
        } else {
          svc.updateEquipment(e['id'], nomeCtrl.text, catCtrl.text);
        }
        Get.back();
      }
    );
  }
}

void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
  Get.defaultDialog(
    title: 'Confirmar Exclusão',
    middleText: 'Tem certeza que deseja apagar este item?',
    textConfirm: 'Apagar',
    textCancel: 'Cancelar',
    confirmTextColor: Colors.white,
    buttonColor: Colors.red,
    onConfirm: () {
      Get.back();
      onConfirm();
    }
  );
}
