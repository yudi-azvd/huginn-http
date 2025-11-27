#!/usr/bin/env bash
set -e

# FIXME: Gambiarra maldita. vscode do nada resolveu não encontrar o executável
# do odin
if command -v odin &>/dev/null 2>&1; then
    printf ""
else 
    echo "Did not find Odin. Exporting"
    export PATH="~/Odin:$PATH"
fi

odin build examples/basic/ -file -debug -out:basic.out