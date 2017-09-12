package;

import tink.unit.*;
import tink.testrunner.*;

class RunTests {

  static function main() {
    var table:dynamodb.Table<{name:String}> = new dynamodb.Table<{name:String}>();
    table.query(function(fields) return fields.name == 'jjj');
    
    Runner.run(TestBatch.make([
      new ExprTest(),
      new ParamTest(),
    ])).handle(Runner.exit);
  }
  
}