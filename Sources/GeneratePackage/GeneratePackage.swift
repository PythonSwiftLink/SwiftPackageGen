import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder
import PathKit
import Yams
import SwiftPackage

func packageSample(repo: String, macOS: Bool) -> String {
"""
// swift-tools-version: 5.8

import PackageDescription

let package = Package(
name: "\(repo)",
platforms: [.iOS(.v13)\(macOS ? ", .macOS(.v11)" : "")],
products: [],
dependencies: [],
targets: []
)
"""
}


//extension PathKit.Path: Decodable {
//	public init(from decoder: Decoder) throws {
//		self.init(try decoder.singleValueContainer().decode(String.self))
//	}
//}
extension PathKit.Path {
	func createBinaryTargets() -> [PackageBinaryTarget] {
		self
			.compactMap { file in
				switch file.extension {
				case "zip":
					return PackageBinaryTarget(path: file)
				case "xcframework":
					return PackageBinaryTarget(path: file)
				default: break
				}
				return nil
			}
//			.filter({$0.extension == "zip"})
//			.map(PackageBinaryTarget.init)
	}
}

extension GeneratePackage {
	class SyntaxDependencies {
		var src: TupleExprElementSyntax
		
		
		init(name: String, src: TupleExprElementSyntax, spec: PackageSpec, version: String, dependencies: [PackageSpecDependency]) {
			self.src = src
			
		}
	}
	
	class SyntaxTarget {
		var name: String? { src.getTargetName() }
		var spec: PackageSpec
		var targetSpec: PackageSpec.PackageTarget? { spec.targets.first(where: {$0.name == name }) }
		var src: FunctionCallExprSyntax
		
