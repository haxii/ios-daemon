# iOS-daemon

Demonize an iOS command-line tool on a jail broken device using dpkg &amp; launchctl

## 原理

守护进程是由 `launchd` 启动，通过 `launchctl` 命令加载配置文件

后台进程主要包括两个部分，一个可执行的二进制文件和一个配置 plist 配置文件

因为后台进程是由`launchd`启动的，所以它应该属于 `root:wheel`：

```bash
haxii-5:~ root# ls -l /sbin/launchd
-r-xr-xr-x 1 root wheel 154736 Nov  8  2013 /sbin/launchd
```

所以 deb 安装包内的文件必须是 `root:wheel` 权限，这样安装后才可以被 `launchd` 启动

## 构建 deb 安装包

现在我们已经有了一个可执行二进制文件 `daemon_demo` (这个 demo 是一个 http server, 安装成功以后,
 你可以访问`http://0.0.0.0:1118/`来验证是否成功) 和它的配置文件 `demo.ini` (提供一个 server port 配置)

接下来需要做的是创建一个 plist 配置文件, 
deb 安装包的基本信息文件 `control` 和安装卸载的脚本文件 `extrainst_` `prerm`, 
最后修改他们的权限并使用 `dpkg-deb` 打包

### 创建 plist 配置文件

以 “com.haxii.demo.plist” 为文件名新建文件，然后将下面的代码写入文件中：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>KeepAlive</key>
        <true/>
        <key>Label</key>
        <string>com.haxii.demo</string>
        <key>ProgramArguments</key>
        <array>
            <string>/usr/bin/daemon_demo</string>
            <string>-config</string>
            <string>/etc/demo.ini</string>
        </array>
        <key>Sockets</key>
        <dict>
            <key>Listeners</key>
            <dict>
                <key>SockServiceName</key>
                <string>daemondemo</string>
                <key>SockType</key>
                <string>stream</string>
                <key>SockFamily</key>
                <string>IPv4</string>
            </dict>
        </dict>
        <key>inetdCompatibility</key>
        <dict>
            <key>Wait</key>
            <false/>
        </dict>
        <key>StandardErrorPath</key>
        <string>/dev/null</string>
        <key>SessionCreate</key>
        <true/>
        <key>RunAtLoad</key>
        <true/>
    </dict>
</plist>
```

在这些键值对当中:
* Label 键对应的是一个可以唯一标示你的后台进程的字符串，
* Program 键对应的是可执行文件所在位置的绝对路径，这两个都是必填的。
* ProgramArguments 如果你的后台进程还有其他的参数，那么只需要在文件中增加这样的键值对即可
* KeepAlive 被杀死后会自动开启
* RunAtLoad `launchctl` load plist 配置文件后会自动启动服务
* Sockets if your daemon monitors a well-known port (one of the ports listed in /etc/services)
  * SockServiceName  The string for SockServiceName typically comes from the leftmost column in /etc/services
  * SockType is one of dgram (UDP) or stream (TCP/IP)
* inetdCompatibility The launchd daemon emulates the older inetd-style daemon semantics if you provide the inetdCompatibility key:


### 创建 deb 安装包的 control 和安装卸载脚本

创建基本信息文件 control, 记录软件标识，版本号，平台，依赖信息等数据
```text
Package: com.haxii.daemondemo
Name: daemondemo
Depends: 
Architecture: iphoneos-arm
Description: haxii 
Maintainer: haxii
Author: haxii
Section: System
Tag: role::hacker
Version: 0.0.1-1+debug
```

添加 deb 包 安装和更新时运行的脚本文件 `extrainst_` 
```bash
#!/bin/sh

if [[ $1 == upgrade ]]; then
    /bin/launchctl unload /Library/LaunchDaemons/com.haxii.demo.plist
fi

if [[ $1 == install || $1 == upgrade ]]; then
    /bin/launchctl load /Library/LaunchDaemons/com.haxii.demo.plist
fi

exit 0
```

添加 deb 包 卸载时运行的脚本文件 `prerm`
```bash
#!/bin/sh

if [[ $1 == remove || $1 == purge ]]; then
    /bin/launchctl unload /Library/LaunchDaemons/com.haxii.demo.plist
fi

exit 0
```

### 整理文件目录

最后我们把可执行二进制文件 `daemon_demo` 保存在项目根目录下的 `/usr/bin/` 文件夹中

可执行二进制文件的配置文件 `demo.ini` 保存在项目根目录下的 `/etc/` 文件夹中

把 plist 配置文件 `com.haxii.demo.plist` 保存在项目根目录下的 `/Library/LaunchDaemons/` 文件夹中

把 `control`, `extrainst_`, `prerm` 放在项目根目录下的 `/DEBIAN/` 文件夹中

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

### 修改权限

通过命令将所有文件的 `用户和组` 改为 `root:wheel`：

先需要打包文件移动到一个临时文件夹`.tmp`下面, 然后修改权限,如下：

```bash
sudo chown -R root:wheel .tmp/
```
### 使用 dpkg-deb 打包 

最后我们可以使用 dpkg-deb 将所有文件打成 deb 包, 这个 deb 包在安装后，
 `daemon_demo` 就可以变成一个守护进程来运行, 并且杀死后自动重启

## 参考文档

> [dpkg Packaging](http://iphonedevwiki.net/index.php/Packaging)

> [Daemons and Services Programming Guide](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)