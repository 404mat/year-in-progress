#!/bin/sh
set -e
cd "$(dirname "$0")"
mkdir -p "Year In Progress.app/Contents/MacOS"
swiftc -O -framework AppKit -o "Year In Progress.app/Contents/MacOS/YearInProgress" src/main.swift
cp Info.plist "Year In Progress.app/Contents/Info.plist"
echo -n "APPL????" > "Year In Progress.app/Contents/PkgInfo"
codesign --force --sign - "Year In Progress.app"
echo "Built Year In Progress.app"
