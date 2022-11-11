FROM trinketer22/func_docker:latest as builder

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y git && \
	rm -rf /var/lib/apt/lists/*
WORKDIR /toncli
RUN git pull

FROM ubuntu:20.04 as final
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y openssl wget python3 pip && \
	rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/lite-client /usr/local/bin/
COPY --from=builder /usr/local/bin/func /usr/local/bin/
COPY --from=builder /usr/local/bin/fift /usr/local/bin/
COPY --from=builder /usr/local/lib/libtonlibjson.so /usr/local/lib/
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
