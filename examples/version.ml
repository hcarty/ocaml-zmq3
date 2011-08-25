let () =
  let (major, minor, patch) = Zmq.version () in
  Printf.printf "Current 0MQ version is %d.%d.%d\n" major minor patch
