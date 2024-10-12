//
//  File.swift
//  
//
//  Created by CodeBuilder on 16/10/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
//import GeneratePackage
import PathKit


enum PackageArgNames: String {
	case name
	case products
	case dependencies
	case targets
	//case linkedSettings
}

enum TargetArgNames: String {
	case name
	case dependencies
	case linkerSettings
}

public struct PackageReleaseInfo {
	public let version: String
	public let owner: String
	public let repo: String
	
	public init(version: String, owner: String, repo: String) {
		self.version = version
		self.owner = owner
		self.repo = repo
	}
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

public protocol SwiftPackage: AnyObject {
	var swiftFile: SourceFileSyntax { get }
	var xcframeworks: Path { get }
//	var version: String { get }
//	var owner: String { get }
//	var repo: String { get }
	var release_info: PackageReleaseInfo { get }
	var spec: SwiftPackageSpec? { get }
	var modifiedFile: SourceFileSyntax { get set }
	
	//var binaryTargets: []
}

enum TargetType: String {
	case target
	case binaryTarget
	
	init?(target: FunctionCallExprSyntax) {
		guard let memberAccessExpr = target.calledExpression.as(MemberAccessExprSyntax.self) else { return nil }
		self.init(rawValue: memberAccessExpr.declName.baseName.text)
	}
}

public extension SwiftPackage {
	
	func updateBinaryTargets(_ targets: inout ArrayExprSyntax) async throws {
		try await targets.updateBinaryTargets(
			binaries: xcframeworks,
			version: release_info.version,
			owner: release_info.owner,
			repo: release_info.repo
		)
	}
	
}

extension ArrayExprSyntax {
	
	mutating func updateBinaryTargets(spec: SwiftPackageSpec, info: PackageReleaseInfo ) async throws {
		let binary_files = spec.binaryTargets.reduce(into: [SwiftPackageSpec.BinaryFile]()) { partialResult, target in
			partialResult.append(contentsOf: target.files)
		}
		elements = .init(try await elements.asyncMap { element in
			guard
				var target = element.expression.as(FunctionCallExprSyntax.self),
				TargetType(target: target) == .binaryTarget
			else { return element }
//			try await target.updateBinaryTarget(
//				binaries: binary_files,
//				version: info.version,
//				owner: info.owner,
//				repo: info.repo
//			)
			try await target.updateBinaryTarget(binaries: binary_files, info: info)
			return element.with(\.expression, .init(target))
		})
	}
	
	mutating func updateBinaryTargets(binaries: Path, version: String, owner: String, repo: String) async throws {
		elements =  .init(try await elements.asyncMap {
			element in
			
			guard
				var target = element.expression.as(FunctionCallExprSyntax.self),
				TargetType(target: target) == .binaryTarget
			else { return element }
			try await target.updateBinaryTarget(
				binaries: binaries,
				version: version,
				owner: owner,
				repo: repo
			)
			return element.with(\.expression, .init(target))
			
			//return element.withExpression(.init(target))
		})
	}
}

extension FunctionCallExprSyntax {
	mutating func updateBinaryTarget(binaries: [SwiftPackageSpec.BinaryFile], info: PackageReleaseInfo) async throws {
		guard let name = arguments.first?.expression.as(StringLiteralExprSyntax.self)?.segments.first?.description else { fatalError() }
		guard let binary = binaries.first(where: {$0.name == name}) else { fatalError() }
		arguments = .init(
			arguments.map({
				arg in
				switch arg.label?.description {
				case "url":
					return arg.with(\.expression, .init(StringLiteralExprSyntax(content:  "https://github.com/\(info.owner)/\(info.repo)/releases/download/\(info.version)/\(binary.name)"))
					)
					//					return arg.withExpression(
					//						.init(StringLiteralExprSyntax(content:  "https://github.com/\(owner)/\(repo)/releases/download/\(version)/\(binary.lastComponent)"))
					//					)
				case "checksum":
					return arg.with(\.expression, .init(literal: binary.sha256))
				default: return arg
				}
				
			})
		)
	}
	
	fileprivate mutating func updateBinary(bin: SwiftPackageSpec.BinaryFile, info: PackageReleaseInfo) async throws {
		
	}
	
