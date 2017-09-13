package dynamodb.macros;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using tink.MacroApi;
using tink.CoreApi;

class GenPut {
	public static function wrap(placeholder:Expr, ct:ComplexType):Function {
		return placeholder.func(['value'.toArg(ct)], false);
	}
	
	public static function nullable(e:Expr):Expr {
		return macro value == null ? {NULL: true} : $e;
	}
	
	public static function string():Expr {
		return macro {S: value};
	}
	
	public static function float():Expr {
		return macro {N: Std.string(value)};
	}
	
	public static function int():Expr {
		return macro {N: Std.string(value)};
	}
	
	public static function dyn(e:Expr, ct:ComplexType):Expr {
		throw 'not supported';
	}
	
	public static function dynAccess(e:Expr):Expr {
		throw 'not supported';
	}
	
	public static function bool():Expr {
		return macro {BOOL: value};
	}
	
	public static function date():Expr {
		return macro {S: value.toString()}; // TODO: this has to be ISO8601
	}
	
	public static function bytes():Expr {
		return macro {B: haxe.crypto.Base64.encode(value)};
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
		return macro {L: [for(value in value) $e]};
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