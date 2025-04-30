let read_file path =
  let ic = open_in path in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  content

(* Main router *)
let router =
  Dream.router [
    Dream.get "/" (fun _ ->
      let content = read_file "static/index.html" in
      Dream.html content
    );
    Dream.get "/client.js" (fun _ ->
      let content = read_file "static/client.js" in
      Dream.respond ~headers:["Content-Type", "application/javascript"] content
    );
    Dream.get "/ws" (fun request ->
      let username = Dream.query request "username" |> Option.value ~default:"Anonymous" in
      Dream.websocket (fun websocket ->
        Chat_room.handle_connection websocket username
      )
    );
  ]

(* Start the server *)
let () =
  Dream.run
  @@ Dream.logger
  @@ router