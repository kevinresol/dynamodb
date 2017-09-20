package dynamodb.driver;

import haxe.crypto.Base64;
import haxe.DynamicAccess;
using tink.CoreApi;

@:build(futurize.Futurize.build())
class NodeDriver implements Driver {
	
	var dynamodb:js.aws.dynamodb.DynamoDB;
		
	public function new(config) {
		dynamodb = new js.aws.dynamodb.DynamoDB(config);
	}
	
	public function getItem<T>(params:{}):Promise<T>
		return @:futurize dynamodb.getItem(cast params, $cb1)
			.next(function(data):T return cast rectify(data.Item));
			// TODO: how to generate generic function again?
			
	
	public function scan<T>(params:{}):Promise<Array<T>>
		return @:futurize dynamodb.scan(cast params, $cb1)
			.next(function(data):Array<T> return [for(item in data.Items) (cast rectify(item):T)]);
	
	public function putItem<T>(params:{}):Promise<Noise>
		return @:futurize dynamodb.putItem(cast params, $cb1);
	
	public function createTable<T>(params:{}):Promise<Noise>
		return @:futurize dynamodb.createTable(cast params, $cb1);
	
	public function deleteTable<T>(params:{}):Promise<Noise>
		return @:futurize dynamodb.deleteTable(cast params, $cb1);
	
	public function listTables<T>():Promise<Array<String>>
		return @:futurize dynamodb.listTables({}, $cb1)
			.next(function(o) return o.TableNames);
			
			
	
	function convertValue(item:DynamicAccess<Any>):Any {
		for(type in item.keys()) {
			var value:Any = item.get(type);
			return switch type {
				case 'S' | 'SS' | 'BOOL': value;
				case 'N': Std.parseInt(value);
				case 'NS': (value:Array<String>).map(Std.parseInt);
				case 'B': Base64.decode(value);
				case 'BS': (value:Array<String>).map(Base64.decode.bind(_, false));
				case 'M': cast rectify(value);
				case 'L': (value:Array<DynamicAccess<Any>>).map(convertValue);
				case 'NULL': null;
				default: throw 'unknown type "$type"';
			}
		}
		throw 'unreachable';
	}
		
	function rectify(obj:DynamicAccess<DynamicAccess<Any>>):DynamicAccess<Dynamic> {
		
		var ret = new DynamicAccess<Dynamic>();
		for(key in obj.keys()) {
			var field = obj.get(key);
			ret.set(key, convertValue(obj.get(key)));
		}
		return ret;
	}
}