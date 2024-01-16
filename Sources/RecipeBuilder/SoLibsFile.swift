//
//  File.swift
//  
//
//  Created by CodeBuilder on 15/01/2024.
//

import Foundation
import PathKit

public struct SoLibsFile {
	
	var linkerSource: Path
	var xcodePath: Path?
	var optionals: String?
	
	public init(file: Path, dist_lib: Path) throws {
		self.linkerSource = dist_lib
		
		let content = try file.read(.utf8)
		let args = content.split(separator: "-L").map(String.init)
		switch args.count {
		case 4...:
			optionals = args[2...].joined(separator: " ")
			xcodePath = .init(args[1])
		case 3:
			optionals = args[2]
			xcodePath = .init(args[1])
		case 2:
			xcodePath = .init(args[1])
			
		
		default: break//fatalError("\(args.count) - \(file)")
		}
	}
	
	public var output: String? {
		if let xcodePath = xcodePath {
			if let optionals = optionals {
				return "-L\(linkerSource.string) -L\(xcodePath.string) -L\(optionals)"
			}
			return "-L\(linkerSource.string) -L\(xcodePath.string)"
		}
		return nil
	}
}
