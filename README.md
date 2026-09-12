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

## Releases

Prebuilt versions are available on the
[Releases page](https://github.com/404mat/year-in-progress/releases). To
publish a new release, push a tag: `git tag v0.1.0 && git push origin v0.1.0`.

## Troubleshooting

**macOS says the app can't be verified.** The app is ad-hoc signed, so macOS
may warn that it cannot verify the developer. To open it, right-click the app
and choose **Open**, or run:

```sh
xattr -cr "Year In Progress.app"
```

**`open` fails with LaunchServices error `-10825`.** This can happen with
ad-hoc–signed builds in some locations. Run the binary directly instead:

```sh
"Year In Progress.app/Contents/MacOS/YearInProgress"
```
