import 'package:flutter/material.dart';
import 'calculator.dart';

void main() {
  runApp(const NiuApp());
}

class NiuApp extends StatelessWidget {
  const NiuApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Niu Poker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const NiuHomePage(),
    );
  }
}

class NiuHomePage extends StatefulWidget {
  const NiuHomePage({super.key});
  @override
  State<NiuHomePage> createState() => _NiuHomePageState();
}

class _NiuHomePageState extends State<NiuHomePage> {
  final List<PokerCard> _inputCards = [];
  List<PokerCard> _displayCards = [];
  String _firstRoundText = '';
  String _resultText = '';
  bool _isResultMode = false;
  NiuResult? _currentResult;

  void _addCard(String rankLabel, {bool isSpadeAce = false}) {
    if (_inputCards.length >= 5) return;

    Rank? r = Rank.fromInput(rankLabel);
    if (r == null) return;

    final suit = isSpadeAce ? Suit.spade : Suit.none;
    final newCard = PokerCard(r, suit);

    setState(() {
      _inputCards.add(newCard);
      _syncDisplay();
      _updateFirstRound();
      if (_inputCards.length == 5) {
        _computeBest();
      }
    });
  }

  void _deleteCard() {
    if (_inputCards.isEmpty) return;
    setState(() {
      _inputCards.removeLast();
      _isResultMode = false;
      _currentResult = null;
      _resultText = '';
      _syncDisplay();
      _updateFirstRound();
    });
  }

  void _syncDisplay() {
    if (!_isResultMode) {
      _displayCards = List.from(_inputCards);
    }
  }

  void _updateFirstRound() {
    if (_inputCards.length >= 3) {
      final p = NiuCalculator.firstRoundPoints(_inputCards.take(3).toList());
      // Show 10 instead of 0
      _firstRoundText = 'First round: ${p == 0 ? 10 : p} ${p == 0 ? 'x2' : 'x1'}';
    } else {
      _firstRoundText = '';
    }
  }

  void _computeBest() {
    final res = NiuCalculator.findBest(_inputCards);
    _currentResult = res;
    _isResultMode = true;
    
    if (!res.hasBase) {
      _displayCards = List.from(_inputCards); // No reorder if no base
      _resultText = 'Result: 没有牛';
    } else {
      // Reorder: Base (3) + Last (2)
      final base = res.baseIndices.map((i) => _inputCards[i]).toList();
      final last = res.remainingIndices.map((i) => _inputCards[i]).toList();
      _displayCards = [...base, ...last];
      
      final pointsText = res.points == 0 ? '牛牛' : '牛${res.points}';
      _resultText = 'Result: $pointsText (x${res.multiplier})';
    }
  }

  Widget _buildCardSlot(int index, {double? width, double? height, double? fontSize}) {
    String text = '';
    bool isSpadeAce = false;

    if (index < _displayCards.length) {
      final c = _displayCards[index];
      text = c.rank.label;
      if (c.rank == Rank.a && c.suit == Suit.spade) {
        text = '♠A';
        isSpadeAce = true;
      }
      
      // Check for swapped values (3 <-> 6) in base cards and remaining cards
      if (_isResultMode && _currentResult != null && _currentResult!.hasBase) {
        final originalVal = NiuCalculator.value(c.rank);
        int effectiveVal = originalVal;

        if (index < 3) {
          // Base cards (0, 1, 2)
          if (index < _currentResult!.baseEffectiveValues.length) {
             effectiveVal = _currentResult!.baseEffectiveValues[index];
          }
        } else {
          // Remaining cards (3, 4) - indices in remainingEffectiveValues are 0, 1
          final remIndex = index - 3;
          if (remIndex < _currentResult!.remainingEffectiveValues.length) {
             effectiveVal = _currentResult!.remainingEffectiveValues[remIndex];
          }
        }

        if (originalVal != effectiveVal) {
           // Display as 3(6) or 6(3)
           text = '$text($effectiveVal)';
        }
      }
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: text.isNotEmpty ? Colors.white : Colors.grey[200],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            fontSize: fontSize ?? 24,
            fontWeight: FontWeight.bold,
            color: isSpadeAce ? Colors.black : Colors.blue[900],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label, {VoidCallback? onPressed, Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: onPressed ?? () => _addCard(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(label, style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine layout based on state
    Widget cardsDisplay;
    if (_isResultMode && _currentResult != null && _currentResult!.hasBase) {
      // Split layout: 2 cards on top (Points), 3 cards on bottom (Base)
      // Use Expanded/Flex to maximize size and ensure alignment
      // Top row: Spacer(1), Card(2), Card(2), Spacer(1) -> Cards are 1/3 width each
      // Bottom row: Card(2), Card(2), Card(2) -> Cards are 1/3 width each
      
      cardsDisplay = Column(
          children: [
            // Points row (indices 3, 4)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildCardSlot(3, fontSize: 32),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildCardSlot(4, fontSize: 32),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
            // Base row (indices 0, 1, 2)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildCardSlot(0, fontSize: 32),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildCardSlot(1, fontSize: 32),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildCardSlot(2, fontSize: 32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    } else {
      // Single row layout for input or "No Niu"
      cardsDisplay = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
             return Expanded(
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 4.0),
                 child: AspectRatio(
                   aspectRatio: 0.75,
                   child: _buildCardSlot(i, width: null, height: null, fontSize: 24),
                 ),
               ),
             );
          }),
        );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Niu Poker Calculator')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Cards Display Area - Flexible height
          // Give it a flex factor to occupy more space
          // Always use Expanded for card area to prevent overflow and maximize size
          Expanded(
            flex: 3, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: cardsDisplay,
            ),
          ),
            
          const SizedBox(height: 10),
          // Info Display
          Text(
            _firstRoundText,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 5),
          Text(
            _resultText,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          
          // Use Expanded for keyboard area to push it down but allow resizing
          const Spacer(flex: 1), 
          // Keyboard
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(children: [
                  _buildKey('1'), _buildKey('2'), _buildKey('3')
                ]),
                Row(children: [
                  _buildKey('4'), _buildKey('5'), _buildKey('6')
                ]),
                Row(children: [
                  _buildKey('7'), _buildKey('8'), _buildKey('9')
                ]),
                Row(children: [
                  _buildKey('10'), _buildKey('J'), _buildKey('Q')
                ]),
                Row(children: [
                  _buildKey('K'),
                  _buildKey('♠A', onPressed: () => _addCard('A', isSpadeAce: true)),
                  _buildKey('⌫', onPressed: _deleteCard, color: Colors.red[100]),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

