(** ZMQ 3._ bindings for OCaml *)

(** Returns the instaled ZMQ version *)
external version : unit -> int * int * int = "version_stub"

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


(** {6 Context } *)

type context (* abstract *)

(** [init n] creates a context with a thread pool of [n] threads 
    to handle I/O operations.

    @raise ZMQ_exception(EINVAL, _) if an invalid number of threads was requested.
*)
external init : int -> context = "init_stub"

(** [term ctx] terminates the context [ctx]. Refer to the ZMQ manual
    for a deeper explanation of how the termination is performed.
    Terminating a context after a sucessfull termination of that context
    has no effect.
    Important: the bindings do not attemp to terminate the context
    when it is finalized by the garbage collector.

    @raise ZMQ_exception(EFAULT, _) if [ctx] is an invalid context.
    @raise ZMQ_exception(EINTR, _) if the termination was interrupted by a
    signal. It can be restarted if needed.
*)
external term : context -> unit = "term_stub"

(** {6 Socket} *)

(** A type representing the kind of socket to create *)
type 'a kind
type 'a socket (* abstract *)

(** Available socket kinds *)
val pair   : [> `Pair] kind
val pub    : [> `Pub] kind
val sub    : [> `Sub] kind
val req    : [> `Req] kind
val rep    : [> `Rep] kind
val xreq   : [> `Xreq] kind
val xrep   : [> `Xrep] kind
val pull   : [> `Pull] kind
val push   : [> `Push] kind
val xpub   : [> `Xpub] kind
val xsub   : [> `Xsub] kind
val router : [> `Router] kind
val dealer : [> `Dealer] kind

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

(** [socket ctx kind] create a socket associated with the context [ctx]
    and with type [kind]

    @raise ZMQ_exception(EINVAL, _) if the requested socket kind is invalid.
    If this exception is raised the bindings have an error.
    @raise ZMQ_exception(EFAULT, _) if [ctx] is an invalid context.
    @raise ZMQ_exception(EMFILE, _) if the limit on the total number of 0MQ
    sockets has been reached.
    @raise ZMQ_exception(ETERM, _) if [ctx] was terminated.
*)
external socket : context -> 'a kind -> 'a socket = "socket_stub"

(** [close sock] closes the socket [sock].
    Closing a socket after a sucessfull [close] of that socket
    has no effect.
    Important: the bindings do not attemp to close the socket
    when it is finalized by the garbage collector.


    @raise ZMQ_exception(ENOTSOCK, _) if [sock] was invalid.

*)
external close : 'a socket -> unit = "close_stub"

(** {6 Socket options} *)

(** A type representing a socket option. 
    'a restricts the kinds of sockets where this option can be set.
    'b restricts the kinds of sockets where this option can be retrieved.
    'c is the type of the option value.
*)
type ('a, 'b, 'c) sockopt

(** Type of events *)
type event = [`Poll_in | `Poll_out]

(** Available socket options *)
val sndhwm            : ('a,        'a,        int)               sockopt
val rcvhwm            : ('a,        'a,        int)               sockopt
val affinity          : ('a,        'a,        int64)             sockopt
val identity          : ('a,        'a,        string)            sockopt
val subscribe         : ([< `Sub],  [< `None], string)            sockopt
val unsubscribe       : ([< `Sub],  [< `None], string)            sockopt
val rate              : ('a,        'a,        int)               sockopt
val recovery_ivl      : ('a,        'a,        int)               sockopt
val sndbuf            : ('a,        'a,        int)               sockopt
val rcvbuf            : ('a,        'a,        int)               sockopt
val linger            : ('a,        'a,        int)               sockopt
val reconnect_ivl     : ('a,        'a,        int)               sockopt
val reconnect_ivl_max : ('a,        'a,        int)               sockopt
val backlog           : ('a,        'a,        int)               sockopt
val maxmsgsize        : ('a,        'a,        int64)             sockopt
val multicast_hops    : ('a,        'a,        int)               sockopt
val rcvtimeo          : ('a,        'a,        int)               sockopt
val sndtimeo          : ('a,        'a,        int)               sockopt
val kind              : ([< `None],  any_kind, any_kind kind)     sockopt
val rcvmore           : ([< `None], 'a,        bool)              sockopt
val rcvlabel          : ([< `None], 'a,        bool)              sockopt
val fd                : ([< `None], 'a,        Unix.file_descr)   sockopt 
val events            : ([< `None], 'a,        event list)        sockopt

(** [setsockopt sock option value] sets the value [value]
    for the option [option] for the socket [sock].

    @raise ZMQ_exception(EINVAL, _) if the requested option length or the [value]
    is invalid.
    @raise ZMQ_exception(ETERM, _) if the context associated with [sock] was
    terminated.
    @raise ZMQ_exception(ENOTSOCK, _) if [sock] is an invalid socket.
    @raise ZMQ_exception(EINTR, _) if the operation was interrupted
    by delivery of a signal.
*)
external setsockopt : 'a socket -> ('a, 'b, 'c) sockopt -> 'c -> unit =
        "setsockopt_stub"

(** [getsockopt sock option] returns the value
    for the option [option] for the socket [sock].

    @raise ZMQ_exception(ETERM, _) if the context associated with [sock] was
    terminated.
    @raise ZMQ_exception(ENOTSOCK, _) if [sock] is an invalid socket.
    @raise ZMQ_exception(EINTR, _) if the operation was interrupted
    by delivery of a signal.
*)
external getsockopt : 'b socket -> ('a, 'b, 'c) sockopt -> 'c =
        "getsockopt_stub"


