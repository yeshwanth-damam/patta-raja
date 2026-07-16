import 'package:flutter_test/flutter_test.dart';
import 'package:patta_safar/main.dart';

PlayingCard card(int rank, Suit suit) => PlayingCard(rank, suit);

void main() {
  group('Teen Patti hand evaluator', () {
    test('ranks trail above every other hand', () {
      final result = evaluateHand([
        card(7, Suit.hearts),
        card(7, Suit.clubs),
        card(7, Suit.spades),
      ]);

      expect(result.kind, HandKind.trail);
      expect(result.movement, 6);
      expect(result.score, 121);
    });

    test('recognizes ace-low pure sequences', () {
      final result = evaluateHand([
        card(14, Suit.hearts),
        card(2, Suit.hearts),
        card(3, Suit.hearts),
      ]);

      expect(result.kind, HandKind.pureSequence);
      expect(result.movement, 5);
    });

    test('blind doubles score and adds movement', () {
      final seen = evaluateHand([
        card(10, Suit.hearts),
        card(10, Suit.clubs),
        card(4, Suit.spades),
      ]);
      final blind = evaluateHand([
        card(10, Suit.hearts),
        card(10, Suit.clubs),
        card(4, Suit.spades),
      ], blind: true);

      expect(blind.score, seen.score * 2);
      expect(blind.movement, seen.movement + 1);
    });
  });
}
