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


fileprivate func handlePackageTargets(_ targets: inout ArrayExprSyntax) async throws {
	infoPrint("handlePackageTargets(_ targets: inout ArrayExprSyntax)", indent: 2)
	var output_targets: [ArrayElementSyntax] = []
	var output_binaryTargets: [ArrayElementSyntax] = []
	
	for _target in targets.elements {
		infoPrint("_target", _target.expression.kind, indent: 3)
		infoPrint("_target.expression", _target.expression.kind, indent: 4)
		if var target = _target.expression.as(FunctionCallExprSyntax.self) {
			infoPrint("target.calledExpression.kind", target.calledExpression.kind, indent: 4)
			if var memberAccessExpr = target.calledExpression.as(MemberAccessExprSyntax.self) {
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
	//targets = .init(elements: .init(output_targets + output_binaryTargets)).withRightSquare(.rightSquareBracket.withLeadingTrivia(.newline))
	targets = .init(
		leadingTrivia: .newline,
		elements: .init((output_targets + output_binaryTargets))
	)
}

fileprivate func handlePackageDependencies(_ dependencies: inout ArrayExprSyntax) async throws {
	print("\t\thandlePackageDependencies(_ dependencies: inout ArrayExprSyntax):")
	infoPrint("elements", dependencies.elements.map(\.expression.kind), indent: 3)
	//dependencies.rightSquare = .rightSquareBracket.withLeadingTrivia(.newline)
	dependencies.rightSquare = .rightSquareToken(leadingTrivia: .newline)
}

fileprivate func readPackageFunctionCall(syntax: inout FunctionCallExprSyntax) async throws {
	var args: [LabeledExprSyntax] = try await syntax.arguments.asyncMap { arg in
		if let arg_name = arg.label?.text, let arg_case = PackageArgs(rawValue: arg_name) {
			switch arg_case {
			case .name:
				return arg
			case .products:
				return arg
			case .dependencies:
				if var dependencies = arg.expression.as(ArrayExprSyntax.self) {
					try await handlePackageDependencies(&dependencies)
					//return .init(label: arg_name, expression: .init(dependencies)).withTrailingComma(.comma).withLeadingTrivia(.newline)
					return .init(
						label: arg_name,
						expression: dependencies
					).with(\.trailingComma, .commaToken()).with(\.leadingTrivia, .newline)
				}
			case .targets:
				if var targets = arg.expression.as(ArrayExprSyntax.self) {
					//try await handlePackageTargets(&targets)
					//return .init(label: arg_name, expression: .init(targets)).withLeadingTrivia(.newline )
					return .init(
						label: arg_name,
						expression: targets
					).with(\.trailingComma, .commaToken()).with(\.leadingTrivia, .newline)
				}
			}
		}
		return arg
	}
	syntax.argumentList = .init(args)
}

fileprivate func readVariableDeclSyntax(syntax: inout VariableDeclSyntax) async throws {
	print("handleVariableDeclSyntax(syntax: VariableDeclSyntax):")
	if var binding = syntax.bindings.first {
		let pattern = binding.pattern
		print("\t\(pattern.kind) - \(pattern)")
		if let IdentifierPatternSyntax = pattern.as(IdentifierPatternSyntax.self) {
			let identifier = IdentifierPatternSyntax.identifier.text
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


public class ReadSwiftFile: CustomStringConvertible {
	
	let file: Path?
	var output: [CodeBlockItemSyntax] = []
	
	public init(file: Path?, spec: PackageSpec) throws {
		self.file = file
		func code() throws -> String {
			if let file = file {
				return try file.read()
			}
			
			return packageSample(repo: spec.repository, macOS: spec.macOS)
		}
		let parse = Parser.parse(source: try code() )
		output = parse.statements.map({$0})
	}
	
	func modified() async throws {
//		let parse = Parser.parse(source: try file.read() )
//		output = try await parse.statements.asyncMap { stmt in
//			let item = stmt.item
//			switch item.kind {
//			case .VariableDeclSyntax:
//				if var variDecl = item.as(VariableDeclSyntax.self) {
//					try await readVariableDeclSyntax(syntax: &variDecl)
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
		SourceFileSyntax(statements: .init(output), endOfFileToken: .endOfFileToken()).formatted().write(to: &code)
		return code
	}
}

