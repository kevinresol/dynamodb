package dynamodb.macros;

import haxe.macro.Expr;
import tink.macro.BuildCache;
using tink.MacroApi;

class Builder {
	public static function buildFields() {
		return BuildCache.getType('dynamodb.Fields', function(ctx:BuildContext) {
			var fields:Array<Field> = [];
			
			switch ctx.type {
				case TAnonymous(_.get() => anon):
					for(field in anon.fields) {
						var ct = field.type.toComplex();
						fields.push({
							name: field.name,
							kind: FVar(macro:dynamodb.Expr<$ct>, null),
							pos: field.pos,
						});
					}
				case t: throw 'Unsupported type: $t';
			}
			
			return {
				fields: fields,
				kind: TDStructure,
				name: ctx.name,
				pack: ['dynamodb', 'fields'],
				pos: ctx.pos,
			}
		});
	}
	public static function buildTable() {
		return BuildCache.getType('dynamodb.Table', function(ctx:BuildContext) {
			var name = ctx.name;
			
			var fields:Array<{field:String, expr:Expr}> = [];
			switch ctx.type {
				case TAnonymous(_.get() => anon):
					for(field in anon.fields) {
						var ct = field.type.toComplex();
						fields.push({
							field: field.name,
							expr: macro dynamodb.Expr.ExprData.EField($v{field.name}),
						});
					}
				
				case t: throw 'Unsupported type: $t';
			}
			var ct = ctx.type.toComplex();
			var ct = macro:dynamodb.Fields<$ct>;
			var def = macro class $name extends dynamodb.Table.TableBase<$ct> {
				public function new() {
					fields = ${EObjectDecl(fields).at()};
				}
			}
			def.pack = ['dynamodb', 'tables'];
			return def;
		});
	}
}