# Patta Safar

An offline, single-player Teen Patti roguelike mobile game prototype. Win hands to
move across a 12-square journey from Gully to Raj Mahal.

## Included MVP

- Teen Patti 3-card evaluator, including A-2-3 sequences
- Blind (double score and movement) and Seen (two swaps) decisions
- Chips, antes, Boot targets, wins, and busts
- 12-square board with rivals, chests, Nazar, Chaal rest, and Muflis Raja
- Local automatic save/resume

## Run locally

Install the Flutter SDK, then run:

```bash
flutter pub get
flutter run
```

Run the evaluator tests with:

```bash
flutter test
```

This prototype intentionally excludes real-money features, ads, auctions, partners,
and multiplayer. Chips are gameplay-only virtual currency.
