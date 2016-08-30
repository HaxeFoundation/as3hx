package {
    import starling.utils.StringUtil;
    public class Issue213 {
        public function Issue213() {
            StringUtil.format("[VertexData format=\"{0}\" numVertices={1}]", "", 1);
        }
    }
}

import mx.utils.StringUtil;
class Foo {
    public function Foo() {
        StringUtil.trim(" abc ");
        StringUtil.isWhitespace("");
    }
}
