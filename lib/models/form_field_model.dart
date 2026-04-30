enum FieldType { 
  text, 
  longText, 
  multipleChoice, 
  checkbox, 
  date, 
  employeeSearch, 
  departmentDropdown, 
  equipmentCheckboxList, 
  conditionRadioList,
  dynamicTable
}

class FormFieldModel {
  String id;
  String label;
  FieldType type;
  bool isRequired;
  List<String>? options;

  FormFieldModel({
    required this.id,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'isRequired': isRequired,
      'options': options,
    };
  }

  factory FormFieldModel.fromJson(Map<String, dynamic> json) {
    return FormFieldModel(
      id: json['id'],
      label: json['label'],
      type: FieldType.values.firstWhere((e) => e.name == json['type'], orElse: () => FieldType.text),
      isRequired: json['isRequired'] ?? false,
      options: json['options'] != null ? List<String>.from(json['options']) : null,
    );
  }
}
