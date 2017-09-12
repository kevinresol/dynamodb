package dynamodb;

class Table {
	public var fields(default, null):Iterable<TableField>;
}

typedef TableField = {
	name:String,
	type:FieldType,
}