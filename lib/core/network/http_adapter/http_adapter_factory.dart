// 正确写法：只有 export，没有其他代码
export 'adapter_stub.dart'
if (dart.library.html) 'adapter_web.dart'
if (dart.library.io) 'adapter_io.dart';