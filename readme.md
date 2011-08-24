# ocaml-zmq3

ZeroMQ 3 bindings for OCaml

## Requirements

* [OCaml 3.12](http://caml.inria.fr/)
* [Findlib](http://projects.camlcity.org/projects/findlib.html)
* [ZeroMQ 3.*.*](http://www.zeromq.org/intro:get-the-software)

## Install:

``` sh
$ make install
```

## Uninstall

``` sh
$ make uninstall
```

## Examples (interpreter)

### Send/Receive

``` ocaml
let c = Zmq.init 1;;
let s1 = Zmq.socket c Zmq.rep;;
let s2 = Zmq.socket c Zmq.req;;
Zmq.bind s1 "tcp://*:5555";;
Zmq.connect s2 "tcp://localhost:5555";;
Zmq.send s2 "Hello";;
let msg = Zmq.recv s1;;
```

### Using options

``` ocaml
let c = Zmq.init 1;;
let s1 = Zmq.socket c Zmq.rep;;
Zmq.setsockopt s1 Zmq.subscribe "lol";;
```

## Thanks

* wagerlabs (Joel Reymont) - implemented poll and the typing of sockets with variants
* little-arhat (Roman Sokolov) - implemented the file descriptor option
*  bashi-bazouk (Brian Ledger) - inspired the new implementation for the socket options

## Copyright

Copyright (C) 2011 Pedro Borges and Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
