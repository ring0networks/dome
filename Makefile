INSTALL_PATH = /lib/modules/lua/dome
RM = rm -f
MKDIR = mkdir -p -m 0755
INSTALL = install -o root -g root

all: vmlinux.h https.o malware.lua

vmlinux.h:
	bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h

https.o: https.c
	clang -target bpf -Wall -O2 -c -g $<

clean:
	${RM} vmlinux.h https.o malware.lua

install: malware.lua
	${MKDIR} ${INSTALL_PATH}
	${INSTALL} -m 0644 *.lua ${INSTALL_PATH}/

uninstall:
	${RM} -r ${INSTALL_PATH}

run: install
	lunatik reload
	xdp-loader load -m skb luaxdp0 https.o
	lunatik spawn dome/daemon

stop:
	xdp-loader unload --all luaxdp0
	lunatik stop dome/daemon

namespace:
	./namespace.sh

malware.lua:
	./malware.sh

