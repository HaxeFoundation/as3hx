
class Issue273
{
    public function new()
    {
        var param1 = "j";
        switch (param1)
        {
            case "a":
                return 1;
            case "b":
                return 2;
            case "c":
                return 3;
            case "d":
                return 4;
            case "e":
                return 5;
            case "f":
                return 6;
            case "g":
                return 7;
            case "h":
                return 8;
            /* covers case "i": */
            default:
                return 9;
        }
    }
}
