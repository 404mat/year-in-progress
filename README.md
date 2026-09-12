# Year In Progress

A small macOS menu bar app built with AppKit and Swift.

## Build

```sh
./build.sh
```

This compiles `src/main.swift` and produces `Year In Progress.app`.

## Run

```sh
open "Year In Progress.app"
```

### Troubleshooting

If `open` fails with LaunchServices error `-10825` (this can happen with
ad-hoc–signed builds in some locations), run the binary directly instead:

```sh
"Year In Progress.app/Contents/MacOS/YearInProgress"
```
