package dynamodb;

@:enum
abstract ValueType(String) to String {
	var TString = 'S';
	var TNumber = 'N';
	var TBinary = 'B';
	var TBoolean = 'BOOL';
	var TNull = 'NULL';
	var TMap = 'M';
	var TList = 'L';
	var TStringSet = 'SS';
	var TNumberSet = 'NS';
	var TBinarySet = 'BS';
}