// // Admin Question Management Screen
// // This would be a future enhancement for adding questions via the app

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// import '../../core/theme.dart';
// import '../../widgets/custom_button.dart';
// import '../../widgets/custom_text_field.dart';

// class AdminQuestionScreen extends StatefulWidget {
//   const AdminQuestionScreen({super.key});

//   @override
//   State<AdminQuestionScreen> createState() => _AdminQuestionScreenState();
// }

// class _AdminQuestionScreenState extends State<AdminQuestionScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _questionController = TextEditingController();
//   final _explanationController = TextEditingController();
//   final List<TextEditingController> _answerControllers = List.generate(4, (_) => TextEditingController());
  
//   String _selectedCertification = 'isc2-cc';
//   String _selectedSection = 'security-principles';
//   int _correctAnswerIndex = 0;
//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.backgroundDark,
//       appBar: AppBar(
//         backgroundColor: AppTheme.backgroundDark,
//         title: const Text('Add New Question'),
//         foregroundColor: AppTheme.textPrimary,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Certification Selection
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Certification & Section',
//                         style: Theme.of(context).textTheme.headlineSmall,
//                       ),
//                       const SizedBox(height: 16),
//                       DropdownButtonFormField<String>(
//                         value: _selectedCertification,
//                         decoration: const InputDecoration(
//                           labelText: 'Certification',
//                           border: OutlineInputBorder(),
//                         ),
//                         items: const [
//                           DropdownMenuItem(value: 'isc2-cc', child: Text('ISC² CC')),
//                           DropdownMenuItem(value: 'comptia-security-plus', child: Text('CompTIA Security+')),
//                           DropdownMenuItem(value: 'comptia-network-plus', child: Text('CompTIA Network+')),
//                         ],
//                         onChanged: (value) {
//                           setState(() {
//                             _selectedCertification = value!;
//                             _selectedSection = _getSectionsForCertification(value).first;
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       DropdownButtonFormField<String>(
//                         value: _selectedSection,
//                         decoration: const InputDecoration(
//                           labelText: 'Section',
//                           border: OutlineInputBorder(),
//                         ),
//                         items: _getSectionsForCertification(_selectedCertification)
//                             .map((section) => DropdownMenuItem(
//                                   value: section,
//                                   child: Text(_getSectionName(section)),
//                                 ))
//                             .toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             _selectedSection = value!;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               const SizedBox(height: 16),
              
//               // Question Input
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Question Details',
//                         style: Theme.of(context).textTheme.headlineSmall,
//                       ),
//                       const SizedBox(height: 16),
//                       CustomTextField(
//                         controller: _questionController,
//                         labelText: 'Question Text',
//                         maxLines: 3,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter the question text';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       CustomTextField(
//                         controller: _explanationController,
//                         labelText: 'Explanation',
//                         maxLines: 4,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter an explanation';
//                           }
//                           return null;
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               const SizedBox(height: 16),
              
//               // Answer Options
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Answer Options',
//                         style: Theme.of(context).textTheme.headlineSmall,
//                       ),
//                       const SizedBox(height: 16),
//                       ...List.generate(4, (index) => Padding(
//                         padding: const EdgeInsets.only(bottom: 12),
//                         child: Row(
//                           children: [
//                             Radio<int>(
//                               value: index,
//                               groupValue: _correctAnswerIndex,
//                               onChanged: (value) {
//                                 setState(() {
//                                   _correctAnswerIndex = value!;
//                                 });
//                               },
//                             ),
//                             Expanded(
//                               child: CustomTextField(
//                                 controller: _answerControllers[index],
//                                 labelText: 'Option ${String.fromCharCode(65 + index)}',
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please enter option ${String.fromCharCode(65 + index)}';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                       )),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Select the correct answer by clicking the radio button',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: AppTheme.textSecondary,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               const SizedBox(height: 24),
              
//               // Submit Button
//               SizedBox(
//                 width: double.infinity,
//                 child: CustomButton(
//                   text: _isLoading ? 'Adding Question...' : 'Add Question',
//                   onPressed: _isLoading ? null : _submitQuestion,
//                   backgroundColor: AppTheme.primaryBlue,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   List<String> _getSectionsForCertification(String certificationId) {
//     switch (certificationId) {
//       case 'isc2-cc':
//         return [
//           'security-principles',
//           'incident-response',
//           'access-controls',
//           'network-security',
//           'security-operations',
//         ];
//       case 'comptia-security-plus':
//         return [
//           'threats-attacks-vulnerabilities',
//           'architecture-design',
//           'implementation',
//           'operations-incident-response',
//           'governance-risk-compliance',
//         ];
//       default:
//         return ['security-principles'];
//     }
//   }

//   String _getSectionName(String sectionId) {
//     final sectionNames = {
//       'security-principles': 'Security Principles',
//       'incident-response': 'Business Continuity & Incident Response',
//       'access-controls': 'Access Controls Concepts',
//       'network-security': 'Network Security',
//       'security-operations': 'Security Operations',
//       'threats-attacks-vulnerabilities': 'Threats, Attacks, and Vulnerabilities',
//       'architecture-design': 'Architecture and Design',
//       'implementation': 'Implementation',
//       'operations-incident-response': 'Operations and Incident Response',
//       'governance-risk-compliance': 'Governance, Risk, and Compliance',
//     };
//     return sectionNames[sectionId] ?? sectionId;
//   }

//   Future<void> _submitQuestion() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // TODO: Implement question submission to Supabase
//       // This would use a service to add the question to the database
      
//       // For now, show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Question added successfully!'),
//           backgroundColor: AppTheme.successGreen,
//         ),
//       );
      
//       // Clear form
//       _questionController.clear();
//       _explanationController.clear();
//       for (final controller in _answerControllers) {
//         controller.clear();
//       }
//       setState(() {
//         _correctAnswerIndex = 0;
//       });
      
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to add question: $e'),
//           backgroundColor: AppTheme.errorRed,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _questionController.dispose();
//     _explanationController.dispose();
//     for (final controller in _answerControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
// }