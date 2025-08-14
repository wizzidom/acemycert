// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'bulk_question_uploader.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Initialize Supabase (you'll need to add your credentials here)
//   await Supabase.initialize(
//     url: 'YOUR_SUPABASE_URL',
//     anonKey: 'YOUR_SUPABASE_ANON_KEY',
//   );
  
//   runApp(BulkUploaderApp());
// }

// class BulkUploaderApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Bulk Question Uploader',
//       home: BulkUploaderScreen(),
//     );
//   }
// }

// class BulkUploaderScreen extends StatefulWidget {
//   @override
//   _BulkUploaderScreenState createState() => _BulkUploaderScreenState();
// }

// class _BulkUploaderScreenState extends State<BulkUploaderScreen> {
//   bool _isUploading = false;
//   String _status = 'Ready to upload questions';
//   List<String> _logs = [];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Bulk Question Uploader'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               child: Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Status: $_status',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 8),
//                     if (_isUploading)
//                       LinearProgressIndicator(),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _isUploading ? null : _startUpload,
//               child: Text(_isUploading ? 'Uploading...' : 'Start Upload'),
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(vertical: 16),
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//             SizedBox(height: 16),
//             Expanded(
//               child: Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(8.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Upload Log:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(height: 8),
//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: _logs.length,
//                           itemBuilder: (context, index) {
//                             return Padding(
//                               padding: EdgeInsets.symmetric(vertical: 2),
//                               child: Text(
//                                 _logs[index],
//                                 style: TextStyle(
//                                   fontFamily: 'monospace',
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _startUpload() async {
//     setState(() {
//       _isUploading = true;
//       _status = 'Uploading questions...';
//       _logs.clear();
//     });

//     try {
//       final uploader = BulkQuestionUploader();
      
//       // Override print to capture logs
//       final originalPrint = print;
//       print = (Object? object) {
//         setState(() {
//           _logs.add(object.toString());
//         });
//         originalPrint(object);
//       };
      
//       await uploader.uploadNewQuestions();
      
//       // Restore original print
//       print = originalPrint;
      
//       setState(() {
//         _status = 'Upload completed successfully!';
//         _isUploading = false;
//       });
      
//     } catch (e) {
//       setState(() {
//         _status = 'Upload failed: $e';
//         _isUploading = false;
//         _logs.add('❌ Error: $e');
//       });
//     }
//   }
// }