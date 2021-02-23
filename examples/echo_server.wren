import "plugin" for Plugin
import "dome" for Process

Plugin.load("domeworking")

import "domeworking" for TcpListener

class Game {
  static init() {
    var listener = TcpListener.bind("127.0.0.1:4150")
    System.print("Listening at 4150")
    System.print("Waiting for a connection...")
    var connection = listener.accept()
    listener.close()
    while (true) {
      var data = connection.read()
      if (data == null) break
      connection.write(data)
      System.write(data)
    }
    Process.exit()
  }

  static update() {}
  static draw(a) {}
}
