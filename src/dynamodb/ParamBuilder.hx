package dynamodb;

import haxe.DynamicAccess;
import dynamodb.Expr;

class ParamBuilder {
	public static function buildQueryExpr<T>(tableName, expr:ExprData<T>):QueryParams {
		return new QueryParamBuilder(expr).toParams(tableName);
	}
	
	var expression:String;
	var counter = 0;
	var names = new DynamicAccess();
	var values = new DynamicAccess();
	
	function rec<T>(e:ExprData<T>) {
		return switch e {
			case EConst(value, type):
				var id = 'values${counter++}';
				var rep = new DynamicAccess();
				rep.set(type, value);
				values.set(id, rep);
				':$id';
			case EField(name):
				var id = 'names${counter++}';
				names.set(id, name);
				'#$id';
			case EBinop(op, e1, e2):
				rec(e1) + binop(op) + rec(e2);
		}
	}
	
	function binop<L, R, T>(op:Binop<L, R, T>):String
		return switch op {
			case Eq: '=';
		}
}

class QueryParamBuilder extends ParamBuilder {
	function new(expr) {
		expression = rec(expr);
	}
	
	public function toParams(tableName:String):QueryParams {
		return {
			TableName: tableName,
			ExpressionAttributeNames: names,
			ExpressionAttributeValues: values,
			KeyConditionExpression: expression,
		}
	}
}

typedef Params = {
	TableName:String,
}

typedef GetParams = {
	> Params,
	Key:DynamicAccess<DynamicAccess<Dynamic>>,
}

typedef QueryParams = {
	> Params,
	?ExpressionAttributeNames:DynamicAccess<String>,
	?ExpressionAttributeValues:DynamicAccess<DynamicAccess<Dynamic>>,
	?KeyConditionExpression:String,
	?ProjectionExpression:String,
}

typedef CreateTableParams = {
	> Params,
	AttributeDefinitions:Array<{AttributeName:String, AttributeType:ValueType}>,
	KeySchema:Array<{AttributeName:String, KeyType:IndexType}>,
	ProvisionedThroughput:{
		ReadCapacityUnits:Int,
		WriteCapacityUnits:Int,
	}
}