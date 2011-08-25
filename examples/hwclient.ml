let () =
  let ctx = Zmq.init 1 in

  print_endline "Connecting to hello world server…";
  let requester = Zmq.socket ctx Zmq.req in
  Zmq.connect requester "tcp://localhost:5555";

  for i=0 to 9 do
    Printf.printf "Sending Hello %d...\n" i;
    Zmq.send requester "Hello";

    let _ = Zmq.recv requester in
    
    Printf.printf "Received World %d\n" i
  done;

  Zmq.close requester;
  Zmq.term ctx
