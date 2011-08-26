#include <stdlib.h>
#include <stdio.h>
#include <strings.h>

#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/intext.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/threads.h>

#if defined(_WIN32) || defined(_WIN64)
#  include <winsock2.h>
#  include <windows.h>
#endif

#include <zmq.h>

static value POOL_LIST_CACHE[4];
static value const EMPTY_LIST = Val_int(0);
static value const EMPTY_STRING = Atom(String_tag);
static value *ZMQ_EXCEPTION_NAME;
static value POLL_IN_HASH;
static value POLL_OUT_HASH;

CAMLprim void stub_init () {
    CAMLparam0 ();
    CAMLlocal3 (poll_in_list, poll_out_list, poll_in_out_list);
    
    POLL_IN_HASH  = caml_hash_variant("Poll_in");
    POLL_OUT_HASH = caml_hash_variant("Poll_out");
    ZMQ_EXCEPTION_NAME = caml_named_value("zmq exception");

    POOL_LIST_CACHE[0] = EMPTY_LIST;
    
    poll_out_list = caml_alloc_small(2, 0);
    Field(poll_out_list, 0) = POLL_OUT_HASH;
    Field(poll_out_list, 1) = EMPTY_LIST;
    caml_register_generational_global_root(&POOL_LIST_CACHE[POLL_OUT]);
    POOL_LIST_CACHE[POLL_OUT] = poll_out_list;

    poll_in_out_list = caml_alloc_small(2, 0);
    Field(poll_in_out_list, 0) = POLL_IN_HASH;
    Field(poll_in_out_list, 1) = poll_out_list;
    caml_register_generational_global_root(&POOL_LIST_CACHE[POLL_IN|POLL_OUT]);
    POOL_LIST_CACHE[POLL_IN|POLL_OUT] = poll_in_out_list;

    poll_in_list = caml_alloc_small(2, 0);
    Field(poll_in_list, 0) = POLL_IN_HASH;
    Field(poll_in_list, 1) = EMPTY_LIST;
    caml_register_generational_global_root(&POOL_LIST_CACHE[POLL_IN]);
    POOL_LIST_CACHE[POLL_IN] = poll_in_list;

    CAMLreturn0;
}

CAMLprim value version_stub () {
    CAMLparam0 ();
    CAMLlocal1 (version);

    int major, minor, patch;
    zmq_version(&major, &minor, &patch);

    version = caml_alloc_small(3, 0);
    Field(version, 0) = Val_int(major);
    Field(version, 1) = Val_int(minor);
    Field(version, 2) = Val_int(patch);

    CAMLreturn (version);
}

struct wrap {
    void *wrapped;
    int terminated;
};

#define Wrap_val(v) ((struct wrap *) Data_custom_val(v))
#define Context_val(v) Wrap_val(v)
#define Socket_val(v) Wrap_val(v)

static struct custom_operations stub_socket_ops = {
    "org.zeromq.socket",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default
};

static struct custom_operations stub_context_ops = {
    "org.zeromq.context",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default
};

static value stub_wrap_new(void *wrappable, struct custom_operations *ops) {
    CAMLparam0 ();
    CAMLlocal1 (wrap);
    wrap = caml_alloc_custom(ops, sizeof (struct wrap), 0, 1);
    Context_val(wrap)->wrapped = wrappable;
    Context_val(wrap)->terminated = 0;
    CAMLreturn (wrap);
}

static value stub_socket_new(void *zmq_socket) {
    return stub_wrap_new(zmq_socket, &stub_socket_ops);
}

static value stub_context_new(void *zmq_context) {
    return stub_wrap_new(zmq_context, &stub_context_ops);
}

/* This table must be synchronized with the variant definition. */
static int const stub_error_table[] = {
    EINVAL,
    EFAULT,
    EMTHREAD,
    ETERM,
    ENODEV,
    EADDRNOTAVAIL,
    EADDRINUSE,
    ENOCOMPATPROTO,
    EPROTONOSUPPORT,
    EAGAIN,
    ENOTSUP,
    EFSM,
    ENOMEM,
    EINTR
};

/* Size of stub_error_table */
#define EUNKNOWN (14)

void stub_raise_if(int condition) {
    CAMLparam0 ();
    CAMLlocalN(error_parameters, 2);
    if(condition) {
        int error_to_raise = EUNKNOWN;
        int current_errno = zmq_errno();
        int i;
        for (i = 0; i < EUNKNOWN; i++) {
            if (current_errno == stub_error_table[i]) {
                error_to_raise = i;
                break;
            }
        }
        error_parameters[0] = Val_int(error_to_raise);
        error_parameters[1] = caml_copy_string(zmq_strerror(current_errno));
        caml_raise_with_args(
            *ZMQ_EXCEPTION_NAME,
            2,
            error_parameters);
    }
    CAMLreturn0;
}

