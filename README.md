# domeworking

A networking library for [DOME](http://domeengine.com/).

This version works only with custom version of DOME that has [PR #173](https://github.com/domeengine/dome/pull/173) merged. I hope DOME will soon release a new minor version with this PR inside.

## Installation

Just download the `domeworking.dll` or `domeworking.so` from the [releases page](https://github.com/ChayimFriedman2/domeworking/releases/), and put them in the base directory of your DOME game.

After that, in your `main.wren` file, do:

```wren
import "plugin" for Plugin

Plugin.load("domeworking")

import "domeworking" for ...
```

## Documentation

### `class TcpListener`

A TCP listener that can accept TCP connections.

#### `construct bind(addr)`

Binds this listener to listen to an address.

#### `accept()`

Blocks until a connection request is sent to this `TcpListener`. Returns a `TcpStream` with the new connection.

#### `close()`

Closed the listener. After closing, the listener will not accept new connections.

The finalizer also close the listener, but never depends on that as finalizers are non-deterministic. Always close your listeners explicitly.

### `class TcpStream`

#### `construct connect(addr)`

Connects to the specified address.

#### `read()`

Reads a chunk from the stream (blocking), and returns it as a `String`.

If the stream is closed, this function returns `null`.

#### `read(timeout)`

Same as `read()`, but also returns `null` if the timeout has been passed. The timeout is specified in seconds (fractions are allowed).

#### `write(data)`

Writes data to the stream (blocking). Aborts the fiber if the stream is closed.

#### `closed`

Returns `true` if this stream is close. Note that this check is not accurate: it will never return `false` for an opened stream, but may return `true` for a closed stream if it was closed by the other side and no operations (reads/writes) were performed on it since then.

#### `close()`

Closed the stream. This closed the stream on both sides.

It is an error to close an already-closed stream, for example, a stream that was closed because the other side called `.close()`.

The finalizer also close the stream, but never depends on that as finalizers are non-deterministic. Always close your streams explicitly.
