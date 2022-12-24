#!/bin/bash

TONCLI_CMD="toncli-local"

# ./toncli-docker update_libs /path/to/toncli_conf_dir/
if [[ $1 == "update_libs" ]]; then
    docker run --rm -it \
    -v "$(pwd)":/code \
    -v "$2":/root/.config \
    $TONCLI_CMD update_libs
# ./toncli-docker deploy /path/to/toncli_conf_dir/
elif [[ $1 == "deploy" ]]; then
    docker run --rm -it \
    -v "$(pwd)":/code \
    -v "$2":/root/.config \
    $TONCLI_CMD deploy $@:3
else
    docker run --rm -it \
    -v "$(pwd)":/code \
    $TONCLI_CMD $@
fi

# all commands w/ toncli: https://github.com/disintar/toncli/blob/master/docs/advanced/commands.md