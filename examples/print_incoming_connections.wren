import "plugin" for Plugin
import "dome" for Process

Plugin.load("domeworking")

import "domeworking" for TcpListener

class Game {
  static init() {
    var listener = TcpListener.bind("127.0.0.1:4150")
    System.print("Listening at 4150")
    System.print("Waiting for a connection...")
    while (true) {
      var connection = listener.accept()
      System.print("Connection %(connection) from %(connection.remoteAddr)")
      connection.close()
    }
    listener.close()
    Process.exit()
  }

  static update() {}
  static draw(a) {}
}
