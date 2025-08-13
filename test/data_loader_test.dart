import 'package:flutter_test/flutter_test.dart';
import 'package:cybersecurity_quiz_platform/services/data_loader_service.dart';

void main() {
  group('Data Loader Service Tests', () {
    test('ISC² CC sections have correct information', () {
      final sections = DataLoaderService.getISC2Sections();
      
      expect(sections.length, 5);
      expect(sections.containsKey('security-principles'), true);
      expect(sections.containsKey('incident-response'), true);
      expect(sections.containsKey('access-controls'), true);
      expect(sections.containsKey('network-security'), true);
      expect(sections.containsKey('security-operations'), true);
    });

    test('Question counts are accurate', () {
      final counts = DataLoaderService.getQuestionCounts();
      
      expect(counts.length, 5);
      counts.values.forEach((count) {
        expect(count, 20); // Each domain has 20 questions
      });
    });

    test('Total question count is correct', () {
      final totalCount = DataLoaderService.getTotalQuestionCount();
      expect(totalCount, 100); // 5 domains × 20 questions = 100
    });
  });
}