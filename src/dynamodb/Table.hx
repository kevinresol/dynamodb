package dynamodb;

import dynamodb.driver.*;

using tink.CoreApi;

@:genericBuild(dynamodb.macros.Builder.buildTable())
class Table<T> {}

class TableBase<Model, Fields, IndexFields> {
	public var name(default, null):String;
	public var fields(default, null):Fields;
	public var info(default, null):{fields:Iterable<TableField>};
	var driver:Driver;
	
	public function new(name, driver) {
		this.name = name;
		this.driver = driver;
	}
	
	public function create() {
		var param = ParamBuilder.createTable(name, [for(field in info.fields) if(field.indexType != null) field]);
		return driver.createTable(param);
	}
	
	public function delete() {
		return driver.deleteTable({TableName: name});
	}
		
	public function get(indices:IndexFields):Promise<Model> {
		throw 'abstract';
	}
		
	public function put(data:Model):Promise<Noise> {
		throw 'abstract';
	}
	
	public function scan(expr:Fields->Expr<Bool>) {
		var params = ParamBuilder.scan(name, expr(fields));
		return driver.scan(params);
	}
}

typedef TableField = {
	name:String,
	indexType:IndexType,
	valueType:ValueType,
}