		var version: String
		var dependencies: SyntaxDependencies? {
			if let member = src.getMember(key: .dependencies) {
				
				//return SyntaxDependencies(src: member, spec: spec, version: version)
			}
			
			return nil
		}
		init(name: String, spec: PackageSpec, src: FunctionCallExprSyntax, version: String) {
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
		
		var binaryTargets: [ArrayElementSyntax] {
			
			
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
	
	
	
	fileprivate func handleTarget(_ target: inout FunctionCallExprSyntax) async throws {
		
	}
	
	fileprivate func handlePackageTargets(_ targets: inout ArrayExprSyntax) async throws {
		//infoPrint("handlePackageTargets(_ targets: inout ArrayExpr)", indent: 2)
		var output_targets: [ArrayElementSyntax] = []
		var output_binaryTargets: [ArrayElementSyntax] = []
		
		var filteredTargets = targets.elements.filter { element in
			if let target = element.expression.as(FunctionCallExprSyntax.self) {
				if TargetType(target: target) == .target { return true }
			}
			return false
		}
		var filteredBinaryTargets = targets.elements.filter { element  in
			if let target = element.expression.as(FunctionCallExprSyntax.self) {
				if TargetType(target: target) == .binaryTarget { return true }
			}
			return false
		}
		if filteredTargets.isEmpty {
			filteredTargets.append(contentsOf: spec.targets.compactMap { specTarget in
				if specTarget.custom_recipe { return nil }
				//return .init(
				return .init(
					expression: ExprSyntax(stringLiteral: """
					.target(
					name: "\(specTarget.name)",
					dependencies: [
					],
					resources: [
					],
					linkerSettings:[
					]
					),
					""").with(\.leadingTrivia, .newline + .tab)
							 //.withLeadingTrivia(.newline + .tab) ).withTrailingComma(.comma)
				)
			})
								   
		}
		for var _target in filteredTargets {
			guard var func_target = _target.expression.as(FunctionCallExprSyntax.self) else { fatalError() }
			
			let syntaxTarget = SyntaxTarget(name: "", spec: spec, src: func_target, version: version)
			
			if let t = syntaxTarget.targetSpec {
				let binaryDeps = t.dependencies.compactMap { $0 as? PackageSpec.BinaryTarget}
				for dependency in binaryDeps {
					
					
				}
			}

			_target.expression = .init(syntaxTarget.src)
			output_targets.append(_target)
		}
		for target in spec.targets {
			for dependency in target.dependencies.compactMap({$0 as? PackageSpec.BinaryTarget}) {
				output_binaryTargets.append(contentsOf: dependency.binaryTargets.map { binaryTarget in
					if dependency.localUsage {
						
						if Path(binaryTarget.file).exists {
							binaryTarget.binaryTarget(name: binaryTarget.filename, path: binaryTarget.file )
						} else {
							binaryTarget.binaryTarget(name: binaryTarget.filename, path: (Path.current + binaryTarget.file).string )
						}
						
					} else {
						binaryTarget.binaryTarget(owner: spec.owner, repo: spec.repository, version: version)
					}
				})
			}
			
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
		targets = .init(elements: .init(itemsBuilder: {
			for output_target in output_targets {
				output_target
			}
			for output_binaryTarget in output_binaryTargets {
				output_binaryTarget
			}
		}))
		//targets = .init(elements: .init(output_targets + output_binaryTargets)).withRightSquare(.rightSquareBracket.withLeadingTrivia(.newline))
	}
	
	fileprivate func handleLinkedSettings(_ settings: inout ArrayExprSyntax) async throws {
		
	}
	
	fileprivate func handlePackageDependencies(_ dependencies: inout ArrayExprSyntax) async throws {
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
			dependencies.elements.append( .init(expression: ExprSyntax(stringLiteral: packageString)) )
												   //.withLeadingTrivia(.newline + .tab))
		}
		//dependencies.rightSquare = .rightSquareBracket.withLeadingTrivia(.newline)
		dependencies.rightSquare = .rightSquareToken(leadingTrivia: .newline)
	}
	fileprivate func handleProducts(_ products: inout ArrayExprSyntax) async throws {
		for product in spec.products {
			switch product {
			case .library(let name, let targets):
				
				products.elements.append(.init(
					leadingTrivia: .newline + .tab,
					expression: ExprSyntax(stringLiteral: """
						.library(
						name: "\(name)",
						targets: [
						\(targets.map({"\"\($0)\""}).joined(separator: ",\n"))
						]
						)
						"""),
					trailingComma: .commaToken(trailingTrivia: .newline)
					
				)
				)
				//.withLeadingTrivia(.newline + .tab).withRightParen(.rightParen.withLeadingTrivia(.newline + .tab))).withTrailingComma(.comma))
			}
		}
	}
	
	fileprivate func readPackageFunctionCall(syntax: inout FunctionCallExprSyntax) async throws {
		let args: [LabeledExprSyntax] = try await syntax.arguments.asyncMap { arg in
			if let arg_name = arg.label?.text, let arg_case = PackageArgNames(rawValue: arg_name) {
				switch arg_case {
				case .name:
					return arg
				case .products:
					if var products = arg.expression.as(ArrayExprSyntax.self) {
						if products.elements.count == 0 {
							try await handleProducts(&products)
						}
						arg.with(\.expression, .init(
							products.with(\.rightSquare, .rightSquareToken(leadingTrivia: .newline)))
						)
						//return arg.withExpression(.init(products.withRightSquare(.rightSquareBracket.withLeadingTrivia(.newline))))
					}
					
					return arg
				case .dependencies:
					if var dependencies = arg.expression.as(ArrayExprSyntax.self) {
						try await handlePackageDependencies(&dependencies)
						return .init(
							label: arg_name,
							expression: dependencies
						)
						//return .init(label: arg_name, expression: .init(dependencies)).withTrailingComma(.comma).withLeadingTrivia(.newline)
					}
				case .targets:
					if var targets = arg.expression.as(ArrayExprSyntax.self) {
						try await handlePackageTargets(&targets)
						return .init(
							label: arg_name,
							expression: targets
						)
						//return .init(label: arg_name, expression: .init(targets)).withLeadingTrivia(.newline )
					}
				
				}
			}
			return arg
		}
		syntax.argumentList = .init(args)
	}
	
	fileprivate func readVariableDecl(syntax: inout VariableDeclSyntax) async throws {
		//print("handleVariableDecl(syntax: VariableDecl):")
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
}


public class GeneratePackage {
	
	public var spec: PackageSpec
	public var swiftFile: ReadSwiftFile
	var version: String
	
	public init(fromSwiftFile file: Path?, spec: Path, version: String) async throws {
		self.spec = try YAMLDecoder().decode( PackageSpec.self, from: spec.read() )
		self.version = version
		swiftFile = try .init(file: file, spec: self.spec)
		swiftFile.output = try await swiftFile.output.asyncMap { stmt in
			let item = stmt.item
			switch item.kind {
			case .variableDecl:
				if var variDecl = item.as(VariableDeclSyntax.self) {
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

extension ReadSwiftFile {
	
}


public class UpdateBinaryTargets {
	public var swiftFile: SourceFileSyntax
	public var xcframeworks: Path
	public var version: String
	public var owner: String
	public var repo: String
	var modifiedFile: SourceFileSyntax
	
	public init(file: Path, xcframeworks: Path, version: String, owmer: String, repo: String) async throws {
		let _file = Parser.parse(source: try file.read())
		swiftFile = _file
		modifiedFile = _file
		self.version = version
		self.xcframeworks = xcframeworks
		self.owner = owmer
		self.repo = repo
		let _new: [CodeBlockItemSyntax] = try await swiftFile.statements.asyncMap { stmt in
			let item = stmt.item
			switch item.kind {
			case .variableDecl:
				guard var variDecl = item.as(VariableDeclSyntax.self) else { fatalError() }
				try await modifyPackage(&variDecl)
				return .init(item: .decl(.init(variDecl)))
			default:
				return stmt
			}
		}
		modifiedFile = SourceFileSyntax(statements: .init(_new), endOfFileToken: .endOfFileToken() )
	}
	
	func modifyPackage(_ syntax: inout VariableDeclSyntax)async throws {
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
						//try await handlePackageTargets(&targets)
						try await targets.updateTargets(
							binaries: xcframeworks,
							version: version,
							owner: owner,
							repo: repo
						)
						//return .init(label: arg_name, expression: .init(targets)).withLeadingTrivia(.newline )
						return .init(
							label: arg_name,
							expression: targets
						).with(\.leadingTrivia, .newline)
					}
				default: return arg
				}
			
			}
			return arg
		}
		syntax.arguments = .init(args)
	}
	
	public var description: String {
		var code = ""
		modifiedFile.formatted().write(to: &code)
		return code
	}
}

extension ArrayExprSyntax {
	mutating func updateTargets(binaries: Path, version: String, owner: String, repo: String) async throws {
		let updated_elements = try await elements.asyncMap { element in
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
			
		}
		elements = .init(updated_elements)
//		elements = .init(expressions: try await elements.asyncMap {
//			element in
//			guard
//				var target = element.expression.as(FunctionCallExprSyntax.self),
//				TargetType(target: target) == .binaryTarget
//			else { return element.expression }
//			try await target.updateBinaryTarget(
//				binaries: binaries,
//				version: version,
//				owner: owner,
//				repo: repo
//			)
//			return .init(target)
//			//return element.withExpression(.init(target))
//			//element.with(\.expression, target)
//		})
	}
}

extension FunctionCallExprSyntax {
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
					return arg.with(\.expression,
						.init(StringLiteralExprSyntax(content:  "https://github.com/\(owner)/\(repo)/releases/download/\(version)/\(binary.lastComponent)"))
					)
				case "checksum":
					return arg.with(\.expression,
						"\(literal: try binary.sha256())"
					)
				default: return arg
				}
				
			})
		)
	}
}

extension UpdateBinaryTargets {
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
}




