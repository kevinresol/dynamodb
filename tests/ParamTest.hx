package;

import dynamodb.Expr;
import dynamodb.ParamBuilder;

@:asserts
class ParamTest {
	public function new() {}
	
	public function eq() {
		var str:Expr<String> = EField('str');
		var expr:Expr<Bool> = str == 'mystr';
		var param = ParamBuilder.buildQueryExpr('mytable', expr);
		asserts.assert(param.TableName == 'mytable');
		asserts.assert(param.ExpressionAttributeNames.get('names0') == 'str');
		asserts.assert(param.ExpressionAttributeValues.get('values1').exists('S'));
		asserts.assert(param.ExpressionAttributeValues.get('values1').get('S') == 'mystr');
		asserts.assert(param.KeyConditionExpression == '#names0=:values1');
		return asserts.done();
	}
}