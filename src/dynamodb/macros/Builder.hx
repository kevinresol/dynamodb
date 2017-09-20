package dynamodb.macros;

import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.BuildCache;
import tink.typecrawler.Crawler;
using tink.MacroApi;

class Builder {
	public static function buildFields() {
		return BuildCache.getType('dynamodb.Fields', function(ctx:BuildContext) {
			var fields:Array<Field> = [];
			
			switch ctx.type.reduce() {
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
	
	public static function buildIndexFields() {
		return BuildCache.getType('dynamodb.IndexFields', function(ctx:BuildContext) {
			var fields:Array<Field> = [];
			
			switch ctx.type.reduce() {
				case TAnonymous(_.get() => anon):
					for(field in anon.fields) {
						switch getIndexType(field) {
							case macro null: // skip
							case _:
								fields.push({
									name: field.name,
									meta: [{name: ':optional', pos: field.pos}],
									kind: FVar(field.type.toComplex(), null),
									pos: field.pos,
								});
						}
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
			var infoFields:Array<Expr> = [];
			switch ctx.type.reduce() {
				case TAnonymous(_.get() => anon):
					for(field in anon.fields) {
						var ct = field.type.toComplex();
						fields.push({
							field: field.name,
							expr: macro dynamodb.Expr.ExprData.EField($v{field.name}),
						});
						infoFields.push(macro {
							name: $v{field.name},
							valueType: ${switch field.type {
								case TInst(_.get() => {name: 'Array', pack: []}, [_.getID() => 'String']): macro TStringSet;
								case TInst(_.get() => {name: 'Array', pack: []}, [_.getID() => 'Int' | 'Float']): macro TNumberSet;
								case TInst(_.get() => {name: 'Array', pack: []}, [_.getID() => 'haxe.io.Bytes']): macro TBinarySet;
								case _.getID() => 'String': macro TString;
								case _.getID() => 'Int' | 'Float': macro TNumber;
								case _.getID() => 'haxe.io.Bytes': macro TBinary;
								case v: field.pos.error('Unsupported data type $v');
							}},
							indexType: ${getIndexType(field)},
						});
					}
				
				case t: throw 'Unsupported type: $t';
			}
			var modelCt = ctx.type.toComplex();
			var fieldsCt = macro:dynamodb.Fields<$modelCt>;
			var indexFieldsCt = macro:dynamodb.Fields.IndexFields<$modelCt>;
			var def = macro class $name extends dynamodb.Table.TableBase<$modelCt, $fieldsCt, $indexFieldsCt> {
				public function new(name, driver) {
					super(name, driver);
					fields = ${EObjectDecl(fields).at()};
					info = {
						fields: ${EArrayDecl(infoFields).at()},
					}
				}
				
				override function get(indices:$indexFieldsCt):tink.core.Promise<$modelCt>
					return driver.getItem(dynamodb.ParamBuilder.get(name, indices));
					
				override function put(data:$modelCt)
					return driver.putItem(dynamodb.ParamBuilder.put(name, data));
					
			}
			def.pack = ['dynamodb', 'tables'];
			return def;
		});
	}
	
	public static function buildItemWriter() {
		return BuildCache.getType('dynamodb.ItemWriter', function(ctx:BuildContext) {
			var name = ctx.name;
			var ct = ctx.type.toComplex();
				
			var def = macro class $name {
				public function new() {}
			} 
			
			function add(t:TypeDefinition)
				def.fields = def.fields.concat(t.fields);
			
			var ret = Crawler.crawl(ctx.type, ctx.pos, GenWriter);
			
			def.fields = def.fields.concat(ret.fields);
			
			add(macro class { 
				public function build(value)
					@:pos(ret.expr.pos) return ${ret.expr};
			});
			
			return def;
		});
	}
	
	public static function buildItemParser() {
		return BuildCache.getType('dynamodb.ItemParser', function(ctx:BuildContext) {
			var name = ctx.name;
			var ct = ctx.type.toComplex();
				
			var def = macro class $name {
				public function new() {}
			} 
			
			function add(t:TypeDefinition)
				def.fields = def.fields.concat(t.fields);
			
			var ret = Crawler.crawl(ctx.type, ctx.pos, GenReader);
			
			def.fields = def.fields.concat(ret.fields);
			
			add(macro class { 
				public function parse(value)
					@:pos(ret.expr.pos) return ${ret.expr};
			});
			
			return def;
		});
	}
	
	static function getIndexType(field:ClassField) {
		return switch field.meta.extract(':index') {
			case []: macro null;
			case [{params: [e]}]: macro ($e:dynamodb.IndexType);
			default: field.pos.error('Invalid @:index meta');
		}
	}
}