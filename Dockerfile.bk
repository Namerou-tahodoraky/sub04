FROM python:3.9-buster as build-stage

RUN apt-get update
RUN apt-get install -y curl gnupg2 ca-certificates lsb-release
RUN echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
RUN curl -o /tmp/nginx_signing.key https://nginx.org/keys/nginx_signing.key
RUN mv /tmp/nginx_signing.key /etc/apt/trusted.gpg.d/nginx_signing.asc
RUN apt-get update
RUN apt-get install -y nginx
RUN pip install flask uwsgi

RUN mkdir -p /build/usr/local/bin
RUN mkdir -p /build/usr/lib

# nginx
RUN mkdir -p /build/etc/default/
RUN cp -r /etc/default/nginx /build/etc/default/nginx
RUN cp -r /etc/default/nginx-debug /build/etc/default/nginx-debug

RUN mkdir -p /build/etc/init.d/
RUN cp -r /etc/init.d/nginx /build/etc/init.d/nginx
RUN cp -r /etc/init.d/nginx-debug /build/etc/init.d/nginx-debug

RUN mkdir -p /build/etc/logrotate.d/
RUN cp -r /etc/logrotate.d/nginx /build/etc/logrotate.d/nginx


RUN mkdir -p /build/etc/
RUN cp -r /etc/nginx /build/etc/nginx

RUN mkdir -p /build/lib/systemd/system
RUN cp -r /lib/systemd/system/nginx.service /build/lib/systemd/system/nginx.service
RUN cp -r /lib/systemd/system/nginx-debug.service /build/lib/systemd/system/nginx-debug.service

RUN mkdir -p /build/usr/lib/nginx
RUN cp -r /usr/lib/nginx /build/usr/lib/nginx

RUN mkdir -p /build/usr/sbin
RUN cp -r /usr/sbin/nginx /build/usr/sbin/nginx
RUN cp -r /usr/sbin/nginx-debug /build/usr/sbin/nginx-debug

# flask
RUN cp /usr/local/bin/flask /build/usr/local/bin/

# uwsgi
RUN cp /usr/local/bin/uwsgi /build/usr/local/bin/
RUN mkdir -p /build/usr/lib/x86_64-linux-gnu/
RUN cp /usr/lib/x86_64-linux-gnu/libicui18n.so.63 /build/usr/lib/x86_64-linux-gnu/libicui18n.so.63
RUN cp /usr/lib/x86_64-linux-gnu/libicudata.so.63 /build/usr/lib/x86_64-linux-gnu/libicudata.so.63
RUN cp /usr/lib/x86_64-linux-gnu/libxml2.so.2 /build/usr/lib/x86_64-linux-gnu/libxml2.so.2
RUN cp /usr/lib/x86_64-linux-gnu/libicuuc.so.63 /build/usr/lib/x86_64-linux-gnu/libicuuc.so.63

# other python librarys
RUN mkdir -p /build/usr/local/lib/python3.9/
RUN cp -r /usr/local/lib/python3.9/site-packages /build/usr/local/lib/python3.9/site-packages

FROM python:3.9-slim-buster as release-stage
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo
COPY --from=build-stage /build/ /
COPY ./app/default.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /var/log/nginx \
  && mkdir -p /var/cache/nginx \
  && useradd nginx

CMD ["/bin/bash", "/app/entrypoint.sh"]
