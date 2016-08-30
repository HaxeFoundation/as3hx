import starling.utils.StringUtil;

class Issue213
{
    public function new()
    {
        StringUtil.format("[VertexData format=\"{0}\" numVertices={1}]", "", 1);
    }
}



class Foo
{
    public function new()
    {
        StringTools.trim(" abc ");
        StringTools.isSpace("", 0);
    }
}
