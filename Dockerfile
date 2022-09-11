FROM python:3.10-alpine as builder
RUN apk add g++ clang musl-dev compiler-rt lld openssl-dev zlib-dev linux-headers cmake make git
ENV CC clang
ENV CXX clang++
ENV LD lld

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
		cmake ..  -DCMAKE_C_FLAGS="--rtlib=compiler-rt" -DTON_ARCH="" -DCMAKE_BUILD_TYPE=Release; \
	else \
		cmake .. -DCMAKE_C_FLAGS="--rtlib=compiler-rt" -DTON_ARCH=""; \
	fi && \
	cmake --build . --parallel  $(nproc) -j $(nproc) --target  fift && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target func && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target lite-client && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target tonlibjson

FROM python:3.10-alpine as toncli

COPY --from=builder /ton/build/lite-client/lite-client /usr/local/bin/
COPY --from=builder /ton/build/crypto/func /usr/local/bin/
COPY --from=builder /ton/build/crypto/fift /usr/local/bin/
COPY --from=builder /ton/build/tonlib/libtonlibjson.so /usr/local/lib/
COPY --from=builder /toncli /toncli

WORKDIR /

RUN apk update && apk add compiler-rt libatomic openssl zlib

RUN python -m pip install --upgrade pip && \
	pip install -e toncli

ENV TONCLI_CONFD .config/toncli/
ENV TONCLI_CONF_NAME config.ini

RUN mkdir -p $HOME/$TONCLI_CONFD && \
	cp /toncli/src/toncli/$TONCLI_CONF_NAME $HOME/$TONCLI_CONFD/ && \
	echo -e "\n\n[executable]" >> ${HOME}/${TONCLI_CONFD}/$TONCLI_CONF_NAME && \
	echo "func = /usr/local/bin/func" >> $HOME/$TONCLI_CONFD/$TONCLI_CONF_NAME && \
	echo "fift = /usr/local/bin/fift" >> $HOME/$TONCLI_CONFD/$TONCLI_CONF_NAME&& \
	echo "lite-client = /usr/local/bin/lite-client" >> $HOME/$TONCLI_CONFD/$TONCLI_CONF_NAME && \
	toncli update_libs && mkdir -p /code

COPY hello /code

COPY toncli.sh /

WORKDIR /code

ENTRYPOINT ["/toncli.sh"]
