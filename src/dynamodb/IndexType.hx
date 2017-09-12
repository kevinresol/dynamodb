package dynamodb;

@:enum
abstract IndexType(String) to String {
	var IHash = 'HASH';
	var IRange = 'RANGE';
}