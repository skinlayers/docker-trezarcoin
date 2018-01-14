FROM ubuntu:xenial
LABEL maintainer="skinlayers@gmail.com"

ENV RPCUSER trezarcoinrpc
ENV RPCPASSWORD OVERRIDE_ME
ENV RPCPORT 17299
ENV PORT 17298

ARG TZC_VERSION=1.0.0.0
ARG TZC_ARCHIVE_NAME=v${TZC_VERSION}-tzc
ARG TZC_ARCHIVE_FILE=${TZC_ARCHIVE_NAME}.tar.gz
ARG TZC_ARCHIVE_DIR=TrezarCoin-${TZC_VERSION}-tzc
ARG TZC_ARCHIVE_URL=https://github.com/TrezarCoin/TrezarCoin/archive/${TZC_ARCHIVE_FILE}
ARG TZC_ARCHIVE_SHA256=6c4731e6d3786451dd02f23c659d2bde3d36b04a71e36952b6a548143a4d6f28
ARG TZC_ARCHIVE_SHA256_FILE=${TZC_ARCHIVE_NAME}-sha256.txt

ARG P2CLI_VERSION=r5
ARG P2CLI_URL=https://github.com/wrouesnel/p2cli/releases/download/${P2CLI_VERSION}/p2
ARG P2CLI_SHA256=36b9ef23cb8dc443cd64e18e6f8b5c1fcbaf975b54496e9fa9233811bd630c78
ARG P2CLI_SHA256_FILE=p2-${P2CLI_VERSION}-sha256.txt


RUN set -eux && \
    adduser --system --home /data --group trezarcoin && \
    echo 'deb http://ppa.launchpad.net/bitcoin/bitcoin/ubuntu xenial main' > \
        /etc/apt/sources.list.d/bitcoin-ubuntu-bitcoin-xenial.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8842CE5E && \
    BUILD_DEPENDENCIES=" \
        curl \
        build-essential \
        libssl-dev \
        libboost-all-dev \
        libdb4.8-dev \
        libdb4.8++-dev \
        libboost1.58-all-dev \
        libminiupnpc-dev \
    "; \
    RUNTIME_DEPENDENCIES=" \
        ca-certificates \
        libboost-filesystem1.58.0 \
        libboost-program-options1.58.0 \
        libboost-system1.58.0 \
        libboost-thread1.58.0 \
        libssl1.0.0 \
        libdb4.8++ \
        libminiupnpc10 \
    "; \
    apt-get update && apt-get -y install $BUILD_DEPENDENCIES && \
    curl -L "$P2CLI_URL" -o p2 && \
    echo "$P2CLI_SHA256  p2" > "$P2CLI_SHA256_FILE" && \
    sha256sum -c "$P2CLI_SHA256_FILE" && \
    chmod 0755 p2 && \
    mv p2 /usr/local/bin/ && \
    rm "$P2CLI_SHA256_FILE" \
    && \
    curl -L "$TZC_ARCHIVE_URL" -o "$TZC_ARCHIVE_FILE" && \
    echo "$TZC_ARCHIVE_SHA256  $TZC_ARCHIVE_FILE" > "$TZC_ARCHIVE_SHA256_FILE" && \
    sha256sum -c "$TZC_ARCHIVE_SHA256_FILE" && \
    tar xf "$TZC_ARCHIVE_FILE" && \
    cd "${TZC_ARCHIVE_DIR}/src" && \
    make -f makefile.unix USE_UPNP=1 && \
    mv trezarcoind /usr/local/bin/ && \
    cd / && \
    rm -r \
        "$TZC_ARCHIVE_DIR" \
        "$TZC_ARCHIVE_FILE" \
        "$TZC_ARCHIVE_SHA256_FILE" && \
    apt-mark manual $RUNTIME_DEPENDENCIES && \
    apt-get remove --purge -y $BUILD_DEPENDENCIES $(apt-mark showauto) && \
    apt-get -y install $RUNTIME_DEPENDENCIES && \
    rm -r /var/lib/apt/lists/* && \
    chmod 0700 /data

COPY ./docker-entrypoint.sh /
COPY ./trezarcoin.conf.p2 /

RUN chmod 0755 /docker-entrypoint.sh

EXPOSE 17298 17299

VOLUME /data

USER trezarcoin

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/local/bin/trezarcoind", "-printtoconsole"]
