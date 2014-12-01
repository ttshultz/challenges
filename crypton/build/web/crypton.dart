// Travis Shultz, 2014
// 
// crypton - the decryptor
//
// Uses a hybrid genetic algorithms approach with only mutation.
// Also uses ngrams and basic word lookup.

import 'dart:html';
import 'dart:async';
import 'dart:math' as Math;

String justWords; // String of ords in message (alphabetic only)
Set usWords; // Set of valid US words
List<String> wordsInMessage; // List of words in the message
String message; // Raw input message

// nGrams - Common English ngrams - read from uri
Map ngrams3; // trigrams

Map adam = {"a": "a", "b": "b", "c": "c", "d": "d", "e": "e", "f": "f",
         "g": "g", "h": "h", "i": "i", "j": "j", "k": "k", "l": "l",
         "m": "m", "n": "n", "o": "o", "p": "p", "q": "q", "r": "r",
         "s": "s", "t": "t", "u": "u", "v": "v", "w": "w", "x": "x",
         "y": "y", "z": "z"};

// UI
TextAreaElement taMessage; // message to decode
ButtonElement btnDecode; // the Decode button
Element solution; // Where to output the solution
Element stats; // reportable statistics\
Element keyOut; // key
Element elapsed; // Elapsed time output

List<String> inputMessage; // Input message

// Chromosome class
class Chromosome {
  Map sequence;
  int fitness;
  
  Chromosome (Map str, int score) {
   sequence = new Map.from(str);
   fitness = score;
  }
}

// Read in dictionaries and ngrams
// Setup UI events for decrypting
void main() {
// Obtain input elements
taMessage = querySelector("#message");
btnDecode = querySelector("#btnDecode");
solution = querySelector("#solution");
stats = querySelector("#stats");
keyOut = querySelector("#keyOut");
elapsed = querySelector("#elapsed");

// Read word dictionary
HttpRequest.getString("usdic.txt")
 .then(getDictionary)
 .catchError(handleError);

// Read trigrams dictionary
HttpRequest.getString("ngrams3.txt")
 .then(getTrigrams)
 .catchError(handleError);

// Setup UI events
btnDecode.onClick.listen((e) => onDecodeClicked());
}

void handleError(Error error) {
  print(error);
}

// Reads US Dictionary of words into usWords Set
getDictionary (String dict) {
  List<String> wordLines = new List<String>();
  wordLines = dict.trim().split("\r\n");
  usWords = new Set();
  usWords.addAll(wordLines);
}

// Reads trigrams
getTrigrams (String trigrams) {
  List<String> ngramLines = new List<String>();
  ngramLines = trigrams.trim().split("\r\n");
  ngrams3 = new Map();
  
  Pattern sp = "\t";
  for (var line in ngramLines) {
   List<String> kv = line.split(sp);
   ngrams3[kv[0]] =  int.parse(kv[1]);
  }
}

void onDecodeClicked() {
  onMessageChanged();
}  

bool solved = false;
Map mutant;
int theScore = 0;
int tries = 0;
int genSize = 700;
int civilization = 1;
int generation = 1;
List<Chromosome> potentials = new List<Chromosome>();
Stopwatch stopwatch;

void onMessageChanged() {
  solved=false;
  message = taMessage.value;
  generation = 1;
  civilization = 1;

  potentials = new List<Chromosome>();

  // Get words from message
  justWords = removePunctuation(message).toLowerCase();
  
  Pattern space=" ";
  wordsInMessage = justWords.split(space);

  // Seed initial generation of potential chromosomes
  while (potentials.length <= genSize) {
    mutant = shuffle(adam, new Math.Random().nextInt(400));
    theScore = score_nGrams(mutant);
    potentials.add(new Chromosome(mutant, theScore));
  }

  // Main loop (timed)
  // New generation = the best + mutate(the best)
  // i.e. Elitism + Darwin
  stopwatch = new Stopwatch()..start();
  DivElement newChild;
  new Timer(new Duration(milliseconds:500), () => nextGeneration()); // timer used to free up UI rendering
}

