
import ArgumentParser
import SwiftPrettyPrint
import PathKit

extension PathKit.Path: ExpressibleByArgument {
	public init?(argument: String) {
		self.init(argument)
	}
}
@main
struct SwiftPackageGen: AsyncParsableCommand {
	
	
	@Argument var spec: Path
	@Argument var version: String
	@Option var input: Path?
	@Option var output: Path?
	
    mutating func run() async throws {
		print("swift_file: \(input?.string ?? "no file using internal string")")
		print("spec: \(spec.string)")
		print("version: \(version)")
		
		let package = try await GeneratePackage(fromSwiftFile: input, spec: spec, version: version)
		if let output = output {
			print("--output: \(output.string)")
			try output.write(package.swiftFile.description, encoding: .utf8)
		} else {
			if let input = input {
				try input.write(package.swiftFile.description, encoding: .utf8)
			}
		}
    }
}
