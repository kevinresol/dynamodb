package dynamodb;

@:genericBuild(dynamodb.macros.Builder.buildTable())
class Table<T> {}

class TableBase<T> {
	public var name(default, null):String;
	public var fields(default, null):T;
	public var runfimeFields(default, null):Iterable<TableField>;
	
	public function query(expr:T->Expr<Bool>) {
		var params = ParamBuilder.buildQuery(name, expr(fields));
		trace(params);
	}
}

typedef TableField = {
	name:String,
	type:ValueType,
}