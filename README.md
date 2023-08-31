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
      - MY_HOSTNAME=SYSTEM-HOSTNAME-HERE
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
- mailserver runs on host "mynas"
- You want to send cron email from host "daily_driver"
- the user on "daily_driver" is "fred"
- you have added "mynas" in /etc/hosts on "daily_driver"

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

        default: localmail@mynas
        fred: localmail@mynas


## Read mail with Thunderbird

- create new mail account "LocalMail"
- Default Identity - Change "mynas"
    - Your Name: Local Mail
    - Email Address: localmail@mynas
- Server Settings
    - Server Type: IMAP Mail Server
    - Port: 14300
    - Server Name: mynas
    - User Name: localmail
    - Connection Security: STARTTLS
    - Authentication Method: Normal password
- When it asks for a password, use the password specified in MY_PASSWORD above

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

