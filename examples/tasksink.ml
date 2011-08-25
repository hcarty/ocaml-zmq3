let () = 
  let ctx = Zmq.init 1 in
  let receiver = Zmq.socket ctx Zmq.pull in
  
  Zmq.bind receiver "tcp://*:5558";

  let _ = Zmq.recv receiver in
  let start_time = Sys.time () in
  let task_nbr = 99 in

  for i=0 to task_nbr do
    let _ = Zmq.recv receiver in
    if (i / 10 * 10) = i then
      print_string(":")
    else
      print_string(".")
  done;
  
  Printf.printf "Total elapsed time: %d msec\n" (int_of_float (Sys.time () -. start_time));

  Zmq.close receiver;
  Zmq.term ctx
