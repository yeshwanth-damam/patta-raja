import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const PattaSafarApp());

class PattaSafarApp extends StatelessWidget {
  const PattaSafarApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Patta Safar',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff0b6b4f),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xff071d18),
          useMaterial3: true,
        ),
        home: const GamePage(),
      );
}

enum Suit { hearts, diamonds, clubs, spades }

class PlayingCard {
  const PlayingCard(this.rank, this.suit);
  final int rank;
  final Suit suit;

  String get label => '${_rankLabel(rank)}${_suitSymbol(suit)}';
  Color get color =>
      suit == Suit.hearts || suit == Suit.diamonds ? Colors.redAccent : Colors.white;

  Map<String, dynamic> toJson() => {'rank': rank, 'suit': suit.index};
  factory PlayingCard.fromJson(Map<String, dynamic> json) =>
      PlayingCard(json['rank'] as int, Suit.values[json['suit'] as int]);
}

String _rankLabel(int rank) {
  if (rank == 14) return 'A';
  if (rank == 13) return 'K';
  if (rank == 12) return 'Q';
  if (rank == 11) return 'J';
  return '$rank';
}

String _suitSymbol(Suit suit) => ['♥', '♦', '♣', '♠'][suit.index];

enum HandKind { highCard, pair, color, sequence, pureSequence, trail }

class HandResult {
  const HandResult(this.kind, this.score, this.movement);
  final HandKind kind;
  final int score;
  final int movement;
  String get title => switch (kind) {
        HandKind.trail => 'Trail',
        HandKind.pureSequence => 'Pure Sequence',
        HandKind.sequence => 'Sequence',
        HandKind.color => 'Color',
        HandKind.pair => 'Pair',
        HandKind.highCard => 'High Card',
      };
}

HandResult evaluateHand(List<PlayingCard> cards, {bool blind = false}) {
  final ranks = cards.map((c) => c.rank).toList()..sort();
  final pips = ranks.fold<int>(0, (sum, value) => sum + value);
  final sameSuit = cards.map((c) => c.suit).toSet().length == 1;
  final isTrail = ranks.toSet().length == 1;
  final isSequence = (ranks[2] - ranks[0] == 2 && ranks.toSet().length == 3) ||
      (ranks[0] == 2 && ranks[1] == 3 && ranks[2] == 14);
  final isPair = ranks.toSet().length == 2;
  final (kind, base, movement) = isTrail
      ? (HandKind.trail, 100, 6)
      : isSequence && sameSuit
          ? (HandKind.pureSequence, 80, 5)
          : isSequence
              ? (HandKind.sequence, 60, 4)
              : sameSuit
                  ? (HandKind.color, 45, 3)
                  : isPair
                      ? (HandKind.pair, 30, 2)
                      : (HandKind.highCard, 15, 1);
  final multiplier = blind ? 2 : 1;
  return HandResult(kind, (base + pips) * multiplier, movement + (blind ? 1 : 0));
}

enum SquareType { round, rival, chest, nazar, rest, boss }

class BoardSquare {
  const BoardSquare(this.type, this.name, this.icon);
  final SquareType type;
  final String name;
  final String icon;
}

const board = [
  BoardSquare(SquareType.round, 'Gully Gate', '🏮'),
  BoardSquare(SquareType.rival, 'Rival: Bunty', '🃏'),
  BoardSquare(SquareType.round, 'Tea Stall', '☕'),
  BoardSquare(SquareType.chest, 'Lucky Chest', '🎁'),
  BoardSquare(SquareType.round, 'Old Bridge', '🌉'),
  BoardSquare(SquareType.nazar, 'Nazar', '🧿'),
  BoardSquare(SquareType.rival, 'Rival: Chintu', '🃏'),
  BoardSquare(SquareType.rest, 'Chaal Rest', '🪷'),
  BoardSquare(SquareType.round, 'Market Lane', '🏮'),
  BoardSquare(SquareType.chest, 'Lucky Chest', '🎁'),
  BoardSquare(SquareType.round, 'Palace Road', '🏰'),
  BoardSquare(SquareType.boss, 'Muflis Raja', '👑'),
];

enum RoundStage { chooseMode, playing, resolved, won, lost }

class GameState {
  const GameState({
    required this.chips,
    required this.position,
    required this.round,
    required this.forcedSeen,
    required this.stage,
    required this.message,
    this.cards = const [],
    this.blind = false,
    this.swaps = 2,
    this.result,
  });
  final int chips, position, round, swaps;
  final bool forcedSeen, blind;
  final RoundStage stage;
  final String message;
  final List<PlayingCard> cards;
  final HandResult? result;

  int get boot => position == 11 ? 58 : 55 + round * 15;
  bool get isBoss => position == 11;
  BoardSquare get square => board[min(position, board.length - 1)];

