package;

import dynamodb.*;
import dynamodb.Expr;
import dynamodb.driver.*;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:asserts
class TableTest {
	
	var driver:Driver;
	var table:Table<MyTable>;
	
	public function new() {
		driver = new NodeDriver({
			region: 'whatever',
			endpoint: 'http://localhost:8000',
		});
		table = new Table<MyTable>('test', driver);
	}
	
	@:before
	public function before()
		return driver.listTables()
			.next(function(tables) return if(tables.indexOf(table.name) == -1) Noise else table.delete());
	
	public function create() {
		table.create()
			.next(function(_) return driver.listTables())
			.next(function(tables) {
				asserts.assert(tables.length == 1);
				asserts.assert(tables[0] == table.name);
				return Noise;
			})
			.handle(asserts.handle);
		return asserts;
	}
	
	public function delete() {
		table.create()
			.next(function(_) return table.delete())
			.next(function(_) return driver.listTables())
			.next(function(tables) {
				asserts.assert(tables.length == 0);
				return Noise;
			})
			.handle(asserts.handle);
		return asserts;
	}
	
	public function putAndGet() {
		table.create()
			.next(function(_) return table.put({id: 'my-id', values: ['a', 'b', 'c']}))
			.next(function(_) return table.get({id: 'my-id'}))
			.next(function(data) {
				asserts.assert(data.id == 'my-id');
				asserts.assert(data.values.length == 3);
				asserts.assert(data.values[0] == 'a');
				asserts.assert(data.values[1] == 'b');
				asserts.assert(data.values[2] == 'c');
				return Noise;
			})
			.handle(asserts.handle);
		return asserts;
	}
}

typedef MyTable = {
	@:index(IHash) var id:String;
	var values:Array<String>;
}