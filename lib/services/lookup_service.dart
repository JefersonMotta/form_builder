import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LookupService extends GetxService {
  final _supabase = Supabase.instance.client;
  
  final departments = <Map<String, dynamic>>[].obs;
  final equipments = <Map<String, dynamic>>[].obs;
  final conditions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    try {
      final deps = await _supabase.from('departments').select().order('name');
      departments.value = deps;

      final eqs = await _supabase.from('equipments').select().order('name');
      equipments.value = eqs;

      final conds = await _supabase.from('condition_status').select();
      conditions.value = conds;
    } catch (e) {
      print('Erro ao carregar lookups: $e');
    }
  }

  // --- Departments CRUD ---
  Future<bool> addDepartment(String name) async {
    try {
      final res = await _supabase.from('departments').insert({'name': name, 'is_active': true}).select().single();
      departments.add(res);
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível adicionar o setor: $e');
      return false;
    }
  }

  Future<bool> updateDepartment(String id, String name) async {
    try {
      await _supabase.from('departments').update({'name': name}).eq('id', id);
      final index = departments.indexWhere((d) => d['id'] == id);
      if (index != -1) {
        departments[index]['name'] = name;
        departments.refresh();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteDepartment(String id) async {
    try {
      await _supabase.from('departments').delete().eq('id', id);
      departments.removeWhere((d) => d['id'] == id);
      Get.snackbar('Sucesso', 'Setor removido.', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Erro', 'O setor pode estar em uso em relatórios antigos. $e');
    }
  }

  // --- Equipments CRUD ---
  Future<bool> addEquipment(String name, String category) async {
    try {
      final res = await _supabase.from('equipments').insert({'name': name, 'category': category, 'is_active': true}).select().single();
      equipments.add(res);
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível adicionar o EPI: $e');
      return false;
    }
  }

  Future<bool> updateEquipment(String id, String name, String category) async {
    try {
      await _supabase.from('equipments').update({'name': name, 'category': category}).eq('id', id);
      final index = equipments.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        equipments[index]['name'] = name;
        equipments[index]['category'] = category;
        equipments.refresh();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteEquipment(String id) async {
    try {
      await _supabase.from('equipments').delete().eq('id', id);
      equipments.removeWhere((e) => e['id'] == id);
      Get.snackbar('Sucesso', 'EPI removido.', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Erro', 'O EPI pode estar em uso. $e');
    }
  }
}
