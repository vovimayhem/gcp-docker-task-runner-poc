FROM ruby:2.6.5-alpine3.10 AS runtime

WORKDIR /usr/src

ENV HOME=/usr/src PATH=/usr/src/bin:$PATH

RUN apk add --no-cache ca-certificates less libc6-compat openssl tzdata

FROM runtime AS development

RUN apk add --no-cache build-base git

RUN export DOCKERIZE_VERSION=0.6.1 \
 && wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz \
 && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz \
 && rm dockerize-linux-amd64-v${DOCKERIZE_VERSION}.tar.gz

ADD Gemfile* /usr/src/

# GRPC Won't build unless bundler is configured to compile native extensions
# from source:
ENV BUNDLE_FORCE_RUBY_PLATFORM=1

RUN CFLAGS="-Wno-cast-function-type" bundle install --jobs=4 --retry=3

ARG DEVELOPER_UID="1000"

RUN adduser -u $DEVELOPER_UID -h /usr/src -D -H -g "Developer User" you

# ==============================================================================
FROM development AS testing
COPY . /usr/src

# ==============================================================================
FROM testing AS builder

RUN bundle config without development:test \
 && bundle clean \
 && rm -rf tmp/* \
 # Remove unneeded files (cached *.gem, *.o, *.c)
 && rm -rf /usr/local/bundle/cache/*.gem \
 && find /usr/local/bundle/gems/ -name "*.c" -delete \
 && find /usr/local/bundle/gems/ -name "*.o" -delete

# ==============================================================================
FROM runtime AS release
COPY --from=builder /usr/local/bin/dockerize /usr/local/bin/dockerize
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=nobody:nobody /usr/src /usr/src
CMD [ "subscribe" ]
