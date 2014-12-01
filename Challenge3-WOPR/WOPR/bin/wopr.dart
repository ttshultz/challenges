// Battleship Client
// Attempt #4
//
// by Travis Shultz 2014
//
// Useful only with a server application (wopr.exe)
//
// Asynchronously communicates with Wopr server
// Scores the entire board before each guess checking for possible ship placements.
//
// This is a horrible mess. Sorry, but just don't have time to clean it up.
//
// To play more games, Change gamesToPlay variable

import 'dart:io';
import 'dart:async';

// State of the Game
int gamesToPlay = 50; // <===== How many games to play in a row
int wins = 0;
int games = 1;
String prevGuess = ''; // The position of the previous guess
int cntGuesses = 1; // Number of guesses so far
Map guessByLocation = new Map ();   // (location, shot number) A0 => 1
Map guessByShotNumber = new Map (); // (shot number, location) 1 => A0
bool finished = false; // Game finished
bool win = false; // Did we win?
bool socketOpen = false; // Is the TCP socket open?
dynamic mySocket; // handle to the WOPR Server
Map board = new Map(); // Status of the board. For each position: Hit/Miss/Sunk
int totalGuessesForWins = 0; // Used only to calculate average guesses per game for wins

// Status of a particular position in the ocean
String MISS = 'M';
String UNKNOWN = 'U';
String SUNK = 'S';
String HIT = 'H';

// Indexes for the Ships List
int CARRIER = 0;
int BATTLESHIP = 1;
int CRUISER = 2;
int SUBMARINE = 3;
int DESTROYER = 4;

// Keep track of whether ships are sunk and how big they are
class Ship {
  String type;
  num size;
  bool sunk;
  
  Ship(this.type, this.size, this.sunk);
}

// List of the 5 ships
List<Ship> Ships = [];

// A single Grid Square - Convenience class for conversions to strings
class Grid {
  int row;
  int col;
  String pos; // String representation (e.g. A0)
  int score;
  
  Grid.fromColRow(this.col, this.row) {
    pos = new String.fromCharCode(col + ('A'.codeUnitAt(0))) + row.toString();
    score = 0;
  }

  Grid.fromString(this.pos) {
    col = pos.codeUnitAt(0) - 'A'.codeUnitAt(0);
    row = int.parse(pos.substring(1));
    score = 0;
  }
  toString() {
    return pos;
  }
}

// Reset for a New Game
void Init() {
  
  // Initialize Ships
  Ships.removeWhere((e) => true);
  
  Ship s;
  
  s = new Ship('Carrier', 5, false);
  Ships.add(s);
  
  s = new Ship('Battleship', 4, false);
  Ships.add(s);
  
  s = new Ship('Cruiser', 3, false);
  Ships.add(s);
  
  s = new Ship('Submarine', 3, false);
  Ships.add(s);
  
  s = new Ship('Destroyer', 2, false);
  Ships.add(s);
  
  // Initialize Board
  board.clear();
  board = new Map();
  for (int row=0; row<10; row++) {
    for (int col=0; col<10; col++) {
       String thisPosition = new Grid.fromColRow(col, row).toString();
       board[thisPosition] = UNKNOWN;
    }
  }
  
  // Clear Guesses
  guessByShotNumber.clear();
  guessByLocation.clear();
  cntGuesses = 1;
  prevGuess = '';
  win = false;
}

// Main
// - Connect to the Server
// - Start the game
// - Start asynchronous I/O to make a single guess
void main(List<String> args) {
  
  Init();
  dynamic socket;

  // Connect to TCP Server
  Socket.connect("127.0.0.1", 20000).then((socket) {
    mySocket = socket;
    print('Connected to: '
        '${socket.remoteAddress.address}:${socket.remotePort}');
    socketOpen = true;

    socket.listen((data) {
      onMsgReceived(new String.fromCharCodes(data).trim());
    },
    onDone: () {
      print ("Done");
      socket.destroy();
      socketOpen = false;
    });

    // Start Battleship
    String end9 = '\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n';
    String play=' PLAY BATTLESHIP' + end9;

    socket.write(play);

    delay(2000);
    print('Playing ${gamesToPlay} games');
    print ('Change value of variable ${gamesToPlay} in wopr.dart to adjust the number of games');

    // Set timer (asynchronous) for the "guesser" function
    new Timer(new Duration(milliseconds:500), () => guesser());
  });
}