Duration duration;
// Gets the next generation of potential chromosomes (usually) based on the current generation.
void nextGeneration() {
  potentials.sort((x, y) => y.fitness.compareTo(x.fitness));
  
  // Keep best (elitist)
  potentials.removeRange(genSize ~/ 2, potentials.length);
  double wordPercent = score(potentials.first.sequence) / wordsInMessage.length;
  double spread = (potentials.first.fitness - potentials.last.fitness) / potentials.first.fitness;
  String outStats = "Civilization $civilization, Generation $generation scores=${potentials.first.fitness}-${potentials.last.fitness}, diversity=${(spread*100).toStringAsPrecision(4)}%, words=${(wordPercent*100).toStringAsPrecision(4)}%";
  keyOut.innerHtml = "${potentials.first.sequence}";
  String firstSolutionText ="${decode(potentials.first.sequence)}\n"; 

  String decodedMsg = decodeOriginalMessage(potentials.first.sequence);
  solution.innerHtml = emphasizeWords(decodedMsg);
  stats.text=outStats;

  duration = stopwatch.elapsed;
  elapsed.text= "Elapsed Time: ${duration}";
    
  // Start  over if stuck - i.e. start a new civilization based on new chromosomes
  if (((potentials.first.fitness == potentials.last.fitness) || // no variation in this generation
      ((spread < 0.0001) && (wordPercent < 0.28)))) { // 3% variation in generation, 28% valid words
    potentials.clear();
    civilization++; // wipe out the civilization and start anew 
    generation = 1;

    // Add randoms (diversity)
    mutant = shuffle(adam, 50);
    while (potentials.length <= genSize) {
      mutant = shuffle(adam, new Math.Random().nextInt(3)+1);
      theScore = score_nGrams(mutant);
      potentials.add(new Chromosome(mutant, theScore));
    }
  }
  // Mutate high potentials (darwin)
  int i=0;
  while (potentials.length <= genSize) {
    Map newMutant = shuffle(potentials[i].sequence, new Math.Random().nextInt(3)+1);
    potentials.add(new Chromosome(newMutant, score_nGrams(newMutant)));
    i++;
  }
  if (wordPercent > 0.99) { 
    solved =  true;
  }
  else {
    generation++;
    tries++;
  }
  
  if (solved == true) {
    Duration duration = stopwatch.elapsed;
    elapsed.text= "COMPLETED IN: ${duration}";
    solution.innerHtml = "<em>" + decodedMsg + "</em>";
  }
  else {
    new Timer(new Duration(milliseconds:3), () => nextGeneration());
  }
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

// Scores the message with the given key based on trigrams
int score_nGrams (Map key) {
  // ngrams Map
  int keyScore = 0;
  List<String> decodedWords = decode(key);

  // Score trigrams
  for (var word in decodedWords) {
    for (int i=0; i<word.length-2; i++) {
      String threeLetters = word.substring(i,i+3);
      if (ngrams3[threeLetters] != null)
        keyScore += log2(ngrams3[threeLetters]);
    }
  }
  return keyScore;
}

// log base 2. Not built-in.
int log2 (int n) {
  int bits = 0;
  while (n > 0) {
    bits++;
    n >>= 1;
  }
  return bits;
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
  Pattern alpha = new RegExp(r"[^a-zA-Z| ]");
  
  justWords = text.replaceAll(dash, " ");
  justWords = justWords.replaceAll(alpha, "");
  
  return justWords;
}

String toLetter(int code) {
  return new String.fromCharCode(code + 'a'.codeUnitAt(0));
}

// Decode the original message
String prevDecodedMessage = "";
String decodeOriginalMessage (Map<String,String> key) {
  String decodedText="";
  
  for (int i=0; i<message.length; i++) {
    String character = message[i].toLowerCase();
    if (key[character] != null) {
      decodedText += key[character].toUpperCase();
    }
    else {
      decodedText += character.toUpperCase(); 
    }
  }
  prevDecodedMessage=decodedText;
  return decodedText;
}

// Highlights words from dictionary
String emphasizeWords(String text) {
  String returnString = "";
  String nextWord = "";
  bool inWord = false;
  String character = "";
  
  for (int i=0; i<text.length; i++) {
    character = text[i].toLowerCase();
    if (character.contains(new RegExp(r'[a-z]')) == true) {
      inWord = true;
      nextWord += character;
    }
    else {
      if (nextWord.length > 0 ) {
        inWord = false;
        
        // Highlight a valid word in the output (this makes it show green. The <em> is styled in the .css)
        if (usWords.contains(nextWord)) {
          returnString += "<em>" + nextWord.toUpperCase() + "</em>";
          nextWord = "";
        }
        else {
          returnString += nextWord.toUpperCase();
          nextWord = "";
        }
      }
      returnString += character;
    }
  }   
  if (nextWord.length>0)
    returnString += nextWord.toUpperCase();
  return returnString;
}