	mutating func updateBinaryTarget(binaries: Path, version: String, owner: String, repo: String) async throws {
		print(self.calledExpression.description)
		guard let name = arguments.first?.expression.as(StringLiteralExprSyntax.self)?.segments.first?.description else { fatalError() }
		let binaryFiles = try binaries.children()
		print(name, binaryFiles.map(\.lastComponentWithoutExtension).contains(name))
		guard let binary = binaryFiles.first(where: {$0.lastComponentWithoutExtension == name}) else { fatalError() }
		arguments = .init(
			try arguments.map({
				arg in
				switch arg.label?.description {
				case "url":
					return arg.with(\.expression, .init(StringLiteralExprSyntax(content:  "https://github.com/\(owner)/\(repo)/releases/download/\(version)/\(binary.lastComponent)"))
					)
//					return arg.withExpression(
//						.init(StringLiteralExprSyntax(content:  "https://github.com/\(owner)/\(repo)/releases/download/\(version)/\(binary.lastComponent)"))
//					)
				case "checksum":
					return arg.with(\.expression,
						.init(literal: try binary.sha256())
					)
				default: return arg
				}
				
			})
		)
	}
}
//
//
//extension ArrayExpr {
//	mutating func updateTargets(binaries: Path, version: String, owner: String, repo: String) async throws {
//		
//		elements = .init(try await elements.asyncMap {
//			element in
//			guard
//				var target = element.expression.as(FunctionCallExpr.self),
//				TargetType(target: target) == .binaryTarget
//			else { return element }
//			try await target.updateBinaryTarget(
//				binaries: binaries,
//				version: version,
//				owner: owner,
//				repo: repo
//			)
//			
//			return element.withExpression(.init(target))
//		})
//	}
//}
//
public extension SwiftPackage {
	func modifyPackage() async throws {
		modifiedFile.statements = .init(try await swiftFile.statements.asyncMap { stmt in
			if var vari = stmt.item.as(VariableDeclSyntax.self) {
				try await _modifyPackage(&vari)
				return .init(item: .init(vari))
			}
			
			return stmt
		}
		)
	}
	
	func _modifyPackage(_ syntax: inout VariableDeclSyntax) async throws {
		if var binding = syntax.bindings.first {
			let pattern = binding.pattern
			print("\t\(pattern.kind) - \(pattern)")
			if let identifierPattern = pattern.as(IdentifierPatternSyntax.self) {
				let identifier = identifierPattern.identifier.text
				switch identifier {
				case "package":
					if var packageValue = binding.initializer?.value.as(FunctionCallExprSyntax.self) {
						try await readPackageFunctionCall(syntax: &packageValue)
						binding.initializer?.value = .init(packageValue)
					}
					//fatalError()
				default: fatalError(identifier)
				}
				//print("\t\(binding.initializer?.value.kind.nameForDiagnostics ?? "no initializer.value")")
				//print("\t\()")
			}
			syntax.bindings = .init([binding])
		}
	}


	fileprivate func readPackageFunctionCall(syntax: inout FunctionCallExprSyntax) async throws {
		let args: [LabeledExprSyntax] = try await syntax.arguments.asyncMap { arg in
			if let arg_name = arg.label?.text, let arg_case = PackageArgNames(rawValue: arg_name) {
				switch arg_case {
					
				case .targets:
					if var targets = arg.expression.as(ArrayExprSyntax.self) {
						if let spec = spec {
							try await targets.updateBinaryTargets(spec: spec, info: release_info)
						} else {
							try await updateBinaryTargets(&targets)
						}
						//return .init(label: arg_name, expression: .init(targets)).with(\.trailingTrivia, .newline )
						return .init(
							label: arg_name,
							expression: targets
						).with(\.trailingTrivia, .newline)
					}
				case .dependencies:
					
					
					return arg
				default: return arg
				}
				
			}
			return arg
		}
		syntax.arguments = .init(args)
	}
	
	var description: String {
		var code = ""
		modifiedFile.formatted().write(to: &code)
		return code
	}
}


public extension SwiftPackage {
	
}
////
////class TargetClass {
////	
////	enum TargetArgNames: String {
////		case name
////		case dependencies
////		case linkerSettings
////	}
////	
////	var name: String?
////	
////	init(args: TupleExprElementList, spec: PackageSpec.PackageTarget) {
////		for arg in args {
////			if let argText = arg.label?.text, let targetArg = TargetArgNames(rawValue: argText) {
////				switch targetArg {
////				case .name:
////					name = arg.expression.as(StringLiteralExpr.self)?.segments.first?.description
////				case .dependencies:
////					break
////				case .linkerSettings:
////					(spec.linkerSettings ?? [])
////					
////				}
////			}
////		}
////	}
////}

class PackageClass {
	var name: String = ""
	
	
}
