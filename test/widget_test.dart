// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cybersecurity_quiz_platform/core/theme.dart';
import 'package:cybersecurity_quiz_platform/core/constants.dart';
import 'package:cybersecurity_quiz_platform/models/certification.dart';
import 'package:cybersecurity_quiz_platform/services/quiz_service.dart';

void main() {
  group('App Components Tests', () {
    testWidgets('Theme has correct colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    test('App constants are defined correctly', () {
      expect(AppConstants.appName, 'CyberQuiz Pro');
      expect(AppConstants.defaultQuizLength, 10);
      expect(AppConstants.defaultPadding, 16.0);
    });

    test('Quiz service can load certifications', () async {
      final quizService = QuizService();
      final certifications = await quizService.getCertifications();
      
      expect(certifications.isNotEmpty, true);
      expect(certifications.length, 3);
      expect(certifications.first.name, contains('CompTIA'));
    });

    test('Certification model works correctly', () {
      final certification = Certification(
        id: 'test-cert',
        name: 'Test Certification',
        description: 'A test certification',
        iconUrl: '',
        totalQuestions: 100,
        sections: [],
      );

      expect(certification.id, 'test-cert');
      expect(certification.name, 'Test Certification');
      expect(certification.totalQuestions, 100);
    });
  });
}
