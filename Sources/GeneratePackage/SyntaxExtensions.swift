
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder


extension FunctionCallExpr {
	
	enum TargetMember: String {
		case name
		case dependencies
		case resources
		case linkerSettings
	}
	func getMemberIndex(key: TargetMember) -> Int? {
		getMember(key: key)?.indexInParent
	}
	func getMember(key: TargetMember) -> TupleExprElement? {
		
		return argumentList.first { element in
			if let argName = element.label?.text {
				if argName == key.rawValue {
					return true
				}
			}
			
			return false
		}

	}
	
	func getMember<T: ExprSyntaxProtocol>(as: T.Type, key: TargetMember) ->(label: String?,expresion: T)? {
		if let member = getMember(key: key), let expression = member.expression.as(T.self) {
			return (member.label?.text, expression)
		}
		return nil
	}
	
	func getTargetName() -> String? {
		getMember(key: .name)?.expression.as(StringLiteralExpr.self)?.segments.first?.description
	}
	
	mutating func updateMember(key: TargetMember, with: TupleExprElement) {
		if let index = getMemberIndex(key: key) {
			argumentList = argumentList.replacing(childAt: index, with: with)
		}
	}
}

extension PackageSpecDependency {
	func expr() -> ExprSyntaxProtocol {
		fatalError()
	}
	
	func arrayElement() -> [ArrayElement] {
		switch self {
		case let target as PackageSpec.Target:
			return [
				.init(expression: Expr(stringLiteral: "\"\(target.target)\"").withLeadingTrivia(.newline + .tabs(2))).withTrailingComma(.comma)
			]
		case let bin as PackageSpec.BinaryTarget:
			return .init(bin.binaryTargets.map { .init(
				expression: StringLiteralExpr(stringLiteral: "\"\($0.filename)\"").withLeadingTrivia(.newline + .tabs(2))
			).withTrailingComma(.comma)
			} )
		case let product as PackageSpec.PackageProduct:
			
			let call: FunctionCallExpr
			if let package = product.package {
				call = ".product(name: \"\(raw: product.product)\", package: \"\(raw: package)\")"
			} else {
				call = ".product(name: \"\(raw: product.product)\")"
			}
//			if let _product = product.product {
//				call = ".product(name: \"\(raw: _product)\", package: \"\(raw: product.package)\")"
//			} else {
//				call = ".product(name: \"\(raw: product.package)\")"
//			}
			return [.init(expression: call).withLeadingTrivia(.newline + .tabs(2)).withTrailingComma(.comma)]
		default: fatalError()
			//		case .framework(let value):
			//			return ".linkedFramework(\"\(value)\")"
			//		case .library(let value):
			//			return ".linkedLibrary(\"\(value)\")"
		}
		
		
	}
}

extension PackageSpec.PackageTarget {
	func modifyLinkerSettings(_ input: inout FunctionCallExpr) {
		if var (label,member) = input.getMember(as: ArrayExpr.self, key: .linkerSettings) {
			if let linkerSettings = linkerSettings {
				member.elements = .init( linkerSettings.map{$0.setting().withTrailingComma(.comma)} )
			}
			
			input.updateMember(key: .linkerSettings, with: .init(
				label: label, expression: .init(member) ).withLeadingTrivia(.newline + .tab)//.withTrailingComma(.comma)
			)
		}
	}
	func modifyDependencies(_ input: inout FunctionCallExpr) {
		if var (label,member) = input.getMember(as: ArrayExpr.self, key: .dependencies) {
			var elements = [ArrayElement]()
			for dep in dependencies {
				elements.append(contentsOf: dep.arrayElement())
			}
			member.elements = .init(elements)
			input.updateMember(key: .dependencies, with: .init(
				label: label, expression: .init(member) ).withLeadingTrivia(.newline + .tab).withTrailingComma(.comma)
			)
			
			
		}
	}
	func modifyResources(_ input: inout FunctionCallExpr) {
		if var (label,member) = input.getMember(as: ArrayExpr.self, key: .resources) {
			var elements = [ArrayElement]()
			for res in resources ?? [] {
				elements.append(.copyResource(res))
			}
			member.elements = .init(elements)
			input.updateMember(key: .resources, with: .init(
				label: label, expression: .init(member) ).withLeadingTrivia(.newline + .tab).withTrailingComma(.comma)
			)
			
			
		}
	}
}
