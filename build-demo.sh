#!/bin/bash

# Build script for GitHub Pages demo

echo "Building Elm demo for GitHub Pages..."

# Clean and build optimized version
rm -f docs/index.html
elm make src/Main.elm --output=docs/index.html --optimize

if [ $? -eq 0 ]; then
    echo "✅ Demo built successfully in docs/index.html"
    echo "📁 Ready for GitHub Pages deployment"
    echo "🌐 Enable GitHub Pages in repo settings to serve from docs/ folder"
else
    echo "❌ Build failed"
    exit 1
fi