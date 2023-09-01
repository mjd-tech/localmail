# localmail
Docker image for Mail/IMAP server for local network

- receive-only, no internet
- Based on Debian, Postfix, Dovecot
- Intended for receiving cron email from local linux hosts
- Read mail with IMAP client such as Thunderbird

NOTE: the email user account is hard-coded to "localmail".

## Build image
```
# you may need sudo to do this
docker build -t localmail .
```

## Compose / Portainer
These are the settings that worked for me.

In this example the mailserver is **mynas.local**  
Replace mynas with your servername. keep the .local  
I tried just using mynas without the .local but couldn't get Thunderbird to connect.

Ports 2500 and 14300 are used so it won't interfere with other mail services.
Some NAS units run Postfix on the standard ports.

Change MY_HOSTNAME, MY_PASSWORD, /PATH/TO

```
version: "2.1"
services:
  localmail:
    image: localmail
    container_name: localmail
    environment:
      - MY_HOSTNAME=mynas.local
      - MY_PASSWORD=password
    volumes:
      - /PATH/TO/appdata/localmail/Maildir:/home/localmail/Maildir
      - /etc/timezone:/etc/timezone:ro
    ports:
      - 2500:25/tcp
      - 14300:143/tcp
    init: true
    restart: unless-stopped
```

## Sending cron email from linux hosts
For example:
- mailserver runs on "mynas.local"
- You want to send cron email from "daily_driver"
- the user on "daily_driver" is "fred"
- you have added "mynas.local" and its IP4 address in `/etc/hosts` on "daily_driver"

On "daily_driver"
- install **msmtp-mta** package
- edit (as root) `/etc/msmtprc` Change host, port (if needed), and "from"

        account default
        host mynas
        port 2500
        auto_from off
        from fred@daily_driver
        aliases /etc/aliases
        syslog LOG_MAIL

- edit (as root) `/etc/aliases` Change "mynas" and "fred" as needed

        default: localmail@mynas.local
        fred: localmail@mynas.local


## Read mail with Thunderbird

- create new mail account "LocalMail"
- Default Identity - Change "mynas"
    - Your Name: Local Mail
    - Email Address: localmail@mynas.local
- Server Settings
    - Server Type: IMAP Mail Server
    - Port: 14300
    - Server Name: mynas.local
    - User Name: localmail
    - Connection Security: STARTTLS
    - Authentication Method: Normal password
- When it asks for a password, use the password specified in MY_PASSWORD above

### NOTE - IP6 and the .local domain
- .local is a special domain name used by mDNS (avahi), which runs on most Linux boxes.
- avahi supports both IP4 and IP6, but Docker containers only work with IP4.
- If Thunderbird sees mynas.local as an IP6 address, it won't connect
- Put "mynas.local" in your `/etc/hosts` file, with its IP4 address
- check your `/etc/nsswitch.conf`. It should have a line like this:

```
hosts:          files mdns4_minimal [NOTFOUND=return] dns myhostname
```
There may be other stuff. The important thing is "files" comes before "mdns..."

## Testing

```
# send mail to root, receive mail at mailbox specified in /etc/aliases
echo -e "Subject: Hello\n\nHello, world" | sendmail root

# create a test cron job as root.
sudo crontab -e

# add this line, and a blank line below it
* * * * *  echo Test from root cron

# email should be sent at start of next minute.
```

Be sure to **deactivate** the cron job when finished testing!

