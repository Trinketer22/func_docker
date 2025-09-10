FROM ubuntu:22.04 as builder
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake ninja-build openssl libtool autoconf lsb-release software-properties-common gpg libssl-dev pkg-config libsecp256k1-dev liblz4-dev libsodium-dev libjemalloc-dev ccache libmicrohttpd-dev zlib1g-dev gperf wget git && rm -rf /var/lib/apt/lists/*


ARG TON_GIT=https://github.com/SpyCheese/ton
ARG TON_BRANCH=toncli-local
ARG BUILD_DEBUG=0
ARG CUSTOM_CMAKE=""

WORKDIR /

RUN echo "Cloning ${TON_GIT} ${TON_BRANCH}" && \
	git clone -b ${TON_BRANCH} --recursive ${TON_GIT} && \
    	git clone https://github.com/disintar/toncli

RUN wget https://apt.llvm.org/llvm.sh && chmod +x ./llvm.sh
RUN ./llvm.sh 16 all

ENV CC clang-16
ENV CXX clang++-16

WORKDIR /ton

RUN mkdir build && cd build && \
	cmake -GNinja -DTON_USE_JEMALLOC=ON ..\
	-DCMAKE_BUILD_TYPE=Release && \
	ninja fift func lite-client tonlibjson

FROM ubuntu:22.04 as toncli
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y libsodium23 libsecp256k1-0 openssl wget python3 pip && \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder /ton/build/lite-client/lite-client /usr/local/bin/
COPY --from=builder /ton/build/crypto/func /usr/local/bin/
COPY --from=builder /ton/build/crypto/fift /usr/local/bin/
COPY --from=builder /ton/build/tonlib/libtonlibjson.so /usr/local/lib/
COPY --from=builder /toncli /toncli

RUN /usr/local/bin/func -V
RUN /usr/local/bin/fift -V
RUN /usr/local/bin/lite-client -V

WORKDIR /

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
	python -m pip install --upgrade pip && \
	pip install -e toncli

ENV TONCLI_CONFD .config/toncli/
ENV TONCLI_CONF_NAME config.ini

RUN mkdir -p $HOME/$TONCLI_CONFD && \
	cp /toncli/src/toncli/$TONCLI_CONF_NAME $HOME/$TONCLI_CONFD/ && \
	echo "\n\n[executable]" >> ${HOME}/${TONCLI_CONFD}/$TONCLI_CONF_NAME && \
	echo "func = /usr/local/bin/func" >> $HOME/$TONCLI_CONFD/$TONCLI_CONF_NAME && \
	echo "fift = /usr/local/bin/fift" >> $HOME/$TONCLI_CONFD/$TONCLI_CONF_NAME&& \
	echo "lite-client = /usr/local/bin/lite-client" >> $HOME/$TONCLI_CONFD/$TONCLI_CONF_NAME && \
	toncli update_libs && \
	mkdir -p /code

COPY --from=builder /ton/crypto/fift/lib/Asm.fif /
COPY merge_asm.sh /

RUN mv Asm.fif $HOME/$TONCLI_CONFD/fift-libs/Asm.fif

RUN bash merge_asm.sh $HOME/$TONCLI_CONFD/fift-libs/Asm.fif $HOME/$TONCLI_CONFD/fift-libs/AsmTests.fif
RUN rm /merge_asm.sh

COPY hello /code

COPY toncli.sh /

WORKDIR /code

ENTRYPOINT ["/toncli.sh"]