// Guesser makes one guess each time it is called.
// Subsequent calls are done via a timer at the end of the function.
void guesser () {
  List<String> cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];

  // Make a Guess
  // Make a guess based on nearby hits
  if ((cntGuesses<70) && (finished == false)){
    String guess = nextGuess();
    // Send guess to server
    mySocket.write(Shoot(guess));

    //And record it
    guessByLocation[guess] = cntGuesses.toString();
    guessByShotNumber[cntGuesses.toString()] = guess;
    cntGuesses++;
    prevGuess=guess;
  }

  // Game Finished. Report Win/Loss
  if (finished == true) {
    if (win == true) {
//      print ('I Sank Your Battleship!');
      wins++;
    }
    print ('${wins} Wins ${games-wins} Losses');
    games++;
  }
  else if (cntGuesses>100) {
    // This never happens, but just in case
    finished = true;
    print ('Shots exceeded but no win/lose message received.');
  }

  if (finished == false)
    new Timer(new Duration(milliseconds:70), () => guesser()); //Time between guesses (for server and async i/o)
  else {
    // Game won or lost, so close old game
    delay(1000);
    String msgQuit = " QUIT XXXXXXXXXXXXXXXXXXXXXXXXXXX";
    mySocket.write(msgQuit);

    if (games <= gamesToPlay)
    {
      // Start next game
      delay(2000);
      String end9 = '\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n';
      String play=' PLAY BATTLESHIP' + end9;
      mySocket.write(play);    
      delay(1000);
      
      finished = false;
      Init();
      
      // Start over with guessing
      new Timer(new Duration(milliseconds:500), () => guesser());
    }
  }
}

// General Delay function (sleep) to deal with async and slow server startup
void delay (int milliseconds) {
  int beginTime = new DateTime.now().millisecondsSinceEpoch;
  while (new DateTime.now().millisecondsSinceEpoch - beginTime < milliseconds){}
}

// Endline codes required for server
String end12 = '\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n';

// Data received from server
// Hit, Miss, Win, Loss
void onMsgReceived(String msg) {
  //print(msg);

  // TODO: There's a better way of doing this...(i.e. list of RegEx)
  RegExp regexHit  = new RegExp(r'(\d+) HIT');
  RegExp regexMiss = new RegExp(r'(\d+) MISS');
  RegExp regexLoss = new RegExp(r'YOU_LOSE');
  RegExp regexWin  = new RegExp(r'SUNK_MY_BATTLESHIP');
  RegExp regexCarrier = new RegExp(r'CARRIER_SUNK');
  RegExp regexCruiser = new RegExp(r'CRUISER_SUNK');
  RegExp regexSubmarine = new RegExp(r'SUBMARINE_SUNK');
  RegExp regexDestroyer = new RegExp(r'DESTROYER_SUNK');
  RegExp regexBattleship = new RegExp(r'BATTLESHIP_SUNK');

  // A HIT (e.g. 59 HIT)
  Match matchHit = regexHit.firstMatch(msg);
  if (matchHit != null) {
    String guessNumber = matchHit.input.substring(matchHit.start,matchHit.end).split(' ').first;
    if (guessByShotNumber[guessNumber] != null) {
      String hit = guessByShotNumber[guessNumber];
      board[hit] = HIT; 
  //    print ('Marked ${hit} = HIT');
    }
  }

  // A MISS
  Match matchMiss = regexMiss.firstMatch(msg);
  if (matchMiss != null) {
    //print (matchMiss.input.substring(matchMiss.start,matchMiss.end).split(' ').first + " MISS found");
    String guessNumber = matchMiss.input.substring(matchMiss.start,matchMiss.end).split(' ').first;
    //print ('-- ${guessNumber}, ${guessByShotNumber[guessNumber]}');
    if (guessByShotNumber[guessNumber] != null) {
      String miss = guessByShotNumber[guessNumber];
      board[miss] = MISS;
      //print ('Marked ${miss} = MISS');
    }
  }

  Match matchShip = regexCarrier.firstMatch(msg);
  if (matchShip != null) {
    //print ("* CARRIER SUNK *");
    Ships[CARRIER].sunk = true;
    markSunk(5);
  }

  Match matchBattleship = regexBattleship.firstMatch(msg);
  if (matchShip != null) {
    //print ("* BATTLESHIP SUNK *");
    Ships[BATTLESHIP].sunk = true;
    markSunk(4);    
  }

  matchShip = regexCruiser.firstMatch(msg);
  if (matchShip != null) {
    //print ("* CRUISER SUNK *");
    Ships[CRUISER].sunk = true;
    markSunk(3);    
  }

  matchShip = regexSubmarine.firstMatch(msg);
  if (matchShip != null) {
    //print ("* SUBMARINE SUNK *");
    Ships[SUBMARINE].sunk = true;
    markSunk(3);    
  }
/* Not needed. The Server lies and is mis-reporting the destroyer sunk when it's not
  Match matchDestroyer = regexDestroyer.firstMatch(msg);
  if (matchShip != null) {
    print ("* DESTROYER SUNK *");
    Ships[DESTROYER].sunk = true;
    markSunk(2);    
  }
*/
  
  // Lost the Match (server informed us)
  Match matchLoss = regexLoss.firstMatch(msg);
  if (matchLoss != null) {
  //  print ("* MATCH LOSS RECEIVED *");
    finished = true;
    win = false;
  }

  // Won the Match (server informed us)
  Match matchWin = regexWin.firstMatch(msg);
  if (matchWin != null) {
    //print ("* MATCH WIN RECEIVED *");
    finished = true;
    win = true;
  }

}

