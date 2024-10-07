// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "RemindersMacOs.Repositories",
	platforms: [
		.macOS(.v15)
	],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "RemindersMacOs.Repositories",
			targets: ["RemindersMacOs.Repositories"]),
	],
	dependencies: [
		.package(url: "https://github.com/vapor/vapor", from: "4.105.0"),
		.package(url: "https://github.com/vapor/jwt.git", from: "4.2.0"),
		.package(url: "https://github.com/vapor/fluent", from: "4.4.0"),
		.package(url: "https://github.com/vapor/fluent-sqlite-driver", from: "4.1.0"),
		.package(name: "UserDTOs", path: "../UserDTOs"),
		.package(name: "RemindersMacOS.DTOs", path: "../RemindersMacOS.DTOs")
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "RemindersMacOs.Repositories",
			dependencies: [
				.product(
					name: "Vapor",
					package: "vapor"
				),
				.product(
					name: "Fluent",
					package: "fluent"
				),
				.product(
					name: "FluentSQLiteDriver",
					package: "fluent-sqlite-driver"
				),
				.product(
					name: "JWT",
					package: "jwt"
				),
				.product(
					name: "UserDTOs",
					package: "UserDTOs"
				),
				.product(
					name: "RemindersMacOS.DTOs",
					package: "RemindersMacOS.DTOs"
				)
			]
		),
		.testTarget(
			name: "RemindersMacOs.RepositoriesTests",
			dependencies: ["RemindersMacOs.Repositories"]
		),
	]
)