  GameState copyWith({
    int? chips,
    int? position,
    int? round,
    int? swaps,
    bool? forcedSeen,
    bool? blind,
    RoundStage? stage,
    String? message,
    List<PlayingCard>? cards,
    HandResult? result,
    bool clearResult = false,
  }) =>
      GameState(
        chips: chips ?? this.chips,
        position: position ?? this.position,
        round: round ?? this.round,
        swaps: swaps ?? this.swaps,
        forcedSeen: forcedSeen ?? this.forcedSeen,
        blind: blind ?? this.blind,
        stage: stage ?? this.stage,
        message: message ?? this.message,
        cards: cards ?? this.cards,
        result: clearResult ? null : result ?? this.result,
      );

  Map<String, dynamic> toJson() => {
        'chips': chips,
        'position': position,
        'round': round,
        'forcedSeen': forcedSeen,
        'stage': stage.index,
        'message': message,
        'cards': cards.map((c) => c.toJson()).toList(),
        'blind': blind,
        'swaps': swaps,
      };
  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        chips: json['chips'] as int,
        position: json['position'] as int,
        round: json['round'] as int,
        forcedSeen: json['forcedSeen'] as bool,
        stage: RoundStage.chooseMode,
        message: 'Your journey resumes. Choose Blind or Seen.',
        cards: (json['cards'] as List<dynamic>)
            .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
            .toList(),
        blind: json['blind'] as bool,
        swaps: json['swaps'] as int,
      );
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const _saveKey = 'patta_safar_run';
  GameState _game = const GameState(
    chips: 1000,
    position: 0,
    round: 1,
    forcedSeen: false,
    stage: RoundStage.chooseMode,
    message: 'Welcome to Gully. Will you play Blind or Seen?',
  );

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw != null && mounted) setState(() => _game = GameState.fromJson(jsonDecode(raw)));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(_game.toJson()));
  }

  PlayingCard _draw(Random random) =>
      PlayingCard(random.nextInt(13) + 2, Suit.values[random.nextInt(4)]);

  void _startRound(bool blind) {
    if (_game.forcedSeen && blind) return;
    final ante = max(10, _game.boot ~/ 10);
    if (_game.chips < ante) {
      setState(() => _game = _game.copyWith(stage: RoundStage.lost, message: 'Not enough chips. Your Safar ends.'));
      return;
    }
    final random = Random(_game.round * 1009 + _game.position * 97);
    final cards = List.generate(3, (_) => _draw(random));
    setState(() {
      _game = _game.copyWith(
        chips: _game.chips - ante,
        cards: cards,
        blind: blind,
        swaps: blind ? 0 : 2,
        stage: RoundStage.playing,
        message: blind
            ? 'Blind hand locked. Reveal it when you are ready.'
            : 'Swap up to two cards, then lock your hand.',
      );
    });
    _save();
  }

  void _swap(int index) {
    if (_game.swaps == 0 || _game.blind) return;
    final random = Random((_game.round * 1009) + (_game.position * 97) + 31 + _game.swaps);
    final cards = [..._game.cards]..[index] = _draw(random);
    setState(() => _game = _game.copyWith(cards: cards, swaps: _game.swaps - 1));
    _save();
  }

  void _lockHand() {
    final result = evaluateHand(_game.cards, blind: _game.blind);
    final win = _game.isBoss ? result.score <= _game.boot : result.score >= _game.boot;
    final anteRefund = max(10, _game.boot ~/ 10);
    final payout = anteRefund + _game.boot ~/ 5 + (_game.swaps * 10);
    setState(() {
      _game = _game.copyWith(
        chips: win ? _game.chips + payout : _game.chips,
        result: result,
        stage: RoundStage.resolved,
        message: _game.isBoss
            ? '${result.title}: ${result.score}. Muflis needs ${_game.boot} or lower.'
            : '${result.title}: ${result.score} vs Boot ${_game.boot}.',
      );
    });
    _save();
  }

  void _continue() {
    final result = _game.result!;
    final win = _game.isBoss ? result.score <= _game.boot : result.score >= _game.boot;
    if (!win) {
      if (_game.chips <= 0) {
        setState(() => _game = _game.copyWith(stage: RoundStage.lost, message: 'Out of chips. The Safar ends here.'));
      } else {
        setState(() => _game = _game.copyWith(
              round: _game.round + 1,
              forcedSeen: false,
              stage: RoundStage.chooseMode,
              clearResult: true,
              message: 'Try again. Blind or Seen?',
            ));
      }
      _save();
      return;
    }
    final next = min(11, _game.position + result.movement);
    var chips = _game.chips;
    var forcedSeen = false;
    var message = 'You moved ${result.movement} spaces to ${board[next].name}.';
    final landed = board[next];
    if (landed.type == SquareType.chest) {
      chips += 150;
      message += ' Chest found: +150 chips!';
    } else if (landed.type == SquareType.nazar) {
      forcedSeen = true;
      message += ' Nazar: your next round is forced Seen.';
    } else if (landed.type == SquareType.rest) {
      chips += 50;
      message += ' You rest and recover 50 chips.';
    } else if (landed.type == SquareType.rival) {
      final rivalScore = 65 + _game.round * 12;
      if (result.score >= rivalScore) {
        chips += 100;
        message += ' You beat the rival ($rivalScore): +100 chips!';
      } else {
        chips = max(0, chips - 80);
        message += ' Rival scored $rivalScore: −80 chips.';
      }
    }
    // Reaching square 12 starts the boss; only winning the boss completes a run.
    final wonGame = _game.isBoss && next == 11 && landed.type == SquareType.boss;
    setState(() {
      _game = _game.copyWith(
        chips: chips,
        position: next,
        round: _game.round + 1,
        forcedSeen: forcedSeen,
        stage: wonGame ? RoundStage.won : RoundStage.chooseMode,
        clearResult: true,
        message: wonGame
            ? 'Raj Mahal reached! You completed Patta Safar.'
            : next == 11 && landed.type == SquareType.boss
                ? 'Muflis Raja awaits. Make a hand scoring 58 or lower.'
                : message,
      );
    });
    _save();
  }

  Future<void> _newRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    setState(() {
      _game = const GameState(
        chips: 1000,
        position: 0,
        round: 1,
        forcedSeen: false,
        stage: RoundStage.chooseMode,
        message: 'A new journey starts at Gully. Blind or Seen?',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PATTA SAFAR'),
        actions: [IconButton(icon: const Icon(Icons.refresh), tooltip: 'New journey', onPressed: _newRun)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _status(game),
              const SizedBox(height: 14),
              _board(game),
              const SizedBox(height: 14),
              Expanded(child: _roundPanel(game)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(GameState game) => Row(
        children: [
          _stat('CHIPS', '${game.chips}', Icons.toll),
          const SizedBox(width: 8),
          _stat(game.isBoss ? 'MUFLIS MAX' : 'BOOT', '${game.boot}', Icons.flag),
          const SizedBox(width: 8),
          _stat('ROUND', '${game.round}', Icons.casino),
        ],
      );

  Widget _stat(String label, String value, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xff123d31), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [Icon(icon, size: 18), Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 10))]),
        ),
      );

  Widget _board(GameState game) => SizedBox(
        height: 120,
        child: GridView.count(
          crossAxisCount: 6,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          children: List.generate(board.length, (index) {
            final current = index == game.position;
            return Container(
              decoration: BoxDecoration(
                color: current ? const Color(0xffd7a52b) : const Color(0xff124a3a),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: index == 11 ? Colors.amber : Colors.transparent),
              ),
              alignment: Alignment.center,
              child: Text(current ? '🪙\n${index + 1}' : '${board[index].icon}\n${index + 1}', textAlign: TextAlign.center),
            );
          }),
        ),
      );

  Widget _roundPanel(GameState game) {
    if (game.stage == RoundStage.won || game.stage == RoundStage.lost) {
      final won = game.stage == RoundStage.won;
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(won ? '🏆 YOU REACHED RAJ MAHAL' : '💨 SAFAR OVER', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(game.message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _newRun, icon: const Icon(Icons.replay), label: const Text('START NEW SAFAR')),
      ]));
    }
    return Column(
      children: [
        Text(game.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 14),
        if (game.stage == RoundStage.playing || game.stage == RoundStage.resolved)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) => _card(game.cards[index], hidden: game.blind && game.stage == RoundStage.playing, onTap: () => _swap(index))),
          ),
        const Spacer(),
        if (game.stage == RoundStage.chooseMode) ...[
          Text(game.forcedSeen ? '🧿 Nazar forces you to play Seen.' : 'Choose your risk', style: const TextStyle(color: Colors.amber)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: game.forcedSeen ? null : () => _startRound(true), child: const Text('BLIND\n×2 SCORE + MOVE', textAlign: TextAlign.center))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () => _startRound(false), child: const Text('SEEN\nSWAP 2 CARDS', textAlign: TextAlign.center))),
          ]),
        ] else if (game.stage == RoundStage.playing)
          FilledButton(
            onPressed: _lockHand,
            child: Text(game.blind ? 'REVEAL BLIND HAND' : 'LOCK HAND  •  ${game.swaps} SWAPS LEFT'),
          )
        else if (game.stage == RoundStage.resolved) ...[
          if (game.result != null) Text('${game.result!.title} • ${game.result!.score} points', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          FilledButton(onPressed: _continue, child: const Text('CONTINUE SAFAR')),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _card(PlayingCard card, {required bool hidden, required VoidCallback onTap}) => InkWell(
        onTap: hidden ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 78,
          height: 112,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hidden ? const Color(0xffb12636) : const Color(0xfff7e9c8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: hidden
              ? const Center(child: Icon(Icons.question_mark, size: 40, color: Colors.white))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(card.label, style: TextStyle(fontSize: 25, color: card.color == Colors.white ? Colors.black : card.color, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Align(alignment: Alignment.bottomRight, child: Text(card.label, style: TextStyle(fontSize: 16, color: card.color == Colors.white ? Colors.black : card.color))),
                ]),
        ),
      );
}
