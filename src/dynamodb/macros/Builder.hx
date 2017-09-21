package dynamodb.macros;

import haxe.macro.Type;
import haxe.macro.Expr;
import tink.macro.BuildCache;
import tink.typecrawler.Crawler;
using tink.MacroApi;

class Builder {
	public static function buildDatabase() {
		var builder = new ClassBuilder();
		var ctor = builder.getConstructor();
		for(member in builder) {
			switch [member.extractMeta(':table'), member.getVar()] {
				case [Success({params: p}), Success({type: ct})]:
					var tableName = if(p.length == 0) member.name else p[0].getString().sure();
					member.kind = FVar(macro:dynamodb.Table<$ct>, null);
					member.publish();
					ctor.init(member.name, member.pos, Value(macro new dynamodb.Table<$ct>($v{tableName}, driver)));
				default:
					// TODO: print error nicely
			}
		}
		return builder.export();
	}
	
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
						switch getIndexTypes(field).primary {
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
			
			
			var infoIndices:Array<Expr> = [];
			var infoIndicesPrimary:Array<Expr> = [];
			var infoIndicesGlobalSecondary = new Map();
			var infoIndicesLocalSecondary = new Map();
			
			
			switch ctx.type.reduce() {
				case TAnonymous(_.get() => anon):
					for(field in anon.fields) {
						var ct = field.type.toComplex();
						var indices = getIndexTypes(field);
						
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
							indexType: ${indices.primary},
						});
						
						switch indices.primary {
							case macro null: // ok
							case e: infoIndicesPrimary.push(macro {name: $v{field.name}, type: ${indices.primary}});
						}
						
						for(i in indices.globalSecondary) {
							if(!infoIndicesGlobalSecondary.exists(i.name)) infoIndicesGlobalSecondary.set(i.name, []);
							infoIndicesGlobalSecondary.get(i.name).push(macro {name: $v{field.name}, type: ${i.key}});
						}
						
						for(i in indices.localSecondary) {
							if(!infoIndicesLocalSecondary.exists(i.name)) infoIndicesLocalSecondary.set(i.name, []);
							infoIndicesLocalSecondary.get(i.name).push(macro {name: $v{field.name}, type: ${i.key}});
						}
					}
				
				case t: throw 'Unsupported type: $t';
			}
			
			infoIndices.push(macro {kind: Primary, keys: $a{infoIndicesPrimary}});
			for(name in infoIndicesGlobalSecondary.keys()) infoIndices.push(macro {kind: GlobalSecondary($v{name}), keys: $a{infoIndicesGlobalSecondary.get(name)}});
			for(name in infoIndicesLocalSecondary.keys()) infoIndices.push(macro {kind: LocbalSecondary($v{name}), keys: $a{infoIndicesLocalSecondary.get(name)}});
			
			var modelCt = ctx.type.toComplex();
			var fieldsCt = macro:dynamodb.Fields<$modelCt>;
			var indexFieldsCt = macro:dynamodb.Fields.IndexFields<$modelCt>;
			var def = macro class $name extends dynamodb.Table.TableBase<$modelCt, $fieldsCt, $indexFieldsCt> {
				public function new(name, driver) {
					super(name, driver);
					fields = ${EObjectDecl(fields).at()};
					info = {
						fields: ${EArrayDecl(infoFields).at()},
						indices: ${EArrayDecl(infoIndices).at()},
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
	
	static function getIndexTypes(field:ClassField) {
		var ret = {
			primary: macro null,
			globalSecondary: [],
			localSecondary: [],
		}
		
		switch field.meta.extract(':index') {
			case []: // do nothing
			case [{params: [e]}]: ret.primary = macro ($e:dynamodb.IndexType);
			default: field.pos.error('Invalid @:index meta');
		}
		
		for(v in field.meta.extract(':globalSecondaryIndex')) {
			ret.globalSecondary.push({name: v.params[0].getString().sure(), key: macro (${v.params[1]}:dynamodb.IndexType)});
		}
		
		for(v in field.meta.extract(':localSecondaryIndex')) {
			ret.localSecondary.push({name: v.params[0].getString().sure(), key: macro (${v.params[1]}:dynamodb.IndexType)});
		}
		
		return ret;
	}
}