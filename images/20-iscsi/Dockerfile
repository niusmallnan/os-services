FROM gcc:7.3.0
# FROM arm64=arm64v8/gcc:7.3.0

RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
        libssl-dev libmount-dev \
        kmod \
        parted lsscsi ksh curl git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /dist
COPY build.sh /dist/

CMD ["/dist/build.sh"]

ENTRYPOINT ["/usr/bin/ros", "entrypoint"]
