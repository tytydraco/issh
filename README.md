# issh
Insecure shelling via netcat

# Install
For a typical Linux system, putting this script in the PATH variable should be enough.
- `curl -L https://git.io/JnKnM > /usr/local/bin/issh && chmod +x /usr/local/bin/issh`

# Features
- Support embedded systems that lack OpenSSL/OpenSSH
- Upwards of 10x faster (see benchmarks)
- Android support
- Relies almost exclusively on [toybox](http://landley.net/toybox/about.html)
- Acts as both a server and client
- Supports fully interactive clients
- Supports filtering of external connections

# Benchmarks against OpenSSH
Since we do not rely on OpenSSL, we are able to get a reply from a server in significantly less time using issh. In this benchmark, we compare `sshpass -p <PASSWORD> ssh host@localhost <COMMAND>` against `./issh -c "sh"` and `./issh -C localhost`.

- OpenSSH: ~150ms avg latency
- issh: ~15ms avg latency

# Examples
You can use issh for a variety of tasks. Here's a few examples to get you started.

### Remote non-interactive shell
- Server: `./issh -d` (`-d` forks our server to the background)
- Client: `echo "whoami" | ./issh -C localhost`

### Remote interactive shell (no auth)
Note that for interactive shells, we should do a few things:
1) Use a login shell, so we source our profile dotfile
2) Use an interactive shell to handle TTY commands
3) Redirect STDERR to STDOUT, so our client can see it
- Server: `./issh -d -c "sh -li 2>&1"`
- Client: `./issh -C localhost -t` (connects as an interactive tty)

### Remote interactive shell (su auth)
- Server: `./issh -d -c "su -c 'sh -li' - username 2>&1"`
- Client: `./issh -C localhost -t` (greeted with su asking for password; if success, dropped into `sh -li`)

### Remote interactive shell (custom auth)
- Server: `./issh -d -c "./auth.sh"`
- Server: Create an authentication script that should be presented to the client on connect. Here's an example. Ideally, your password would not be stored in plaintext in the script. Other authentication ideas could be to use SSL or GPG keys. **Authentication is not provided by issh.**
```sh
#!/usr/bin/env bash
echo -n "Enter secret key: "
read -r key
[[ "$key" == "password123" ]] && bash -li 2>&1
```
- Client: `./issh -C localhost -t` (connects as an interactive tty)
- Client: `Enter secret key: password123`

### Public system API
- Server: `./issh -d -c "cat /proc/loadavg"`
- Client: `SERVER_LOADAVG="$(./issh -C localhost)"`

# Systemd
You can start issh on bootup using systemd. The default configuration creates an interactive bash session.
1) `cp issh /usr/bin/issh`
2) `chmod +x /usr/bin/issh`
3) `cp systemd/isshd.service /etc/systemd/system/`
4) `chmod +x /etc/systemd/system/isshd.service`
5) `systemctl enable --now isshd`

# Android
Since issh is built on top of toybox instead of typical GNU tools, we can support a wider variety of devices, including Android.

### Opening a privileged ADB shell session
A useful concept is allowing a regular user to gain ADB-level access without needing to be constantly connected to a computer, nor needing wireless debugging or an ADB binary of any kind.

1) Using a computer, start an `adb shell`
2) Pull the `issh` script somewhere local (i.e., /sdcard/Download/)
3) `sh issh -d -c "sh -li 2>&1"`

Now, on a client (which can be the device itself via a standard terminal emulator), we can connect to this session locally.
1) `sh issh -C localhost -t`
2) `pm grant com.example.app android.permission.PRIVILEDGED_PERMISSION_EXAMPLE`

In this case, our client does not need to use a computer to gain ADB-level access since we have an open issh session.

### Benefits
1) Avoiding ADB protocol entirely
2) Avoiding cross-compiling ADB binary
3) Avoiding external programs that rely on binary executables
4) Compatibility with Android 6+ (instead of Android 10+)
5) Wireless debugging is no longer necessary

### Termux
You can launch an issh session in Termux as well. However, Termux lacks toybox, so we must add it to our PATH variable from the Android system. Use the built-in Termux issh wrapper to automate the process:
1) `./issh.termux.sh`
