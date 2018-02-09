# iOS-daemon

Demonize an iOS command-line tool on a jail broken device using dpkg &amp; launchctl

守护进程是由 `launchd` 启动，通过 `launchctl` 命令加载配置文件

后台进程包括两个部分，一个可执行的二进制文件和一个配置 plist 配置文件

## 一、创建可执行二进制文件

利用 [`Theos`](https://github.com/cszichao/theos-golang) 来创建一个可执行二进制文件, 保存在项目根目录下的 `/usr/bin/` 文件夹中

## 二、创建 plist

以 “com.haxii.demo.plist” 为文件名新建文件，然后将下面的代码写入文件中：

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>KeepAlive</key>
        <true/>
        <key>Label</key>
        <string>com.haxii.demo</string>
        <key>Program</key>
        <string>/usr/bin/daemon_demo</string>
        <key>RunAtLoad</key>
        <true/>
</dict>
</plist>
```

把这个 plist 配置文件保存在项目根目录下的 `/Library/LaunchDaemons/` 文件夹中

在这些键值对当中，Label 键对应的是一个可以唯一标示你的后台进程的字符串，
Program 键对应的是可执行文件所在位置的绝对路径，这两个都是必填的。

### 传入多个参数

如果你的后台进程还有其他的参数，那么只需要在文件中增加类似下面这样的键值对即可：

```text
    <key>ProgramArguments</key>
    <array>
        <string>arg1</string>
        <string>arg2</string>
        <string>more args...</string>
    </array>
```
工具的配置文件保存在项目根目录下的 `/etc/` 文件夹中

### Listening on Sockets

You can also include other keys in your configuration property list file. For example, if your daemon monitors a well-known port (one of the ports listed in /etc/services), add a Sockets entry as follows:
```text
    <key>Sockets</key>
    <dict>
        <key>Listeners</key>
        <dict>
            <key>SockServiceName</key>
            <string>daemondome</string>
            <key>SockType</key>
            <string>stream</string>
            <key>SockFamily</key>
            <string>IPv4</string>
        </dict>
    </dict>

```

The SockType is one of dgram (UDP) or stream (TCP/IP)

### Emulating inetd

The launchd daemon emulates the older inetd-style daemon semantics if you provide the inetdCompatibility key:

```text
    <key>inetdCompatibility</key>
    <dict>
        <key>Wait</key>
        <false/>
    </dict>
```

## 三、添加 deb 安装卸载脚本

创建文件夹 `DEBIAN`, 和文件 control

为了在 deb 包安装后自动运行，我们需要添加运行脚本 `extrainst_`  和 `prerm`

[参考文档](http://iphonedevwiki.net/index.php/Packaging)

最后我们的目录结构应该是这样

```text
.
├── DEBIAN
│   ├── control
│   ├── extrainst_
│   └── prerm
├── Library
│   └── LaunchDaemons
│       └── com.haxii.demo.plist
├── etc
│   └── demo.ini
└── usr
    └── bin
        └── daemon_demo
```

## 四、修改权限

因为后台进程是由`launchd`启动的，所以它应该属于 `root:wheel`：

```bash
haxii-5:~ root# ls -l /sbin/launchd
-r-xr-xr-x 1 root wheel 154736 Nov  8  2013 /sbin/launchd
```
所以需要修改包内每个文件的权限

先需要打包文件移动到一个临时文件夹`.tmp`下面, 然后修改权限,如下：

```bash
sudo chown -R root:wheel .tmp/
```
然后使用 dpkg-deb 打包 

可以尝试使用 Makefile 打包
```bash
sudo make
```