int sizeOfSmallestRemainingShip() {
  int i = 4;
  
  while ((i>=0) && (Ships[i].sunk == true)) {
    i--;
  }
  
  if (i>=0) {
   // print ('smallest ship = ${Ships[i].size}');
    return Ships[i].size;
  }
  else
    return 2;
}

// Format a "SHOOT" message for server for a particular location
String Shoot(String loc) {
  String shot = ' SHOOT ' + loc + end12;
  return shot;
}

//  find contiguous hits of length matching sunk ship that was hit last.
//  mark those hits as sunk
void markSunk (int size) {
  Grid priorGuess = new Grid.fromString(prevGuess);
  String hits = r'';
  for (int i=0; i<size; i++)
    hits += r'H';

  RegExp regexHits = new RegExp(hits);
  
  String sunkRow = rowAsString(priorGuess.row);
  String sunkCol = colAsString(priorGuess.col);
  
  Match matchRow = regexHits.firstMatch(sunkRow);
  if (matchRow != null) {
    if ((priorGuess.col >= matchRow.start) && (priorGuess.col < matchRow.end)) {
      for (int j=matchRow.start; j<matchRow.end; j++) {
        Grid markCellSunk = new Grid.fromColRow(j, priorGuess.row); // mark all columns sunk
        board[markCellSunk.toString()] = SUNK;
      }
      //print ('Sunk size=${size}, Row ${sunkRow}, Cols=${matchRow.start}-${matchRow.end-1}');
      //print ("Row Now '${rowAsString(priorGuess.row)})'");
    }
  }
  
  Match matchCol = regexHits.firstMatch(sunkCol);
  if (matchCol != null) {
    if ((priorGuess.row >= matchCol.start) && (priorGuess.row < matchCol.end)) {
      for (int j=matchCol.start; j<matchCol.end; j++) {
        Grid markCellSunk = new Grid.fromColRow(priorGuess.col, j); // mark all rows sunk
        board[markCellSunk.toString()] = SUNK;
      }
     // print ('Sunk size=${size}, Col ${sunkCol}, Rows=${matchCol.start}-${matchCol.end-1}');
     // print ("Col Now '${colAsString(priorGuess.col)})'");
    }
  }
}

// Convert to string for debugging
String rowAsString(int row) {
  String returnRow = '';
  
  for (int i=0; i<=9; i++) {
    returnRow += board[new Grid.fromColRow(i, row).toString()];    
  }
  
  return returnRow;
}

// Convert to string for debugging
String colAsString(int col) {
  String returnCol = '';
  
  for (int i=0; i<=9; i++) {
    returnCol += board[new Grid.fromColRow(col, i).toString()];    
  }
  
  return returnCol;
}

