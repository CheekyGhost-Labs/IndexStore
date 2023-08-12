# IndexStore

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FCheekyGhost-Labs%2FIndexStore%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/CheekyGhost-Labs/IndexStore) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FCheekyGhost-Labs%2FIndexStore%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/CheekyGhost-Labs/IndexStore)

IndexStore is a library providing that provides a query-based approach for searching for and working with source symbols within an indexed code base. It is built on top of the [Apple IndexStoreDB Library](https://github.com/apple/indexstore-db), which provides access to the index data produced by the swift compiler.

With this library, you can easily search for and analyze symbols in your code, making it a powerful tool for building developer tools, static analyzers, and code refactoring utilities.

## Note:

The [Apple IndexStoreDB Library](https://github.com/apple/indexstore-db) is not considered stable yet as it has no resolvable semvar tags. This project points at a release branch found on the repo and is actively maintained.

## Workflows:

|  Branch  | Latest Swift/Xcode  |   Legacy Swift Support (5.7, 5.6, 5.5)  |
|:---------|:-------------------:|:---------------------------------------:|
| main | [![Build and Test](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/unit-tests.yml/badge.svg?branch=main)](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/unit-tests.yml) | [![Test Previous Swift Versions](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/test-xcode-versions.yml/badge.svg?branch=main)](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/test-xcode-versions.yml) |
| develop | [![Build and Test](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/unit-tests.yml/badge.svg?branch=develop)](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/unit-tests.yml) | [![Test Previous Swift Versions](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/test-xcode-versions.yml/badge.svg?branch=develop)](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/test-xcode-versions.yml) |
| release/1.0 | [![Build and Test](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/unit-tests.yml/badge.svg?branch=release/1.0)](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/unit-tests.yml) | [![Test Previous Swift Versions](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/test-xcode-versions.yml/badge.svg?branch=release/1.0)](https://github.com/CheekyGhost-Labs/IndexStore/actions/workflows/test-xcode-versions.yml) |

## Features:

- Query symbols and occurrences in your Swift source code
- Find the occurrences and references of symbols
- Access detailed information about symbols, such as their USR, source file location, parent, inheritance, and more
- Access detailed information about symbols (location, kind, parent, etc.)
- Filter and customize queries with various options, such as restricting to the project directory or specific source files
- Supports both Swift and Objective-C code
- Retrieve symbols conforming to a specific protocol
- Retrieve symbols subclassing a specific class
- Find invocations of a specific symbol
- Check if a symbol is invoked by a test case
- Identify empty extensions

### Getting Started:

To use `IndexStore` in your project, you'll need to instantiate an index with a valid `Configuration` instance.

The `Configuration` holds, among other things, paths to the project directory, libIndexStore, and IndexStoreDB database. The only required value to get started is the `projectDirectory` location, which is the working directory of the project you are assessing.

By default the configuration will automatically resolve the required `indexStorePath` and `libIndexStorePath` based on the running process. This will use `xcode-select` and `ProcessInfo().environment` to derive the index store details for the project within the `projectDirectory`.

You can also override this by providing your own values.

#### Instantiating:

Once you have your configuration ready, you can create an `IndexStore` instance:

```swift
// Manual Configuration
let configuration = Configuration(projectDirectory: "path/to/project/root")
instanceUnderTest = IndexStore(configuration: configuration)
```

The `Configuration` is also `Decodable` and can be built from a JSON file:

```swift
let configuration = try Configuration.fromJson(at: configPath)
instanceUnderTest = IndexStore(configuration: configuration)
```

#### Basic Usage

Once you have a configured `IndexStore` instance, you can begin querying for symbols:


1. Import `IndexStore`:

```swift
import IndexStore
```

2. Use the `IndexStore` instance to query for symbols, occurrences, or other information:

```swift
// Query for functions by name
let results = indexStore.querySymbols(.functions("someFunctionName"))

// Find all class symbols
let classSymbols = indexStore.querySymbols(.kinds([.class]))

// Find all extensions of a type
let results = indexStore.querySymbols(.extensions(ofType: "MyClass"))

// Find all extensions of a class within specific source files
let results = indexStore.querySymbols(.extensions(in: ["path", "path"], matching: "XCTest"))

// Find all invocations of a function symbol
let function = indexStore.querySymbols(.functions("someFunctionName"))[0]
let results = indexStore.invocationsOfSymbol(function)

// Find all symbols declared in a specific file
let symbols = indexStore.querySymbols(
    .withSourceFiles(["/path/to/your/project/SourceFile.swift"])
    .withKinds(SourceKind.allCases)
    .withRoles(.all)
)
```

#### Convenience Methods

IndexStore provides convenience methods for common static analysis tasks:

- Find symbols conforming to a specific protocol:

```swift
let conformingSymbols = indexStore.sourceSymbols(conformingToProtocol: "SomeProtocol")
```

- Find symbols subclassing a specific class:

```swift
let subclassingSymbols = indexStore.sourceSymbols(subclassing: "SomeClass")
```

- Find invocations of a specific symbol:

```swift
let invocations = indexStore.invocationsOfSymbol(someSymbol)
```

- Check if a symbol is invoked by a test case:

```swift
let isInvokedByTestCase = indexStore.isSymbolInvokedByTestCase(someSymbol)
```

- Identify empty extensions:

```swift
let emptyExtensions = indexStore.sourceSymbols(forEmptyExtensionsMatching: "SomeType")
```

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/CheekyGhost-Labs/IndexStore.git", branch: "release/1.0"),
    ],
    targets: [
        .executableTarget(name: "<command-line-tool>", dependencies: [
            // other dependencies
            .product(name: "IndexStore", package: "IndexStore")
        ]),
        // other targets
    ]
)
```

## License

IndexStore is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Contribution

### Submitting a Bug Report

Swift Markdown tracks all bug reports with [GitHub Issues](https://github.com/CheekyGhost-Labs/IndexStore/issues).
You can use the "IndexStore" component for issues and feature requests specific to IndexStore.
When you submit a bug report we ask that you are descriptive and include as much information as possible to document or re-create the issue.

### Submitting a Feature Request

For feature requests, please feel free to file a [GitHub issue](https://github.com/CheekyGhost-Labs/IndexStore/issues/new)

Don't hesitate to submit a feature request if you see a way IndexStore can be improved to better meet your needs.

### Contributing to IndexStore

Due to [Apple IndexStoreDB Library](https://github.com/apple/indexstore-db) repo using branches for releases rather than tagging stable versions, the IndexStore repo can't follow the traditional semvar and [Git Flow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) approach.

The approach IndexStore takes for releases is:
- main: contains the latest stable release
- develop: contains the latest stable changes pending release
- release/<major>.minor: contains released code

A release branch will have a semantic version without accounting for patch updates. For example

```shell
release/1.0
release/1.1
```

- any `patch` changes (bug fixes and improvements that don't change the public interface) will be pulled into the appropriate release branch as needed.

- any `minor` updates (publicly visible changes that are backwards compatible) will get their own release branch.

- any `major` updates (publicly visible changes that are **not** backwards compatible) will get their own release branch.

Releases will still be tagged for when the [Apple IndexStoreDB Library](https://github.com/apple/indexstore-db) becomes stable. This will also allow us to manage patch releases easier too.

For the most part, pull requests should be made against the `develop` branch to coordinate releases with multiple features and fixes. This also provides a means to test from the `develop` branch in the wild to further test pending releases. Once a release is ready it will be merged into `main` and release branches created/updated from the `main` branch.

If a fix for an older version is being made, the pull request can be made against the intended release branch, and the change can be worked into the other branches with the help of maintainers as needed.

To get started:

1. **Fork the repository**: Start by creating a fork of the project to your own GitHub account.

2. **Clone the forked repository**: After forking, clone your forked repository to your local machine so you can make changes.

```shell
git clone https://github.com/CheekyGhost-Labs/IndexStore.git
```

3. **Create a new branch**: Before making changes, create a new branch for your feature or bug fix. Use a descriptive name that reflects the purpose of your changes.

```shell
git checkout -b your-feature-branch
```

4. **Follow the Swift Language Guide**: Ensure that your code adheres to the [Swift Language Guide](https://swift.org/documentation/api-design-guidelines/) for styling and syntax conventions.

5. **Make your changes**: Implement your feature or bug fix, following the project's code style and best practices. Don't forget to add tests and update documentation as needed.

6. **Commit your changes**: Commit your changes with a descriptive and concise commit message. Use the imperative mood, and explain what your commit does, rather than what you did.

```shell

# Feature
git commit -m "Feature: Adding convenience method for resolving awesomeness"


# Bug
git commit -m "Bug: Fixing issue where awesome query was not including awesome"
```

7. **Pull the latest changes from the upstream**: Before submitting your changes, make sure to pull the latest changes from the upstream repository and merge them into your branch. This helps to avoid any potential merge conflicts.

```shell
git pull origin develop
```

8. **Push your changes**: Push your changes to your forked repository on GitHub.

```shell
git push origin your-feature-branch
```

9. **Submit a pull request**: Finally, create a pull request from your forked repository to the original repository, targeting the `develop` branch. Fill in the pull request template with the necessary details, and wait for the project maintainers to review your contribution.

### Unit Testing

Please ensure you add unit tests for any changes. The aim is not `100%` coverage, but rather meaningful test coverage that ensures your changes are behaving as expected without negatively effecting existing behavior.

Please note that the project maintainers may ask you to make changes to your contribution or provide additional information. Be open to feedback and willing to make adjustments as needed. Once your pull request is approved and merged, your changes will become part of the project!