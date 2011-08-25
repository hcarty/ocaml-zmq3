let () =
  let ctx = Zmq.init 1 in
  let responder = Zmq.socket ctx Zmq.rep in
  Zmq.bind responder "tcp://*:5555";

  while true do
    let _ = Zmq.recv responder in
    print_endline "Received Hello";

    Thread.delay 1.0;

    Zmq.send responder "World";
  done;

  Zmq.close responder;
  Zmq.term ctx
