# BrainFuck to Zig Parser
A tool to prase BrainFuck to Zig.

## Introduction
Do you find yourself torn between your team's preference for Zig and your loyalty to BrainFuck? Fear not! With this tool, you can parse your BrainFuck code to Zig, allowing you to stick to your trusty language without compromise. This parser also adds some handy features, such as extra commands in test mode and a catch for infinite loops.

## Getting Started
### Download Files
Clone or download the repository.

### Compiler Settings
Open the compiler settings and edit the `path_to_zig` to match your Zig path. If you encounter an "AppAccessDenied" error, add `sudo` to your Zig command in the compiler settings.

### Build the Parser
Run `zig build` to build the parser. After building, the parser executable can be found at: `./zig-out/bin/bf_zig_parser`.

## Usage
Use the following command to compile your BrainFuck code to Zig:

Add `-run` directly behind `build` to run the executable immediately. Add `-test` directly behind `build` (stackable) to compile test commands in the executable.

## Features
- The generated Zig code is formatted with spacing, making it more readable and easier to debug your BrainFuck code.
- Loops are implemented with a maximum to catch infinite loops (change `maximum_iterations` to increase the amount of cycles).
- Use `?` and `!` in test mode to print the current index and cell value as an integer, respectively.
- Colored print statements for extra clarity.

## Limitations
- `sudo` access needed
- Runs shell in empty environment

## Optimizations
- Repeated operators will be combined. For example, `+++++` is interpreted as `+5`.

## Dependencies
Tested in version 0.12 of Zig.

## Development
Feel free to look at the TODOs and tidy up the code.
