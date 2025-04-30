# Camel Chat 🐪

A real-time chat application built with OCaml, Dream (with Lwt), and WebSockets.

## Features

- Real-time messaging using WebSockets
- Simple and clean web interface
- Built with OCaml and Dream web framework

## Prerequisites

- OCaml (>= 4.08.0)
- opam (OCaml package manager)
- dune (build system)

## Installation

1. Create a new opam switch for the project:
```bash
opam switch create . --deps-only
```

2. Install dependencies:
```bash
opam install dream yojson lwt
```

## Building and Running

1. Build the project:
```bash
dune build
```

2. Run the server:
```bash
dune exec src/server.exe
```

3. Open your browser and navigate to:
```
http://localhost:8080
```

## Project Structure

- `src/`
  - `server.ml` - HTTP and WebSocket server
  - `chat_room.ml` - Chat room logic and client management
  - `dune` - Build configuration
- `static/`
  - `index.html` - Chat UI
  - `client.js` - WebSocket client code

## License

MIT License