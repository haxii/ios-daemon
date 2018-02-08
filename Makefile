deb.tmpdir = .

all: builddir release clean
	echo "make success"

builddir:clean
	mkdir -p $(deb.tmpdir)/.tmp/DEBIAN
	mkdir -p $(deb.tmpdir)/.tmp/etc
	mkdir -p $(deb.tmpdir)/.tmp/Library/LaunchDaemons
	mkdir -p $(deb.tmpdir)/.tmp/usr/bin
	cp -rf $(deb.tmpdir)/DEBIAN/* $(deb.tmpdir)/.tmp/DEBIAN/
	cp -rf $(deb.tmpdir)/etc/* $(deb.tmpdir)/.tmp/etc/
	cp -rf $(deb.tmpdir)/Library/LaunchDaemons/* $(deb.tmpdir)/.tmp/Library/LaunchDaemons/
	cp -rf $(deb.tmpdir)/usr/bin/* $(deb.tmpdir)/.tmp/usr/bin/

release:
	mkdir -p $(deb.tmpdir)/package
	rm -rf $(deb.tmpdir)/package/*
	chown -R root:wheel $(deb.tmpdir)/.tmp/
	dpkg-deb -Zgzip -b $(deb.tmpdir)/.tmp/ $(deb.tmpdir)/package/ios.tmpdaemon+0.0.1-iphone-arm.deb
	rm -rf $(deb.tmpdir)/.tmp/
clean:
	rm -rf $(deb.tmpdir)/.tmp/