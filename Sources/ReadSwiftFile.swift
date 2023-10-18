//
//  File.swift
//  
//
//  Created by CodeBuilder on 15/10/2023.
//

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder
import PathKit


fileprivate func handlePackageTargets(_ targets: inout ArrayExpr) async throws {
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
//	for (k,v) in binaryTargets {
//		output_binaryTargets.append(
//			.binaryTarget(owner: owner, repo: repo, version: version, file_name: k, sha: v).withTrailingComma(.comma)
//		)
//	}
	targets = .init(elements: .init(output_targets + output_binaryTargets)).withRightSquare(.rightSquareBracket.withLeadingTrivia(.newline))
}

fileprivate func handlePackageDependencies(_ dependencies: inout ArrayExpr) async throws {
	print("\t\thandlePackageDependencies(_ dependencies: inout ArrayExpr):")
	infoPrint("elements", dependencies.elements.map(\.expression.kind), indent: 3)
	dependencies.rightSquare = .rightSquareBracket.withLeadingTrivia(.newline)
}

fileprivate func readPackageFunctionCall(syntax: inout FunctionCallExpr) async throws {
	var args: [TupleExprElement] = try await syntax.argumentList.asyncMap { arg in
		if let arg_name = arg.label?.text, let arg_case = PackageArgs(rawValue: arg_name) {
			switch arg_case {
			case .name:
				return arg
			case .products:
				return arg
			case .dependencies:
				if var dependencies = arg.expression.as(ArrayExpr.self) {
					try await handlePackageDependencies(&dependencies)
					return .init(label: arg_name, expression: .init(dependencies)).withTrailingComma(.comma).withLeadingTrivia(.newline)
				}
			case .targets:
				if var targets = arg.expression.as(ArrayExpr.self) {
					//try await handlePackageTargets(&targets)
					return .init(label: arg_name, expression: .init(targets)).withLeadingTrivia(.newline )
				}
			}
		}
		return arg
	}
	syntax.argumentList = .init(args)
}

fileprivate func readVariableDecl(syntax: inout VariableDecl) async throws {
	print("handleVariableDecl(syntax: VariableDecl):")
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


class ReadSwiftFile: CustomStringConvertible {
	
	let file: Path?
	var output: [CodeBlockItemSyntax] = []
	
	init(file: Path?, spec: PackageSpec) throws {
		self.file = file
		func code() throws -> String {
			if let file = file {
				return try file.read()
			}
			return packageSample(repo: spec.repository)
		}
		let parse = Parser.parse(source: try code() )
		output = parse.statements.map({$0})
	}
	
	func modified() async throws {
//		let parse = Parser.parse(source: try file.read() )
//		output = try await parse.statements.asyncMap { stmt in
//			let item = stmt.item
//			switch item.kind {
//			case .variableDecl:
//				if var variDecl = item.as(VariableDecl.self) {
//					try await readVariableDecl(syntax: &variDecl)
//					return .init(item: .decl(.init(variDecl)))
//					
//				}
//			default:
//				return stmt
//			}
//			return stmt
//		}

		fatalError()
	}
	
	
	public var description: String {
		var code = ""
		SourceFile(statements: .init(output), eofToken: .eof).formatted().write(to: &code)
		return code
	}
}

