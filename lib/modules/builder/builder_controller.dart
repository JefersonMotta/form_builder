import 'package:get/get.dart';
import '../../models/form_model.dart';
import '../../models/form_field_model.dart';

class BuilderController extends GetxController {
  var formModel = FormModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: 'Novo Formulário',
    description: '',
    fields: [],
  ).obs;

  void initEdit(FormModel? toEdit) {
    if (toEdit != null) {
      formModel.value = FormModel(
        id: toEdit.id,
        title: toEdit.title,
        description: toEdit.description,
        requireSignature: toEdit.requireSignature,
        fields: toEdit.fields.map((f) => FormFieldModel(
          id: f.id, 
          label: f.label, 
          type: f.type, 
          isRequired: f.isRequired, 
          options: f.options != null ? List.from(f.options!) : null
        )).toList(),
      );
    }
  }

  void updateTitle(String newTitle) {
    formModel.update((val) {
      val?.title = newTitle;
    });
  }

  void updateDescription(String newDesc) {
    formModel.update((val) {
      val?.description = newDesc;
    });
  }

  void addField(FieldType type, {String? presetLabel, List<String>? presetOptions}) {
    String defaultLabel = presetLabel ?? 'Nova Pergunta';
    List<String>? defaultOptions = presetOptions;

    if (presetLabel == null) {
      switch(type) {
        case FieldType.employeeSearch: defaultLabel = 'Colaborador Inspecionado'; break;
        case FieldType.departmentDropdown: defaultLabel = 'Selecione o Setor'; break;
        case FieldType.equipmentCheckboxList: defaultLabel = 'EPIs em Uso'; break;
        case FieldType.conditionRadioList: defaultLabel = 'Estado de Conservação'; break;
        case FieldType.dynamicTable: 
          defaultLabel = 'Tabela de Inspeção'; 
          defaultOptions = ['Item/Equipamento', 'Condição', 'Observação']; 
          break;
        case FieldType.multipleChoice:
        case FieldType.checkbox:
          defaultOptions = ['Opção 1'];
          break;
        default: break;
      }
    }

    formModel.update((val) {
      val?.fields.add(FormFieldModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: defaultLabel,
        type: type,
        options: defaultOptions,
      ));
    });
  }

  void removeField(String id) {
    formModel.update((val) {
      val?.fields.removeWhere((field) => field.id == id);
    });
  }

  void toggleRequireSignature(bool require) {
    formModel.update((val) {
      val?.requireSignature = require;
    });
  }

  void updateFieldLabel(String id, String newLabel) {
    formModel.update((val) {
      final field = val?.fields.firstWhere((f) => f.id == id);
      field?.label = newLabel;
    });
  }

  void updateFieldRequired(String id, bool required) {
    formModel.update((val) {
      final field = val?.fields.firstWhere((f) => f.id == id);
      field?.isRequired = required;
    });
  }

  void addFieldOption(String id) {
    formModel.update((val) {
      final field = val?.fields.firstWhere((f) => f.id == id);
      field?.options?.add('Nova Opção');
    });
  }

  void removeFieldOption(String id, int index) {
    formModel.update((val) {
      final field = val?.fields.firstWhere((f) => f.id == id);
      field?.options?.removeAt(index);
    });
  }

  void updateFieldOption(String id, int index, String newValue) {
    formModel.update((val) {
      final field = val?.fields.firstWhere((f) => f.id == id);
      field?.options?[index] = newValue;
    });
  }

  void reorderFields(int oldIndex, int newIndex) {
    formModel.update((val) {
      if (newIndex > oldIndex) newIndex -= 1;
      final field = val?.fields.removeAt(oldIndex);
      if (field != null) {
        val?.fields.insert(newIndex, field);
      }
    });
  }
}
