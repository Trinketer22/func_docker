FROM trinketer22/func_docker:slim as builder

RUN apk update && apk add git
WORKDIR /toncli
RUN git pull

FROM python:3.10-alpine as final
COPY --from=builder /usr/local/bin/lite-client /usr/local/bin/
COPY --from=builder /usr/local/bin/func /usr/local/bin/
COPY --from=builder /usr/local/bin/fift /usr/local/bin/
COPY --from=builder /usr/local/lib/libtonlibjson.so /usr/local/lib/
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
