// Travis Shultz, 2014
// 
// crypto - the decryptor
// Uses a hybrid genetic algorithms approach with only mutation.
//
//  
import 'dart:io';
import 'dart:math' as Math;

String empty = "";
String space = " ";

Map adam = {"a": "a", "b": "b", "c": "c", "d": "d", "e": "e", "f": "f",
            "g": "g", "h": "h", "i": "i", "j": "j", "k": "k", "l": "l",
            "m": "m", "n": "n", "o": "o", "p": "p", "q": "q", "r": "r",
            "s": "s", "t": "t", "u": "u", "v": "v", "w": "w", "x": "x",
            "y": "y", "z": "z"};

//onegrams: String frequency = "etaoinshrdlcumwfgypbvkjxqz";
 
String message = """
WQR PTPRD BMCQ MC CVTDD, KRDDZJ, DRRLQ-DMER, TXN SHZPTPDK WQR ZNNRCW WQMXG MX WQR YXMIRHCR. MW BRRNC ZX PHTMXJTIR RXRHGK 
HRLRMIRN XZW BHZV MWC ZJX LTHHMRH, PYW BHZV WQZCR THZYXN MW. MW TPCZHPC TDD YXLZXCLMZYC VRXWTD BHRFYRXLMRC BHZV WQMC 
PHTMXJTIR RXRHGK WZ XZYHMCQ MWCRDB JMWQ. MW WQRX RULHRWRC MXWZ WQR VMXN ZB MWC LTHHMRH T WRDRSTWQML VTWHMU BZHVRN PK 
LZVPMXMXG WQR LZXCLMZYC WQZYGQW BHRFYRXLMRC JMWQ XRHIR CMGXTDC SMLERN YS BHZV WQR CSRRLQ LRXWHRC ZB WQR PHTMX JQMLQ QTC 
CYSSDMRN WQRV. WQR SHTLWMLTD YSCQZW ZB TDD WQMC MC WQTW MB KZY CWMLE T PTPRD BMCQ MX KZYH RTH KZY LTX MXCWTXWDK YXNRHCWTXN 
TXKWQMXG CTMN WZ KZY MX TXK BZHV ZB DTXGYTGR. WQR CSRRLQ STWWRHXC KZY TLWYTDDK QRTH NRLZNR WQR PHTMXJTIR VTWHMU JQMLQ QTC 
PRRX BRN MXWZ KZYH VMXN PK KZYH PTPRD BMCQ.
""";

String justWords;
Set usWords;
List<String> wordsInMessage;
Map ngrams2; // bigrams
Map ngrams3; // trigrams


class Chromosome {
  Map sequence;
  int fitness;
  
  Chromosome (Map str, int score) {
    sequence = new Map.from(str);
    fitness = score;
  }
  
  dump () {
    print ("$sequence\n");
  }
}

