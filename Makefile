install:
	mkdir -p /opt/snappup
	cp ./snappup /opt/snappup
	ln -s /opt/snappup/snappup /usr/bin/snappup
	chmod 0755 /usr/bin/snappup /opt/snappup/snappup

uninstall:
	rm /usr/bin/snappup
	rm -rf /opt/snappup
