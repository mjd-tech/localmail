FROM debian:buster-slim

# Install Packages
RUN apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
ca-certificates \
dovecot-imapd \
gettext-base \
mailutils \
postfix \
procmail \
sasl2-bin \
&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Generate email user
RUN adduser localmail --quiet --disabled-password --shell /usr/sbin/nologin --gecos ""
RUN mkdir /home/localmail/Maildir && chown localmail /home/localmail/Maildir && \
chmod 700 /home/localmail/Maildir

# Copy dovecot configuration
COPY 10-auth.conf /etc/dovecot/conf.d/10-auth.conf
COPY 10-master.conf /etc/dovecot/conf.d/10-master.conf
COPY 10-mail.conf /etc/dovecot/conf.d/10-mail.conf

# Copy postfix template. It's used to generate the actual conf file at runtime. 
COPY ./main.cf.template ./
COPY ./entrypoint.sh ./

EXPOSE 25/TCP 143/TCP

ENTRYPOINT ["./entrypoint.sh"]
CMD ["postfix", "-v", "start-fg"]
