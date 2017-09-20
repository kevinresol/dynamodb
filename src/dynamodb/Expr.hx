package dynamodb;

enum ExprData<T> {
	EConst(v:T, type:ValueType);
	EField(name:String);
	EBinop<L, R>(op:Binop<L, R, T>, e1:ExprData<L>, e2:ExprData<R>);
	ECall(f:Func);
}

typedef Update<T> = {field:ExprData<T>, value:T}

@:coreType
abstract Comparable from Int from Float from String {}

abstract Expr<T>(ExprData<T>) from ExprData<T> {
	public var expr(get, never):ExprData<T>;
	inline function get_expr() return this;
	
	@:op(A==B) public static inline function eqString<T:String>(a:Expr<T>, b:T):Expr<Bool> return EBinop(Eq, a.asData(), fromString(b).asData());
	@:op(A==B) public static inline function eqFloat<T:Float>(a:Expr<T>, b:T):Expr<Bool> return EBinop(Eq, a.asData(), fromFloat(b).asData());
	@:op(A>B) public static inline function gtFloat<T:Float>(a:Expr<T>, b:T):Expr<Bool> return EBinop(Gt, a.asData(), fromFloat(b).asData());
	@:op(A<B) public static inline function ltFloat<T:Float>(a:Expr<T>, b:T):Expr<Bool> return EBinop(Lt, a.asData(), fromFloat(b).asData());
	@:op(A==B) public static inline function eq<T>(a:Expr<T>, b:Expr<T>):Expr<Bool> return EBinop(Eq, a.asData(), b.asData());
	@:op(A>B) public static inline function gt<T>(a:Expr<T>, b:Expr<T>):Expr<Bool> return EBinop(Gt, a.asData(), b.asData());
	@:op(A<B) public static inline function lt<T>(a:Expr<T>, b:Expr<T>):Expr<Bool> return EBinop(Lt, a.asData(), b.asData());
	
	@:impl public static inline function contains<T>(a:ExprData<Array<T>>, v:Expr<T>):Expr<Bool> return ECall(Contains(a, v.asData()));
		
	@:to
	public inline function asData():ExprData<T>
		return this;
		
	@:from
	public static function fromString<T:String>(v:T):Expr<T>
		return EConst(v, TString);
	
	@:from
	public static function fromFloat<T:Float>(v:T):Expr<T>
		return EConst(v, TNumber);
	
	@:from
	public static function fromBool(v:Bool):Expr<Bool>
		return EConst(v, TBoolean);
}

enum Binop<L, R, T> {
  Eq<T>:Binop<T, T, Bool>;
  Gt<T>:Binop<T, T, Bool>;
  Lt<T>:Binop<T, T, Bool>;
  
  And:Binop<Bool, Bool, Bool>;
  Or:Binop<Bool, Bool, Bool>;
}

enum Func {
	Contains<T>(arr:ExprData<Array<T>>, val:ExprData<T>);
}