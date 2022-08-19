FROM ubuntu:20.04 as builder
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake clang-6.0 openssl libssl-dev zlib1g-dev gperf wget git && \
	rm -rf /var/lib/apt/lists/*
ENV CC clang-6.0
ENV CXX clang++-6.0
WORKDIR /
RUN git clone -b toncli-local --recursive https://github.com/SpyCheese/ton && \
	git clone https://github.com/disintar/toncli

WORKDIR /ton

RUN mkdir build && \
	cd build && \
	cmake ..  && \
	cmake --build . --parallel $(nproc) -j $(nproc) --target fift && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target func && \
	cmake --build . --parallel  $(nproc) -j $(nproc)  --target lite-client

FROM ubuntu:20.04 as toncli
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y openssl wget python3 pip && \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder /ton/build/lite-client/lite-client /usr/local/bin/
COPY --from=builder /ton/build/crypto/func /usr/local/bin/
COPY --from=builder /ton/build/crypto/fift /usr/local/bin/
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

CMD [ "toncli", "run_tests" ]

ENTRYPOINT ["/toncli.sh"]
