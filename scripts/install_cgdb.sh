#!/usr/bin/env bash

git clone https://github.com/cgdb/cgdb.git
cd cgdb
./autogen.sh
./configure --prefix="$HOME"/.local
make -srj4
make install
