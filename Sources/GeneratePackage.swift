import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder
import PathKit
import Yams

func packageSample(repo: String) -> String {
"""
// swift-tools-version: 5.8

import PackageDescription

let package = Package(
name: "\(repo)",
platforms: [.iOS(.v13)],
products: [],
dependencies: [],
targets: []
)
"""
}


extension PathKit.Path: Decodable {
	public init(from decoder: Decoder) throws {
		self.init(try decoder.singleValueContainer().decode(String.self))
	}
}
extension PathKit.Path {
	func createBinaryTargets() -> [PackageBinaryTarget] {
		self
			.filter({$0.extension == "zip"})
			.map(PackageBinaryTarget.init)
	}
}

extension GeneratePackage {
	class SyntaxDependencies {
		var src: TupleExprElement
		
		
		init(name: String, src: TupleExprElement, spec: PackageSpec, version: String, dependencies: [PackageSpecDependency]) {
			self.src = src
			
		}
	}
	
	class SyntaxTarget {
		var name: String? { src.getTargetName() }
		var spec: PackageSpec
		var targetSpec: PackageSpec.PackageTarget? { spec.targets.first(where: {$0.name == name }) }
		var src: FunctionCallExpr
		
		var version: String
		var dependencies: SyntaxDependencies? {
			if let member = src.getMember(key: .dependencies) {
				
				//return SyntaxDependencies(src: member, spec: spec, version: version)
			}
			
			return nil
		}
		init(name: String, spec: PackageSpec, src: FunctionCallExpr, version: String) {
			//self.name = name
			self.spec = spec
			self.src = src
			self.version = version
			
			if let t = targetSpec {
				t.modifyDependencies(&self.src)
				t.modifyResources(&self.src)
				t.modifyLinkerSettings(&self.src)
				
			}
		}
		
		var binaryTargets: [ArrayElement] {
			
			
			return []
		}
	}
}

extension GeneratePackage {
	
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
	
	
	
	fileprivate func handleTarget(_ target: inout FunctionCallExpr) async throws {
		
	}
	
	fileprivate func handlePackageTargets(_ targets: inout ArrayExpr) async throws {
		//infoPrint("handlePackageTargets(_ targets: inout ArrayExpr)", indent: 2)
		var output_targets: [ArrayElement] = []
		var output_binaryTargets: [ArrayElement] = []
		
		var filteredTargets = targets.elements.filter { element in
			if let target = element.expression.as(FunctionCallExpr.self) {
				if TargetType(target: target) == .target { return true }
			}
			return false
		}
		var filteredBinaryTargets = targets.elements.filter { element  in
			if let target = element.expression.as(FunctionCallExpr.self) {
				if TargetType(target: target) == .binaryTarget { return true }
			}
			return false
		}
		if filteredTargets.isEmpty {
			filteredTargets.append(contentsOf: spec.targets.map { specTarget in
				.init(expression: FunctionCallExpr(stringLiteral:
				"""
				.target(
					name: "\(specTarget.name)",
					dependencies: [
					],
					resources: [
					],
					linkerSettings:[
					]
					)
				""").withLeadingTrivia(.newline + .tab) ).withTrailingComma(.comma)
			})
		}
		for var _target in filteredTargets {
			guard var func_target = _target.expression.as(FunctionCallExpr.self) else { fatalError() }
			
			let syntaxTarget = SyntaxTarget(name: "", spec: spec, src: func_target, version: version)
			
			if let t = syntaxTarget.targetSpec {
				let binaryDeps = t.dependencies.compactMap { $0 as? PackageSpec.BinaryTarget}
				for dependency in binaryDeps {
					output_binaryTargets.append(contentsOf: dependency.binaryTargets.map { binaryTarget in
						binaryTarget.binaryTarget(owner: spec.owner, repo: spec.repository, version: version)
					})
					
				}
			}

			_target.expression = .init(syntaxTarget.src)
			output_targets.append(_target)
		}
		
		for binary in filteredBinaryTargets {
			infoPrint("target.argumentList", binary.description, indent: 5)
		}
		
		
//		for var _target in targets.elements {
//			if var func_target = _target.expression.as(FunctionCallExpr.self) {
//				switch TargetType(target: func_target) {
//				case .target:
//					if let targetName = func_target.getTargetName(), let t = spec.targets.first(where: {$0.name == targetName}) {
//						t.modifyLinkerSettings(&func_target)
//						_target.expression = .init(func_target)
//						let binaryDeps = t.dependencies.compactMap { $0 as? PackageSpec.BinaryTarget}
//						for dependency in binaryDeps {
//							output_binaryTargets.append(contentsOf: dependency.binaryTargets.map { binaryTarget in
//								binaryTarget.binaryTarget(owner: spec.owner, repo: spec.repository, version: version)
//							})
//						}
//					}
//					output_targets.append(_target)
//					
//				case .binaryTarget:
//					infoPrint("target.argumentList", func_target.argumentList.map(\.description), indent: 5)
////					for _target_arg in target.argumentList {
////						let arg_exp = _target_arg.expression
////						//infoPrint(_target_arg.label?.text ?? "_", arg_exp, indent: 6)
////					}
//				default: fatalError()
//				}
//			}
//			
//		}
		targets = .init(elements: .init(output_targets + output_binaryTargets)).withRightSquare(.rightSquareBracket.withLeadingTrivia(.newline))
	}
	
