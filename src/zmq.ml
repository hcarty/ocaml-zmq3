type error =
    EINVAL
  | EFAULT
  | EMTHREAD
  | ETERM
  | ENODEV
  | EADDRNOTAVAIL
  | EADDRINUSE
  | ENOCOMPATPROTO
  | EPROTONOSUPPORT
  | EAGAIN
  | ENOTSUP
  | EFSM
  | ENOMEM
  | EINTR
  | EUNKNOWN

exception Zmq_exception of error * string

external stub_init : unit -> unit = "stub_init"

external version : unit -> int * int * int = "version_stub"

type context

external init : int -> context = "init_stub"
external term : context -> unit = "term_stub"

type 'a kind = int
type 'a socket (* abstract *)

(* Must match the constants on zmq.h *)
let pair = 0
let pub  = 1
let sub  = 2
let req  = 3
let rep  = 4
let xreq = 5
let xrep = 6
let pull = 7
let push = 8
let xpub = 9
let xsub = 10
let router = 11
let dealer = 12

type any_kind = [
    `Pair
  | `Pub
  | `Sub
  | `Req
  | `Rep
  | `Xreq
  | `Xrep
  | `Xsub
  | `Xpub
  | `Dealer
  | `Router
  | `Pull
  | `Push ]

external socket : context -> 'a kind -> 'a socket = "socket_stub"
external close : 'a socket -> unit = "close_stub"


type ('a, 'b, 'c) sockopt = int

(** Type of events *)
type event = [`Poll_in | `Poll_out]

(* Mast match the constants on zmq.h *)
let sndhwm            = 23
let rcvhwm            = 24
let affinity          = 4
let identity          = 5
let subscribe         = 6
let unsubscribe       = 7
let rate              = 8
let recovery_ivl      = 9
let sndbuf            = 11
let rcvbuf            = 12
let linger            = 17
let reconnect_ivl     = 18
let reconnect_ivl_max = 21
let backlog           = 19
let maxmsgsize        = 22
let multicast_hops    = 25
let rcvtimeo          = 27
let sndtimeo          = 28
let kind              = 16
let rcvmore           = 13
let rcvlabel          = 29
let fd                = 14
let events            = 15

external setsockopt : 'a socket -> ('a, 'b, 'c) sockopt -> 'c -> unit =
        "setsockopt_stub"
external getsockopt : 'b socket -> ('a, 'b, 'c) sockopt -> 'c =
        "getsockopt_stub"


type recv_flag = [`Dont_wait] (* Receive flags *)
type send_flag = [recv_flag | `Snd_more | `Snd_label] (* Send flags *)

let flags_to_int = function
    `Dont_wait -> 1
  | `Snd_more  -> 2
  | `Snd_label -> 4

let rec lor_flags = function
      [] -> 0
    | x::xs -> (flags_to_int x) lor (lor_flags xs)

external stub_send : 'a socket -> string -> int -> unit = "send_stub"
let send ?(flags=[]) sock str = stub_send sock str (lor_flags flags)

external stub_recv : 'a socket -> int -> string = "recv_stub"
let recv ?(flags=[]) sock = stub_recv sock (lor_flags flags)


external bind : 'a socket -> string -> unit = "bind_stub"
external connect : 'a socket -> string -> unit = "connect_stub"

let () = 
  Callback.register_exception "zmq exception"
                              (Zmq_exception(EUNKNOWN,"Unkown error"));
  stub_init ();

