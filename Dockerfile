FROM java:8-jre-alpine
MAINTAINER Denis Baryshev <dennybaa@gmail.com>

ENV HADOOP_VERSION 2.7.2
ENV HADOOP_HOME /usr/local/hadoop-${HADOOP_VERSION}
ENV HADOOP_CONF_DIR /etc/hadoop
ENV HADOOP_HDFS_USER hdfs

LABEL vendor=ActionML \
      version_tags="[\"2.7\",\"2.7.2\"]"

# Update alpine and install required tools
RUN apk update && apk add --update bash curl

# Fetch, unpack hadoop dist and prepare layout
RUN curl -L http://www-us.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz \
      | tar -xzp -C /usr/local && \
      mv ${HADOOP_HOME}/etc/hadoop /etc/ && \
      ln -s /etc/hadoop/ ${HADOOP_HOME}/etc/hadoop && \
      mkdir -p /hadoop/dfs/name \
               /hadoop/dfs/sname1 \
               /hadoop/dfs/data1

RUN curl -L https://github.com/kelseyhightower/confd/releases/download/v0.12.0-alpha3/confd-0.12.0-alpha3-linux-amd64 \
         -o /usr/local/bin/confd && chmod 755 /usr/local/bin/confd

# Create users (to go "non-root") and set directory permissions
RUN curl -L http://dl-cdn.alpinelinux.org/alpine/edge/testing/x86_64/shadow-4.2.1-r3.apk \
         -o /tmp/shadow.apk && apk add /tmp/shadow.apk && rm /tmp/* && \
    useradd -mU -d /home/hadoop hadoop && passwd -d hadoop && \
    useradd -mU -d /home/hdfs -G hadoop hdfs && passwd -d hdfs && \
    chown -R hdfs:hdfs /hadoop/dfs

VOLUME [ "/etc/hadoop", "/hadoop/dfs/name", "/hadoop/dfs/sname1", "/hadoop/dfs/data1" ]

# Hadoop defaults
ENV HADOOP_OPTS -Djava.net.preferIPv4Stack=true
ENV HADOOP_PORTMAP_OPTS -Xmx512m
ENV HADOOP_CLIENT_OPTS -Xmx512m

# Add confd configuration files
ADD ./conf.d /etc/confd/conf.d
ADD ./templates /etc/confd/templates

ADD ./hdfs-site.xml ./hdfs-bootstrap-paths ${HADOOP_CONF_DIR}/
ADD ./*.sh /

# HDFS exposed ports
EXPOSE 9000 50010 50020 50070 50075 50090