	fileprivate func handleLinkedSettings(_ settings: inout ArrayExpr) async throws {
		
	}
	
	fileprivate func handlePackageDependencies(_ dependencies: inout ArrayExpr) async throws {
		print("\t\thandlePackageDependencies(_ dependencies: inout ArrayExpr):")
		infoPrint("elements", dependencies.elements.map(\.expression.kind), indent: 3)
		for pack in (spec.dependencies ?? []).compactMap({$0 as? PackageSpec.SwiftPackage}) {
			var packageString: String {
				switch pack.version {
				case .branch(branch: _):
					return ""
				case .from(version: let version):
					return ".package(url: \"\(pack.url ?? "")\", from: .init(\(version.replacingOccurrences(of: ".", with: ", "))))"
				case .upToNextMajor(version: let version):
					return ".package(url: \"\(pack.url ?? "")\", .upToNextMajor(from: \"\(version)\"))"
				case .version(version: _):
					return ""
				}
			}
			dependencies = dependencies.addElement(.init(expression: FunctionCallExpr(stringLiteral: packageString)).withLeadingTrivia(.newline + .tab))
		}
		dependencies.rightSquare = .rightSquareBracket.withLeadingTrivia(.newline)
	}
	fileprivate func handleProducts(_ products: inout ArrayExpr) async throws {
		for product in spec.products {
			switch product {
			case .library(let name, let targets):
				products.elements = products.elements.appending(.init(
					expression: FunctionCallExpr(stringLiteral: """
					.library(
						name: "\(name)",
						targets: [
							\(targets.map({"\"\($0)\""}).joined(separator: ",\n\t"))
						]
					)
					"""
					).withLeadingTrivia(.newline + .tab).withRightParen(.rightParen.withLeadingTrivia(.newline + .tab))).withTrailingComma(.comma))
			}
		}
	}
	
	fileprivate func readPackageFunctionCall(syntax: inout FunctionCallExpr) async throws {
		var args: [TupleExprElement] = try await syntax.argumentList.asyncMap { arg in
			if let arg_name = arg.label?.text, let arg_case = PackageArgNames(rawValue: arg_name) {
				switch arg_case {
				case .name:
					return arg
				case .products:
					if var products = arg.expression.as(ArrayExpr.self) {
						try await handleProducts(&products)
						
						return arg.withExpression(.init(products.withRightSquare(.rightSquareBracket.withLeadingTrivia(.newline))))
					}
					
					return arg
				case .dependencies:
					if var dependencies = arg.expression.as(ArrayExpr.self) {
						try await handlePackageDependencies(&dependencies)
						return .init(label: arg_name, expression: .init(dependencies)).withTrailingComma(.comma).withLeadingTrivia(.newline)
					}
				case .targets:
					if var targets = arg.expression.as(ArrayExpr.self) {
						try await handlePackageTargets(&targets)
						return .init(label: arg_name, expression: .init(targets)).withLeadingTrivia(.newline )
					}
				
				}
			}
			return arg
		}
		syntax.argumentList = .init(args)
	}
	
	fileprivate func readVariableDecl(syntax: inout VariableDecl) async throws {
		//print("handleVariableDecl(syntax: VariableDecl):")
		if var binding = syntax.bindings.first {
			let pattern = binding.pattern
			print("\t\(pattern.kind) - \(pattern)")
			if let identifierPattern = pattern.as(IdentifierPattern.self) {
				let identifier = identifierPattern.identifier.text
				switch identifier {
				case "package":
					if var packageValue = binding.initializer?.value.as(FunctionCallExpr.self) {
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
}


class GeneratePackage {
	
	var spec: PackageSpec
	var swiftFile: ReadSwiftFile
	var version: String
	
	init(fromSwiftFile file: Path?, spec: Path, version: String) async throws {
		self.spec = try YAMLDecoder().decode( PackageSpec.self, from: spec.read() )
		self.version = version
		swiftFile = try .init(file: file, spec: self.spec)
		swiftFile.output = try await swiftFile.output.asyncMap { stmt in
			let item = stmt.item
			switch item.kind {
			case .variableDecl:
				if var variDecl = item.as(VariableDecl.self) {
					try await readVariableDecl(syntax: &variDecl)
					return .init(item: .decl(.init(variDecl)))
					
				}
			default:
				return stmt
			}
			return stmt
		}

		
	}
	
}





