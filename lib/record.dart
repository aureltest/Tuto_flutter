import 'game.dart';

class Record {
  final String hiddenWord;
  final String lastGuess;
  final bool isWin;
  final int score;
  

  Record({required this.hiddenWord, required this.lastGuess, required this.isWin, required this.score});

  Map<String, dynamic> toJson() {
    return {
      'hiddenWord': hiddenWord,
      'lastGuess': lastGuess,
      'isWin': isWin,
      'score': score,
    };
  }

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      hiddenWord: json['hiddenWord'] as String,
      lastGuess: json['lastGuess'] as String,
      isWin: json['isWin'] as bool,
      score: json['score'] as int,
    );
  }
}

