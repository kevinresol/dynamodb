package dynamodb;

import dynamodb.driver.*;

@:autoBuild(dynamodb.macros.Builder.buildDatabase())
class Database {
	var driver:Driver;
	public function new(driver)
		this.driver = driver;
}