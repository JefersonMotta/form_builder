import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Colaborador {
  String id;
  String cracha;
  String nome;

  Colaborador({required this.id, required this.cracha, required this.nome});
}

class EmployeeService extends GetxService {
  final _supabase = Supabase.instance.client;
  final colaboradores = <Colaborador>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      final response = await _supabase.from('employees').select().order('name');
      colaboradores.value = response.map((e) => Colaborador(
        id: e['id'],
        cracha: e['badge_number'],
        nome: e['name']
      )).toList();
    } catch (e) {
      print('Erro ao carregar colaboradores: $e');
    }
  }

  Future<bool> addEmployee(String cracha, String nome) async {
    try {
      final response = await _supabase.from('employees').insert({
        'badge_number': cracha,
        'name': nome,
      }).select().single();
      colaboradores.add(Colaborador(id: response['id'], cracha: response['badge_number'], nome: response['name']));
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível adicionar o colaborador: $e');
      return false;
    }
  }

  Future<bool> updateEmployee(String id, String cracha, String nome) async {
    try {
      await _supabase.from('employees').update({
        'badge_number': cracha,
        'name': nome,
      }).eq('id', id);
      
      final index = colaboradores.indexWhere((c) => c.id == id);
      if (index != -1) {
        colaboradores[index].cracha = cracha;
        colaboradores[index].nome = nome;
        colaboradores.refresh();
      }
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível atualizar o colaborador: $e');
      return false;
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      await _supabase.from('employees').delete().eq('id', id);
      colaboradores.removeWhere((c) => c.id == id);
      Get.snackbar('Sucesso', 'Colaborador removido.', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Erro', 'O colaborador pode ter relatórios vinculados a ele. $e');
    }
  }
}
