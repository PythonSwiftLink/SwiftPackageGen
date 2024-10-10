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


public class UpdatePackage: SwiftPackage {
	public var swiftFile: SwiftSyntax.SourceFileSyntax
	
	public var xcframeworks: PathKit.Path
	
	public var version: String
	
	public var owner: String
	
	public var repo: String
	
	public var modifiedFile: SwiftSyntax.SourceFileSyntax
	
	public init(swiftFile: Path, xcframeworks: PathKit.Path, version: String, owner: String, repo: String) throws {
		
		let _swiftFile = Parser.parse(source: try swiftFile.read())
		self.swiftFile = _swiftFile
		self.xcframeworks = xcframeworks
		self.version = version
		self.owner = owner
		self.repo = repo
		self.modifiedFile = _swiftFile
	}
}