// Returns a score for placement of a ship of given size at the given position.
int scorePlacement(String pos, int size) {
  Grid square = new Grid.fromString(pos);
  
  int totalScore = 1;

  // Score all potential Horizontal placements
  int startPoint = square.col - size + 1;
  startPoint = startPoint.clamp(0, 10 - size);
  int endPoint = square.col + size - 1;
  endPoint = endPoint.clamp(startPoint, 9);

  int i = startPoint;
  bool obstructed = false;
  // For each possible unobstructed horizontal placement
  if (startPoint > endPoint)
    print ("*** ERROR startpoint > endpoint ***");
  
  while ((i<=endPoint) && (!obstructed)) {
    int score = 0;
    for (int j=0; j<size; j++) {
      Grid shipSegment = new Grid.fromColRow(i+j, square.row);
      if (board[shipSegment.toString()] == SUNK){
        obstructed = true; score = 0;
      }
      else if (board[shipSegment.toString()] == HIT) {
        score += 100; // hits get heavier score placement
      }
      else {
        score++;
      }
    }
    totalScore += score;
    obstructed = false;
    i++;
  }

  // Score all potential Vertical placements
  // TODO: Refactor duplicated horizontal code
  startPoint = square.row - size + 1;
  startPoint = startPoint.clamp(0, 10 - size);
  endPoint = square.row + size - 1;
  endPoint = endPoint.clamp(startPoint, 9);

  i = startPoint;
  obstructed = false;
  // For each possible unobstructed vertical placement
  if (startPoint > endPoint)
    print ("*** ERROR startpoint > endpoint Vert ***");
  while ((i<=endPoint) && (!obstructed)) {
    int score = 0;
    for (int j=0; j<size; j++) {
      Grid shipSegment = new Grid.fromColRow(square.col, i+j); // Varies row
      if (board[shipSegment.toString()] == SUNK){
        obstructed = true; score = 0;
      }
      else if (board[shipSegment.toString()] == HIT) {
        score += 100; // hits get heavier score placement
      }
      else {
        score++;
      }
    }
    totalScore += score;
    obstructed = false;
    i++;
  }
  
  // Use checkered search pattern
  // Should use sizeOfSmallestRemainingShip(), but the server lies, so 2 is the best we can do.
  if ((square.col + square.row)%2 == 0)
    totalScore *= 2;
  
  return totalScore;
}

// Scores each cell on the board based on likelihood of containing a good guess.
// Returns the cell with the best score.
String nextGuess () {
  String bestGuess = 'Z9';
  int bestScore = -1;

  List<Grid> scoreGrids = [];
  
  // Score every square on the board. Keep the one with the best score as our best guess.
  for (int row=0; row<10; row++) {
    for (int col=0; col<10; col++) {
      String scorePosition = new Grid.fromColRow(col, row).toString();
      String status = board[scorePosition]; // What happened? hit, miss, sunk, unvisited
      if (status != null) {
        if ((status != MISS) && (status != SUNK) && (status != HIT)) {
          int score = 0;
          Ships.forEach((ship) {
            if (ship.sunk == false) {
              score += scorePlacement(scorePosition, ship.size);
            }
          });
          if ((score > bestScore) && (scorePosition != bestGuess)) {
            bestScore = score;
            bestGuess = scorePosition;
          }
        }
      }
      else
        print ("********** Position ${scorePosition} is NULL"); // debug
    }
  }
  
  if (justDestroyerOrBattleshipLeft == true)
    print ('Best Guess ${bestGuess} (Score: ${bestScore})'); // debug
  
  return bestGuess;
}

bool justDestroyerOrBattleshipLeft() {
  if ((Ships[CARRIER].sunk == true) && (Ships[CRUISER].sunk == true) && (Ships[SUBMARINE].sunk == true))
    return true;
  else
    return false;
}

// Return Next letter or number
String next(String item) {
  // Next letter for A - J
  int charVal = item.codeUnitAt(0); 
  if ((charVal >= 'A'.codeUnitAt(0)) && (charVal<'J'.codeUnitAt(0)))
    return new String.fromCharCode(charVal + 1);
  else if (item == 'J')
    return null;
  
  // Next Number
  int i = int.parse(item);
  if ((i>=0) && (i<9))
    return (i+1).toString();

  // Return null for unknown characters and '9'
  return null;
}

// Return Previous letter or number
String prev(String item) {
  // Prev letter for A - J
  int charVal = item.codeUnitAt(0); 
  if ((charVal > 'A'.codeUnitAt(0)) && (charVal<='J'.codeUnitAt(0)))
    return new String.fromCharCode(charVal -1);
  else if (item == 'A')
    return null;
  
  // Next Number
  int i = int.parse(item);
  if ((i>0) && (i<=9))
    return (i-1).toString();

  // Return null for unknown characters and '0'
  return null;
}
