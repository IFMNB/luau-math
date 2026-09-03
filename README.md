# luau-math

A collection of data structures and utilities for [Luau](https://luau.org/), focused on compact data representation, predictable memory usage, and efficient operations on large collections.

The project is intended for applications where conventional Lua tables are not always the most suitable choice, particularly when working with large amounts of homogeneous data.

## Features

* Compact data-oriented collections
* Typed arrays for common Luau value types
* Boolean collections
* Bit-level storage and operations
* Searching for occupied and available positions
* Forward and reverse traversal
* Support for sparse collections
* Memory-conscious data structures
* Luau type annotations
* Designed with native execution and optimization in mind

## Design Goals

The project focuses on a few general principles:

**Memory efficiency**

Large collections should avoid unnecessary per-element overhead where possible.

**Predictable behavior**

Collection operations should have clearly defined semantics and stable performance characteristics.

**Data-oriented usage**

The library is designed to work well with systems that process large numbers of similar values rather than many unrelated objects.

**Luau-first API**

The public interfaces are designed around Luau's type system and runtime rather than attempting to reproduce APIs from another language.

**Large collections**

The primary use case is not replacing ordinary Lua tables everywhere. The library is intended for situations where collection size, memory footprint, or predictable access patterns become important.

## Installation

The packages are organized for use with the Roblox/Luau ecosystem and can be integrated into projects using Wally or directly included in a Luau project.

For Wally-based projects, add the desired package to your project's dependencies and require it normally.

## Testing

The repository contains dedicated tests for the project's data structures. Tests cover functional behavior as well as performance-oriented workloads and boundary cases.

## Status

luau-math is an evolving collection of Luau data structures and utilities.

APIs and individual packages may change as the project develops.

## License

See [LICENSE](LICENSE) for licensing information.
