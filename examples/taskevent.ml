let () = 
  let ctx = Zmq.init 1 in
  let sender = Zmq.socket ctx Zmq.push in
  Zmq.bind sender "tcp://*:5557";

  let sink = Zmq.socket ctx Zmq.push in
  Zmq.connect sink "tcp://localhost:5558";

  print_endline "Press Enter when the workers are ready: ";
  let _ = read_line () in
  print_endline "Sending tasks to workers...\n";

  Zmq.send sink "0";

  Random.self_init ();
  
  let task_nbr = 100 in
  let total_msec = ref 0 in
  for i=1 to task_nbr do 
    let workload = (Random.int 100) + 1 in
    total_msec := !total_msec + workload;
    Zmq.send sender (string_of_int workload);
  done;

  Printf.printf "Total expected cost: %d msec\n" !total_msec;

  Thread.delay 1.0;

  Zmq.close sink;
  Zmq.close sender;
  Zmq.term ctx
