#!/usr/bin/env sh

dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
cd "$dir"
echo "\nOpen your web browser to localhost:8000 to view the documentation from this directory. 
There is a localhost shortcut in this directory for convenience.

Note that you need to stop this process (Ctrl-C) to view other documentation.\n"
python -m SimpleHTTPServer