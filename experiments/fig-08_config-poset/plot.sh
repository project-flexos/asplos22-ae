#!/bin/bash

if [ $# != "2" ]; then
    echo "Usage: $0 <image format extension (svg, pdf, etc.) <output file>"
    exit 0
fi

# First check that graphviz is installed
if ! command -v dot &> /dev/null; then
    echo "Graphviz not installed, install it with:"
    echo "sudo apt install graphviz"
    exit -1
fi

# Plot
dot -T$1 -Kneato poset.dot > $2
