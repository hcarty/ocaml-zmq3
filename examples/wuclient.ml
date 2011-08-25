let () =
  let ctx = Zmq.init 1 in
  print_endline "Collecting updates from weather server...\n";
  let subscriber = Zmq.socket ctx Zmq.sub in
  Zmq.connect subscriber "tcp://localhost:5556";

  let filter = Array.(if length Sys.argv < 2 then "10001 " else Sys.argv.(1)) in
  Zmq.setsockopt subscriber Zmq.subscribe filter;

  let update_nbr = 5 in
  let total_temp = ref 0 in
  for i=1 to update_nbr do
    let zip, temp, rel = Scanf.sscanf (Zmq.recv subscriber) "%d %d %d" (fun a b c -> a,b,c) in
    total_temp := !total_temp + temp
  done;
  
  Printf.printf "Average temperature for zipcode '%s' was %dF\n" filter (!total_temp / update_nbr);

  Zmq.close subscriber;
  Zmq.term ctx
