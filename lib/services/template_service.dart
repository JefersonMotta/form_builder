import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/form_model.dart';
import '../models/form_field_model.dart';
import 'package:flutter/material.dart';

class TemplateService extends GetxService {
  final _supabase = Supabase.instance.client;
  final templates = <FormModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTemplates();
  }

  Future<void> fetchTemplates() async {
    try {
      final response = await _supabase
          .from('form_templates')
          .select()
          .order('created_at', ascending: false);
      templates.value = response.map((row) {
        return FormModel(
          id: row['id'],
          title: row['title'],
          description: row['description'] ?? '',
          requireSignature: row['require_signature'] ?? true,
          fields: (row['fields'] as List)
              .map((f) => FormFieldModel.fromJson(f as Map<String, dynamic>))
              .toList(),
        );
      }).toList();
    } catch (e) {
      print('Erro ao carregar templates: $e');
    }
  }

  Future<bool> addTemplate(FormModel form) async {
    try {
      final response = await _supabase
          .from('form_templates')
          .insert({
            'title': form.title,
            'description': form.description,
            'require_signature': form.requireSignature,
            'fields': form.fields.map((f) => f.toJson()).toList(),
          })
          .select()
          .single();

      // Atualiza localmente e adiciona o ID real do banco
      form.id = response['id'];
      templates.insert(0, form);
      return true;
    } catch (e) {
      Get.snackbar(
        'Erro ao salvar',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<bool> updateTemplate(FormModel form) async {
    try {
      await _supabase
          .from('form_templates')
          .update({
            'title': form.title,
            'description': form.description,
            'require_signature': form.requireSignature,
            'fields': form.fields.map((f) => f.toJson()).toList(),
          })
          .eq('id', form.id);

      final index = templates.indexWhere((t) => t.id == form.id);
      if (index != -1) {
        templates[index] = form;
        templates.refresh();
      }
      return true;
    } catch (e) {
      Get.snackbar(
        'Erro ao atualizar',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _supabase.from('form_templates').delete().eq('id', id);
      templates.removeWhere((t) => t.id == id);
      Get.snackbar(
        'Apagado',
        'O formulário foi excluído.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro ao apagar',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
