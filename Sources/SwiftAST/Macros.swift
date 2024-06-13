/// Expands an input Swift expression as an equivalent SwiftAST `Expression`
/// hierarchy.
///
/// Errors during macro expansion will result in an `UnknownExpression` being
/// returned, and an error being raised in the editor.
@freestanding(expression)
macro ast_expandExpression<T>(_: T) -> Expression =
    #externalMacro(module: "SwiftASTMacros", type: "SwiftASTExpressionMacro")

/// Expands an input Swift type as an equivalent SwiftAST `SwiftAST`
/// hierarchy.
///
/// Errors during macro expansion will result in an `SwiftAST.errorType` being
/// returned, and an error being raised in the editor.
@freestanding(expression)
macro ast_expandType<T>() -> SwiftType =
    #externalMacro(module: "SwiftASTMacros", type: "SwiftASTTypeMacro")

func test() {
    //#ast_expandType<[Int: String]>()

}
