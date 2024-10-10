//
//  File.swift
//  
//
//  Created by CodeBuilder on 14/01/2024.
//

import Foundation
import ArgumentParser
import PathKit
//import GeneratePackage
import Yams

public struct RecipeBuilder {
	
	var recipe: String
	
	var spec: Path
	var path: String?
	var output: Path?
	
	public init(recipe: String, spec: Path, path: String? = nil, output: Path? = nil) {
		self.recipe = recipe
		self.path = path
		self.spec = spec
		if let output = output {
			self.output = (output + "Package.swift")
		}
	}
	
	public func run() async throws {
		if !Path.hostPython.exists {
			let kivycore_version = "311.0.4"
			try await buildHostPython()
			InstallPythonCert()
			try await createVenv()
			try await pipInstallVenv(pips: ["https://github.com/PythonSwiftLink/KivyCore/releases/download/\(kivycore_version)/kivy-ios.zip"])
		}
		print("\n\n############################\n\n\t\tbuilding recipe\n\n############################")
		//let packageSpec = try YAMLDecoder().decode( PackageSpec.self, from: spec.read() )
		//let version = "311.0.4"
		
		
		if let recipe_path = path {
			try Toolchain.Build(recipe: recipe, optionalArgs: ["--add-custom-recipe", recipe_path]).run()
		} else {
			try Toolchain.Build(recipe: recipe, optionalArgs: nil).run()
		}
//		print("\n\n############################\n\n\t\tgenerating Package.swift\n\n############################")
//		let package = try await GeneratePackage(fromSwiftFile: nil, spec: spec, version: version)
//
//		
//		print("\n\n############################\n\n\t\trepacking recipe\n\n############################")
//		
//		let repack = RePackRecipe(recipe: recipe, packageString: package.swiftFile.description, source: .current, destination: .current + "packages/\(recipe)")
//		try await repack.repack()
//		
//		for target in package.spec.targets {
//			for dep in target.dependencies {
//				if let binary = dep as? PackageSpec.BinaryTarget {
//					for bt in binary.binaryTargets {
//						let dst = (repack.destination + bt.file)
//						try bt.path.forceCopy(dst)
//					}
//				}
//			}
//			
//		}
		
		
	}
	
	
	
	
}

extension Path {
	
	func forceCopy(_ destination: Path) throws {
		if destination.exists { try destination.delete() }
		try copy(destination)
	}
}
