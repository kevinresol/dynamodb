package;

import dynamodb.Expr;
import dynamodb.ParamBuilder;

@:asserts
class ParamTest {
	public function new() {}
	
	public function eq() {
		var str:Expr<String> = EField('str');
		var expr:Expr<Bool> = str == 'mystr';
		var param = ParamBuilder.query('mytable', expr);
		asserts.assert(param.TableName == 'mytable');
		asserts.assert(param.ExpressionAttributeNames.get('#n0') == 'str');
		asserts.assert(param.ExpressionAttributeValues.get(':v0').exists('S'));
		asserts.assert(param.ExpressionAttributeValues.get(':v0').get('S') == 'mystr');
		asserts.assert(param.KeyConditionExpression == '#n0 = :v0');
		return asserts.done();
	}
	
	public function put() {
		var param = ParamBuilder.put('mytable', {foo: 'bar'});
		asserts.assert(param.TableName == 'mytable');
		asserts.assert(param.Item.foo.S == 'bar');
		return asserts.done();
	}
	
	public function get() {
		var param = ParamBuilder.get('mytable', {foo: 'bar'});
		asserts.assert(param.TableName == 'mytable');
		asserts.assert(param.Key.foo.S == 'bar');
		return asserts.done();
	}
}