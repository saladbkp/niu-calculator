class Suit {
  final String label;
  const Suit._(this.label);
  static const none = Suit._('None');
  static const spade = Suit._('Spade');
  static const heart = Suit._('Heart');
  static const diamond = Suit._('Diamond');
  static const club = Suit._('Club');
  static const all = [none, spade, heart, diamond, club];
}

class Rank {
  final String label;
  const Rank._(this.label);
  static const a = Rank._('1');
  static const two = Rank._('2');
  static const three = Rank._('3');
  static const four = Rank._('4');
  static const five = Rank._('5');
  static const six = Rank._('6');
  static const seven = Rank._('7');
  static const eight = Rank._('8');
  static const nine = Rank._('9');
  static const ten = Rank._('10');
  static const j = Rank._('J');
  static const q = Rank._('Q');
  static const k = Rank._('K');
  static Rank? fromInput(String input) {
    final s = input.trim().toUpperCase();
    switch (s) {
      case '1':
      case 'A':
        return a;
      case '2':
        return two;
      case '3':
        return three;
      case '4':
        return four;
      case '5':
        return five;
      case '6':
        return six;
      case '7':
        return seven;
      case '8':
        return eight;
      case '9':
        return nine;
      case '10':
      case 'T':
        return ten;
      case 'J':
        return j;
      case 'Q':
        return q;
      case 'K':
        return k;
      default:
        return null;
    }
  }
}

class PokerCard  {
  final Rank rank;
  final Suit suit;
  const PokerCard (this.rank, this.suit);
}

class NiuResult {
  final bool hasBase;
  final List<int> baseIndices;
  final List<int> remainingIndices;
  final List<int> baseEffectiveValues;
  final List<int> remainingEffectiveValues;
  final int points;
  final int multiplier;
  const NiuResult(this.hasBase, this.baseIndices, this.remainingIndices, this.points, this.multiplier, {this.baseEffectiveValues = const [], this.remainingEffectiveValues = const []});
}

class NiuCalculator {
  static int value(Rank r) {
    if (r == Rank.j || r == Rank.q || r == Rank.k || r == Rank.ten) return 10;
    if (r == Rank.a) return 1;
    if (r == Rank.two) return 2;
    if (r == Rank.three) return 3;
    if (r == Rank.four) return 4;
    if (r == Rank.five) return 5;
    if (r == Rank.six) return 6;
    if (r == Rank.seven) return 7;
    if (r == Rank.eight) return 8;
    if (r == Rank.nine) return 9;
    return 0;
  }
  static List<int> baseValuesWithSwap(Rank r) {
    if (r == Rank.three) return [3, 6];
    if (r == Rank.six) return [6, 3];
    return [value(r)];
  }
  static int firstRoundPoints(List<PokerCard> cards3) {
    final s = cards3.fold<int>(0, (acc, c) => acc + value(c.rank));
    return s % 10;
    }
  static NiuResult findBest(List<PokerCard> cards5) {
    NiuResult? best;
    final n = cards5.length;
    final indices = List<int>.generate(n, (i) => i);
    for (var i = 0; i < n - 2; i++) {
      for (var j = i + 1; j < n - 1; j++) {
        for (var k = j + 1; k < n; k++) {
          final triple = [cards5[i], cards5[j], cards5[k]];
          final vals = triple.map((c) => baseValuesWithSwap(c.rank)).toList();
          var baseOk = false;
          List<int> effectiveValues = [];
          
          void dfs(int idx, int sum, List<int> currentValues) {
            if (baseOk) return;
            if (idx == 3) {
              if (sum % 10 == 0) {
                baseOk = true;
                effectiveValues = List.from(currentValues);
              }
              return;
            }
            for (final v in vals[idx]) {
              currentValues.add(v);
              dfs(idx + 1, sum + v, currentValues);
              currentValues.removeLast();
              if (baseOk) return;
            }
          }
          dfs(0, 0, []);
          
          // Base found. Now optimize remaining cards.
          // BUT: We should only proceed if a base was actually found!
          if (!baseOk) continue;

          final rem = indices.where((x) => x != i && x != j && x != k).toList();
          final c1 = cards5[rem[0]];
          final c2 = cards5[rem[1]];
          
          final v1s = baseValuesWithSwap(c1.rank);
          final v2s = baseValuesWithSwap(c2.rank);
          
          int bestP = -1;
          int bestComparableP = -1;
          List<int> bestRemainingEffectiveValues = [];
          
          // Find best points for this base considering swaps in remaining cards
          for (final v1 in v1s) {
            for (final v2 in v2s) {
              final s = v1 + v2;
              final p = s % 10;
              final comp = p == 0 ? 10 : p;
              if (comp > bestComparableP) {
                bestComparableP = comp;
                bestP = p;
                bestRemainingEffectiveValues = [v1, v2];
              }
            }
          }
          
          // Calculate multiplier
          // Use bestP to detect Niu Niu (0) which might be formed via swaps
          int m = multiplierFor(c1, c2, points: bestP);

          // Combine effective values for base and remaining for result storage
          // Note: NiuResult currently only has baseEffectiveValues. 
          // We can append remaining ones if we want to display them, 
          // but NiuResult definition might need update or we just store base ones.
          // For now, let's just use baseEffectiveValues as per existing class, 
          // but we might want to extend it later if we want to show brackets for remaining cards.
          // Actually, let's stick to existing class structure to minimize breakage,
          // but wait, if we don't store effective values for remaining cards,
          // the UI won't know to show "3(6)".
          // The user complained about the calculation ("2+3->6=8"), not the UI.
          // But seeing "2 3" and "Niu 8" is confusing.
          // I should probably update NiuResult to store all effective values.
          
          // However, NiuResult constructor only takes baseEffectiveValues.
          // Let's check NiuResult definition again.
          // line 78: const NiuResult(..., {this.baseEffectiveValues = const []});
          
          // I will update NiuResult to include remainingEffectiveValues.
          
          final cand = NiuResult(true, [i, j, k], rem, bestP, m, baseEffectiveValues: effectiveValues, remainingEffectiveValues: bestRemainingEffectiveValues);
          
          if (best == null) {
            best = cand;
          } else {
             // Compare using 10 for Niu Niu (0)
             final bestComp = best!.points == 0 ? 10 : best!.points;
             final candComp = cand.points == 0 ? 10 : cand.points;
             
            if (candComp > bestComp) {
              best = cand;
            } else if (candComp == bestComp && cand.multiplier > best!.multiplier) {
              best = cand;
            }
          }
        }
      }
    }
    if (best == null) {
      return NiuResult(false, const [], const [], 0, 0);
    }
    return best!;
  }
  
  static int multiplierFor(PokerCard a, PokerCard b, {int? points}) {
    final sameRank = a.rank == b.rank;
    final hasSpadeAceWithFace = hasSpadeAceAndFace(a, b);
    
    if (hasSpadeAceWithFace) return 5;
    if (sameRank) return 3;
    
    // If points is 0 (Niu Niu) or sumExact is 10 (legacy check)
    final sumExact = value(a.rank) + value(b.rank);
    if ((points != null && points == 0) || sumExact == 10) return 2;
    
    return 1;
  }
  static bool hasSpadeAceAndFace(PokerCard a, PokerCard b) {
    bool isFace(Rank r) => r == Rank.j || r == Rank.q || r == Rank.k;
    final cond1 = a.rank == Rank.a && a.suit == Suit.spade && isFace(b.rank);
    final cond2 = b.rank == Rank.a && b.suit == Suit.spade && isFace(a.rank);
    return cond1 || cond2;
  }
}

