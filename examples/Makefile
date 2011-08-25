OCAMLFIND= ocamlfind
OCAMLC= ocamlc

DEPS=  -thread -package zmq
OBJS= version.exe hwclient.exe hwserver.exe taskevent.exe \
	tasksink.exe taskwork.exe wuclient.exe wuserver.exe

all: $(OBJS)

%.exe: %.ml
	$(OCAMLFIND) $(OCAMLC) $(DEPS) -linkpkg $< -o $@
clean:
	rm -rf *.exe *.cmi *.cmo

.PHONY: clean