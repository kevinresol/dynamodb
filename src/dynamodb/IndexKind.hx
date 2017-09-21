package dynamodb;

enum IndexKind {
	Primary;
	GlobalSecondary(name:String);
	LocalSecondary(name:String);
}