main(List<String> args) {
 //message = message2;
  var inFile = new File(args[0]);
  message = inFile.readAsLinesSync();
  
  // Read word dictionary
  var usWordFile = new File ("usdic.txt");
  List<String> wordLines = usWordFile.readAsLinesSync();
 
  usWords = new Set();
  usWords.addAll(wordLines);
  
  // Read bigrams dictionary
  var ngram2File = new File("ngrams2.txt");
  List<String> ngramLines = ngram2File.readAsLinesSync();
  ngrams2 = new Map();
  
  Pattern sp = "\t";
  for (var line in ngramLines) {
    List<String> kv = line.split(sp);
    ngrams2[kv[0]] =  int.parse(kv[1]);
  }
  
  // Read trigrams dictionary
  var ngram3File = new File("ngrams3.txt");
  List<String> ngram3Lines = ngram3File.readAsLinesSync();
  ngrams3 = new Map();
  
//  Pattern sp = "\t";
  for (var line in ngram3Lines) {
    List<String> kv = line.split(sp);
    ngrams3[kv[0]] =  int.parse(kv[1]);
  }
  
  print (ngrams3);

  // Get words from message
  justWords = removePunctuation(message).toLowerCase();

  Pattern space=" ";
  wordsInMessage = justWords.split(space);
  print ("${wordsInMessage.length} words in meessage =\n $wordsInMessage");
  
  bool solved = false;
  Map mutant;
  int theScore = 0;
  int tries = 0;
  int highScore = -1;
  int genSize = 500;
  int generation = 1;
  List<Chromosome> potentials = new List<Chromosome>();

  // Seed initial generation of potentials
  while (potentials.length <= genSize) {
    mutant = shuffle(adam, new Math.Random().nextInt(400));
    theScore = score_nGrams(mutant);
    potentials.add(new Chromosome(mutant, theScore));
  }
  
  // Main loop (timed)
  // New generation = the best + mutate(the best) + randoms
  // i.e. Elitism + Darwin + Diversity  
  Stopwatch stopwatch = new Stopwatch()..start();
  while (!solved) {
    potentials.sort((x, y) => y.fitness.compareTo(x.fitness));

    // Keep best 
    potentials.removeRange(genSize ~/ 3, potentials.length);
    double wordPercent = score(potentials.first.sequence) / wordsInMessage.length;
    double spread = (potentials.first.fitness - potentials.last.fitness) / potentials.first.fitness;
    print ("Generation $generation scores=${potentials.first.fitness}-${potentials.last.fitness}, diversity=${(spread*100).toStringAsPrecision(4)}%, words=${(wordPercent*100).toStringAsPrecision(4)}%");
    print ("${decode(potentials.first.sequence)}\n");
  
    // Mutate high potentials
    for (int i=0; i<genSize ~/ 3; i++) {
      Map newMutant = shuffle(potentials[i].sequence, 1);
      potentials.add(new Chromosome(newMutant, score_nGrams(newMutant)));
    }

    // Start all over if stuck
    if ((potentials.first.fitness == potentials.last.fitness) || // no variation in this generation
        ((spread < 0.03) && (wordPercent < 0.28))) { // 3% variation in generation, 28% valid words
      potentials.clear();
    }
    
    // Add randoms
    mutant = shuffle(adam, 50);
    while (potentials.length <= genSize) {
      mutant = shuffle(adam, new Math.Random().nextInt(3));
      theScore = score_nGrams(mutant);
      potentials.add(new Chromosome(mutant, theScore));
    }
    if (score(potentials.first.sequence) == wordsInMessage.length) {
      solved =  true;
    }
    else {
      generation++;
      tries++;
    }
  }
  Duration duration = stopwatch.elapsed;
  print ("Elapsed ${duration}");
  print("score=${score_nGrams(potentials.first.sequence)}, $tries tries, Key=${potentials.first.sequence}\n");
  print (decode(potentials.first.sequence));
}

int score (Map key) {
  int keyScore = 0;
  List<String> decodedWords = decode(key);
  
  for (var word in decodedWords) {
    if (usWords.contains(word)) {
      keyScore++;
    }
  }
  return keyScore;
}

int score_nGrams (Map key) {
  // ngrams Map
  int keyScore = 0;
  List<String> decodedWords = decode(key);
 
  // Score bigrams
  for (var word in decodedWords) {
    for (int i=0; i<word.length-1; i++) {
      String twoLetters = word.substring(i,i+2);
      if (ngrams2[twoLetters] != null)
        keyScore += ngrams2[twoLetters] ~/ 2858953;
    }
  } 

  // Score trigrams
  for (var word in decodedWords) {
    for (int i=0; i<word.length-2; i++) {
      String threeLetters = word.substring(i,i+3);
      if (ngrams3[threeLetters] != null)
        keyScore += ngrams3[threeLetters] ~/ 6254;
    }
  }
  
  return keyScore;
}

// Returns decoded list of words using the key
List<String> decode(Map theKey) {
  List<String> decoded = new List<String>();
  
  for (String word in wordsInMessage) {
    String thisWord = "";
    for (int i=0; i<word.length; i++) {
      String letter = (word[i]).toLowerCase();
      String decodedLetter = theKey[letter]; 
      thisWord += decodedLetter;
    }
    decoded.add(thisWord);
  }
  
  return decoded;
}

// Swap elements entropy number of times
Map shuffle(Map original, int entropy) {
  Map shuffled = new Map.from(original);
  for (int i=0; i<entropy; i++)
    shuffled = new Map.from(
        swap(shuffled,
            toLetter(new Math.Random().nextInt(26)),
            toLetter(new Math.Random().nextInt(26))));
  
  return shuffled;
}

// swap values for the two keys
Map swap(Map chromo, String part1, String part2) {
  Map newChromosome = new Map.from(chromo);
  newChromosome[part1] = chromo[part2];
  newChromosome[part2] = chromo[part1];

  return newChromosome;
}

// Make the string presentable
String removePunctuation(String text) {
  String justWords = "";
  
  Pattern dash = "-";
  Pattern alpha = new RegExp(r"[^a-zA-Z| ]");//;new RegExp(r'e'), 
  
  justWords = text.replaceAll(dash, " ");
  justWords = justWords.replaceAll(alpha, "");

  return justWords;
}

String toLetter(int code) {
  return new String.fromCharCode(code + 'a'.codeUnitAt(0));
}