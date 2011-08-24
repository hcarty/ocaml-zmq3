default all:
	@echo "==== Building ocaml-zmq3 ===="
	$(MAKE) -C src all
	@echo "==== Successfully built ocaml-zmq3 ===="

install: all
	@echo "==== Installing ocaml-zmq3 ===="
	$(MAKE) -C src install
	@echo "==== Successfully installed ocaml-zmq3 ===="

uninstall:
	@echo "==== Uninstalling ocaml-zmq3 ===="
	$(MAKE) -C src uninstall
	@echo "==== Successfully uninstalled ocaml-zmq3 ===="

reinstall: uninstall install

clean:
	$(MAKE) -C src clean