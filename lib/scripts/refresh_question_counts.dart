import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (you'll need to add your credentials here)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(RefreshCountsApp());
}

class RefreshCountsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Refresh Question Counts',
      home: RefreshCountsScreen(),
    );
  }
}

class RefreshCountsScreen extends StatefulWidget {
  @override
  _RefreshCountsScreenState createState() => _RefreshCountsScreenState();
}

class _RefreshCountsScreenState extends State<RefreshCountsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isRefreshing = false;
  String _status = 'Ready to refresh question counts';
  List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Refresh Question Counts'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    if (_isRefreshing)
                      LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRefreshing ? null : _refreshCounts,
              child: Text(_isRefreshing ? 'Refreshing...' : 'Refresh Question Counts'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refresh Log:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _logs[index],
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    print(message);
  }

  void _refreshCounts() async {
    setState(() {
      _isRefreshing = true;
      _status = 'Refreshing question counts...';
      _logs.clear();
    });

    try {
      _addLog('🔄 Starting question count refresh...');
      
      // Get all sections for ISC² CC
      final sections = await _supabase
          .from('sections')
          .select('id, name')
          .eq('certification_id', 'isc2-cc');
      
      _addLog('📊 Found ${sections.length} sections to update');
      
      int totalQuestions = 0;
      
      for (final section in sections) {
        final sectionId = section['id'] as String;
        final sectionName = section['name'] as String;
        
        // Count actual questions in this section
        final questions = await _supabase
            .from('questions')
            .select('id')
            .eq('section_id', sectionId);
        
        final questionCount = questions.length;
        totalQuestions += questionCount;
        
        _addLog('  📝 $sectionName: $questionCount questions');
        
        // Update section question count
        await _supabase
            .from('sections')
            .update({'question_count': questionCount})
            .eq('id', sectionId);
      }
      
      _addLog('📊 Total questions across all sections: $totalQuestions');
      
      // Update total certification question count
      await _supabase
          .from('certifications')
          .update({'total_questions': totalQuestions})
          .eq('id', 'isc2-cc');
      
      _addLog('✅ Updated certification total questions: $totalQuestions');
      
      // Verify the updates
      _addLog('🔍 Verifying updates...');
      
      final updatedSections = await _supabase
          .from('sections')
          .select('id, name, question_count')
          .eq('certification_id', 'isc2-cc')
          .order('order_index');
      
      for (final section in updatedSections) {
        _addLog('  ✓ ${section['name']}: ${section['question_count']} questions');
      }
      
      final certification = await _supabase
          .from('certifications')
          .select('total_questions')
          .eq('id', 'isc2-cc')
          .single();
      
      _addLog('  ✓ Total certification questions: ${certification['total_questions']}');
      
      setState(() {
        _status = 'Question counts refreshed successfully!';
        _isRefreshing = false;
      });
      
      _addLog('🎉 Question count refresh completed!');
      _addLog('💡 Restart your app to see the updated counts in the UI');
      
    } catch (e) {
      setState(() {
        _status = 'Refresh failed: $e';
        _isRefreshing = false;
      });
      _addLog('❌ Error: $e');
    }
  }
}