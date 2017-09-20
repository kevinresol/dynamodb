package dynamodb.macros;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using tink.MacroApi;
using tink.CoreApi;

class GenReader {
	public static function wrap(placeholder:Expr, ct:ComplexType):Function {
		return placeholder.func(['value'.toArg(macro:Dynamic)], false);
	}
	
	public static function nullable(e:Expr):Expr {
		return macro value.NULL ? null : $e;
	}
	
	public static function string():Expr {
		return macro value.S;
	}
	
	public static function float():Expr {
		return macro Std.parseFloat(value.N);
	}
	
	public static function int():Expr {
		return macro Std.parseInt(value.N);
	}
	
	public static function dyn(e:Expr, ct:ComplexType):Expr {
		throw 'not supported';
	}
	
	public static function dynAccess(e:Expr):Expr {
		throw 'not supported';
	}
	
	public static function bool():Expr {
		return macro value;
	}
	
	public static function date():Expr {
		return macro Date.fromString(value.S); // TODO: this has to be ISO8601
	}
	
	public static function bytes():Expr {
		return macro haxe.crypto.Base64.decode(value);
	}
	
	public static function anon(fields:Array<FieldInfo>, ct:ComplexType):Expr {
		var exprs = [macro var ret = new haxe.DynamicAccess<{}>()];
		
		for(field in fields) {
			var name = field.name;
			exprs.push(macro {
				var value = value.$name;
				ret.set($v{name}, ${field.expr});
			});
		}
		
		exprs.push(macro return ret);
		return macro $b{exprs};
	}
	
	public static function array(e:Expr):Expr {
		return macro [for(value in (value.L:Array<Dynamic>)) $e];
	}
	
	public static function map(k:Expr, v:Expr):Expr {
		throw 'not supported';
	}
	
	public static function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, gen:GenType):Expr {
		throw 'not supported';
	}
	
	public static function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr {
		throw 'not supported';
	}
	
	public static function rescue(t:Type, pos:Position, gen:GenType):Option<Expr> {
		return None;
	}
	
	public static function reject(t:Type):String {
		return 'DynamoDB: ${t.getID()} is not supported';
	}
	
	public static function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool {
		return true;
	}
	
	public static function drive(type:Type, pos:Position, gen:Type->Position->Expr):Expr {
		return gen(type, pos);
	}
	
}