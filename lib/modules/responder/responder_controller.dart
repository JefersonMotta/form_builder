import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';
import '../../models/form_model.dart';
import '../../services/submission_service.dart';
import '../home/home_view.dart';

class ResponderController extends GetxController {
  final FormModel form;

  // Respostas salvas por ID do campo
  final answers = <String, dynamic>{}.obs;

  // IDs dos campos com erro de validação
  final errors = <String>{}.obs;

  // Controlador da Assinatura
  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  ResponderController(this.form);

  void updateAnswer(String fieldId, dynamic value) {
    answers[fieldId] = value;
    // Remove o erro se o usuário começar a preencher
    if (errors.contains(fieldId)) {
      errors.remove(fieldId);
    }
  }

  void updateCheckbox(String fieldId, String option, bool isChecked) {
    List<String> current = List<String>.from(answers[fieldId] ?? []);
    if (isChecked) {
      current.add(option);
    } else {
      current.remove(option);
    }
    answers[fieldId] = current;
    
    if (current.isNotEmpty && errors.contains(fieldId)) {
      errors.remove(fieldId);
    }
  }

  void clearSignature() {
    signatureController.clear();
  }

  void addTableRow(String fieldId, List<String> columns) {
    List<Map<String, dynamic>> current = List<Map<String, dynamic>>.from(
      answers[fieldId] ?? [],
    );
    Map<String, dynamic> newRow = {};
    for (var col in columns) {
      newRow[col] = '';
    }
    current.add(newRow);
    answers[fieldId] = current;
    if (errors.contains(fieldId)) errors.remove(fieldId);
  }

  void updateTableCell(
    String fieldId,
    int rowIndex,
    String column,
    String value,
  ) {
    List<Map<String, dynamic>> current = List<Map<String, dynamic>>.from(
      answers[fieldId] ?? [],
    );
    current[rowIndex][column] = value;
    answers[fieldId] = current;
  }

  void removeTableRow(String fieldId, int rowIndex) {
    List<Map<String, dynamic>> current = List<Map<String, dynamic>>.from(
      answers[fieldId] ?? [],
    );
    current.removeAt(rowIndex);
    answers[fieldId] = current;
  }

  Future<void> submitForm() async {
    errors.clear();
    bool hasValidationError = false;

    // Validar campos obrigatórios
    for (var field in form.fields) {
      if (field.isRequired) {
        var ans = answers[field.id];
        bool isEmpty = false;
        
        if (ans == null) {
          isEmpty = true;
        } else if (ans is String && ans.trim().isEmpty) {
          isEmpty = true;
        } else if (ans is List && ans.isEmpty) {
          isEmpty = true;
        }

        if (isEmpty) {
          errors.add(field.id);
          hasValidationError = true;
        }
      }
    }

    if (hasValidationError) {
      Get.snackbar(
        'Campos Pendentes',
        'Por favor, preencha os campos destacados em vermelho.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Validar Assinatura
    String? signatureBase64;
    if (form.requireSignature) {
      if (signatureController.isEmpty) {
        Get.snackbar(
          'Assinatura Pendente',
          'A assinatura é obrigatória para este formulário.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
      final signatureBytes = await signatureController.toPngBytes();
      if (signatureBytes != null) {
        signatureBase64 = base64Encode(signatureBytes);
      }
    }

    // Converter para readable answers
    final Map<String, dynamic> readableAnswers = {};
    for (var field in form.fields) {
      if (answers.containsKey(field.id)) {
        readableAnswers[field.label] = answers[field.id];
      }
    }

    final submission = {
      'formId': form.id,
      'formTitle': form.title,
      'date': DateTime.now().toString(),
      'answers': readableAnswers,
      'signature': signatureBase64 != null ? 'Assinatura Coletada' : 'Não exigido',
      'signatureBase64': signatureBase64,
    };

    Get.find<SubmissionService>().addSubmission(submission);
    Get.offAll(() => const HomeView());
    
    Get.snackbar(
      'Sucesso!',
      'Inspeção concluída com sucesso!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
