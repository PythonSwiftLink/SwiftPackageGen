//
//  File.swift
//  
//
//  Created by CodeBuilder on 16/10/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import GeneratePackage

class TargetClass {
	
	enum TargetArgNames: String {
		case name
		case dependencies
		case linkerSettings
	}
	
	var name: String?
	
	init(args: TupleExprElementList, spec: PackageSpec.PackageTarget) {
		for arg in args {
			if let argText = arg.label?.text, let targetArg = TargetArgNames(rawValue: argText) {
				switch targetArg {
				case .name:
					name = arg.expression.as(StringLiteralExpr.self)?.segments.first?.description
				case .dependencies:
					break
				case .linkerSettings:
					(spec.linkerSettings ?? [])
					
				}
			}
		}
	}
}

class PackageClass {
	var name: String = ""
	
	
}
