class Certification {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final List<QuizSection> sections;
  final int totalQuestions;
  final bool isActive;

  const Certification({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.sections,
    required this.totalQuestions,
    this.isActive = true,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String,
      totalQuestions: json['total_questions'] as int,
      isActive: json['is_active'] as bool? ?? true,
      sections: (json['sections'] as List<dynamic>?)
          ?.map((e) => QuizSection.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'total_questions': totalQuestions,
      'is_active': isActive,
      'sections': sections.map((e) => e.toJson()).toList(),
    };
  }

  // Sample data for development
  static List<Certification> getSampleCertifications() {
    return [
      Certification(
        id: 'comptia_a_plus',
        name: 'CompTIA A+',
        description: 'Entry-level IT certification covering hardware, networking, mobile devices, and troubleshooting',
        iconUrl: 'assets/icons/comptia_a_plus.png',
        totalQuestions: 250,
        sections: [
          QuizSection(
            id: 'hardware',
            name: 'Hardware',
            description: 'Computer hardware components and troubleshooting',
            certificationId: 'comptia_a_plus',
            questionCount: 50,
          ),
          QuizSection(
            id: 'networking',
            name: 'Networking',
            description: 'Network fundamentals and troubleshooting',
            certificationId: 'comptia_a_plus',
            questionCount: 45,
          ),
          QuizSection(
            id: 'mobile_devices',
            name: 'Mobile Devices',
            description: 'Mobile device hardware and network connectivity',
            certificationId: 'comptia_a_plus',
            questionCount: 35,
          ),
          QuizSection(
            id: 'troubleshooting',
            name: 'Troubleshooting',
            description: 'Troubleshooting methodology and problem solving',
            certificationId: 'comptia_a_plus',
            questionCount: 40,
          ),
        ],
      ),
      Certification(
        id: 'comptia_security_plus',
        name: 'CompTIA Security+',
        description: 'Foundational cybersecurity certification covering threats, vulnerabilities, and risk management',
        iconUrl: 'assets/icons/comptia_security_plus.png',
        totalQuestions: 300,
        sections: [
          QuizSection(
            id: 'threats_attacks',
            name: 'Threats & Attacks',
            description: 'Types of attacks, threat actors, and attack vectors',
            certificationId: 'comptia_security_plus',
            questionCount: 60,
          ),
          QuizSection(
            id: 'architecture_design',
            name: 'Architecture & Design',
            description: 'Secure network architecture and system design',
            certificationId: 'comptia_security_plus',
            questionCount: 55,
          ),
          QuizSection(
            id: 'implementation',
            name: 'Implementation',
            description: 'Secure protocols, host security, and mobile security',
            certificationId: 'comptia_security_plus',
            questionCount: 50,
          ),
          QuizSection(
            id: 'operations_incident_response',
            name: 'Operations & Incident Response',
            description: 'Security operations and incident response procedures',
            certificationId: 'comptia_security_plus',
            questionCount: 45,
          ),
          QuizSection(
            id: 'governance_risk_compliance',
            name: 'Governance, Risk & Compliance',
            description: 'Risk management, compliance, and governance frameworks',
            certificationId: 'comptia_security_plus',
            questionCount: 40,
          ),
        ],
      ),
      Certification(
        id: 'isc2_cc',
        name: 'ISC² CC',
        description: 'Certified in Cybersecurity - foundational cybersecurity knowledge and skills',
        iconUrl: 'assets/icons/isc2_cc.png',
        totalQuestions: 200,
        sections: [
          QuizSection(
            id: 'security_principles',
            name: 'Security Principles',
            description: 'Fundamental security concepts and principles',
            certificationId: 'isc2_cc',
            questionCount: 50,
          ),
          QuizSection(
            id: 'incident_response',
            name: 'Incident Response',
            description: 'Incident response processes and business continuity',
            certificationId: 'isc2_cc',
            questionCount: 40,
          ),
          QuizSection(
            id: 'access_controls',
            name: 'Access Controls',
            description: 'Access control concepts and implementation',
            certificationId: 'isc2_cc',
            questionCount: 45,
          ),
          QuizSection(
            id: 'network_security',
            name: 'Network Security',
            description: 'Network security concepts and technologies',
            certificationId: 'isc2_cc',
            questionCount: 35,
          ),
          QuizSection(
            id: 'security_operations',
            name: 'Security Operations',
            description: 'Security operations and data security',
            certificationId: 'isc2_cc',
            questionCount: 30,
          ),
        ],
      ),
    ];
  }
}

class QuizSection {
  final String id;
  final String name;
  final String description;
  final String certificationId;
  final int questionCount;

  const QuizSection({
    required this.id,
    required this.name,
    required this.description,
    required this.certificationId,
    required this.questionCount,
  });

  factory QuizSection.fromJson(Map<String, dynamic> json) {
    return QuizSection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      certificationId: json['certification_id'] as String,
      questionCount: json['question_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'certification_id': certificationId,
      'question_count': questionCount,
    };
  }
}