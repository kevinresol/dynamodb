package dynamodb;

@:genericBuild(dynamodb.macros.Builder.buildTable())
class Table<T> {}

class TableBase<Model, Fields> {
	public var name(default, null):String;
	public var fields(default, null):Fields;
	public var runfimeFields(default, null):Iterable<TableField>;
	
	public function new(name)
		this.name = name;
		
	public function put(data:Model) {
		throw 'abstract';
	}
	
	public function query(expr:Fields->Expr<Bool>) {
		var params = ParamBuilder.buildQuery(name, expr(fields));
		trace(params);
	}
}

typedef TableField = {
	name:String,
	index:IndexType,
	type:ValueType,
}