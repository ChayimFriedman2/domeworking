import "plugin" for Plugin
import "dome" for Process

Plugin.load("domeworking")

import "domeworking" for TcpStream

class Game {
  static init() {
    var connection = TcpStream.connect("google.com:80")
    connection.write("GET / HTTP/1.1
Host: google.com
User-Agent: DOME
Connection: close

")
    var result = ""
    while (!connection.closed) result = result + connection.read()
    System.print(result)
    Process.exit()
  }

  static update() {}
  static draw(a) {}
}
