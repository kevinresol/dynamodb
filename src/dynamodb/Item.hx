package dynamodb;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using tink.MacroApi;
#end

class Item {
	public static macro function toParam(e:Expr) {
		var ct = Context.typeof(e).toComplex();
		return macro new dynamodb.Item.ItemWriter<$ct>().build($e);
	}
	
	public static macro function fromParam(e:Expr) {
		return switch e {
			case macro ($e : $ct):
				macro new dynamodb.Item.ItemParser<$ct>().parse($e);
			case _:
				switch Context.getExpectedType() {
					case null:
						e.reject('Cannot determine expected type');
					case _.toComplex() => ct:
						macro new dynamodb.Item.ItemParser<$ct>().parse($e);
				}
		}
	}
}


#if !macro @:genericBuild(dynamodb.macros.Builder.buildItemWriter()) #end
class ItemWriter<T> {}

#if !macro @:genericBuild(dynamodb.macros.Builder.buildItemParser()) #end
class ItemParser<T> {}
