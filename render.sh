#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build output assets/yunxi
swiftc -O -parse-as-library src/EdgeSpeech.swift -o build/edge-speech
ruby -EUTF-8 src/yunxi.rb
swiftc -O src/Media.swift src/Graphics.swift src/Scenes.swift src/Engine.swift src/main.swift -o build/quantum-film
build/quantum-film audio
build/quantum-film preview
caffeinate -i build/quantum-film render
build/quantum-film mux
swiftc -O src/Inspect.swift -o build/inspect
build/inspect
ruby -EUTF-8 src/deliver.rb

