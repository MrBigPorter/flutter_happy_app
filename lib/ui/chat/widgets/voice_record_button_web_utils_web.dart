// 只有 Web 模式下才会真正编译这个文件
// 修复：确保导入正确
import 'dart:js' as js;

void preventDefaultContextMenu() {
  try {
    js.context.callMethod('eval', [
      "window.oncontextmenu = function(event) { event.preventDefault(); return false; };"
    ]);
  } catch (e) {
    print("Web context menu prevent failed: $e");
  }
}