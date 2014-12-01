import 'dart:io';

class Pos {
  num row, col;
  
  Pos(this.row, this.col);
}

// *** PUZZLE CLASS
class Puzzle {
  List<String> contents;
  num size;
  var allNumbers;
  
  Puzzle(this.contents) {
    size = 9;
    allNumbers = new Set();
    allNumbers.addAll(['1', '2', '3', '4', '5', '6', '7', '8', '9']);  
  }
  

  String cell (num row, num col) {
    return contents[row].substring(col,col+1);
  }
  
  void setCell(Pos cell, String value){
    contents[cell.row] = contents[cell.row].substring(0, cell.col) + value + contents[cell.row].substring(cell.col+1, 9);     
  }
  
  // Returns set of all numbers in the row
  Set setFromRow(num r){
    var rowSet = new Set();
    
    for (num i = 0; i < size; i++)
      if (allNumbers.contains(contents[r].substring(i, i +1 )))
        rowSet.add(contents[r].substring(i, i +1 ));
    
    return rowSet;
  }
  
  // Returns set of all numbers in the column
  Set setFromCol(num c){
    var colSet = new Set();
    
    for (num i = 0; i < size; i++)
      if (allNumbers.contains(contents[i].substring(c, c + 1)))
        colSet.add(contents[i].substring(c, c + 1));
    
    return colSet;
  }

  // Returns next empty cell
  Pos NextEmpty () {
    num row = 0;
    num col = 0;
    bool empty = false;
    
    while ((row < size) && !empty) {
      while ((col < size) && !empty) {
        if (cell(row, col) == ' ')
          empty = true;     
        else
          col++;
      }
      if (!empty)
      {
        row++;
        col = 0;
      }
    }
    
    if (empty)
      return new Pos(row, col);
    else
      return new Pos(-1, -1); // No empty cells (i.e. solved)
  }

  bool isValidRow(num row, num trial) {
    return !(setFromRow(row).contains(trial.toString()));
  }
  
  bool isValidCol(num col, num trial) {
    return !(setFromCol(col).contains(trial.toString()));
  }

  // Valid 3x3 box
  bool isValidBox(Pos cell, num trial) {
    num row = ((cell.row / 3)).floor();
    num col = ((cell.col / 3)).floor();

    for (var r = 0; r < 3; r++)
      for (var c = 0; c < 3; c++) {
        if ((col*3 + c + 1) > size)
          print ('oh no');
        
        if (contents[row*3+r].substring(col*3+c, col*3+c+1) == trial.toString())
          return false;        
      }
    
    return true;
  }
  
  bool isValidChoice (Pos cell, num trial) {
    bool ivr = isValidRow(cell.row, trial);
    bool ivc = isValidCol(cell.col, trial);
    bool ivb = isValidBox(cell, trial);
    return (ivr && ivc && ivb);
  }

  void dump() {
    var out = "";
    
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        out += (contents[r].substring(c,c+1));
      }
      out += '\n';
    }
    print (out);
  }
  
}

num steps = 0; // Number of steps to find solution
bool solve3 (Puzzle p, Pos cell)
{
  steps++;
  
  // Solve for next empty cell
  Puzzle q = new Puzzle(p.contents);
  Pos next = q.NextEmpty();

  if (next.row == -1) {
    // Solved
    solution.contents = q.contents;
    return true;
  }
  
  // Try different numbers in the cell
  for (var choice = 1; choice <= q.size; choice++) {
    if (q.isValidChoice(next, choice)) {
      q.setCell(next, choice.toString());
  //    print ('Solve (${next.row},${next.col}) ${q.contents}');
      if (solve3(q, next)) {
        return true;
      }
    }
    q.setCell(next, ' ');
  }
  
  return false; // backtrack
}

Puzzle solution;

// Usage: dart sudoku.dart puzzle.txt
void main(List<String> args) {  
  solution = new Puzzle(['']);
  
  // Read from file into Puzzle
  var inFile = new File(args[0]);
  List<String> lines = inFile.readAsLinesSync();
  var p1 = new Puzzle(lines);
  
  // Solve the Puzzle
  print ("The battle of wits has begun");
  p1.dump();
  
  int beginTime = new DateTime.now().millisecondsSinceEpoch;

  solve3(p1, new Pos(0,0));  // SOLVE!

  int endTime = new DateTime.now().millisecondsSinceEpoch;
  
  if (solution.contents.length > 1) {
    print ("It has worked! You've given everything away!");
    solution.dump();    
    print ("$steps steps in ${((endTime - beginTime) / 1000).ceil()} seconds");
  }
  else
    print ('This does put a damper on our relationship');
}
