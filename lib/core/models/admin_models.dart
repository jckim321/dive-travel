enum CommunityPostType { shopTour, buddy }

enum TideKind {
  shopCrew,
  soloShare,
  lastCall;

  static TideKind parse(dynamic value) {
    switch (value) {
      case 'solo_share':
        return TideKind.soloShare;
      case 'last_call':
        return TideKind.lastCall;
      default:
        return TideKind.shopCrew;
    }
  }

  String get firestoreValue {
    switch (this) {
      case TideKind.shopCrew:
        return 'shop_crew';
      case TideKind.soloShare:
        return 'solo_share';
      case TideKind.lastCall:
        return 'last_call';
    }
  }
}

enum PlaqueStatus {
  none,
  queued,
  shipped;

  static PlaqueStatus parse(dynamic value) {
    switch (value) {
      case 'queued':
        return PlaqueStatus.queued;
      case 'shipped':
        return PlaqueStatus.shipped;
      default:
        return PlaqueStatus.none;
    }
  }

  String get firestoreValue {
    switch (this) {
      case PlaqueStatus.queued:
        return 'queued';
      case PlaqueStatus.shipped:
        return 'shipped';
      case PlaqueStatus.none:
        return 'none';
    }
  }
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.authorUid,
    required this.authorName,
    required this.createdAt,
    this.hidden = false,
    this.language = 'ko',
    this.shopId,
    this.destination = '',
    this.windowLabel = '',
    this.capacity = 6,
    this.bookedSeats = 0,
    this.lookingSeats = 0,
    this.soloShare = false,
    this.kind = TideKind.shopCrew,
  });

  final String id;
  final CommunityPostType type;
  final String title;
  final String subtitle;
  final String authorUid;
  final String authorName;
  final DateTime createdAt;
  final bool hidden;
  final String language;
  final String? shopId;
  final String destination;
  final String windowLabel;
  final int capacity;
  final int bookedSeats;
  final int lookingSeats;
  final bool soloShare;
  final TideKind kind;

  String get body => '$title\n$subtitle';

  int get emptySeats {
    final taken = bookedSeats + lookingSeats;
    final left = capacity - taken;
    return left < 0 ? 0 : left;
  }

  CommunityPost copyWith({bool? hidden, String? language, int? lookingSeats}) {
    return CommunityPost(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      authorUid: authorUid,
      authorName: authorName,
      createdAt: createdAt,
      hidden: hidden ?? this.hidden,
      language: language ?? this.language,
      shopId: shopId,
      destination: destination,
      windowLabel: windowLabel,
      capacity: capacity,
      bookedSeats: bookedSeats,
      lookingSeats: lookingSeats ?? this.lookingSeats,
      soloShare: soloShare,
      kind: kind,
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorUid,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.language = 'en',
  });

  final String id;
  final String postId;
  final String authorUid;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final String language;
}

class PendingInstructor {
  const PendingInstructor({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.agency,
    required this.photoUrl,
  });

  final String uid;
  final String email;
  final String displayName;
  final String agency;
  final String photoUrl;
}

abstract final class CommunityPostCatalog {
  static final seeds = <CommunityPost>[
    CommunityPost(
      id: 'seed-shop-bohol',
      type: CommunityPostType.shopTour,
      title: '보홀 하이드아웃 · 샵 크루',
      subtitle: '체크다이브 후 샵이 물속 버디를 배정합니다. 같은 밴, 같은 보트가 먼저입니다.',
      authorUid: 'system',
      authorName: '다이브 트래블',
      createdAt: DateTime(2026, 9, 1),
      language: 'ko',
      shopId: 'bohol-hideout',
      destination: 'Bohol',
      windowLabel: '10.03 – 10.06',
      capacity: 6,
      bookedSeats: 4,
      lookingSeats: 1,
      kind: TideKind.shopCrew,
    ),
    CommunityPost(
      id: 'seed-buddy-dahab',
      type: CommunityPostType.buddy,
      title: '다합 블루홀 · 마감 1석',
      subtitle: '내일 마감. 싱글차지 없이 마지막 침대를 나눕니다.',
      authorUid: 'system',
      authorName: '다이브 트래블',
      createdAt: DateTime(2026, 9, 2),
      language: 'ko',
      shopId: 'dahab-bluehole',
      destination: 'Dahab',
      windowLabel: '09.20 – 09.23',
      capacity: 4,
      bookedSeats: 3,
      lookingSeats: 0,
      soloShare: true,
      kind: TideKind.lastCall,
    ),
    CommunityPost(
      id: 'seed-buddy-dahab-en',
      type: CommunityPostType.buddy,
      title: 'Dahab weekend · solo share',
      subtitle:
          'Share the twin. Shop assigns the water buddy after the check dive.',
      authorUid: 'system',
      authorName: 'Alex Rivera',
      createdAt: DateTime(2026, 9, 10),
      language: 'en',
      shopId: 'dahab-bluehole',
      destination: 'Dahab',
      windowLabel: '09.26 – 09.28',
      capacity: 2,
      bookedSeats: 1,
      lookingSeats: 1,
      soloShare: true,
      kind: TideKind.soloShare,
    ),
    CommunityPost(
      id: 'seed-buddy-kerama-ja',
      type: CommunityPostType.buddy,
      title: 'ケラマ 2タンク',
      subtitle: '初心者歓迎。同じ船に乗る人だけ集めます。',
      authorUid: 'system',
      authorName: '佐藤ダイバー',
      createdAt: DateTime(2026, 9, 12),
      language: 'ja',
      shopId: 'kerama-okinawa',
      destination: 'Kerama',
      windowLabel: '10.11 – 10.12',
      capacity: 6,
      bookedSeats: 2,
      lookingSeats: 2,
      kind: TideKind.shopCrew,
    ),
    CommunityPost(
      id: 'seed-buddy-komodo',
      type: CommunityPostType.buddy,
      title: '코모도 오픈트립 · 싱글쉐어',
      subtitle: '침대만 나눕니다. 물속은 가이드가 페어합니다.',
      authorUid: 'system',
      authorName: '민서',
      createdAt: DateTime(2026, 9, 14),
      language: 'ko',
      shopId: 'komodo-comel',
      destination: 'Komodo',
      windowLabel: '11.02 – 11.05',
      capacity: 8,
      bookedSeats: 5,
      lookingSeats: 2,
      soloShare: true,
      kind: TideKind.soloShare,
    ),
    CommunityPost(
      id: 'seed-buddy-palau',
      type: CommunityPostType.buddy,
      title: '팔라우 록아일랜드 · 빈 자리 채우기',
      subtitle: '이미 예약한 크루가 한 자리를 열고 있습니다.',
      authorUid: 'system',
      authorName: 'Noah Park',
      createdAt: DateTime(2026, 9, 15),
      language: 'en',
      shopId: 'palau-rock-islands',
      destination: 'Palau',
      windowLabel: '12.08 – 12.14',
      capacity: 6,
      bookedSeats: 5,
      lookingSeats: 0,
      kind: TideKind.lastCall,
    ),
  ];

  static final seedComments = <CommunityComment>[
    CommunityComment(
      id: 'seed-comment-dahab-en',
      postId: 'seed-buddy-dahab-en',
      authorUid: 'system',
      authorName: 'Mia Chen',
      body: 'I have my own gear. Can I join Friday afternoon?',
      createdAt: DateTime(2026, 9, 11),
      language: 'en',
    ),
  ];
}
