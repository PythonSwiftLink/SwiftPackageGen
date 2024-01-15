//
//  File 2.swift
//  
//
//  Created by CodeBuilder on 14/10/2023.
//

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder
import PathKit


extension ArrayElementSyntax {
	static func binaryTarget(owner: String, repo: String, version: String, file_name: String, sha: String) -> Self {
		let call = FunctionCallExprSyntax(stringLiteral: """
		.binaryTarget(name: "\(file_name)", url: "https://github.com/\(owner)/\(repo)/releases/download/\(version)/\(file_name).zip", checksum: "\(sha)")
		""")
		
		return .init(expression: call).withLeadingTrivia(.newline + .tab)
	}
	static func copyResource(_ src: String) -> Self {
		let call = FunctionCallExprSyntax(stringLiteral: """
			.copy("\(src)")
			""")
		
		return .init(expression: call).withLeadingTrivia(.newline + .tab)
	}
}

func infoPrint(_ label: String, indent: Int) {
	let tabs = String.init(repeating: "\t", count: indent)
	print("\(tabs)\(label):")
}
func infoPrint(_ label: String, _ value: Any, indent: Int) {
	let tabs = String.init(repeating: "\t", count: indent)
	print("\(tabs)\(label): \(value)")
}

enum PackageArgs: String {
	case name
	case products
	case dependencies
	case targets
}

enum TargetType: String {
	case target
	case binaryTarget
	
	init?(target: FunctionCallExpr) {
		guard let memberAccessExpr = target.calledExpression.as(MemberAccessExpr.self) else { return nil }
		self.init(rawValue: memberAccessExpr.name.text)
	}
}


public class PackageGenerator: CustomStringConvertible {

	
	
	
	private var output: [CodeBlockItemSyntax] = []
	
	//var file: Path
	var owner: String
	var repo: String
	var version: String
	
	var binaryTargets: [String: String]
	
	
	public init(file: Path, owner: String, repo: String, version: String, binaryTargets: [String : String]) async throws {
		self.owner = owner
		self.repo = repo
		self.version = version
		self.binaryTargets = binaryTargets
		let parse = Parser.parse(source: try file.read() )
		
		for stmt in parse.statements {
			let item = stmt.item
			switch item.kind {
			case .variableDecl:
				if var variDecl = item.as(VariableDecl.self) {
					try await handleVariableDecl(syntax: &variDecl)
					output.append(.init(item: .decl(.init(variDecl))))
				}
			default:
				output.append(stmt)
				//print(item.kind)
				//print()
				//print(item)
				//print()
				//output.append(stmt)
			}
			
		}
	}
	
	public var description: String {
		SourceFile(statements: .init(output), eofToken: .eof).formatted().description
	}
	
	func handleVariableDecl(syntax: inout VariableDecl) async throws {
		print("handleVariableDecl(syntax: VariableDecl):")
		if var binding = syntax.bindings.first {
			let pattern = binding.pattern
			print("\t\(pattern.kind) - \(pattern)")
			if let identifierPattern = pattern.as(IdentifierPattern.self) {
				let identifier = identifierPattern.identifier.text
				switch identifier {
				case "package":
					if var packageValue = binding.initializer?.value.as(FunctionCallExpr.self) {
						try await handlePackageFunctionCall(syntax: &packageValue)
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
	
	
	func handlePackageFunctionCall(syntax: inout FunctionCallExpr) async throws {
		print("\t\(syntax.calledExpression.kind)")
		var args = [TupleExprElement]()
		for (i,arg) in syntax.argumentList.enumerated() {
			if let arg_name = arg.label?.text, let arg_case = PackageArgs(rawValue: arg_name) {
				print("\t\t\(arg_name) - \(arg.expression.kind)")
				switch arg_case {
				case .name:
					args.append(arg)
				case .products:
					args.append(arg)
				case .dependencies:
					if var dependencies = arg.expression.as(ArrayExpr.self) {
						try await handlePackageDependencies(&dependencies)
						args.append(.init(label: arg_name, expression: .init(dependencies)).withTrailingComma(.comma).withLeadingTrivia(.newline))
					}
					
					
				case .targets:
					if var targets = arg.expression.as(ArrayExpr.self) {
						try await handlePackageTargets(&targets)
						args.append( .init(label: arg_name, expression: .init(targets)).withLeadingTrivia(.newline ) )
					}
				}
			}
		}
		syntax.argumentList = .init(args)
	}
	func handlePackageDependencies(_ dependencies: inout ArrayExpr) async throws {
		print("\t\thandlePackageDependencies(_ dependencies: inout ArrayExpr):")
		infoPrint("elements", dependencies.elements.map(\.expression.kind), indent: 3)
		
		
		dependencies.rightSquare = .rightSquareBracket.withLeadingTrivia(.newline)
	}
	func handlePackageTargets(_ targets: inout ArrayExpr) async throws {
		infoPrint("handlePackageTargets(_ targets: inout ArrayExpr)", indent: 2)
		var output_targets: [ArrayElementSyntax] = []
		var output_binaryTargets: [ArrayElementSyntax] = []
		
		for _target in targets.elements {
			infoPrint("_target", _target.expression.kind, indent: 3)
			infoPrint("_target.expression", _target.expression.kind, indent: 4)
			if var target = _target.expression.as(FunctionCallExpr.self) {
				infoPrint("target.calledExpression.kind", target.calledExpression.kind, indent: 4)
				if var memberAccessExpr = target.calledExpression.as(MemberAccessExpr.self) {
					if let target_type = TargetType(rawValue: memberAccessExpr.name.text) {
						infoPrint("target type", target_type, indent: 4)
						switch target_type {
						case .target:
							output_targets.append(_target)
						case .binaryTarget:
							infoPrint("target.argumentList", target.argumentList.map(\.description), indent: 5)
							for _target_arg in target.argumentList {
								let arg_exp = _target_arg.expression
								infoPrint(_target_arg.label?.text ?? "_", arg_exp, indent: 6)
							}
						}
					}
				}
				
				//infoPrint("target.calledExpression", target.calledExpression.kind, indent: 4)
			}
		}
		for (k,v) in binaryTargets {
			output_binaryTargets.append(
				.binaryTarget(owner: owner, repo: repo, version: version, file_name: k, sha: v).withTrailingComma(.comma)
			)
		}
		targets = .init(elements: .init(output_targets + output_binaryTargets)).withRightSquare(.rightSquareBracket.withLeadingTrivia(.newline))
	}
	
}
