/// Expands an input Swift expression as an equivalent SwiftAST `Expression`
/// hierarchy.
///
/// Errors during macro expansion will result in an `UnknownExpression` being
/// returned, and an error being raised in the editor.
@freestanding(expression)
macro ast_expandExpression<T>(_: T) -> Expression =
    #externalMacro(module: "SwiftASTMacros", type: "SwiftASTExpressionMacro")

/// Expands an input Swift expression within an input closure's first statement
/// as an equivalent SwiftAST `Expression` hierarchy.
///
/// The macro implementation expects `T` to resolve to a closure type, with its
/// first statement the expression to synthesize.
///
/// Errors during macro expansion will result in an `UnknownExpression` being
/// returned, and an error being raised in the editor.
@freestanding(expression)
macro ast_expandExpression<T>(firstExpressionIn: T) -> Expression =
    #externalMacro(module: "SwiftASTMacros", type: "SwiftASTExpressionMacro")

/// Expands an input Swift type as an equivalent SwiftAST `SwiftAST`
/// hierarchy.
///
/// Errors during macro expansion will result in an `SwiftAST.errorType` being
/// returned, and an error being raised in the editor.
@freestanding(expression)
macro ast_expandType<T>() -> SwiftType =
    #externalMacro(module: "SwiftASTMacros", type: "SwiftASTTypeMacro")

/// Expands an input Swift closure expression as an equivalent SwiftAST
/// `CompoundStatement` hierarchy.
///
/// If `singleStatement` is `true` in the call site, the macro expands only
/// the first statement within the closure.
///
/// The macro implementation expects `T` to resolve to a closure type.
///
/// Errors during macro expansion will result in an `UnknownStatement` being
/// returned, and an error being raised in the editor.
@freestanding(expression)
macro ast_expandStatements<T>(singleStatement: Bool = false, _: T) -> CompoundStatement =
    #externalMacro(module: "SwiftASTMacros", type: "SwiftASTStatementsMacro")

/// Expands an input Swift closure expression as an equivalent SwiftAST
/// `CompoundStatement` hierarchy.
///
/// If `singleStatement` is `true` in the call site, the macro expands only
/// the first statement within the closure.
///
/// The macro implementation expects `T` to resolve to a closure type.
///
/// Errors during macro expansion will result in an `UnknownStatement` being
/// returned, and an error being raised in the editor.
@freestanding(expression)
macro ast_expandStatements<T>(singleStatement: Bool, _: T) -> Statement =
    #externalMacro(module: "SwiftASTMacros", type: "SwiftASTStatementsMacro")
