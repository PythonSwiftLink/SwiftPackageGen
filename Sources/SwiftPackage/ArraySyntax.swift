//
//  File.swift
//  
//
//  Created by CodeBuilder on 09/10/2024.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder



extension  LabeledExprListSyntax.Element {
	func withExpr<E: ExprSyntaxProtocol>(_ expr: E) -> Self {
		with(\.expression, .init(expr))
	}
}