CAMLprim value init_stub(value num_threads) {
    CAMLparam1 (num_threads);

    caml_release_runtime_system();
    /* ints are outside ocaml's heap, so it's safe to use Int_val */
    void *ctx = zmq_init(Int_val(num_threads));
    caml_acquire_runtime_system();

    stub_raise_if(ctx == NULL);

    CAMLreturn (stub_context_new(ctx));
}

CAMLprim value term_stub(value ctx) {
    CAMLparam1 (ctx);
    struct wrap *context = Context_val(ctx);
    if (!context->terminated) {

        caml_release_runtime_system();
        int result = zmq_term(context->wrapped);
        caml_acquire_runtime_system();

        stub_raise_if (result == -1);
        /* If raised this doesn't get executed */
        context->terminated = 1;
    }
    CAMLreturn (Val_unit);
}

CAMLprim value socket_stub(value ctx, value socket_kind) {
    CAMLparam2 (ctx, socket_kind);
    struct wrap *context = Context_val(ctx);

    caml_release_runtime_system();
    void *socket = zmq_socket(context->wrapped, Int_val(socket_kind));
    caml_acquire_runtime_system();

    stub_raise_if (socket == NULL);
    
    CAMLreturn (stub_socket_new(socket));
}

CAMLprim value close_stub(value sock) {
    CAMLparam1 (sock);
    struct wrap *socket = Socket_val(sock);
    if (!socket->terminated) {
    
        caml_release_runtime_system();    
        int result = zmq_close(socket->wrapped);
        caml_acquire_runtime_system();
    
        stub_raise_if (result == -1);
        
        socket->terminated = 1;
    }
    CAMLreturn (Val_unit);
}

CAMLprim value setsockopt_stub(value sock, value sockopt, value val) {
    CAMLparam3 (sock, sockopt, val);

    int native_sockopt = Int_val(sockopt);
    struct wrap *socket = Socket_val(sock);
    int result = -1;
    switch (native_sockopt) {
        case ZMQ_SNDHWM:
        case ZMQ_RCVHWM:
        case ZMQ_RATE:
        case ZMQ_RECOVERY_IVL:
        case ZMQ_SNDBUF:
        case ZMQ_RCVBUF:
        case ZMQ_LINGER:
        case ZMQ_RECONNECT_IVL_MAX:
        case ZMQ_BACKLOG:
        case ZMQ_MULTICAST_HOPS:
        case ZMQ_RCVTIMEO:
        case ZMQ_SNDTIMEO:
        {
            int optval = Int_val(val);
            result = zmq_setsockopt(socket->wrapped, native_sockopt, &optval, sizeof(optval));
        }
        break;
        
        case ZMQ_IDENTITY:
        case ZMQ_SUBSCRIBE:
        case ZMQ_UNSUBSCRIBE:
        {
            result = zmq_setsockopt(socket->wrapped,
                                    native_sockopt,
                                    String_val(val),
                                    caml_string_length(val));
        }
        break;

        case ZMQ_AFFINITY:
        case ZMQ_MAXMSGSIZE:
        {
            int64 optval = Int64_val(val);
            result = zmq_setsockopt(socket->wrapped, native_sockopt, &optval, sizeof(optval));
        }
        break;

        default:
            caml_failwith("Bidings error");
    }

    stub_raise_if (result == -1);

    CAMLreturn (Val_unit);
}

CAMLprim value getsockopt_stub(value sock, value sockopt) {
    CAMLparam2 (sock, sockopt);
    CAMLlocal1 (result);
    int error = -1;
    int native_sockopt = Int_val(sockopt);
    struct wrap *socket = Socket_val(sock);
    
    switch (native_sockopt) {
        case ZMQ_SNDHWM:
        case ZMQ_RCVHWM:
        case ZMQ_RATE:
        case ZMQ_RECOVERY_IVL:
        case ZMQ_SNDBUF:
        case ZMQ_RCVBUF:
        case ZMQ_LINGER:
        case ZMQ_RECONNECT_IVL:
        case ZMQ_RECONNECT_IVL_MAX:
        case ZMQ_BACKLOG:
        case ZMQ_MULTICAST_HOPS:
        case ZMQ_RCVTIMEO:
        case ZMQ_SNDTIMEO:
        case ZMQ_RCVMORE:
        case ZMQ_RCVLABEL:
        case ZMQ_TYPE:
        {   
            int res;
            size_t size = sizeof(res);
            error = zmq_getsockopt(socket->wrapped, native_sockopt, &res, &size);
            stub_raise_if (error == -1);            
            result = Val_int(res);
        }
        break;

        case ZMQ_AFFINITY:
        case ZMQ_MAXMSGSIZE:
        {
            int64 res;
            size_t size = sizeof(res);
            error = zmq_getsockopt(socket->wrapped, native_sockopt, &res, &size);
            stub_raise_if (error == -1);
            result = caml_copy_int64(res);
        }
        break;

        case ZMQ_EVENTS:
        {
            int res;
            size_t size = sizeof(res);
            error = zmq_getsockopt(socket->wrapped, native_sockopt, &res, &size);
            stub_raise_if (error == -1);            
            result = POOL_LIST_CACHE[res];
        }
        break;
        
        case ZMQ_IDENTITY:
        {
            char buffer[256];
            buffer[255] = '\0';
            size_t size = sizeof(buffer);
            error = zmq_getsockopt(socket->wrapped, native_sockopt, buffer, &size);
            stub_raise_if (error == -1);
            if (size == 0) {
                result = EMPTY_STRING;
            } else {
                result = caml_copy_string(buffer);
            }
        }
        break;            

        case ZMQ_FD:
        {
            #if defined(_WIN32) || defined(_WIN64)
            SOCKET fd;
            #else
            int fd;
            #endif
            size_t size = sizeof (fd);
            error = zmq_getsockopt (socket->wrapped, native_sockopt, (void *) (&fd), &size);
            stub_raise_if (error == -1);
            #if defined(_WIN32) || defined(_WIN64)
            result = win_alloc_socket(fd);
            #else
            result = Val_int(fd);
            #endif
        }
        break;

        default:
            caml_failwith("Bidings error");            

    }
    CAMLreturn (result);
}