(** {6 Send/Receive} *)

type recv_flag = [`Dont_wait] (* Receive flags *)
type send_flag = [recv_flag | `Snd_more | `Snd_label] (* Send flags *)

(** [send flags sock message] sends [message] through the socket [sock] *)
val send : ?flags:send_flag list -> 'a socket -> string -> unit

(** [recv flags sock] sends [message] receives a message.
    Note: While zmq_recv fill a provided buffer with the contents of the
    message (truncating if the buffer isn't big enough) this function
    returns a complete message.
*)
val recv : ?flags:recv_flag list -> 'a socket -> string


(** {6 Wiring} *)

(** [bind sock endpoint] creates an endpoint for accepting connections
    and bint it to socket [sock].
    
    @raise ZMQ_exception(EINVAL, _) if [endpoint] is an invalid endpoint.
    @raise ZMQ_exception(EPROTONOSUPPORT, _) if the requested transport protocol
    is not supported.
    @raise ZMQ_exception(ENOCOMPATPROTO, _) if the requested transport protocol
    is not compatible with the socket type.
    @raise ZMQ_exception(EADDRINUSE, _) if the address is already in use.
    @raise ZMQ_exception(EADDRNOTAVAIL, _) if the address was not local.
    @raise ZMQ_exception(ENODEV, _) if the requested address specifies a non
    existent interface.
    @raise ZMQ_exception(ETERM, _) if the context associated with [sock] was
    terminated.
    @raise ZMQ_exception(ENOTSOCK, _) if [sock] is an invalid socket.
    @raise ZMQ_exception(EMTHREAD, _) no I/O thread is available to complete the
    task.
*)
external bind : 'a socket -> string -> unit = "bind_stub"

(** [connect sock endpoint] connects the socket [sock] to the endpoint
    [endpoint].
    
    @raise ZMQ_exception(EINVAL, _) if [endpoint] is an invalid endpoint.
    @raise ZMQ_exception(EPROTONOSUPPORT, _) if the requested transport protocol
    is not supported.
    @raise ZMQ_exception(ENOCOMPATPROTO, _) if the requested transport protocol
    is not compatible with the socket type.
    @raise ZMQ_exception(ETERM, _) if the context associated with [sock] was
    terminated.
    @raise ZMQ_exception(ENOTSOCK, _) if [sock] is an invalid socket.
    @raise ZMQ_exception(EMTHREAD, _) if no I/O thread is available to complete the
    task.
*)
external connect : 'a socket -> string -> unit = "connect_stub"
