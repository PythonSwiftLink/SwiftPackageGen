//
//  File.swift
//  
//
//  Created by CodeBuilder on 10/10/2024.
//

import Foundation
import SwiftPackage
import ArgumentParser
import PathKit


extension SwiftPackageGen {
	
	struct Update: AsyncParsableCommand {
		@Argument var file: Path
		@Argument var xcframework: Path
		@Argument var version: String
		@Argument var owner: String
		@Argument var repo: String
		@Option var output: Path?
		@Option var spec: Path?
		
		func run() async throws {
			print("running command")
			let package = try UpdatePackage(
				swiftFile: file,
				xcframeworks: xcframework,
				info: .init(version: version, owner: owner, repo: repo),
				spec: spec
			)
			try await package.modifyPackage()
			let new = package
				.description
			
			if let output = output {
				try output.write(new, encoding: .utf8)
			} else {
				try file.write(new, encoding: .utf8)
			}
		}
	}
}