CAMLprim value send_stub(value socket, value string, value options) {
    CAMLparam3 (socket, string, options);

    void *sock = Socket_val(socket)->wrapped;
    zmq_msg_t msg;
    int result = zmq_msg_init_size(&msg, caml_string_length(string));
    stub_raise_if (result == -1);

    /* Doesn't copy '\0' */
    memcpy ((void *) zmq_msg_data (&msg), String_val(string), caml_string_length(string));

    caml_release_runtime_system();
    result = zmq_sendmsg(sock, &msg, Int_val(options));
    caml_acquire_runtime_system();

    int close_result = zmq_msg_close (&msg);
    stub_raise_if (result == -1);
    stub_raise_if (close_result == -1);

    CAMLreturn(Val_unit);
}

CAMLprim value recv_stub(value socket, value rcv_option) {
    CAMLparam2 (socket, rcv_option);
    CAMLlocal1 (message);

    void *sock = Socket_val(socket)->wrapped;

    zmq_msg_t request;
    int result = zmq_msg_init (&request);
    stub_raise_if (result == -1);

    caml_release_runtime_system();
    result = zmq_recvmsg(sock, &request, Int_val(rcv_option));
    caml_acquire_runtime_system();

    stub_raise_if (result == -1);

    size_t size = zmq_msg_size (&request);
    if (size == 0) {
        message = EMPTY_STRING;
    } else {
        message = caml_alloc_string(size);
        memcpy (String_val(message), zmq_msg_data (&request), size);
    }
    result = zmq_msg_close(&request);
    stub_raise_if (result == -1);
    CAMLreturn (message);
}

#define BUFF_THRESHOLD (64)

static char *
copy_with_stack_buffer(char *buffer, size_t buffsize, value str, int *alloced) {
    size_t strlen = caml_string_length(str);
    char *dest = NULL;
    if (strlen < buffsize) {
        *alloced = 0;
        dest = buffer;
    } else {
        *alloced = 1;
        dest = caml_stat_alloc((strlen + 1) * sizeof(char));
    }
    memcpy(dest, String_val(str), strlen);
    dest[strlen] = '\0';
    return dest;
}

CAMLprim value bind_stub(value sock, value string_address) {
    CAMLparam2 (sock, string_address);
    char buffer[BUFF_THRESHOLD];
    struct wrap *socket = Socket_val(sock);
    int alloced = 0;
    char *strcopy = copy_with_stack_buffer(buffer,
                                           sizeof(buffer),
                                           string_address,
                                           &alloced);

    caml_release_runtime_system();
    int result = zmq_bind(socket->wrapped, strcopy);
    caml_acquire_runtime_system();

    if (alloced) caml_stat_free(strcopy);
    stub_raise_if (result == -1);
    CAMLreturn(Val_unit);
}

CAMLprim value connect_stub(value sock, value string_address) {
    CAMLparam2 (sock, string_address);
    char buffer[BUFF_THRESHOLD];
    struct wrap *socket = Socket_val(sock);
    int alloced = 0;
    char *strcopy = copy_with_stack_buffer(buffer,
                                           sizeof(buffer),
                                           string_address,
                                           &alloced);

    caml_release_runtime_system();
    int result = zmq_connect(socket->wrapped, strcopy);
    caml_acquire_runtime_system();

    if (alloced) caml_stat_free(strcopy);
    stub_raise_if (result == -1);
    CAMLreturn(Val_unit);
}
