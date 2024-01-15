//
//  File.swift
//  
//
//  Created by CodeBuilder on 14/01/2024.
//

import Foundation
import PathKit


struct Toolchain {
	
	class Build {
		let outputPipe = Pipe()
		
		var process = Process()
		init(recipe: String, optionalArgs: [String]?) {
			
			let extraArgs = (optionalArgs ?? []).joined(separator: " ")
			//standardOutput = outputPipe
			var _arguments = [
				"-c",
				"""
				. \(Path.venvActivate.string)
				toolchain clean \(recipe) \(extraArgs)
				toolchain build \(recipe) \(extraArgs)
				deactivate
				"""
			]
//			if let optionalArgs = optionalArgs {
//				_arguments.append(contentsOf: optionalArgs)
//			}
			process.executableURL = .ZSH
			process.arguments = _arguments
		}
		
		func run() throws {
			try process.run()
			
			process.waitUntilExit()
		}
	}
	
}
