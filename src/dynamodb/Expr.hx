package dynamodb;

enum ExprData<T> {
	EConst(v:T, type:ValueType);
	EField(name:String);
	EBinop<L, R>(op:Binop<L, R, T>, e1:ExprData<L>, e2:ExprData<R>);
}

typedef Update<T> = {field:ExprData<T>, value:T}

@:coreType
abstract Comparable from Int from Float from String {}

abstract Expr<T>(ExprData<T>) from ExprData<T> {
	public var expr(get, never):ExprData<T>;
	inline function get_expr() return this;
	
	// @:op(A==B)
	// public static function eqConst<T>(a:Expr<T>, b:T):Expr<Bool>
	// 	return EBinop(Eq, a, b);
		
	// @:op(A>B)
	// public static function gtConst<T>(a:Expr<T>, b:T):Expr<Bool>
	// 	return EBinop(Gt, a, b);
	
	// @:op(A<B)
	// public static function ltConst<T>(a:Expr<T>, b:T):Expr<Bool>
	// 	return EBinop(Lt, a, b);
	
	@:op(A==B)
	public static function eq<T>(a:Expr<T>, b:Expr<T>):Expr<Bool>
		return EBinop(Eq, a.asData(), b.asData());
		
	@:op(A>B)
	public static function gt<T>(a:Expr<T>, b:Expr<T>):Expr<Bool>
		return EBinop(Gt, a.asData(), b.asData());
	
	@:op(A<B)
	public static function lt<T>(a:Expr<T>, b:Expr<T>):Expr<Bool>
		return EBinop(Lt, a.asData(), b.asData());
		
	@:to
	public inline function asData():ExprData<T>
		return this;
		
	@:from
	public static function fromString(v:String):Expr<String>
		return EConst(v, TString);
	
	@:from
	public static function fromFloat(v:Float):Expr<Float>
		return EConst(v, TNumber);
	
	@:from
	public static function fromBool(v:Bool):Expr<Bool>
		return EConst(v, TBoolean);
}

enum Binop<L, R, T> {
  Eq<T>:Binop<T, T, Bool>;
  Gt<T>:Binop<T, T, Bool>;
  Lt<T>:Binop<T, T, Bool>;
}