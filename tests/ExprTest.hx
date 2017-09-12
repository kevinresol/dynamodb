package;

import dynamodb.Expr;

@:asserts
class ExprTest {
	public function new() {}
	
	public function conversion() {
		var expr:Expr<String> = 'mystr';
		asserts.assert(expr.expr.match(EConst('mystr', TString)));
		return asserts.done();
	}
	
	public function eq() {
		var str:Expr<String> = EField('str');
		var expr:ExprData<Bool> = str == 'mystr';
		asserts.assert(expr.match(EBinop(Eq, EField('str'), EConst('mystr', TString))));
		var expr:ExprData<Bool> = str == EConst('mystr', TString);
		asserts.assert(expr.match(EBinop(Eq, EField('str'), EConst('mystr', TString))));
		var expr:ExprData<Bool> = str == (EConst('mystr', TString):Expr<String>);
		asserts.assert(expr.match(EBinop(Eq, EField('str'), EConst('mystr', TString))));
		return asserts.done();
	}
}