/// Shared JSON fixtures for the online tests, shaped exactly like the
/// responses from `netlify/functions/api.mjs`.
const Map<String, dynamic> worldJson = <String, dynamic>{
  'weekStart': '2026-10-19',
  'boss': <String, dynamic>{
    'name': 'The Procrastination Hydra',
    'emoji': '🐉',
    'hpMax': 2800,
    'damage': 1190,
    'remaining': 1610,
    'percent': 43,
    'defeated': false,
    'endsInDays': 4,
  },
  'guild': <String, dynamic>{
    'players': 4,
    'weeklyCompletions': 119,
    'weeklyXp': 1190,
    'todayCompletions': 7,
    'todayXp': 70,
    'streakDays': 6,
    'totalCompletions': 842,
  },
};

Map<String, dynamic> authJson({String name = 'Night Owl'}) => <String, dynamic>{
      'player': <String, dynamic>{
        'id': 'player-1',
        'name': name,
        'createdAt': '2026-10-19T08:00:00.000Z',
      },
      'token': 'tok_acceptance_1234567890',
      'syncCode': 'ABCD-EFGH-JKLM',
      'stats': <String, dynamic>{'totalXp': 0, 'weeklyXp': 0, 'streak': 0},
      'world': worldJson,
    };

Map<String, dynamic> leaderboardJson() => <String, dynamic>{
      'world': worldJson,
      'leaders': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'player-1',
          'name': 'Night Owl',
          'weeklyXp': 120,
          'totalXp': 420,
          'lastSeenAt': '2026-10-19T08:00:00.000Z',
        },
        <String, dynamic>{
          'id': 'player-2',
          'name': 'Early Bird',
          'weeklyXp': 90,
          'totalXp': 310,
          'lastSeenAt': '2026-10-19T07:30:00.000Z',
        },
      ],
    };
