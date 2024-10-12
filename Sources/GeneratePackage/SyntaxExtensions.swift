
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder




extension FunctionCallExprSyntax {
	
	enum TargetMember: String {
		case name
		case dependencies
		case resources
		case linkerSettings
	}
	func getMemberIndex(key: TargetMember) -> SyntaxChildrenIndex? {
		//getMember(key: key)?.indexInParent
		guard let item = getMember(key: key) else { return nil }
		return arguments.firstIndex(of: item)
	}
	
	func getMember(key: TargetMember) -> LabeledExprSyntax? {
		
		return arguments.first { element in
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
		getMember(key: .name)?.expression.as(StringLiteralExprSyntax.self)?.segments.first?.description
	}
	
	mutating func updateMember(key: TargetMember, with: LabeledExprSyntax) {
		if let _index = getMemberIndex(key: key) {
			arguments = arguments.with(\.[_index], with)
		}
	}
}

extension PackageSpecDependency {
	func expr() -> ExprSyntaxProtocol {
		fatalError()
	}
	
	func arrayElement() -> [ArrayElementSyntax] {
		switch self {
		case let target as PackageSpec.Target:
			return [
				.init(
					expression: ExprSyntax(
						stringLiteral: "\"\(target.target)\""
					)
				).with(\.trailingComma ,.commaToken()).with(\.leadingTrivia, .newline + .tabs(2))
			]
		case let bin as PackageSpec.BinaryTarget:
			return .init(bin.binaryTargets.map {
				.init(
					expression: StringLiteralExprSyntax(
						 "\"\($0.filename)\""
					)!//.withLeadingTrivia(.newline + .tabs(2))
				)
			} )
		case let product as PackageSpec.PackageProduct:
			
			let call: ExprSyntax
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
			return [
				.init(
					leadingTrivia: .newline + .tabs(2),
					expression: call
				)
			]
			//return [.init(expression: call).withLeadingTrivia(.newline + .tabs(2)).withTrailingComma(.comma)]
		default: fatalError()
			//		case .framework(let value):
			//			return ".linkedFramework(\"\(value)\")"
			//		case .library(let value):
			//			return ".linkedLibrary(\"\(value)\")"
		}
		
		
	}
}

extension PackageSpec.PackageTarget {
	func modifyLinkerSettings(_ input: inout FunctionCallExprSyntax) {
		if var (label,member) = input.getMember(as: ArrayExprSyntax.self, key: .linkerSettings) {
			if let linkerSettings = linkerSettings {
				//member.elements = .init( linkerSettings.map{$0.setting().withTrailingComma(.comma)} )
				member.elements = .init(linkerSettings.map{$0.setting().with(\.trailingComma, .commaToken())})
			}
			
			input.updateMember(
				key: .linkerSettings,
				with: .init(
					label: label,
					expression: member
				).with(\.leadingTrivia, .newline + .tab)
				//.withLeadingTrivia(.newline + .tab)//.withTrailingComma(.comma)
			)
		}
	}
	func modifyDependencies(_ input: inout FunctionCallExprSyntax) {
		if var (label,member) = input.getMember(as: ArrayExprSyntax.self, key: .dependencies) {
			var elements = [ArrayElementSyntax]()
			for dep in dependencies {
				elements.append(contentsOf: dep.arrayElement())
			}
			member.elements = .init(elements)
			input.updateMember(
				key: .dependencies,
				with: .init(
					label: label,
					expression: member
				).with(\.trailingComma, .commaToken()).with(\.leadingTrivia, .newline + .tab)
			)
//			input.updateMember(key: .dependencies, with: .init(
//				label: label, expression: .init(member) ).withLeadingTrivia(.newline + .tab).withTrailingComma(.comma)
//			)
			
			
		}
	}
	func modifyResources(_ input: inout FunctionCallExprSyntax) {
		if var (label,member) = input.getMember(as: ArrayExprSyntax.self, key: .resources) {
			var elements = [ArrayElementSyntax]()
			for res in resources ?? [] {
				elements.append(.copyResource(res))
			}
			member.elements = .init(elements)
//			input.updateMember(key: .resources, with: .init(
//				label: label, expression: .init(member) ).withLeadingTrivia(.newline + .tab).withTrailingComma(.comma)
//			)
			input.updateMember(
				key: .dependencies,
				with: .init(
					label: label,
					expression: member
				).with(\.trailingComma, .commaToken()).with(\.leadingTrivia, .newline + .tab)
			)
			
			
		}
	}
}
