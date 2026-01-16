open Lwt.Infix

(* Maximum message length *)
let max_message_length = 500

(* Client information type *)
type client_info = {
  websocket: Dream.websocket;
  username: string;
  color: string;
  is_typing: bool;
}

(* Maintain a list of active WebSocket connections *)
let clients = ref []

(* Generate a random color for a user *)
let random_color () =
  let colors = [
    "#FF6B6B"; "#4ECDC4"; "#45B7D1"; "#96CEB4"; "#FFEEAD";
    "#D4A5A5"; "#9B59B6"; "#3498DB"; "#1ABC9C"; "#F1C40F"
  ] in
  List.nth colors (Random.int (List.length colors))

(* Add a new client to the registry *)
let add_client client username =
  let color = random_color () in
  let client_info = { websocket = client; username; color; is_typing = false } in
  clients := client_info :: !clients;
  Lwt.return_unit

(* Remove a client from the registry *)
let remove_client client =
  clients := List.filter (fun c -> c.websocket != client) !clients;
  Lwt.return_unit

(* Format a message with username, color, and timestamp *)
let format_message username color message =
  let timestamp = Unix.time () |> int_of_float |> string_of_int in
  `Assoc [
    ("username", `String username);
    ("color", `String color);
    ("message", `String message);
    ("timestamp", `String timestamp)
  ] |> Yojson.Safe.to_string

(* Format typing status *)
let format_typing_status username color is_typing =
  `Assoc [
    ("type", `String "typing_status");
    ("username", `String username);
    ("color", `String color);
    ("is_typing", `Bool is_typing)
  ] |> Yojson.Safe.to_string

(* Broadcast a message to all connected clients *)
let broadcast message =
  Lwt_list.iter_p
    (fun client ->
      Dream.send client.websocket message)
    !clients

(* Broadcast a system message *)
let broadcast_system message =
  let system_message = format_message "System" "#666666" message in
  broadcast system_message

(* Update typing status and broadcast *)
let update_typing_status client is_typing =
  let client_info = List.find (fun c -> c.websocket == client) !clients in
  let typing_message = format_typing_status client_info.username client_info.color is_typing in
  broadcast typing_message

(* Handle a new WebSocket connection *)
let handle_connection client username =
  (* Add client to registry *)
  add_client client username >>= fun () ->

  (* Broadcast join message *)
  broadcast_system (username ^ " joined the chat") >>= fun () ->

  (* Handle incoming messages *)
  let rec loop () =
    Dream.receive client >>= function
    | Some message ->
        let client_info = List.find (fun c -> c.websocket == client) !clients in
        (try
          let json_message = Yojson.Safe.from_string message in
          match json_message with
          | `Assoc [("type", `String "typing_start")] ->
              update_typing_status client true >>= fun () ->
              loop ()
          | `Assoc [("type", `String "typing_end")] ->
              update_typing_status client false >>= fun () ->
              loop ()
          | _ ->
              (* Check message length *)
              if String.length message > max_message_length then
                let error_msg = format_message "System" "#FF0000"
                  (Printf.sprintf "Message too long! Maximum %d characters allowed." max_message_length) in
                Dream.send client error_msg >>= fun () ->
                loop ()
              else
                let formatted_message = format_message client_info.username client_info.color message in
                broadcast formatted_message >>= fun () ->
                loop ()
        with _ ->
          (* If JSON parsing fails, treat as regular message *)
          (* Check message length *)
          if String.length message > max_message_length then
            let error_msg = format_message "System" "#FF0000"
              (Printf.sprintf "Message too long! Maximum %d characters allowed." max_message_length) in
            Dream.send client error_msg >>= fun () ->
            loop ()
          else
            let formatted_message = format_message client_info.username client_info.color message in
            broadcast formatted_message >>= fun () ->
            loop ())
    | None ->
        (* Client disconnected, clean up *)
        let client_info = List.find (fun c -> c.websocket == client) !clients in
        broadcast_system (client_info.username ^ " left the chat") >>= fun () ->
        remove_client client
  in
  loop ()