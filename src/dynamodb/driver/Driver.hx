package dynamodb.driver;

import haxe.DynamicAccess;

using tink.CoreApi;

interface Driver {
	function getItem<T>(param:{}):Promise<T>;
	function scan<T>(param:{}):Promise<Array<T>>;
	function putItem<T>(param:{}):Promise<Noise>;
	function createTable(param:{}):Promise<Noise>;
	function deleteTable(param:{}):Promise<Noise>;
	function listTables():Promise<Array<String>>;
}