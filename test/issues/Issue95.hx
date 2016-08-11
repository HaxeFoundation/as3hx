
typedef ConfigsTypedef = {
    var name : String;
    var id : Int;
}

class Issue95
{
    private static var _configs : Array<ConfigsTypedef> = [
        {
            name : "name",
            id : 10
        }
    ];

    public function new()
    {
    }
}
