
import ArgumentParser
import SwiftPrettyPrint
import PathKit
import RecipeBuilder
import GeneratePackage
import SwiftPackage

extension PathKit.Path: ExpressibleByArgument {
	public init?(argument: String) {
		self.init(argument)
	}
}


@main
struct SwiftPackageGen: AsyncParsableCommand {
	
	static var configuration: CommandConfiguration = .init(
		version: "0.0.5",
		subcommands: [
			Builder.self,
			
			Update.self
		]
	)
	
//	struct Generate: AsyncParsableCommand {
//		
//		@Argument var spec: Path
//		@Argument var version: String
//		@Option var input: Path?
//		@Option var output: Path?
//		
//		mutating func run() async throws {
//			print("swift_file: \(input?.string ?? "no file using internal string")")
//			print("spec: \(spec.string)")
//			print("version: \(version)")
//			
//			let package = try await GeneratePackage(fromSwiftFile: input, spec: spec, version: version)
//			if let output = output {
//				print("--output: \(output.string)")
//				try output.write(package.swiftFile.description, encoding: .utf8)
//			} else {
//				if let input = input {
//					try input.write(package.swiftFile.description, encoding: .utf8)
//				}
//			}
//		}
//	}
	
	struct Builder: AsyncParsableCommand {
		@Argument var recipe: String
		@Argument var spec: Path
		@Option(name: .shortAndLong) var path: String?
		
		@Option(name: .shortAndLong) var output: Path?
		
		func run() async throws {
			try await RecipeBuilder(recipe: recipe, spec: spec, path: path, output: output).run()
		}
	}
	
//	struct Update: AsyncParsableCommand {
//		@Argument var file: Path
//		@Argument var xcframework: Path
//		@Argument var version: String
//		@Argument var owner: String
//		@Argument var repo: String
//		
//		func run() async throws {
//			let package = try UpdatePackage(
//				swiftFile: file,
//				xcframeworks: xcframework,
//				version: version,
//				owner: owner,
//				repo: repo
//			)
//			try await package.modifyPackage()
////			try await UpdateBinaryTargets(
////				file: file,
////				xcframeworks: xcframework,
////				version: version,
////				owmer: owner,
////				repo: repo
////			)
////				.description
////				.write(toFile: file.string, atomically: true, encoding: .utf8)
//		}
//	}
}
