FROM ubuntu:20.04 as builder
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake clang openssl libssl-dev pkg-config libsecp256k1-dev libsodium-dev libmicrohttpd-dev zlib1g-dev gperf wget git && \
	rm -rf /var/lib/apt/lists/*
ENV CC clang
ENV CXX clang++

ARG TON_GIT=https://github.com/SpyCheese/ton
ARG TON_BRANCH=toncli-local
ARG BUILD_DEBUG=0
ARG CUSTOM_CMAKE=""

WORKDIR /

RUN echo "Cloning ${TON_GIT} ${TON_BRANCH}" && \
	git clone -b ${TON_BRANCH} --recursive ${TON_GIT} && \
    	git clone https://github.com/disintar/toncli

WORKDIR /ton

RUN mkdir build && \
	cd build && \
	if [ ! -z ${CUSTOM_CMAKE} ]; then \
		echo "Executing cmake with args: ${CUSTOM_CMAKE}"; \
		cmake .. ${CUSTOM_CMAKE}; \
	elif [ ${BUILD_DEBUG} -eq 0 ]; then \
		cmake .. -DTON_ARCH="" -DPORTABLE=1 -DCMAKE_BUILD_TYPE=Release; \
	else \
		cmake .. -DTON_ARCH="" -DPORTABLE=1; \
	fi && \
	cmake --build . --parallel $(nproc) -j $(nproc) --target fift && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target func && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target lite-client && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target tonlibjson

FROM ubuntu:20.04 as toncli
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y libsodium23 libsecp256k1-0 openssl wget python3 pip && \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder /ton/build/lite-client/lite-client /usr/local/bin/
COPY --from=builder /ton/build/crypto/func /usr/local/bin/
COPY --from=builder /ton/build/crypto/fift /usr/local/bin/
COPY --from=builder /ton/build/tonlib/libtonlibjson.so /usr/local/lib/
COPY --from=builder /toncli /toncli

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

COPY hello /code

COPY toncli.sh /

WORKDIR /code

ENTRYPOINT ["/toncli.sh"]
