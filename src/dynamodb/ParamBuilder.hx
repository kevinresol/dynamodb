package dynamodb;

import haxe.DynamicAccess;
import dynamodb.Expr;

using Lambda;

#if macro
using tink.MacroApi;
#else
@:genericBuild(dynamodb.macros.Builder.buildPut())
#end
class Put<T> {}

class ParamBuilder {
	public static macro function put<T>(tableName:haxe.macro.Expr.ExprOf<String>, item:haxe.macro.Expr.ExprOf<T>) {
		var ct = haxe.macro.Context.typeof(item).toComplex();
		return macro {
			TableName: $tableName,
			Item: cast dynamodb.Item.toParam($item),
		}
	}
	
	public static macro function get<T>(tableName:haxe.macro.Expr.ExprOf<String>, item:haxe.macro.Expr.ExprOf<T>) {
		var ct = haxe.macro.Context.typeof(item).toComplex();
		return macro {
			TableName: $tableName,
			Key: cast dynamodb.Item.toParam($item),
		}
	}
	
	#if !macro
	public static function createTable<T>(tableName:String, indices:Array<{kind:IndexKind, fields:Array<{name:String, valueType:ValueType, indexType:IndexType}>, ?provisionedThroughput:{read:Int, write:Int}}>):CreateTableParams {
		
		// primary index
		var attributeDefinitions:AttributeDefinitions = [];
		var keySchema = [];
		var provisionedThroughput = {read: 5, write: 5};
		var globalSecondaryIndices = [];
		var localSecondaryIndices = [];
		
		function addAttributeDefinition(name, type) {
			if(!attributeDefinitions.exists(function(def) return def.AttributeName == name))
				attributeDefinitions.push({
					AttributeName: name,
					AttributeType: type,
				});
		}
		
		for(index in indices) {
			switch index.kind {
				case Primary:
					for(field in index.fields) {
						addAttributeDefinition(field.name, field.valueType);
						keySchema.push({
							AttributeName: field.name,
							KeyType: field.indexType,
						});
						if(index.provisionedThroughput != null) provisionedThroughput = index.provisionedThroughput;
					}
					
				case GlobalSecondary(name) | LocalSecondary(name):
					var keySchema = [];
					for(field in index.fields) {
						addAttributeDefinition(field.name, field.valueType);
						keySchema.push({
							AttributeName: field.name,
							KeyType: field.indexType,
						});
					}
					
					(index.kind.match(GlobalSecondary(_)) ? globalSecondaryIndices : localSecondaryIndices).push({
						IndexName: name,
						KeySchema: keySchema,
						Projection: {
							ProjectionType: 'KEYS_ONLY', // TODO
						},
						ProvisionedThroughput: {
							ReadCapacityUnits: index.provisionedThroughput == null ? 5 : index.provisionedThroughput.read,
							WriteCapacityUnits: index.provisionedThroughput == null ? 5 : index.provisionedThroughput.write,
						}
					});
			}
		}
		
		return {
			TableName: tableName,
			AttributeDefinitions: attributeDefinitions,
			KeySchema: keySchema,
			ProvisionedThroughput: {
				ReadCapacityUnits: provisionedThroughput.read,
				WriteCapacityUnits: provisionedThroughput.write,
			},
			GlobalSecondaryIndexes: globalSecondaryIndices.length == 0 ? null : globalSecondaryIndices,
			LocalSecondaryIndexes: localSecondaryIndices.length == 0 ? null : localSecondaryIndices,
		}
	}
	
	public static function scan<T>(tableName, expr:ExprData<T>):ScanParams {
		return new ScanParamBuilder(expr).toParams(tableName);
	}
	
	public static function query<T>(tableName, expr:ExprData<T>, ?options:{?indexName:String}):QueryParams {
		if(options == null) options = {};
		return new QueryParamBuilder(expr).toParams(tableName, options.indexName);
	}
	
	var expression:String;
	var ncounter = 0;
	var vcounter = 0;
	var names = new DynamicAccess();
	var values = new DynamicAccess();
	
	function rec<T>(e:ExprData<T>) {
		return switch e {
			case EConst(value, type):
				var id = ':v${vcounter++}';
				var rep = new DynamicAccess();
				rep.set(type, switch type {
					case TNumber: Std.string(value);
					default: cast value;
				});
				values.set(id, rep);
				id;
			case EField(name):
				var id = '#n${ncounter++}';
				names.set(id, name);
				id;
			case EBinop(op, e1, e2):
				rec(e1) + binop(op) + rec(e2);
			case ECall(f):
				func(f);
		}
	}
	
	function func(f:Func) {
		return switch f {
			case Contains(arr, val): 
				'contains(${rec(arr)}, ${rec(val)})';
		}
	}
	
	function binop<L, R, T>(op:Binop<L, R, T>):String
		return switch op {
			case Eq: ' = ';
			case Gt: ' > ';
			case Lt: ' < ';
			case And: ' AND ';
			case Or: ' OR ';
		}
	#end
}

#if !macro
class QueryParamBuilder extends ParamBuilder {
	function new(expr) {
		expression = rec(expr);
	}
	
	public function toParams(tableName:String, indexName:String):QueryParams {
		return {
			TableName: tableName,
			IndexName: indexName,
			ExpressionAttributeNames: names,
			ExpressionAttributeValues: values,
			KeyConditionExpression: expression,
		}
	}
}

class ScanParamBuilder extends ParamBuilder {
	function new(expr) {
		expression = rec(expr);
	}
	
	public function toParams(tableName:String):ScanParams {
		return {
			TableName: tableName,
			ExpressionAttributeNames: names,
			ExpressionAttributeValues: values,
			FilterExpression: expression,
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
	?IndexName:String,
	?ExpressionAttributeNames:DynamicAccess<String>,
	?ExpressionAttributeValues:DynamicAccess<DynamicAccess<Dynamic>>,
	?KeyConditionExpression:String,
	?ProjectionExpression:String,
}

typedef ScanParams = {
	> Params,
	?ExpressionAttributeNames:DynamicAccess<String>,
	?ExpressionAttributeValues:DynamicAccess<DynamicAccess<Dynamic>>,
	?FilterExpression:String,
	?ProjectionExpression:String,
}

typedef CreateTableParams = {
	> Params,
	AttributeDefinitions:AttributeDefinitions,
	KeySchema:KeySchema,
	ProvisionedThroughput:ProvisionedThroughput,
	?GlobalSecondaryIndexes:SecondaryIndexes,
	?LocalSecondaryIndexes:SecondaryIndexes,
}

typedef SecondaryIndexes = Array<{	
	IndexName:String,
	KeySchema:KeySchema,
	ProvisionedThroughput:ProvisionedThroughput,
	Projection: {
		?NonKeyAttributes:Array<String>,
		ProjectionType:String,
	}
}>

typedef ProvisionedThroughput ={
	ReadCapacityUnits:Int,
	WriteCapacityUnits:Int,
}

typedef AttributeDefinitions = Array<{AttributeName:String, AttributeType:ValueType}>;
typedef KeySchema = Array<{AttributeName:String, KeyType:IndexType}>;
#end