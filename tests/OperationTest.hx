package;

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
				return driver.createTable({
					AttributeDefinitions: [{
						AttributeName: 'id',
						AttributeType: 'S',
					}],
					KeySchema: [{
						AttributeName: 'id',
						KeyType: 'HASH',
					}],
					ProvisionedThroughput: {
						ReadCapacityUnits: 5, 
						WriteCapacityUnits: 5
					},
					TableName:'mytable',
				});
			})
			.next(function(_) return driver.listTables())
			.next(function(tables) {
				asserts.assert(tables.length == 1);
				return Noise;
			})
			.handle(asserts.handle);
		return asserts;
	}
}