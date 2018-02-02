deb_dir = .

all: builddir release clean
	echo "make success"

builddir:clean
	mkdir -p $(deb_dir)/_/DEBIAN
	mkdir -p $(deb_dir)/_/etc
	mkdir -p $(deb_dir)/_/Library/LaunchDaemons
	mkdir -p $(deb_dir)/_/usr/bin
	cp -rf $(deb_dir)/DEBIAN/* $(deb_dir)/_/DEBIAN/
	cp -rf $(deb_dir)/etc/* $(deb_dir)/_/etc/
	cp -rf $(deb_dir)/Library/LaunchDaemons/* $(deb_dir)/_/Library/LaunchDaemons/
	cp -rf $(deb_dir)/usr/bin/* $(deb_dir)/_/usr/bin/

release:
	mkdir -p $(deb_dir)/package
	rm -rf $(deb_dir)/package/*
	chown -R root:wheel $(deb_dir)/_/
	dpkg-deb -Zgzip -b $(deb_dir)/_/ $(deb_dir)/package/ios_daemon+0.0.1-iphone-arm.deb

clean:
	rm -rf $(deb_dir)/_/