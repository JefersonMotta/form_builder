import '../models/form_model.dart';
import '../models/form_field_model.dart';

class MockForms {
  static List<FormModel> getForms() {
    return [
      FormModel(
        id: '1',
        title: 'Inspeção de EPIs Diária',
        description: 'Verificação diária do uso e estado dos Equipamentos de Proteção Individual na fábrica.',
        requireSignature: true,
        fields: [
          FormFieldModel(id: 'f1', label: 'Nome ou Crachá do Colaborador', type: FieldType.employeeSearch, isRequired: true),
          FormFieldModel(id: 'f2', label: 'Setor', type: FieldType.multipleChoice, options: ['Produção', 'Manutenção', 'Logística', 'Limpeza'], isRequired: true),
          FormFieldModel(id: 'f3', label: 'EPIs em uso', type: FieldType.checkbox, options: ['Capacete', 'Óculos de Segurança', 'Protetor Auricular', 'Luvas', 'Bota de Segurança']),
          FormFieldModel(id: 'f4', label: 'Estado de Conservação dos EPIs', type: FieldType.multipleChoice, options: ['Ótimo', 'Bom', 'Regular', 'Necessita Troca'], isRequired: true),
          FormFieldModel(id: 'f5', label: 'Observações Adicionais', type: FieldType.longText),
        ]
      ),
      FormModel(
        id: '2',
        title: 'Relatório de Quase Acidente',
        description: 'Registro de situações de risco que não chegaram a causar lesões, com o fim de prevenção.',
        requireSignature: true,
        fields: [
          FormFieldModel(id: 'f1', label: 'Data do Ocorrido', type: FieldType.date, isRequired: true),
          FormFieldModel(id: 'f2', label: 'Local da Fábrica (Setor/Máquina)', type: FieldType.text, isRequired: true),
          FormFieldModel(id: 'f3', label: 'Descrição da Situação de Risco', type: FieldType.longText, isRequired: true),
          FormFieldModel(id: 'f4', label: 'Ação Imediata Tomada', type: FieldType.longText),
        ]
      ),
      FormModel(
        id: '3',
        title: 'Vistoria de Extintores e Mangueiras',
        description: 'Inspeção periódica dos equipamentos de combate a incêndio do pavilhão.',
        requireSignature: true,
        fields: [
          FormFieldModel(id: 'f1', label: 'Identificação do Extintor (Tag/Número)', type: FieldType.text, isRequired: true),
          FormFieldModel(id: 'f2', label: 'Tipo do Extintor', type: FieldType.multipleChoice, options: ['Água Pressurizada', 'Pó Químico Seco', 'CO2', 'Espuma Mecânica']),
          FormFieldModel(id: 'f3', label: 'Lacre Intacto?', type: FieldType.multipleChoice, options: ['Sim', 'Não'], isRequired: true),
          FormFieldModel(id: 'f4', label: 'Pressão no Manômetro', type: FieldType.multipleChoice, options: ['Faixa Verde (OK)', 'Despressurizado', 'Superpressurizado']),
        ]
      ),
    ];
  }
}
