# Fluentd ban goc KHONG co plugin Elasticsearch -> phai tu build image.
FROM fluent/fluentd:v1.19.3-debian-2.2
USER root
RUN gem install elasticsearch --no-document --version 8.19.0 \
 && gem install fluent-plugin-elasticsearch --no-document --version 5.4.3 \
 && mkdir -p /fluentd/buffer \
 && chown -R fluent:fluent /fluentd
USER fluent
