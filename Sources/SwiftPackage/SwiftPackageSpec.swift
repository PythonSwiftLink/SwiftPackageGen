//
//  File.swift
//  
//
//  Created by CodeBuilder on 12/10/2024.
//

import Foundation

import PathKit


public struct SwiftPackageSpec: Decodable {
	
	public let binaryTargets: [BinaryTarget]
	
	
	
}

extension Path: Decodable {
	public init(from decoder: Decoder) throws {
		self.init(try decoder.singleValueContainer().decode(String.self))
	}
}

extension SwiftPackageSpec {
	public enum BinaryType: String, Decodable {
		case dir
		case file
	}
	
	public struct BinaryFile {
		public let file: Path
		public let name: String
		public let sha256: String
		
		init(file: Path) throws {
			self.file = file
			self.name = file.lastComponentWithoutExtension
			self.sha256 = try file.sha256()
		}
	}
	
	public struct BinaryTarget: Decodable {
		public let name: String
		public let path: Path
		public let type: BinaryType
		
		public var files: [BinaryFile]
		
		enum CodingKeys: CodingKey {
			case name
			case path
			case type
		}
		
		public init(from decoder: Decoder) throws {
			let container: KeyedDecodingContainer<SwiftPackageSpec.BinaryTarget.CodingKeys> = try decoder.container(keyedBy: SwiftPackageSpec.BinaryTarget.CodingKeys.self)
			
			self.name = try container.decode(String.self, forKey: SwiftPackageSpec.BinaryTarget.CodingKeys.name)
			let path = try container.decode(Path.self, forKey: SwiftPackageSpec.BinaryTarget.CodingKeys.path)
			let type = try container.decode(SwiftPackageSpec.BinaryType.self, forKey: SwiftPackageSpec.BinaryTarget.CodingKeys.type)
			self.path = path
			self.type = type
			switch type {
			case .dir:
				files = try path.children().compactMap({ f in
					guard f.extension == "zip" else { return nil }
					return try BinaryFile(file: f)
				})
			case .file:
				files = [
					try BinaryFile(file: path)
				]
			}
			
		}
		
		
	}
}
