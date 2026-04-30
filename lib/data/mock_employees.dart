class Colaborador {
  final String cracha;
  final String nome;

  Colaborador({required this.cracha, required this.nome});
}

class MockEmployees {
  static final List<Colaborador> colaboradores = [
    Colaborador(cracha: '1001', nome: 'João da Silva'),
    Colaborador(cracha: '1002', nome: 'Maria Oliveira'),
    Colaborador(cracha: '1003', nome: 'Carlos Souza'),
    Colaborador(cracha: '1004', nome: 'Ana Costa'),
  ];
}
