let () =
  let ctx = Zmq.init 1 in
  let publisher = Zmq.socket ctx Zmq.pub in
  Zmq.bind publisher "tcp://*:5556";
  Zmq.bind publisher "ipc://weather.ipc";

  Random.self_init ();

  while true do
    
    let zipcode = Random.int 100000 in
    let temperature = (Random.int 215) - 80 in
    let relhumidity = (Random.int 50) + 10 in

    let update = Printf.sprintf "%05d %d %d" zipcode temperature relhumidity in
    
    Zmq.send publisher update;
  done;

  Zmq.close publisher;
  Zmq.term ctx
