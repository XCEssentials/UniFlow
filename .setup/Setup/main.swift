import PathKit

import XCERepoConfigurator

// MARK: - PRE-script invocation output

print("\n")
print("--- BEGIN of '\(Executable.name)' script ---")

// MARK: -

// MARK: Parameters

Spec.BuildSettings.swiftVersion.value = "5.3"

let localRepo = try Spec.LocalRepo.current()

let remoteRepo = try Spec.RemoteRepo(
    accountName: localRepo.context,
    name: localRepo.name
)

let travisCI = (
    address: "https://travis-ci.com/\(remoteRepo.accountName)/\(remoteRepo.name)",
    branch: "master"
)

let company = (
    prefix: "XCE",
    name: remoteRepo.accountName
)

let project = (
    name: remoteRepo.name,
    summary: "Uni-directional data flow & finite state machine merged together",
    copyrightYear: 2016
)

let productName = company.prefix + project.name

let authors = [
    ("Maxim Khatskevich", "maxim@khatskevi.ch")
]

typealias PerSubSpec<T> = (
    core: T,
    tests: T
)

let subSpecs: PerSubSpec = (
    "Core",
    "AllTests"
)

let targetNames: PerSubSpec = (
    productName,
    productName + subSpecs.tests
)

let sourcesLocations: PerSubSpec = (
    Spec.Locations.sources + subSpecs.core,
    Spec.Locations.tests + subSpecs.tests
)

// MARK: Parameters - Summary

localRepo.report()
remoteRepo.report()

// MARK: -

// MARK: Write - ReadMe

try ReadMe()
    .addGitHubLicenseBadge(
        account: company.name,
        repo: project.name
    )
    .addGitHubTagBadge(
        account: company.name,
        repo: project.name
    )
    .addSwiftPMCompatibleBadge()
    .addWrittenInSwiftBadge(
        version: Spec.BuildSettings.swiftVersion.value
    )
    .addStaticShieldsBadge(
        "platforms",
        status: "macOS | iOS | tvOS | watchOS | Linux",
        color: "blue",
        title: "Supported platforms",
        link: "Package.swift"
    )
    .add("""
        [![Build Status](\(travisCI.address).svg?branch=\(travisCI.branch))](\(travisCI.address))
        """
    )
    .add("""

        # \(project.name)

        \(project.summary)

        """
    )
    .prepare(
        removeRepeatingEmptyLines: false
    )
    .writeToFileSystem(
        ifFileExists: .skip
    )

// MARK: Write - License

try License
    .MIT(
        copyrightYear: UInt(project.copyrightYear),
        copyrightEntity: authors.map{ $0.0 }.joined(separator: ", ")
    )
    .prepare()
    .writeToFileSystem()

// MARK: Write - GitHub - PagesConfig

try GitHub
    .PagesConfig()
    .prepare()
    .writeToFileSystem()

// MARK: Write - Git - .gitignore

try Git
    .RepoIgnore()
    .addMacOSSection()
    .addCocoaSection()
    .addSwiftPackageManagerSection(ignoreSources: true)
    .add(
        """
        # we don't need to store project file,
        # as we generate it on-demand
        *.\(Xcode.Project.extension)
        """
    )
    .prepare()
    .writeToFileSystem()

// MARK: Write - Package.swift

let dependencies = (
    requirement: (
        name: """
            XCERequirement
            """,
        swiftPM: """
            .package(name: "XCERequirement", url: "https://github.com/XCEssentials/Requirement", from: "2.0.0")
            """
    ),
    pipeline: (
        name: """
            XCEPipeline
            """,
        swiftPM: """
            .package(name: "XCEPipeline", url: "https://github.com/XCEssentials/Pipeline", from: "3.0.0")
            """
    ),
    swiftHamcrest: (
        name: """
            SwiftHamcrest
            """,
        swiftPM: """
            .package(name: "SwiftHamcrest", url: "https://github.com/nschum/SwiftHamcrest", from: "2.1.1")
            """
    )
)

try CustomTextFile("""
    // swift-tools-version:\(Spec.BuildSettings.swiftVersion.value)

    import PackageDescription

    let package = Package(
        name: "\(productName)",
        products: [
            .library(
                name: "\(productName)",
                targets: [
                    "\(targetNames.core)"
                ]
            )
        ],
        dependencies: [
            \(dependencies.requirement.swiftPM),
            \(dependencies.pipeline.swiftPM),
            \(dependencies.swiftHamcrest.swiftPM)
        ],
        targets: [
            .target(
                name: "\(targetNames.core)",
                dependencies: [
                    "\(dependencies.requirement.name)",
                    "\(dependencies.pipeline.name)"
                ],
                path: "\(sourcesLocations.core)"
            ),
            .testTarget(
                name: "\(targetNames.tests)",
                dependencies: [
                    "\(targetNames.core)",
                    "\(dependencies.requirement.name)",
                    "\(dependencies.pipeline.name)",
                    "\(dependencies.swiftHamcrest.name)"
                ],
                path: "\(sourcesLocations.tests)"
            ),
        ]
    )
    """
    )
    .prepare(
        at: ["Package.swift"]
    )
    .writeToFileSystem()

// MARK: - POST-script invocation output

print("--- END of '\(Executable.name)' script ---")
