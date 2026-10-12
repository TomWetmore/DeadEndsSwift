# Swift Development Outside Xcode

*DeadEnds Development Notes — October 2026*

## 1. Introduction

DeadEnds is written in Swift and was originally developed entirely within Apple's Xcode environment on macOS. The project has since been extended to run on iPadOS, Ubuntu Linux, and WebAssembly (WASM).

An important goal has been to retain a single Swift implementation of the DeadEnds library, including its GEDCOM database, programming language parser, and interpreter.

The environments now supported are:

- **macOS:** The original Xcode development environment.
- **iPadOS:** A native SwiftUI application using the shared DeadEnds library.
- **Ubuntu Linux:** A command-line application compiled using the standalone Swift toolchain.
- **WebAssembly:** The command-line application cross-compiled from Swift to WASM, with the eventual goal of running DeadEnds in a web browser.

The iPad application is still built using Xcode. Linux and WASM use Swift's independent development tools.

## 2. Swift Is Independent of Xcode

Although Swift originated at Apple, it is an open-source programming language with implementations for multiple operating systems and processor architectures.

Xcode provides an integrated development environment for Swift, but the Swift compiler and its supporting tools can operate independently.

The principal components are:

**Swift compiler (`swiftc`)**

Compiles Swift source code into executable machine code or another target format.

**Swift Package Manager (SwiftPM)**

Organizes Swift projects, manages dependencies, and controls compilation and linking.

**Swiftly**

Installs and manages different versions of the Swift toolchain.

**Swift SDKs**

Provide the libraries, runtime support, and other components needed to compile Swift programs for particular target environments.

These tools are distributed through the Swift open-source project.

