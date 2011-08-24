OCAMLFIND= ocamlfind
OCAMLC= ocamlc
OCAMLOPT= ocamlopt
OCAMLMKLIB= ocamlmklib

LIB_NAME= zmq
LIB_NAME_ALT= zmq
META_FILE= META
DEPS= -package unix
OBJS= zmq_stubs.o
INSTALL_FILES=*.mli *.cmi *.cma *.cmx *.cmxa *.a *.so

all: native bytecode

native: zmq.cmxa

zmq.cmxa: zmq.cmi zmq.cmx $(OBJS)
	$(OCAMLMKLIB) -o $(LIB_NAME_ALT) -oc zmqstubs zmq.cmx $(OBJS) -lzmq

bytecode: zmq.cma

zmq.cma: zmq.cmi zmq.cmo $(OBJS)
	$(OCAMLMKLIB) -o $(LIB_NAME_ALT) -oc zmqstubs zmq.cmo $(OBJS) -lzmq

%.cmi: %.mli
	$(OCAMLFIND) $(OCAMLC) $(DEPS) -c $<

%.cmo: %.ml
	$(OCAMLFIND) $(OCAMLC) $(DEPS) -c $<

%.cmx: %.ml
	$(OCAMLFIND) $(OCAMLOPT) $(DEPS) -c $<

%.o: %.c
	$(OCAMLFIND) $(OCAMLC) -c $<

clean:
	rm -rf *.o *.cmi *.cmo *.cmx *.a *.so *.cma *.cmxa


install: all
	$(OCAMLFIND) install $(LIB_NAME) $(META_FILE) $(INSTALL_FILES)

uninstall:
	$(OCAMLFIND) remove $(LIB_NAME)

.PHONY: clean
