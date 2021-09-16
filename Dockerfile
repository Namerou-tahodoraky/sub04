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

FROM python:3.9-buster as refinedet-build

## caffe-cpuの依存ライブラリにtzdataがある.
## tzdataインストール前にgitをインストールしていると、
## tzdataインストール時にコマンドラインでtimezoneの入力を求められる.
## DEBIAN_FRONTEND=noninteractive はそれを回避する為.
# ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y libprotobuf-dev libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev protobuf-compiler
RUN apt-get install -y --no-install-recommends libboost-all-dev
RUN apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev
RUN apt-get install -y libopenblas-dev libatlas-base-dev
RUN pip install \
    numpy \
    scikit-image \
  && pip cache purge
COPY ./RefineDet_build_multicore /RefineDet
RUN cd /RefineDet && make all
RUN cd /RefineDet && make py

# copy binary's
RUN mkdir -p /build/RefineDet/build/lib/ \
  && mkdir -p /build/lib/x86_64-linux-gnu/ \
  && mkdir -p /build/usr/lib/ \
  && mkdir -p /build/usr/lib/x86_64-linux-gnu/ \
  && cp /RefineDet/.build_release/lib/libcaffe.so.1.0.0-rc3 /build/RefineDet/build/lib/ \
  && cp -r /RefineDet/python /build/RefineDet/ \
  && cp /lib/x86_64-linux-gnu/libdbus-1.so.3 \
      /lib/x86_64-linux-gnu/libkeyutils.so.1 \
      /lib/x86_64-linux-gnu/libusb-1.0.so.0 \
    /build/lib/x86_64-linux-gnu/ \
  && cp /usr/lib/libarmadillo.so.9 \
      /usr/lib/libdfalt.so.0 \
      /usr/lib/libgdal.so.20 \
      /usr/lib/libmfhdfalt.so.0 \
      /usr/lib/libogdi.so.3.2 \
    /build/usr/lib/ \
  && cp /usr/lib/x86_64-linux-gnu/libCharLS.so.2 \
      /usr/lib/x86_64-linux-gnu/libHalf.so.23 \
      /usr/lib/x86_64-linux-gnu/libIex-2_2.so.23 \
      /usr/lib/x86_64-linux-gnu/libIlmImf-2_2.so.23 \
      /usr/lib/x86_64-linux-gnu/libIlmThread-2_2.so.23 \
      /usr/lib/x86_64-linux-gnu/libImath-2_2.so.23 \
      /usr/lib/x86_64-linux-gnu/libX11.so.6 \
      /usr/lib/x86_64-linux-gnu/libXau.so.6 \
      /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 \
      /usr/lib/x86_64-linux-gnu/libXcursor.so.1 \
      /usr/lib/x86_64-linux-gnu/libXdamage.so.1 \
      /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 \
      /usr/lib/x86_64-linux-gnu/libXext.so.6 \
      /usr/lib/x86_64-linux-gnu/libXfixes.so.3 \
      /usr/lib/x86_64-linux-gnu/libXi.so.6 \
      /usr/lib/x86_64-linux-gnu/libXinerama.so.1 \
      /usr/lib/x86_64-linux-gnu/libXrandr.so.2 \
      /usr/lib/x86_64-linux-gnu/libXrender.so.1 \
      /usr/lib/x86_64-linux-gnu/libaec.so.0 \
      /usr/lib/x86_64-linux-gnu/libaom.so.0 \
      /usr/lib/x86_64-linux-gnu/libarpack.so.2 \
      /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libatlas.so.3 \
      /usr/lib/x86_64-linux-gnu/libatomic.so.1 \
      /usr/lib/x86_64-linux-gnu/libatspi.so.0 \
      /usr/lib/x86_64-linux-gnu/libavcodec.so.58 \
      /usr/lib/x86_64-linux-gnu/libavformat.so.58 \
      /usr/lib/x86_64-linux-gnu/libavresample.so.4 \
      /usr/lib/x86_64-linux-gnu/libavutil.so.56 \
      /usr/lib/x86_64-linux-gnu/libblas.so.3 \
      /usr/lib/x86_64-linux-gnu/libbluray.so.2 \
      /usr/lib/x86_64-linux-gnu/libboost_atomic.so.1.67.0 \
      /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.67.0 \
      /usr/lib/x86_64-linux-gnu/libboost_python37.so.1.67.0 \
      /usr/lib/x86_64-linux-gnu/libboost_regex.so.1.67.0 \
      /usr/lib/x86_64-linux-gnu/libboost_system.so.1.67.0 \
      /usr/lib/x86_64-linux-gnu/libboost_thread.so.1.67.0 \
      /usr/lib/x86_64-linux-gnu/libbsd.so.0 \
      /usr/lib/x86_64-linux-gnu/libcairo-gobject.so.2 \
      /usr/lib/x86_64-linux-gnu/libcairo.so.2 \
      /usr/lib/x86_64-linux-gnu/libcblas.so.3 \
      /usr/lib/x86_64-linux-gnu/libchromaprint.so.1 \
      /usr/lib/x86_64-linux-gnu/libcodec2.so.0.8.1 \
      /usr/lib/x86_64-linux-gnu/libcroco-0.6.so.3 \
      /usr/lib/x86_64-linux-gnu/libcrystalhd.so.3 \
      /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.4 \
      /usr/lib/x86_64-linux-gnu/libdap.so.25 \
      /usr/lib/x86_64-linux-gnu/libdapclient.so.6 \
      /usr/lib/x86_64-linux-gnu/libdapserver.so.7 \
      /usr/lib/x86_64-linux-gnu/libdatrie.so.1 \
      /usr/lib/x86_64-linux-gnu/libdc1394.so.22 \
      /usr/lib/x86_64-linux-gnu/libdrm.so.2 \
      /usr/lib/x86_64-linux-gnu/libepoxy.so.0 \
      /usr/lib/x86_64-linux-gnu/libepsilon.so.1 \
      /usr/lib/x86_64-linux-gnu/libexif.so.12 \
      /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 \
      /usr/lib/x86_64-linux-gnu/libfreetype.so.6 \
      /usr/lib/x86_64-linux-gnu/libfreexl.so.1 \
      /usr/lib/x86_64-linux-gnu/libfribidi.so.0 \
      /usr/lib/x86_64-linux-gnu/libfyba.so.0 \
      /usr/lib/x86_64-linux-gnu/libfygm.so.0 \
      /usr/lib/x86_64-linux-gnu/libfyut.so.0 \
      /usr/lib/x86_64-linux-gnu/libgdcmCommon.so.2.8 \
      /usr/lib/x86_64-linux-gnu/libgdcmDICT.so.2.8 \
      /usr/lib/x86_64-linux-gnu/libgdcmDSED.so.2.8 \
      /usr/lib/x86_64-linux-gnu/libgdcmIOD.so.2.8 \
      /usr/lib/x86_64-linux-gnu/libgdcmMSFF.so.2.8 \
      /usr/lib/x86_64-linux-gnu/libgdcmjpeg12.so.2.8 \
      /usr/lib/x86_64-linux-gnu/libgdcmjpeg16.so.2.8 \
      /usr/lib/x86_64-linux-gnu/libgdcmjpeg8.so.2.8 \
      /usr/lib/x86_64-linux-gnu/libgdk-3.so.0 \
      /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libgeos-3.7.1.so \
      /usr/lib/x86_64-linux-gnu/libgeos_c.so.1 \
      /usr/lib/x86_64-linux-gnu/libgeotiff.so.2 \
      /usr/lib/x86_64-linux-gnu/libgflags.so.2.2 \
      /usr/lib/x86_64-linux-gnu/libgfortran.so.5 \
      /usr/lib/x86_64-linux-gnu/libgif.so.7 \
      /usr/lib/x86_64-linux-gnu/libgio-2.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libglib-2.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libglog.so.0 \
      /usr/lib/x86_64-linux-gnu/libgme.so.0 \
      /usr/lib/x86_64-linux-gnu/libgmodule-2.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libgobject-2.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libgomp.so.1 \
      /usr/lib/x86_64-linux-gnu/libgphoto2.so.6 \
      /usr/lib/x86_64-linux-gnu/libgphoto2_port.so.12 \
      /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 \
      /usr/lib/x86_64-linux-gnu/libgsm.so.1 \
      /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2 \
      /usr/lib/x86_64-linux-gnu/libgthread-2.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libgtk-3.so.0 \
      /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 \
      /usr/lib/x86_64-linux-gnu/libhdf5_serial.so.103 \
      /usr/lib/x86_64-linux-gnu/libhdf5_serial_hl.so.100 \
      /usr/lib/x86_64-linux-gnu/libicudata.so.63 \
      /usr/lib/x86_64-linux-gnu/libicui18n.so.63 \
      /usr/lib/x86_64-linux-gnu/libicuuc.so.63 \
      /usr/lib/x86_64-linux-gnu/libjbig.so.0 \
      /usr/lib/x86_64-linux-gnu/libjpeg.so.62 \
      /usr/lib/x86_64-linux-gnu/libjson-c.so.3 \
      /usr/lib/x86_64-linux-gnu/libk5crypto.so.3 \
      /usr/lib/x86_64-linux-gnu/libkmlbase.so.1 \
      /usr/lib/x86_64-linux-gnu/libkmlconvenience.so.1 \
      /usr/lib/x86_64-linux-gnu/libkmldom.so.1 \
      /usr/lib/x86_64-linux-gnu/libkmlengine.so.1 \
      /usr/lib/x86_64-linux-gnu/libkmlregionator.so.1 \
      /usr/lib/x86_64-linux-gnu/libkmlxsd.so.1 \
      /usr/lib/x86_64-linux-gnu/libkrb5.so.3 \
      /usr/lib/x86_64-linux-gnu/libkrb5support.so.0 \
      /usr/lib/x86_64-linux-gnu/liblapack.so.3 \
      /usr/lib/x86_64-linux-gnu/liblber-2.4.so.2 \
      /usr/lib/x86_64-linux-gnu/liblcms2.so.2 \
      /usr/lib/x86_64-linux-gnu/libldap_r-2.4.so.2 \
      /usr/lib/x86_64-linux-gnu/libleveldb.so.1d \
      /usr/lib/x86_64-linux-gnu/liblmdb.so.0 \
      /usr/lib/x86_64-linux-gnu/libltdl.so.7 \
      /usr/lib/x86_64-linux-gnu/libmariadb.so.3 \
      /usr/lib/x86_64-linux-gnu/libminizip.so.1 \
      /usr/lib/x86_64-linux-gnu/libmp3lame.so.0 \
      /usr/lib/x86_64-linux-gnu/libmpg123.so.0 \
      /usr/lib/x86_64-linux-gnu/libnetcdf.so.13 \
      /usr/lib/x86_64-linux-gnu/libnghttp2.so.14 \
      /usr/lib/x86_64-linux-gnu/libnspr4.so \
      /usr/lib/x86_64-linux-gnu/libnss3.so \
      /usr/lib/x86_64-linux-gnu/libnssutil3.so \
      /usr/lib/x86_64-linux-gnu/libnuma.so.1 \
      /usr/lib/x86_64-linux-gnu/libodbc.so.2 \
      /usr/lib/x86_64-linux-gnu/libodbcinst.so.2 \
      /usr/lib/x86_64-linux-gnu/libogg.so.0 \
      /usr/lib/x86_64-linux-gnu/libopenblas.so.0 \
      /usr/lib/x86_64-linux-gnu/libopencv_core.so.3.2 \
      /usr/lib/x86_64-linux-gnu/libopencv_highgui.so.3.2 \
      /usr/lib/x86_64-linux-gnu/libopencv_imgcodecs.so.3.2 \
      /usr/lib/x86_64-linux-gnu/libopencv_imgproc.so.3.2 \
      /usr/lib/x86_64-linux-gnu/libopencv_videoio.so.3.2 \
      /usr/lib/x86_64-linux-gnu/libopenjp2.so.7 \
      /usr/lib/x86_64-linux-gnu/libopenmpt.so.0 \
      /usr/lib/x86_64-linux-gnu/libopus.so.0 \
      /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 \
      /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 \
      /usr/lib/x86_64-linux-gnu/libplc4.so \
      /usr/lib/x86_64-linux-gnu/libplds4.so \
      /usr/lib/x86_64-linux-gnu/libpng16.so.16 \
      /usr/lib/x86_64-linux-gnu/libpoppler.so.82 \
      /usr/lib/x86_64-linux-gnu/libpopt.so.0 \
      /usr/lib/x86_64-linux-gnu/libpq.so.5 \
      /usr/lib/x86_64-linux-gnu/libproj.so.13 \
      /usr/lib/x86_64-linux-gnu/libprotobuf.so.17 \
      /usr/lib/x86_64-linux-gnu/libpsl.so.5 \
      /usr/lib/x86_64-linux-gnu/libqhull.so.7 \
      /usr/lib/x86_64-linux-gnu/libquadmath.so.0 \
      /usr/lib/x86_64-linux-gnu/libraw1394.so.11 \
      /usr/lib/x86_64-linux-gnu/librsvg-2.so.2 \
      /usr/lib/x86_64-linux-gnu/librtmp.so.1 \
      /usr/lib/x86_64-linux-gnu/libsasl2.so.2 \
      /usr/lib/x86_64-linux-gnu/libshine.so.3 \
      /usr/lib/x86_64-linux-gnu/libsmime3.so \
      /usr/lib/x86_64-linux-gnu/libsnappy.so.1 \
      /usr/lib/x86_64-linux-gnu/libsoxr.so.0 \
      /usr/lib/x86_64-linux-gnu/libspatialite.so.7 \
      /usr/lib/x86_64-linux-gnu/libspeex.so.1 \
      /usr/lib/x86_64-linux-gnu/libssh-gcrypt.so.4 \
      /usr/lib/x86_64-linux-gnu/libssh2.so.1 \
      /usr/lib/x86_64-linux-gnu/libsuperlu.so.5 \
      /usr/lib/x86_64-linux-gnu/libswresample.so.3 \
      /usr/lib/x86_64-linux-gnu/libswscale.so.5 \
      /usr/lib/x86_64-linux-gnu/libsz.so.2 \
      /usr/lib/x86_64-linux-gnu/libtbb.so.2 \
      /usr/lib/x86_64-linux-gnu/libthai.so.0 \
      /usr/lib/x86_64-linux-gnu/libtheoradec.so.1 \
      /usr/lib/x86_64-linux-gnu/libtheoraenc.so.1 \
      /usr/lib/x86_64-linux-gnu/libtiff.so.5 \
      /usr/lib/x86_64-linux-gnu/libtwolame.so.0 \
      /usr/lib/x86_64-linux-gnu/libunwind.so.8 \
      /usr/lib/x86_64-linux-gnu/liburiparser.so.1 \
      /usr/lib/x86_64-linux-gnu/libva-drm.so.2 \
      /usr/lib/x86_64-linux-gnu/libva-x11.so.2 \
      /usr/lib/x86_64-linux-gnu/libva.so.2 \
      /usr/lib/x86_64-linux-gnu/libvdpau.so.1 \
      /usr/lib/x86_64-linux-gnu/libvorbis.so.0 \
      /usr/lib/x86_64-linux-gnu/libvorbisenc.so.2 \
      /usr/lib/x86_64-linux-gnu/libvorbisfile.so.3 \
      /usr/lib/x86_64-linux-gnu/libvpx.so.5 \
      /usr/lib/x86_64-linux-gnu/libwavpack.so.1 \
      /usr/lib/x86_64-linux-gnu/libwayland-client.so.0 \
      /usr/lib/x86_64-linux-gnu/libwayland-cursor.so.0 \
      /usr/lib/x86_64-linux-gnu/libwayland-egl.so.1 \
      /usr/lib/x86_64-linux-gnu/libwebp.so.6 \
      /usr/lib/x86_64-linux-gnu/libwebpmux.so.3 \
      /usr/lib/x86_64-linux-gnu/libx264.so.155 \
      /usr/lib/x86_64-linux-gnu/libx265.so.165 \
      /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 \
      /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 \
      /usr/lib/x86_64-linux-gnu/libxcb.so.1 \
      /usr/lib/x86_64-linux-gnu/libxerces-c-3.2.so \
      /usr/lib/x86_64-linux-gnu/libxkbcommon.so.0 \
      /usr/lib/x86_64-linux-gnu/libxml2.so.2 \
      /usr/lib/x86_64-linux-gnu/libxvidcore.so.4 \
      /usr/lib/x86_64-linux-gnu/libzvbi.so.0 \
    /build/usr/lib/x86_64-linux-gnu/ \
  && mkdir -p /build/usr/local/lib/python3.9/ \
  && cp -r /usr/local/lib/python3.9/site-packages /build/usr/local/lib/python3.9/site-packages

FROM python:3.9-slim-buster as release-stage
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo
COPY --from=build-stage /build/ /
COPY --from=refinedet-build /build/ /
RUN mkdir -p /var/log/nginx \
  && mkdir -p /var/cache/nginx \
  && useradd nginx
ENV PYTHONPATH=/RefineDet/python
ARG NUM_THREADS=8
ENV OPENBLAS_NUM_THREADS=$NUM_THREADS

CMD ["/bin/bash", "/app/entrypoint.sh"]
