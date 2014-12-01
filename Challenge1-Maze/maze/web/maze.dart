// Maze Solver
//
// Uses breadth-first search and HTML5 canvas
//
// Travis Shultz 2014

import 'dart:html';

String WALL = 'X';
String AIR = ' ';
String START = 'S';
String END = 'E';
String TRAIL = '.';

// Maze Nodes - used for backtracking solution
class Node {
  num x;
  num y;
  Node parent;
  
  Node (this.x, this.y, this.parent) {
  }
}

class Maze {
  List<String> contents;
  Node start;
  Node end;
  var visited;
  
  Maze (this.contents) {
    start = findSymbol(START);
    end = findSymbol(END);
    visited = new Set();
  }
  
  // Find a specific letter in the maze
  Node findSymbol (String symbol) {
    for (int y=0; y<30; y++) {
      for (int x=0; x<30; x++) {
        if (value(x,y) == symbol) {
          Node result = new Node(x, y, null);
          return result;
        }            
      }
    }
    return null;
  }
  
  // Character at maze position
  String value (num x, num y) {
    if ((x>29) || (y>29))
      return WALL;
    if (x+1>29)
      return contents[y].substring(x);
    else
      return contents[y].substring(x, x+1);
  }
  
  // Valid Maze
  bool inRange (num x, num y) {
    return  !((x<0) || (x>29) || (y<0) || (y>29));
  }
  
  bool isWall(num x, num y) {
    bool result = true;
    if ((value(x,y) == WALL) && inRange(x,y))
      result = true;
    else result = false;
    
    return result;
  }
  
  bool isPath(num x, num y, Node current) {
    bool result = true;
    
    if (!inRange(x,y))
      result = false;
    
    if (value(x,y) == WALL)
      result = false;
    
    //Already visited?
    if (visited.contains(x.toString() + ',' + y.toString()))
      result = false;

    return result;
  }
  
  bool isEnd(num x, num y) {
    bool result = true;
    if ((value(x,y) == END) && inRange(x,y))
      result = true;
    else result = false;
    
    return result;
  }
  
  void setCell(num x, num y, String value){
    contents[y] = contents[y].substring(0, x) + value + contents[y].substring(x+1);     
  }

  void solve () {
    queue.add(start);
    bool done = false;
    
    Node current = queue[0];
    while (!isEnd(current.x, current.y)) {
        String visit = current.x.toString() + ',' + current.y.toString();
        visited.add(visit);
        // Left
        if (isPath(current.x-1, current.y, current)) {
          Node neighbor = new Node(current.x-1, current.y, current);
          queue.add(neighbor);
//          print('(${current.x},${current.y}) -> (${neighbor.x},${neighbor.y})');
        }
        // Right
        if (isPath(current.x+1, current.y, current)) {
          Node neighbor = new Node(current.x+1, current.y, current);
          queue.add(neighbor);
        }
        // Up
        if (isPath(current.x, current.y-1, current)) {
          Node neighbor = new Node(current.x, current.y-1, current);
          queue.add(neighbor);
        }
        // Down
        if (isPath(current.x, current.y+1, current)) {
          Node neighbor = new Node(current.x, current.y+1, current);
          queue.add(neighbor);
        }
      queue.removeAt(0);
      current = queue[0];
    }
    
    // Backtrack from end, filling in maze
    while (current.parent != null) {
      current = current.parent;
      if ((current != null) && (value(current.x,current.y) != START)) {
        setCell(current.x, current.y, TRAIL);
//        print ('Path (${current.x},${current.y})');        
      }
    }
  }
  
}

List<Node> queue=[];   // Queue of candidate path nodes

// Render the Maze to HTML 5 Canvas
void render(Maze m1) {
  CanvasElement canvas = querySelector("#canvas");
  CanvasRenderingContext2D context = canvas.context2D;
  
  // Clear screen, setup drawing options
  context.clearRect(0, 0, canvas.width, canvas.height);
  context.lineWidth = 1;
  context.imageSmoothingEnabled = false;  

  // Draw the maze
  ImageElement img = new Element.tag("img");
  img.src= "sheet.png";
  img.onLoad.listen((value) => context.drawImageScaledFromSource(img, 0, 0, 8, 9, 0, 0, 16, 16));
  for (int i=0; i<30; i++) {
    for (int j=0; j<30; j++) {
      String cell = m1.value(j, i);
      num size = 16;
      if (cell == WALL) 
        //drawImageScaledFromSource(img, sourceX, sourceY, sourceWidth, sourceHeight, destX, destY, destWidth, destHeight));
        img.onLoad.listen((value) => context.drawImageScaledFromSource(img, 0, 0, 8, 8, j*size, i*size, size, size));
      else if (cell == AIR)
        img.onLoad.listen((value) => context.drawImageScaledFromSource(img, 8, 0, 8, 8, j*size, i*size, size, size));
      else if (cell == START)
        img.onLoad.listen((value) => context.drawImageScaledFromSource(img, 16, 0, 8, 8, j*size, i*size, size, size));
      else if (cell == END)
        img.onLoad.listen((value) => context.drawImageScaledFromSource(img, 24, 0, 8, 8, j*size, i*size, size, size));
      else if (cell == TRAIL)
        img.onLoad.listen((value) => context.drawImageScaledFromSource(img, 32, 0, 8, 8, j*size, i*size, size, size));
    }
  }  
}

TextAreaElement taMaze; // the maze text element from html
ButtonElement btnSolve; // the solve button from html

Maze theMaze;           // Maze object
List<String> inputText; // Input text from html element

void onMazeChanged() {
  inputText = null;
  inputText = new List<String>();
  inputText.addAll(taMaze.value.split('\n'));
}

void onSolveClicked() {
  onMazeChanged();
  
  theMaze=null;
  queue.removeWhere((e) => true);
  theMaze = new Maze(inputText);
  theMaze.solve();
  render(theMaze);
}

void main() {
  taMaze = querySelector("#taMaze");
  btnSolve = querySelector("#btnSolve");
  
  btnSolve.onClick.listen((e) => onSolveClicked());
  
  onSolveClicked();
}

