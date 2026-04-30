import 'form_field_model.dart';

class FormModel {
  String id;
  String title;
  String description;
  List<FormFieldModel> fields;
  bool requireSignature;

  FormModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.fields,
    this.requireSignature = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fields': fields.map((f) => f.toJson()).toList(),
      'requireSignature': requireSignature,
    };
  }

  factory FormModel.fromJson(Map<String, dynamic> json) {
    return FormModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fields: json['fields'] != null
          ? (json['fields'] as List).map((f) => FormFieldModel.fromJson(f)).toList()
          : [],
      requireSignature: json['requireSignature'] ?? true,
    );
  }
}
