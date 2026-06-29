import 'package:flutter/material.dart';
import 'game.dart';

void main() {
  runApp(const MainApp());
}

class Tile extends StatelessWidget {
  const Tile(this.letter, this.hitType, {super.key});

  final String letter;
  final HitType hitType;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.bounceIn,
      width: 100.0,
      height: 100.0,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: switch (hitType) {
          HitType.hit => Colors.green,
          HitType.partial => Colors.yellow,
          HitType.miss => Colors.grey,
          _ => Colors.white,
        },
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Game _game = Game();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(height: 30),
          for (var guess in _game.guesses)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var letter in guess)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2.5,
                      vertical: 2.5,
                    ),
                    child: Tile(letter.char, letter.type),
                  ),
              ],
            ),
          SizedBox(height: 30),
          if (_game.didWin)
            const Text(
              'You win!',
              style: TextStyle(fontSize: 24, color: Colors.green),
            )
          else if (_game.didLose)
            Column(
              children: [
                const Text(
                  'You lose!',
                  style: TextStyle(fontSize: 24, color: Colors.red),
                ),
                Text(
                  'The word was: ${_game.hiddenWord}',
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ],
            )
          else
            GuessInput(
              onSubmitGuess: (String guess) {
                if (guess.length != 5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$guess must be 5 letters long.')),
                  );
                  return;
                }
                if (!Word.fromString(guess).isLegalGuess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$guess is not a legal word.')),
                  );
                  return;
                }
                setState(() {
                  _game.guess(guess);
                });
              },
            ),
          if (_game.didWin || _game.didLose)
            Padding(
              padding: EdgeInsetsGeometry.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _game.resetGame();
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  textStyle: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                child: const Text('Play Again'),
              ),
            ),
        ],
      ),
    );
  }
}

class GuessInput extends StatelessWidget {
  GuessInput({super.key, required this.onSubmitGuess});

  final void Function(String) onSubmitGuess;
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _onSubmit() {
    onSubmitGuess(_textEditingController.text.trim());
    _textEditingController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 500,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              maxLength: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              controller: _textEditingController,
              focusNode: _focusNode,
              autofocus: true,
              onSubmitted: (input) {
                _onSubmit();
              },
            ),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_circle_up, color: Colors.white),
          style: IconButton.styleFrom(iconSize: 50),
          onPressed: _onSubmit,
        ),
      ],
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordle',
      home: Scaffold(
        backgroundColor: Colors.indigo.shade800,
        appBar: AppBar(
          foregroundColor: Colors.indigo.shade800,
          title: const Align(
            alignment: Alignment.center,
            child: Text(
              'Wordle',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: Center(child: GamePage()),
      ),
    );
  }
}
