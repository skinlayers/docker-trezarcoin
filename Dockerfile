FROM ubuntu:xenial
LABEL maintainer="skinlayers@gmail.com"

ENV RPCUSER trezarcoinrpc
ENV RPCPASSWORD OVERRIDE_ME
ENV RPCPORT 17299
ENV PORT 17298
ENV VERSION 1.0.0.0
ENV TZC_ARCHIVE_NAME v${VERSION}-tzc.tar.gz
ENV TZC_ARCHIVE_SHA256 6c4731e6d3786451dd02f23c659d2bde3d36b04a71e36952b6a548143a4d6f28
ENV P2CLI_VERSION r5
ENV P2CLI_SHA256 36b9ef23cb8dc443cd64e18e6f8b5c1fcbaf975b54496e9fa9233811bd630c78


RUN set -eux && \
    adduser --system --home /data --group trezarcoin && \
    echo 'deb http://ppa.launchpad.net/bitcoin/bitcoin/ubuntu xenial main' > \
        /etc/apt/sources.list.d/bitcoin-ubuntu-bitcoin-xenial.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8842CE5E && \
    buildDeps=" \
        curl \
        build-essential \
        libssl-dev \
        libboost-all-dev \
        libdb4.8-dev \
        libdb4.8++-dev \
        libboost1.58-all-dev \
        libminiupnpc-dev \
    "; \
    runDeps=" \
        ca-certificates \
        libboost-filesystem1.58.0 \
        libboost-program-options1.58.0 \
        libboost-system1.58.0 \
        libboost-thread1.58.0 \
        libssl1.0.0 \
        libdb4.8++ \
        libminiupnpc10 \
    "; \
    apt-get update && apt-get -y install $buildDeps && \
    curl -LO "https://github.com/wrouesnel/p2cli/releases/download/$P2CLI_VERSION/p2" && \
    echo "$P2CLI_SHA256  p2" > "p2cli-$P2CLI_VERSION-sha256sum.txt" && \
    sha256sum -c "p2cli-$P2CLI_VERSION-sha256sum.txt" && \
    chmod 0755 p2 && \
    mv p2 /usr/local/bin/ && \
    rm "p2cli-$P2CLI_VERSION-sha256sum.txt" && \
    curl -LO "https://github.com/TrezarCoin/TrezarCoin/archive/${TZC_ARCHIVE_NAME}" && \
    echo "$TZC_ARCHIVE_SHA256  $TZC_ARCHIVE_NAME" > "${TZC_ARCHIVE_NAME}-sha256sum.txt" && \
    sha256sum -c "${TZC_ARCHIVE_NAME}-sha256sum.txt" && \
    tar xf "$TZC_ARCHIVE_NAME" && \
    cd "TrezarCoin-${VERSION}-tzc/src" && \
    make -f makefile.unix USE_UPNP=1 && \
    mv trezarcoind /usr/local/bin/ && \
    cd / && \
    rm -r \
        "TrezarCoin-${VERSION}-tzc" \
        "$TZC_ARCHIVE_NAME" \
        "$TZC_ARCHIVE_NAME-sha256sum.txt" && \
    apt-mark manual $runDeps && \
    apt-get remove --purge -y $buildDeps $(apt-mark showauto) && \
    apt-get -y install $runDeps && \
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
