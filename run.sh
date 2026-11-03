#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if [ ! -d "FolderViewer.app" ]; then
    ./build_app.sh
fi

open "$DIR/FolderViewer.app"

