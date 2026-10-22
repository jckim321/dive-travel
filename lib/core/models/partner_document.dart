import 'package:dive_travel_app/core/data/dive_star.dart';

enum PartnerDocCategory {
  criteria,
  partnerGuide,
  application,
  auditor,
  training,
  contract;

  static PartnerDocCategory parse(dynamic raw) {
    switch ((raw as String?)?.trim()) {
      case 'criteria':
        return PartnerDocCategory.criteria;
      case 'application':
        return PartnerDocCategory.application;
      case 'auditor':
        return PartnerDocCategory.auditor;
      case 'training':
        return PartnerDocCategory.training;
      case 'contract':
        return PartnerDocCategory.contract;
      case 'partner_guide':
      default:
        return PartnerDocCategory.partnerGuide;
    }
  }

  String get firestoreValue => switch (this) {
        PartnerDocCategory.criteria => 'criteria',
        PartnerDocCategory.partnerGuide => 'partner_guide',
        PartnerDocCategory.application => 'application',
        PartnerDocCategory.auditor => 'auditor',
        PartnerDocCategory.training => 'training',
        PartnerDocCategory.contract => 'contract',
      };
}

enum PartnerDocAudience {
  public,
  internal;

  static PartnerDocAudience parse(dynamic raw) {
    if ((raw as String?)?.trim() == 'internal') {
      return PartnerDocAudience.internal;
    }
    return PartnerDocAudience.public;
  }

  String get firestoreValue => name;
}

enum PartnerDocStatus {
  draft,
  approved;

  static PartnerDocStatus parse(dynamic raw) {
    if ((raw as String?)?.trim() == 'approved') {
      return PartnerDocStatus.approved;
    }
    return PartnerDocStatus.draft;
  }

  String get firestoreValue => name;
}

enum PartnerDocShareMethod {
  share,
  email,
  link,
  qr,
  print;

  static PartnerDocShareMethod parse(dynamic raw) {
    switch ((raw as String?)?.trim()) {
      case 'email':
        return PartnerDocShareMethod.email;
      case 'link':
        return PartnerDocShareMethod.link;
      case 'qr':
        return PartnerDocShareMethod.qr;
      case 'print':
        return PartnerDocShareMethod.print;
      case 'share':
      default:
        return PartnerDocShareMethod.share;
    }
  }

  String get firestoreValue => name;
}

class PartnerDocument {
  const PartnerDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.audience,
    required this.language,
    required this.version,
    required this.status,
    this.assetPath = '',
    this.url = '',
    this.updatedAt,
  });

  factory PartnerDocument.fromDocument(String id, Map<String, dynamic> data) {
    return PartnerDocument(
      id: id,
      title: (data['title'] as String? ?? '').trim(),
      category: PartnerDocCategory.parse(data['category']),
      audience: PartnerDocAudience.parse(data['audience']),
      language: (data['language'] as String? ?? 'ko').trim(),
      version: (data['version'] as String? ?? '1.0').trim(),
      status: PartnerDocStatus.parse(data['status']),
      assetPath: (data['asset_path'] as String? ?? '').trim(),
      url: (data['url'] as String? ?? '').trim(),
      updatedAt: DiveStar.parseDate(data['updated_at']),
    );
  }

  final String id;
  final String title;
  final PartnerDocCategory category;
  final PartnerDocAudience audience;
  final String language;
  final String version;
  final PartnerDocStatus status;
  final String assetPath;
  final String url;
  final DateTime? updatedAt;

  bool get isDraft => status == PartnerDocStatus.draft;

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category.firestoreValue,
        'audience': audience.firestoreValue,
        'language': language,
        'version': version,
        'status': status.firestoreValue,
        'asset_path': assetPath,
        'url': url,
      };

  PartnerDocument copyWith({
    PartnerDocStatus? status,
    String? version,
    String? title,
  }) {
    return PartnerDocument(
      id: id,
      title: title ?? this.title,
      category: category,
      audience: audience,
      language: language,
      version: version ?? this.version,
      status: status ?? this.status,
      assetPath: assetPath,
      url: url,
      updatedAt: updatedAt,
    );
  }

  /// Phase-1 seed: Dive Star guide + letter of intent (KO drafts).
  static List<PartnerDocument> phase1Seeds() => const [
        PartnerDocument(
          id: 'dive-star-guide-ko',
          title: '다이브스타 심사 안내서',
          category: PartnerDocCategory.partnerGuide,
          audience: PartnerDocAudience.public,
          language: 'ko',
          version: '1.0',
          status: PartnerDocStatus.draft,
          assetPath: 'docs_public/dive_star_guide_ko.pdf',
        ),
        PartnerDocument(
          id: 'dive-star-loi-ko',
          title: '다이브스타 심사 신청 의향서',
          category: PartnerDocCategory.application,
          audience: PartnerDocAudience.public,
          language: 'ko',
          version: '1.0',
          status: PartnerDocStatus.draft,
          assetPath: 'docs_public/dive_star_letter_of_intent_ko.pdf',
        ),
      ];
}

class DocumentShareRecord {
  const DocumentShareRecord({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    required this.shopId,
    required this.shopName,
    required this.method,
    required this.adminUid,
    required this.createdAt,
  });

