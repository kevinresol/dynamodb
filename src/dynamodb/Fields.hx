package dynamodb;

@:genericBuild(dynamodb.macros.Builder.buildFields())
class Fields<T> {}

@:genericBuild(dynamodb.macros.Builder.buildIndexFields())
class IndexFields<T> {}