Official starting point: [Swift.org](https://www.swift.org/?utm_source=chatgpt.com)

## 3. Swift Package Manager

Swift Package Manager is particularly important because it allows a Swift project to be compiled without Xcode.

A Swift package contains a file named `Package.swift` in its top-level directory. This file describes the package's products, targets, and external dependencies.

DeadEnds has a Swift package named `DeadEndsSwift`.

Its principal components are:

**DeadEndsLib**

The reusable Swift library containing the database, GEDCOM processing, programming language, and related facilities.

**deadends**

A command-line executable that reads a GEDCOM database and a DeadEnds program, then executes that program.

The package also depends on the external `swift-parsing` library, which is obtained automatically from GitHub.

The principal SwiftPM commands are:

```bash
swift build
swift run
swift test
```

For example:

```bash
swift run deadends Gedfiles/modified.ged Programs/test.dend
```

SwiftPM downloads required dependencies, compiles the necessary modules, and links the executable.

Build products are normally placed under the `.build` directory.

The same `Package.swift` file can be used to build the project for different platforms.

## 4. Swiftly: Managing Swift Installations

Swiftly is the official tool for installing and managing standalone Swift toolchains.

It is particularly useful when multiple Swift versions are needed.

For example:

```bash
swiftly install 6.3.3
swiftly install 6.4.0
```

The active version can be selected with:

```bash
swiftly use 6.4.0
```

Other useful commands include:

```bash
swiftly list
swift --version
```

Swiftly manages the compiler and associated development tools. It does not replace Swift Package Manager.

The distinction is:

- Swiftly determines **which Swift toolchain** is being used.
- SwiftPM determines **what is built and how it is built**.
- A Swift SDK determines **which target environment** the compiler builds for.

Swiftly was installed on Ubuntu before building DeadEnds.

Official documentation: [Swiftly](https://www.swift.org/blog/introducing-swiftly_10/?utm_source=chatgpt.com)

## 5. Ubuntu Linux Environment

The Linux environment runs Ubuntu 24.04 on an ARM64 virtual machine managed by UTM on the Mac.

This allows Linux development without requiring a separate physical computer.

### Installing Swift

The initial installation used Swiftly 1.1.3 to install Swift 6.3.3.

The Ubuntu installation also required several system development packages:

```bash
sudo apt install \
    curl \
    libxml2-dev \
    libncurses-dev \
    z3 \
    zlib1g-dev \
    gcc-13 \
    g++-13 \
    python3-dev
```

Swiftly was installed using the official Linux distribution available from Swift.org.

The shell environment was configured to make Swiftly and its installed toolchains available through the command search path.

This involved sourcing Swiftly's environment configuration from the user's shell startup files.

### Building DeadEnds

The DeadEnds source repository is located at:

```text
~/Projects/DeadEndsSwift
```

From this directory, the package can be compiled with:

```bash
swift build
```

The command-line application can then be executed with:

```bash
.build/debug/deadends \
    Gedfiles/modified.ged \
    Programs/test.dend
```

The command-line executable expects two arguments:

1. A GEDCOM database file.
2. A DeadEnds program file.

This environment demonstrated that the core DeadEnds library and interpreter could run on Linux without Xcode or Apple-specific frameworks.

The Linux command-line interface also provides an implementation of the interactive functions required by DeadEnds programs.

## 6. The iPad Environment

The iPad implementation takes a different approach.

Rather than compiling Swift directly on the iPad, DeadEnds is built as a native iPadOS application using Xcode on the Mac.

The project contains a separate application target named `DeadEndsiPad`.

This application uses the same `DeadEndsLib` library as the macOS and Linux implementations.

The principal difference is the user interface.

The iPad application uses SwiftUI and provides a simple program-running interface with four principal operations:

- Load a GEDCOM database.
- Load a DeadEnds program.
- Compile the program.
- Run the program.

The program compilation here means compiling the DeadEnds scripting language, not compiling Swift source code.

### File Access

On macOS, DeadEnds can use `NSOpenPanel` to select files.

On iPadOS, the application uses SwiftUI's `fileImporter`, which integrates with the iPad Files application.

Files outside the application's private storage may require temporary access through Apple's security-scoped resource mechanism.

### Interactive Programs

The DeadEnds interpreter supports interactive operations such as `getperson`, `getinteger`, and `getstring`.

On the iPad, these operations are implemented using SwiftUI dialogs and sheets.

Swift's asynchronous programming facilities allow the interpreter to suspend execution while waiting for user input and resume afterward.

This is an important architectural feature: the interpreter itself remains shared, while the user interface differs between platforms.

## 7. WebAssembly (WASM)

WebAssembly is a portable binary instruction format designed to execute programs in web browsers and other supported runtime environments.

Swift can now compile programs directly into WebAssembly.

This makes it possible to retain much of the DeadEnds Swift implementation when moving toward a browser-based application.

### Installing Swift 6.4

The WASM work was performed in the existing Ubuntu environment.

Swift 6.4 was installed alongside Swift 6.3.3 using Swiftly:

```bash
swiftly install 6.4.0
swiftly use 6.4.0
```

### Installing the WebAssembly SDK

The Swift 6.4 WebAssembly SDK was obtained from Swift.org and installed using:

```bash
swift sdk install <SDK-download-URL> \
    --checksum <SHA256-checksum>
```

The actual download address and checksum are published in the official Swift documentation.

Installed SDKs can be inspected with:

```bash
swift sdk list
```

The SDK used for DeadEnds has the identifier:

```text
swift-6.4.0-RELEASE_wasm
```

An important requirement is that the SDK version match the Swift toolchain version.

Official instructions: [Getting Started with Swift WebAssembly](https://www.swift.org/documentation/articles/wasm-getting-started.html?utm_source=chatgpt.com)

### Compiling DeadEnds for WASM

The existing DeadEnds Swift package was compiled with:

```bash
swift build --swift-sdk swift-6.4.0-RELEASE_wasm
```

This successfully produced a WebAssembly executable:

```text
.build/out/Products/Debug-webassembly-wasm32/deadends.wasm
```

No translation of the Swift source code into JavaScript was required.

The same Swift compiler and package manager were used, but the target SDK was changed from Linux to WebAssembly.

### Executing WASM Programs

Swift provides support for executing WASM modules using a WebAssembly runtime.

The DeadEnds executable was successfully started using:

```bash
swift run --swift-sdk swift-6.4.0-RELEASE_wasm deadends
```

The program produced its normal usage message:

```text
Usage: deadends database.ged program.dend
```

This confirmed that the compiled WASM program could begin execution.

A subsequent test supplied an actual GEDCOM database and DeadEnds program. Execution progressed into the application, but interactive input did not work as expected.

This remains an unresolved issue.

The current WASM implementation is therefore an important proof of concept, but not yet a working browser application.

## 8. WebAssembly and the Browser

There is an important distinction between compiling a Swift program to WASM and providing a web application.

A WASM executable does not automatically acquire a browser user interface.

The current DeadEnds command-line application expects command-line arguments, file access, and interactive input.

A browser application will require alternative implementations of these facilities.

In particular, the browser version will need mechanisms for:

- Selecting GEDCOM and DeadEnds program files.
- Passing their contents to the Swift library.
- Displaying program output.
- Handling interactive requests from the interpreter.
- Communicating between JavaScript and the WASM module.

The browser will provide the surrounding interface, while the Swift library can continue to perform GEDCOM processing and program interpretation.

JavaScript will probably be needed for browser integration, but the central DeadEnds algorithms should not need to be rewritten in JavaScript.

## 9. External Software and Documentation

The principal external resources used in this work are:

**Swift programming language**

[Swift.org](https://www.swift.org/?utm_source=chatgpt.com)

The official source for Swift releases, toolchains, SDKs, and documentation.

**Swiftly**

[Swiftly on GitHub](https://github.com/swiftlang/swiftly?utm_source=chatgpt.com)

The Swift toolchain installation and version-management utility.

**Swift Package Manager**

[Swift Package Manager on GitHub](https://github.com/swiftlang/swift-package-manager?utm_source=chatgpt.com)

The build system and dependency manager used by the standalone DeadEnds project.

**Swift Parsing**

[swift-parsing on GitHub](https://github.com/pointfreeco/swift-parsing?utm_source=chatgpt.com)

The parsing library used by the DeadEnds programming language implementation.

**Swift WebAssembly**

[Swift WebAssembly Documentation](https://www.swift.org/documentation/articles/wasm-getting-started.html?utm_source=chatgpt.com)

Instructions for installing the WASM SDK and building Swift programs for WebAssembly.

**Ubuntu**

[Ubuntu](https://ubuntu.com/?utm_source=chatgpt.com)

The Linux distribution used for the command-line and WASM development environments.

**UTM**

[UTM Virtual Machines](https://mac.getutm.app/?utm_source=chatgpt.com)

The virtualization software used to run Ubuntu on the Mac.

## 10. Summary

The work to date demonstrates that DeadEnds is no longer dependent on Xcode as its sole development and execution environment.

The same Swift library can be compiled for Apple platforms, Linux, and WebAssembly.

The principal technologies have distinct responsibilities:

| Component      | Purpose                                                |
| -------------- | ------------------------------------------------------ |
| Xcode          | Native macOS and iPadOS development                    |
| Swiftly        | Installing and selecting Swift toolchains              |
| SwiftPM        | Building packages and managing dependencies            |
| Swift compiler | Compiling Swift source code                            |
| Swift SDK      | Providing support for a target platform                |
| Ubuntu         | Native Linux execution                                 |
| WASM           | Portable execution outside the native operating system |
| JavaScript     | Potential browser interface and integration            |

The most significant result is that the core DeadEnds implementation remains in Swift.

Platform-specific differences can be concentrated in relatively small interface layers rather than requiring separate implementations of the database and programming language.

This provides a promising foundation for eventually making DeadEnds available through a web browser.