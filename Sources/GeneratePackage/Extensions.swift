//
//  File.swift
//  
//
//  Created by CodeBuilder on 15/10/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PathKit
import SwiftPackage

extension PackageSpecDependency {
	func binaryTarget(owner: String, repo: String, version: String) -> ArrayElementSyntax? {
		if let self = self as? PackageBinaryTarget {
			return self.binaryTarget(owner: owner, repo: repo, version: version)
		}
		return nil
	}
	
}

extension PackageBinaryTarget {
	
	func binaryTarget(owner: String, repo: String, version: String) -> ArrayElementSyntax {
//		let call = FunctionCallExprSyntax(stringLiteral: """
//		.binaryTarget(name: "\(filename)", url: "https://github.com/\(owner)/\(repo)/releases/download/\(version)/\(file)", checksum: "\(sha)")
//		""")
		let call = ExprSyntax(stringLiteral: """
		.binaryTarget(name: "\(filename)", url: "https://github.com/\(owner)/\(repo)/releases/download/\(version)/\(file)", checksum: "\(sha)")
		""")
		//return .init(expression: call).withLeadingTrivia(.newline + .tab).withTrailingComma(.comma)
		return .init(leadingTrivia: .newline + .tab, expression: call, trailingComma: .commaToken())
	}
	func binaryTarget(name: String, path: String) -> ArrayElementSyntax {
		let local = Path(path).lastComponent
//		let call = FunctionCallExprSyntax(stringLiteral: """
//		.binaryTarget(name: "\(name)", path: "\(local)")
//		""")
//		
//		return .init(expression: call).withLeadingTrivia(.newline + .tab).withTrailingComma(.comma)
		let call = ExprSyntax(stringLiteral: """
		.binaryTarget(name: "\(name)", path: "\(local)")
		""")
		return .init(leadingTrivia: .newline + .tab, expression: call, trailingComma: .commaToken())
	}
}

extension PackageSpec.LinkerSetting {
	
	func string() -> String {
		switch self {
		case .framework(let value):
			return ".linkedFramework(\"\(value)\")"
		case .library(let value):
			return ".linkedLibrary(\"\(value)\")"
		}
	}
	
	func setting() -> ArrayElementSyntax {
		//let call = FunctionCallExpr(stringLiteral: string() )
		let call = ExprSyntax(stringLiteral: string() )
		//return .init(expression: call).withLeadingTrivia(.newline + .tabs(2))
		return .init(leadingTrivia: .newline + .tabs(2), expression: call)
	}
}

func createBinaryTargets(folder: PathKit.Path) -> [PackageBinaryTarget] {
	folder
		.filter({$0.extension == "zip"})
		.map(PackageBinaryTarget.init)
}


extension Sequence {
	func asyncMap<T>(
		_ transform: (Element) async throws -> T
	) async rethrows -> [T] {
		var values = [T]()
		
		for element in self {
			try await values.append(transform(element))
		}
		
		return values
	}
	
}

fileprivate enum DependencyCodingKeys: String, CodingKey {
	case binary
	////case package
	case product
	case target
	//case name
}

extension KeyedDecodingContainer {
	public func decode(_ type: [PackageSpecDependency].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [PackageSpecDependency] {
		if !contains(key) { return [] }
		var c = try nestedUnkeyedContainer(forKey: key)
		var pc = try nestedUnkeyedContainer(forKey: key)
		var output = [PackageSpecDependency]()
		while !c.isAtEnd {
			print(c.currentIndex)
			
			let switchKey = try! c.nestedContainer(keyedBy: DependencyCodingKeys.self)
			
			print(c.currentIndex)
			switch switchKey {
			case let trg where trg.contains(.target):
				output.append(try pc.decode(PackageSpec.Target.self))
			case let bin where bin.contains(.binary):
				//output.append(try nested.decode(PackageSpec.BinaryTarget.self, forKey: .binary))
				output.append(try pc.decode(PackageSpec.BinaryTarget.self))
//			case let pack where pack.contains(.package):
				//output.append(try! nested.decode(PackageSpec.SwiftPackage.self, forKey: .package))
				//let nested = try pc.nestedContainer(keyedBy: PackageSpec.SwiftPackage.CodingKeys.self)
				//print(nested.allKeys, nested.codingPath)
				//output.append(try! pc.decode(PackageSpec.SwiftPackage.self))
			case let product where product.contains(.product):
				//output.append(try nested.decode(PackageSpec.PackageProduct.self, forKey: .product))
				
				output.append(try pc.decode(PackageSpec.PackageProduct.self))
			//case let string where string.contains(.binary)
			default: throw DecodingError.keyNotFound(key, .init(codingPath: [], debugDescription: "wrong key"))
			}
		}
		return output
	}
	
}
