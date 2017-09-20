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
	public function before() {
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
			.next(function(_) return driver.putItem(ParamBuilder.put('mytable', {id:'jj'})))
			.handle(function(o) asserts.handle(o));
		return asserts;
	}
	
	public function get() {
		var param = ParamBuilder.createTable('mytable', [{name: 'id', valueType: TString, indexType: IHash}]);
		driver.createTable(param)
			.next(function(_) return driver.putItem(ParamBuilder.put('mytable', {id:'jj'})))
			.next(function(_) return driver.getItem(ParamBuilder.get('mytable', {id:'jj'})))
			.next(function(o) {
				asserts.assert(o.id == 'jj');
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
				return driver.scan(ParamBuilder.scan('mytable', field > EConst(100, TNumber)));
			})
			.next(function(o) {
				asserts.assert(o.length == 1);
				return driver.scan(ParamBuilder.scan('mytable', field < EConst(100, TNumber)));
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