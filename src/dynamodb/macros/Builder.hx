package dynamodb.macros;

import haxe.macro.Expr;
import tink.macro.BuildCache;
import tink.typecrawler.Crawler;
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
			var modelCt = ctx.type.toComplex();
			var fieldsCt = macro:dynamodb.Fields<$modelCt>;
			var def = macro class $name extends dynamodb.Table.TableBase<$modelCt, $fieldsCt> {
				public function new(name) {
					super(name);
					fields = ${EObjectDecl(fields).at()};
				}
				
				override function put(data:$modelCt) {
					var item = new ParamBuilder.Put<$modelCt>().build(data);
					trace(item);
				}
			}
			def.pack = ['dynamodb', 'tables'];
			return def;
		});
	}
	
	public static function buildPut() {
		return BuildCache.getType('dynamodb.Put', function(ctx:BuildContext) {
			var name = ctx.name;
			var ct = ctx.type.toComplex();
				
			var def = macro class $name {
				public function new() {}
			} 
			
			function add(t:TypeDefinition)
				def.fields = def.fields.concat(t.fields);
			
			var ret = Crawler.crawl(ctx.type, ctx.pos, GenPut);
			
			def.fields = def.fields.concat(ret.fields);
			
			add(macro class { 
				public function build(value)
					@:pos(ret.expr.pos) return ${ret.expr};
			});
			
			return def;
		});
	}
}