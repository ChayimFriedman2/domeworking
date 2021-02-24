import "plugin" for Plugin
import "dome" for Process
import "graphics" for Canvas, Color, Font
import "input" for Mouse

Plugin.load("domeworking")

import "domeworking" for TcpListener, TcpStream

class Game {
  static incorrectArgs() {
    System.print("USAGE:
dome tic_tac_toe.wren -- --listen PORT
OR
dome tic_tac_toe.wren -- SERVER")
    Process.exit(1)
  }

  static init() {
    if (Process.args.count != 3 && Process.args.count != 4) incorrectArgs()
    if (Process.args[2] == "--listen") {
      if (Process.args.count != 4) incorrectArgs()

      var listener = TcpListener.bind("localhost:" + Process.args[3])
      System.print("Waiting for an opponent...")
      __connection = listener.accept()
      listener.close()

      System.print("Ready, set, go!")
      __character = "X"
      __opponentCharacter = "O"
      __myTurn = true
    } else {
      if (Process.args.count != 3) incorrectArgs()
      
      __connection = TcpStream.connect(Process.args[2])

      __character = "O"
      __opponentCharacter = "X"
      __myTurn = false
    }

    __board = [""] * 9

    Canvas.resize(cellSize * 3, cellSize * 3)
    __font = Font.load("AkayaTelivigala", "fonts/AkayaTelivigala-Regular.ttf", 30)
  }

  static won(character) {
    return (__board[0] == character && __board[1] == character && __board[2] == character) ||
      (__board[3] == character && __board[4] == character && __board[5] == character) ||
      (__board[6] == character && __board[7] == character && __board[8] == character) ||
      (__board[0] == character && __board[3] == character && __board[6] == character) ||
      (__board[1] == character && __board[4] == character && __board[7] == character) ||
      (__board[2] == character && __board[5] == character && __board[8] == character) ||
      (__board[0] == character && __board[4] == character && __board[8] == character) ||
      (__board[2] == character && __board[4] == character && __board[6] == character)
  }

  static tie() { __board.all {|c| c != "" } }

  static moveOpponent() {
    var idx = __connection.read(0.01)
    if (__connection.closed) {
      __endMsg = "Opponent exited."
      return
    }
    if (idx == null) return
    idx = Num.fromString(idx)
    
    if (__board[idx] != "") {
      System.print("Opponent tried cheating! But we blocked it 😂")
      Process.exit(2)
    }

    __board[idx] = __opponentCharacter
    if (won(__opponentCharacter)) {
      __endMsg = "You lost!"
    } else if (tie()) {
      __endMsg = "Draw..."
      return
    }

    __myTurn = true
  }

  static update() {
    if (__endMsg != null) return

    if (__myTurn) {
      if (Mouse.isButtonPressed("left")) {
        var column = (Mouse.x / cellSize).floor
        var row = (Mouse.y / cellSize).floor
        var idx = (row * 3) + column
        if (__board[idx] == "") {
          __board[idx] = __character
          __connection.write(idx.toString)
          if (won(__character)) {
            __endMsg = "You won!"
            return
          } else if (tie()) {
            __endMsg = "Draw..."
            return
          }
          __myTurn = false
        }
      }
    } else {
      moveOpponent()
    }
  }

  static cellSize { 50 }

  static draw(a) {
    Canvas.cls()

    if (__endMsg != null) {
      __font.print(__endMsg, 0, 0, Color.white)
      return
    }

    Canvas.line(cellSize, 0, cellSize, Canvas.height, Color.white)
    Canvas.line(cellSize * 2, 0, cellSize * 2, Canvas.height, Color.white)
    Canvas.line(0, cellSize, Canvas.width, cellSize, Color.white)
    Canvas.line(0, cellSize * 2, Canvas.width, cellSize * 2, Color.white)

    for (row in 0...3) {
      for (column in 0...3) {
        __font.print(__board[(row * 3) + column], (cellSize * column) + (cellSize / 3), (cellSize * row) - (cellSize / 3), Color.white)
      }
    }
  }
}
