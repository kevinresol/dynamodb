package dynamodb;

import dynamodb.driver.*;

using tink.CoreApi;

#if !macro @:genericBuild(dynamodb.macros.Builder.buildTable()) #end
class Table<T> {}

class TableBase<Model, Fields, IndexFields> {
	public var name(default, null):String;
	public var fields(default, null):Fields;
	public var info(default, null):{
		fields:Iterable<TableField>,
	};
	var driver:Driver;
	
	public function new(name, driver) {
		this.name = name;
		this.driver = driver;
	}
	
	public function create() {
		var indices = new Map();
		for(field in info.fields) for(index in field.indices) {
			if(!indices.exists(index.kind)) indices.set(index.kind, []);
			indices.get(index.kind).push({
				name: field.name,
				valueType: field.type,
				indexType: index.type,
			});
		}
		var param = ParamBuilder.createTable(name, [for(kind in indices.keys()) {kind: kind, fields: indices.get(kind)}]);
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
	type:ValueType,
	indices:Array<{kind:IndexKind, type:IndexType}>,
}

typedef TableIndex = {
	kind:IndexKind,
	keys:Iterable<{name:String, type:IndexType}>,
}