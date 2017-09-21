package dynamodb;

@:enum
abstract ProjectionType(String) to String {
	var All = 'All';
	var KeysOnly = 'KEYS_ONLY';
	var Include = 'INCLUDE';
}