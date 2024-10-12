//
//  File.swift
//  
//
//  Created by CodeBuilder on 09/10/2024.
//

import Foundation
import PathKit
import SwiftSyntax
import SwiftParser
import Yams

public class UpdatePackage: SwiftPackage {
	public var swiftFile: SwiftSyntax.SourceFileSyntax
	
	public var xcframeworks: PathKit.Path
	
//	public var version: String
//	
//	public var owner: String
//	
//	public var repo: String
	
	public var release_info: PackageReleaseInfo
	
	public var spec: SwiftPackageSpec?
	
	public var modifiedFile: SwiftSyntax.SourceFileSyntax
	
	public init(swiftFile: Path, xcframeworks: PathKit.Path, info: PackageReleaseInfo, spec: Path? = nil) throws {
		
		let _swiftFile = Parser.parse(source: try swiftFile.read())
		self.swiftFile = _swiftFile
		self.xcframeworks = xcframeworks
		self.release_info = info
		if let spec = spec {
			self.spec = try YAMLDecoder().decode(SwiftPackageSpec.self, from: spec.read())
		}
		self.modifiedFile = _swiftFile
	}
}
