import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'modules/home/home_view.dart';
import 'services/submission_service.dart';
import 'services/employee_service.dart';
import 'services/lookup_service.dart';
import 'services/template_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sjnaxavgbzrcrwbcltip.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNqbmF4YXZnYnpyY3J3YmNsdGlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0NzIwODksImV4cCI6MjA5MzA0ODA4OX0.wACq9wiYzY-7zTb-rxvhzV2HB1aYGr2K42jtzahM65A',
  );

  // Inicialização Global dos Serviços
  Get.put(SubmissionService());
  Get.put(EmployeeService());
  Get.put(LookupService());
  Get.put(TemplateService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Painel de Inspeções',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}