  factory DocumentShareRecord.fromDocument(
    String id,
    Map<String, dynamic> data,
  ) {
    return DocumentShareRecord(
      id: id,
      documentId: (data['document_id'] as String? ?? '').trim(),
      documentTitle: (data['document_title'] as String? ?? '').trim(),
      shopId: (data['shop_id'] as String? ?? '').trim(),
      shopName: (data['shop_name'] as String? ?? '').trim(),
      method: PartnerDocShareMethod.parse(data['method']),
      adminUid: (data['admin_uid'] as String? ?? '').trim(),
      createdAt: DiveStar.parseDate(data['created_at']) ?? DateTime.now().toUtc(),
    );
  }

  final String id;
  final String documentId;
  final String documentTitle;
  final String shopId;
  final String shopName;
  final PartnerDocShareMethod method;
  final String adminUid;
  final DateTime createdAt;
}

class PartnerMessageTemplate {
  const PartnerMessageTemplate({
    required this.subject,
    required this.body,
  });

  factory PartnerMessageTemplate.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const PartnerMessageTemplate(subject: '', body: '');
    }
    return PartnerMessageTemplate(
      subject: (data['subject'] as String? ?? '').trim(),
      body: (data['body'] as String? ?? '').trim(),
    );
  }

  final String subject;
  final String body;

  Map<String, dynamic> toMap() => {'subject': subject, 'body': body};

  String fill({required String partnerName, required String link}) {
    return body
        .replaceAll('{파트너명}', partnerName)
        .replaceAll('{partner_name}', partnerName)
        .replaceAll('{링크}', link)
        .replaceAll('{link}', link);
  }

  String fillSubject({required String partnerName, required String link}) {
    return subject
        .replaceAll('{파트너명}', partnerName)
        .replaceAll('{partner_name}', partnerName)
        .replaceAll('{링크}', link)
        .replaceAll('{link}', link);
  }
}

class PartnerDocConfig {
  const PartnerDocConfig({
    required this.channelsByCountry,
    required this.templates,
  });

  factory PartnerDocConfig.fromDocument(Map<String, dynamic> data) {
    final channelsRaw = data['channels_by_country'];
    final templatesRaw = data['templates'];
    final channels = <String, List<String>>{};
    if (channelsRaw is Map) {
      for (final entry in channelsRaw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is List) {
          channels[key] = [
            for (final item in value)
              if (item is String && item.trim().isNotEmpty) item.trim(),
          ];
        }
      }
    }
    final templates = <String, PartnerMessageTemplate>{};
    if (templatesRaw is Map) {
      for (final entry in templatesRaw.entries) {
        if (entry.value is Map) {
          templates[entry.key.toString()] = PartnerMessageTemplate.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }
    return PartnerDocConfig(
      channelsByCountry: channels,
      templates: templates,
    );
  }

  final Map<String, List<String>> channelsByCountry;
  final Map<String, PartnerMessageTemplate> templates;

  List<String> channelsForCountry(String country) {
    final key = country.trim().toUpperCase();
    if (channelsByCountry.containsKey(key)) {
      return channelsByCountry[key]!;
    }
    // Common aliases
    if (key == 'KR' || key == 'KOREA' || country.contains('한국')) {
      return channelsByCountry['KR'] ?? defaultConfig.channelsByCountry['KR']!;
    }
    if (key == 'JP' || country.contains('日本') || country.contains('일본')) {
      return channelsByCountry['JP'] ?? defaultConfig.channelsByCountry['JP']!;
    }
    return channelsByCountry['DEFAULT'] ??
        defaultConfig.channelsByCountry['DEFAULT']!;
  }

  PartnerMessageTemplate templateFor(String language) {
    return templates[language] ??
        templates['ko'] ??
        defaultConfig.templates['ko']!;
  }

  Map<String, dynamic> toMap() => {
        'channels_by_country': channelsByCountry,
        'templates': {
          for (final entry in templates.entries) entry.key: entry.value.toMap(),
        },
      };

  PartnerDocConfig copyWith({
    Map<String, List<String>>? channelsByCountry,
    Map<String, PartnerMessageTemplate>? templates,
  }) {
    return PartnerDocConfig(
      channelsByCountry: channelsByCountry ?? this.channelsByCountry,
      templates: templates ?? this.templates,
    );
  }

  static const PartnerDocConfig defaultConfig = PartnerDocConfig(
    channelsByCountry: {
      'KR': ['kakao', 'email', 'share'],
      'JP': ['line', 'email', 'share'],
      'TH': ['line', 'whatsapp', 'email'],
      'ID': ['whatsapp', 'email', 'share'],
      'DEFAULT': ['whatsapp', 'email', 'share', 'link'],
    },
    templates: {
      'ko': PartnerMessageTemplate(
        subject: '[다이브트래블] {파트너명} 다이브스타 안내 자료',
        body:
            '{파트너명} 담당자님 안녕하세요.\n다이브스타 관련 안내 자료를 보내드립니다.\n\n자료 링크: {링크}\n\n확인 부탁드립니다.',
      ),
      'en': PartnerMessageTemplate(
        subject: '[Dive Travel] Dive Star materials for {partner_name}',
        body:
            'Hello,\nPlease find Dive Star materials for {partner_name}.\n\nLink: {link}\n\nThank you.',
      ),
    },
  );
}
