# issh
An insecure SSH clone using a netcat backend (Android supported)

# How it works
Netcat opens a port on the server device connected to an open shell session. Clients can then connect to the netcat port using their own netcat client.

# Features
- Android support
- Few dependencies (mainly just toybox)
- Local connection filter (only allow localhost connections)

# Usage examples
- No authentication: `sh issh.sh`
- Special port: `sh issh.sh -p [PORT]`

# Android
A main attraction is support for Android using Toybox's netcat potocol. Here's an example of how we can use a computer to open a privileged adb shell session using issh:

Server side:
1) `adb shell`
2) `sh issh.sh`
3) `exit`

Client side (i.e. device itself via terminal emulator):
1) `nc localhost 65432`
2) `pm grant com.example.app android.permission.PRIVILEDGED_PERMISSION_EXAMPLE`

In this case, our client does not need to use a computer to gain adb shell-level access if we have previously opened an issh session.

### Termux
You can launch an issh session in Termux very easily. However, Termux lacks toybox, so we must add it to our PATH variable.

1) `export PATH="$PATH:/system/bin/toybox"`
2) `/system/bin/sh issh.sh`

### But why not use self-connected ADB then (i.e. Termux, LADB, etc.)
1) Avoiding ADB protocol entirely
2) Avoiding cross-compiling ADB binary
3) Avoiding external programs that rely on binary executables
4) Compatibility with Android 6+ (intead of Android 10+)
5) Wireless debugging is no longer necessary

### Limitations
1) Session must be restarted per device reboot
