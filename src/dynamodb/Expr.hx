package dynamodb;

enum ExprData<T> {
	EConst(v:T, type:ValueType);
	EField(name:String);
	EBinop<L, R>(op:Binop<L, R, T>, e1:ExprData<L>, e2:ExprData<R>);
}

typedef Update<T> = {field:ExprData<T>, value:T}

abstract Expr<T>(ExprData<T>) from ExprData<T> {
	public var expr(get, never):ExprData<T>;
	inline function get_expr() return this;
	
	@:op(A==B)
	public static function eq<T>(a:Expr<T>, b:Expr<T>):Expr<Bool>
		return EBinop(Eq, a, b);
		
	@:to
	public inline function asData():ExprData<T> 
		return this;
		
	@:from
	public static macro function from(e) {
		var t = haxe.macro.Context.typeof(e);
		return switch tink.macro.Types.getID(t) {
			case 'String': macro dynamodb.Expr.ExprData.EConst($e, TString);
			case 'dynamodb.ExprData': e;
			case v: throw 'Unsupported type: $v';
		}
	}
}

enum Binop<L, R, T> {
  Eq<T>:Binop<T, T, Bool>;
}