FROM alpine:latest
LABEL PROJECT="tomcat-apr" \
      VERSION="1.0"             \
      AUTHOR="harry"              \
      COMPANY="www.buglife.cn"
MAINTAINER harry "zhangjun@buglife.cn"

# WORKDIR 1
WORKDIR /tmp

# BASH
RUN apk add --no-cache --update-cache bash curl ca-certificates
ENV GLIBC_PKG_VERSION=2.23-r3
RUN curl -Lo /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub
RUN curl -Lo glibc-${GLIBC_PKG_VERSION}.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-${GLIBC_PKG_VERSION}.apk
RUN curl -Lo glibc-bin-${GLIBC_PKG_VERSION}.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-bin-${GLIBC_PKG_VERSION}.apk
RUN curl -Lo glibc-i18n-${GLIBC_PKG_VERSION}.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_PKG_VERSION}/glibc-i18n-${GLIBC_PKG_VERSION}.apk
RUN apk add glibc-${GLIBC_PKG_VERSION}.apk glibc-bin-${GLIBC_PKG_VERSION}.apk glibc-i18n-${GLIBC_PKG_VERSION}.apk
RUN /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8

# DATE
RUN apk --update add --no-cache bash tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata && \
    rm -rf /var/cache

# ADD JAVA
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=73 \
    JAVA_VERSION_BUILD=02 \
    JAVA_PACKAGE=server-jre
# The JDK reference version / server-jre / jdk
# 8/73/02
# 7/80/15

RUN curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" \
  "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz" | gunzip -c - | tar -xf - && \
# apk del curl ca-certificates && \
  mv jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR}/jre /jre && \
  mv jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR}/include/linux /jre/linux && \
#  rm /jre/bin/jjs && \
  rm /jre/bin/keytool && \
  rm /jre/bin/orbd && \
  rm /jre/bin/pack200 && \
  rm /jre/bin/policytool && \
  rm /jre/bin/rmid && \
  rm /jre/bin/rmiregistry && \
  rm /jre/bin/servertool && \
  rm /jre/bin/tnameserv && \
  rm /jre/bin/unpack200 && \
#  rm /jre/lib/ext/nashorn.jar && \
  rm /jre/lib/jfr.jar && \
  rm -rf /jre/lib/jfr && \
  rm -rf /jre/lib/oblique-fonts && \
  rm -rf /tmp/* && \
  rm -rf /var/cache/* && \
  echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

ENV JAVA_HOME /jre
ENV PATH ${PATH}:${JAVA_HOME}/bin

ENV CATALINA_HOME /apache-tomcat
ENV PATH $CATALINA_HOME/bin:$PATH

RUN mkdir -p "$CATALINA_HOME"

WORKDIR $CATALINA_HOME

# let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR

RUN apk add --no-cache busybox
RUN apk add --no-cache libgcc
RUN apk add --no-cache pinentry-gtk
RUN apk add --no-cache gnupg

# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
RUN set -ex \
        && for key in \
                05AB33110949707C93A279E3D3EFE6B686867BA6 \
                07E48665A34DCAFAE522E5E6266191C37C037D42 \
                47309207D818FFD8DCD3F83F1931D684307A10A5 \
                541FBE7D8F78B25E055DDEE13C370389288584E7 \
                61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
                713DA88BE50911535FE716F5208B0AB1D63011C7 \
                79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
                9BA44C2621385CB966EBA586F72C284D731FABEE \
                A27677289986DB50844682F8ACB77FC2E86E29AC \
                A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
                DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
                F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
                F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23 \
        ; do \
                gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
        done

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.6
ENV TOMCAT_TGZ_URL http://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz
ENV TOMCAT_ASC_URL http://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc

RUN set -x \
        \
        && apk add --no-cache --virtual .fetch-deps \
                ca-certificates \
                tar \
                openssl \
        && wget -O tomcat.tar.gz "$TOMCAT_TGZ_URL" \
        && wget -O tomcat.tar.gz.asc "$TOMCAT_ASC_URL" \
        && gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz \
        && tar -xvf tomcat.tar.gz --strip-components=1 \
        \
        && nativeBuildDir="$(mktemp -d)" \
        && tar -xvf bin/tomcat-native.tar.gz -C "$nativeBuildDir" --strip-components=1 \
	&& ls -l $nativeBuildDir \
        && apk add --no-cache --virtual .native-build-deps \
                apr-dev \
                gcc \
                libc-dev \
                make \
                openssl-dev \
        && ( \
                export CATALINA_HOME=$PWD \
                && cd $nativeBuildDir/native \
                && ./configure \
                        --libdir=$TOMCAT_NATIVE_LIBDIR \
                        --prefix=$CATALINA_HOME \
                        --with-apr="$(which apr-1-config)" \
                        --with-java-home=$JAVA_HOME \
                        --with-ssl=yes \
                        --with-os-type=linux \
                && make -j$(getconf _NPROCESSORS_ONLN) \
                && make install \
        ) \
        && runDeps="$( \
                scanelf --needed --nobanner --recursive "$TOMCAT_NATIVE_LIBDIR" \
                        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                        | sort -u \
                        | xargs -r apk info --installed \
                        | sort -u \
        )" \
        && apk add --virtual .tomcat-native-rundeps $runDeps \
        && apk del .fetch-deps .native-build-deps \
        && rm -rf "$nativeBuildDir" \
        && rm bin/tomcat-native.tar.gz

# verify Tomcat Native is working properly
RUN set -e \
        && nativeLines="$(catalina.sh configtest 2>&1)" \
        && nativeLines="$(echo "$nativeLines" | grep 'Apache Tomcat Native')" \
        && nativeLines="$(echo "$nativeLines" | sort -u)" \
        && if ! echo "$nativeLines" | grep 'INFO: Loaded APR based Apache Tomcat Native library' >&2; then \
                echo >&2 "$nativeLines"; \
                exit 1; \
        fi

# Delete tomcat files
RUN rm -rf /apache-tomcat/bin/*.bat \
  && rm -rf /apache-tomcat/webapps/docs \
  && rm -rf /apache-tomcat/webapps/examples \
  && rm -rf /apache-tomcat/webapps/manager \
  && rm -rf /apache-tomcat/webapps/host-manager \
  && rm -rf /apache-tomcat/webapps/ROOT/* \
  && rm -rf /tmp/* \
  && rm -rf /var/cache/*

RUN cat /apache-tomcat/conf/server.xml

# Modify tomcat user tomcat - users. XML
RUN sed -i '$i\ \ \
<role rolename="admin-gui"/>  \ \
<role rolename="manager-gui"/>  \ \
<user username="buglife" password="buglife" roles=" admin-gui , manager-gui "/>' /apache-tomcat/conf/tomcat-users.xml

RUN echo "TEST" > /apache-tomcat/webapps/ROOT/readme.txt

# WORKDIR
WORKDIR /apache-tomcat/webapps

EXPOSE 8080 8443

#ENTRYPOINT /apache-tomcat/bin/catalina.sh run
CMD ["/bin/bash"]
