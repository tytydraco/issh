# issh
Insecure shelling via netcat

# Features
- Support embedded systems that lack OpenSSL/OpenSSH
- Upwards of 10x faster (see benchmarks)
- Android support
- Relies almost exclusively on [toybox](http://landley.net/toybox/about.html)
- Acts as both a server and client
- Supports fully interactive clients
- Supports filtering of external connections

# Benchmarks against OpenSSH
Since we do not rely on OpenSSL, we are able to get a reply from a server in significantly less time using issh. In this benchmark, we compare `sshpass -p <PASSWORD> ssh host@localhost <COMMAND>` against `./issh.sh -c "sh"` and `./issh.sh -C localhost`.

- OpenSSH: ~150ms avg
- issh: ~15ms avg

# Examples
You can use issh for a variety of tasks. Here's a few examples to get you started.

### Remote interactive shell (no auth)
- Server: `setsid ./issh.sh &` (forks our server to the background)
- Client: `./issh.sh -C localhost -t` (connects as an interactive tty)

### Remote interactive shell (auth)
- Server: `setsid ./issh.sh -c "./auth.sh" &`
- Server: Create an authentication script that should be presented to the client on connect. Here's an example. Ideally, your password would not be stored in plaintext in the script. Other authentication ideas could be to use SSL or GPG keys. **Authentication is not provided by issh.**
```sh
#!/usr/bin/env bash
echo -n "Enter secret key: "
read -r key
[[ "$key" == "password123" ]] && bash -li 2>&1
```
- Client: `./issh.sh -C localhost -t` (connects as an interactive tty)
- Client: `Enter secret key: password123`

### Public system API
- Server: `setsid ./issh.sh -c "cat /proc/loadavg" &`
- Client: `SERVER_LOADAVG="$(./issh.sh -C localhost)"`

# Android
Since issh is built on top of toybox instead of typical GNU tools, we can support a wider variety of devices, including Android.

### Opening a privileged ADB shell session
A useful concept is allowing a regular user to gain ADB-level access without needing to be constantly connected to a computer, nor needing wireless debugging or an ADB binary of any kind.

1) Using a computer, start an `adb shell`
2) Pull the `issh.sh` script somewhere local (i.e. /sdcard/Download/)
3) `setsid sh issh.sh &`

Now, on a client (which can be the device itself via a standard terminal emulator), we can connect to this session locally.
1) `sh issh.sh -C localhost -t`
2) `pm grant com.example.app android.permission.PRIVILEDGED_PERMISSION_EXAMPLE`

In this case, our client does not need to use a computer to gain ADB-level access since we have an open issh session.

### Termux
You can launch an issh session in Termux as well. However, Termux lacks toybox, so we must add it to our PATH variable from the Android system.

1) `export PATH="$PATH:/system/bin"`
2) `./issh.sh`

### Benefits
1) Avoiding ADB protocol entirely
2) Avoiding cross-compiling ADB binary
3) Avoiding external programs that rely on binary executables
4) Compatibility with Android 6+ (instead of Android 10+)
5) Wireless debugging is no longer necessary
