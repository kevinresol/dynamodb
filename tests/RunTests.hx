package;

import tink.unit.*;
import tink.testrunner.*;

class RunTests {

  static function main() {
    var table:dynamodb.Table<{name:String, age:Int}> = new dynamodb.Table<{name:String, age:Int}>('name');
    table.query(function(fields) return fields.name == 'jjj');
    table.put({name:'Kevin', age:25});
    
    Runner.run(TestBatch.make([
      new ExprTest(),
      new ParamTest(),
      new OperationTest(),
    ])).handle(Runner.exit);
  }
  
}