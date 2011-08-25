let () = 
  let ctx = Zmq.init 1 in
  let receiver = Zmq.socket ctx Zmq.pull in
  
  Zmq.connect receiver "tcp://localhost:5557";

  let sender = Zmq.socket ctx Zmq.push in
  Zmq.connect sender "tcp://localhost:5558";

  while true do
    let str = Zmq.recv receiver in
    Printf.printf "%s." str;

    Thread.delay (float_of_string str);

    Zmq.send sender "";

  done;

  Zmq.close receiver;
  Zmq.close sender;
  Zmq.term ctx
