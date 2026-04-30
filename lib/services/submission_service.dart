import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionService extends GetxService {
  final _supabase = Supabase.instance.client;
  final submissions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    try {
      final response = await _supabase.from('submissions').select().order('created_at', ascending: false);
      final List<Map<String, dynamic>> loaded = [];
      for (var row in response) {
        loaded.add({
          'formId': row['form_id'],
          'formTitle': row['form_title'],
          'date': row['created_at'],
          'answers': row['answers'],
          'signature': row['signature_base64'] != null ? 'Assinatura Salva' : 'Sem Assinatura',
          'signatureBase64': row['signature_base64'],
        });
      }
      submissions.value = loaded;
    } catch (e) {
      print('Erro ao carregar do Supabase: $e');
    }
  }

  Future<void> addSubmission(Map<String, dynamic> sub) async {
    submissions.insert(0, sub); // Atualiza UI imediatamente

    try {
      await _supabase.from('submissions').insert({
        'form_id': sub['formId'],
        'form_title': sub['formTitle'],
        'answers': sub['answers'],
        'signature_base64': sub['signatureBase64'],
      });
    } catch (e) {
      Get.snackbar('Erro no Supabase', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
