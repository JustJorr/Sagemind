import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'sb_publishable_XWGJrK8m9BoMzT1uQ-tj7w_N5ib02Nc',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvcXBtcGZ0b21mdHpxY2VkamNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwODcwNjQsImV4cCI6MjA4MDY2MzA2NH0.5MCrD4tFjYBdA6hnIk-sNnVtCCY_hpNiFjllII9RjP4',
  );
  runApp(const SageMindApp());
}
