open Lwt.Infix

(* Maintain a list of active WebSocket connections *)
let clients = ref []

(* Add a new client to the registry *)
let add_client client =
  clients := client :: !clients;
  Lwt.return_unit

(* Remove a client from the registry *)
let remove_client client =
  clients := List.filter (fun c -> c != client) !clients;
  Lwt.return_unit

(* Broadcast a message to all connected clients *)
let broadcast message =
  Lwt_list.iter_p
    (fun client ->
      Dream.send client message)
    !clients

(* Handle a new WebSocket connection *)
let handle_connection client =
  (* Add client to registry *)
  add_client client >>= fun () ->

  (* Handle incoming messages *)
  let rec loop () =
    Dream.receive client >>= function
    | Some message ->
        (* Broadcast the message to all clients *)
        broadcast message >>= fun () ->
        loop ()
    | None ->
        (* Client disconnected, clean up *)
        remove_client client
  in
  loop ()