package;

import dynamodb.*;
import dynamodb.Expr;
import dynamodb.driver.*;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:asserts
@:build(futurize.Futurize.build())
class OperationTest {
	
	var driver = new NodeDriver({
		region: 'whatever',
		endpoint: 'http://localhost:8000',
	});
	
	public function new() {}
	
	@:before
	public function before() return clear();
	@:teardown
	public function teardown() return clear();
	
	function clear() {
		return driver.listTables()
			.next(function(tables) return Promise.inParallel([for(table in tables) driver.deleteTable({TableName: table})]));
	}
	
	public function createTable() {
		driver.listTables()
			.next(function(tables) {
				asserts.assert(tables.length == 0);
				var param = ParamBuilder.createTable('mytable', [{name: 'id', valueType: TString, indexType: IHash}]);
				return driver.createTable(param);
			})
			.next(function(_) return driver.listTables())
			.next(function(tables) {
				asserts.assert(tables.length == 1);
				return Noise;
			})
			.handle(asserts.handle);
		return asserts;
	}
	
	public function put() {
		var param = ParamBuilder.createTable('mytable', [{name: 'id', valueType: TString, indexType: IHash}]);
		driver.createTable(param)
			.next(function(_) return driver.putItem(ParamBuilder.put('mytable', {id:'abc'})))
			.handle(function(o) asserts.handle(o));
		return asserts;
	}
	
	public function putArray() {
		var param = ParamBuilder.createTable('mytable', [{name: 'id', valueType: TString, indexType: IHash}]);
		driver.createTable(param)
			.next(function(_) return driver.putItem(ParamBuilder.put('mytable', {id:'abc', values: ['apple', 'orange']})))
			.handle(function(o) asserts.handle(o));
		return asserts;
	}
	
	public function get() {
		var param = ParamBuilder.createTable('mytable', [{name: 'id', valueType: TString, indexType: IHash}]);
		driver.createTable(param)
			.next(function(_) return driver.putItem(ParamBuilder.put('mytable', {id:'abc'})))
			.next(function(_) return driver.getItem(ParamBuilder.get('mytable', {id:'abc'})))
			.next(function(o) {
				asserts.assert(o.id == 'abc');
				return Noise;
			})
			.handle(function(o) {
				asserts.handle(o);
			});
		return asserts;
	}
	
	public function getArray() {
		var param = ParamBuilder.createTable('mytable', [{name: 'id', valueType: TString, indexType: IHash}]);
		driver.createTable(param)
			.next(function(_) return driver.putItem(ParamBuilder.put('mytable', {id:'abc', values: ['apple', 'orange']})))
			.next(function(_) return driver.getItem(ParamBuilder.get('mytable', {id:'abc'})))
			.next(function(o) {
				asserts.assert(o.id == 'abc');
				asserts.assert(o.values[0] == 'apple');
				asserts.assert(o.values[1] == 'orange');
				return Noise;
			})
			.handle(function(o) {
				asserts.handle(o);
			});
		return asserts;
	}
	
	public function scan() {
		var param = ParamBuilder.createTable('mytable', [{name: 'id', valueType: TNumber, indexType: IHash}]);
		var field:Expr<Int> = EField('id');
		driver.createTable(param)
			.next(function(_) return driver.putItem(ParamBuilder.put('mytable', {id: 123})))
			.next(function(_) {
				return driver.scan(ParamBuilder.scan('mytable', field > 100));
			})
			.next(function(o) {
				asserts.assert(o.length == 1);
				return driver.scan(ParamBuilder.scan('mytable', field < 100));
			})
			.next(function(o) {
				asserts.assert(o.length == 0);
				return Noise;
			})
			.handle(function(o) {
				asserts.handle(o);
			});
		return asserts;
	}
	
	public function scanArray() {
		var param = ParamBuilder.createTable('mytable', [{name: 'id', valueType: TNumber, indexType: IHash}]);
		var field:Expr<Array<String>> = EField('values');
		driver.createTable(param)
			.next(function(_) return driver.putItem(ParamBuilder.put('mytable', {id: 123, values: ['apple', 'orange']})))
			.next(function(_) {
				return driver.scan(ParamBuilder.scan('mytable', field.contains('apple')));
			})
			.next(function(o) {
				asserts.assert(o.length == 1);
				return driver.scan(ParamBuilder.scan('mytable', field.contains('pear')));
			})
			.next(function(o) {
				asserts.assert(o.length == 0);
				return Noise;
			})
			.handle(function(o) {
				asserts.handle(o);
			});
		return asserts;
	}
}