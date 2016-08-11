
class Issue15
{
    
    public function new()
    {
        var i : Int = 0;
        if (i != 0)
        {
            trace(i);
        }
        ++i;
        
        if (true)
        {
            trace("");
        }
        else
        {
            trace("");
        }
        ++i;
        
        for (j in 0...10)
        {
            trace("");
        }
        ++i;
        
        for (j in 0...10)
        {
            trace("");
        }
        ++i;
        
        for (name in Reflect.fields({ }))
        {
            trace("");
        }
        ++i;
        
        for (name in Reflect.fields({ }))
        {
            trace("");
        }
        ++i;
        
        for (item/* AS3HX WARNING could not determine type for var: item exp: EObject([]) type: null */ in { })
        {
            trace("");
        }
        ++i;
        
        for (item/* AS3HX WARNING could not determine type for var: item exp: EObject([]) type: null */ in { })
        {
            trace("");
        }
        ++i;
        
        while (true)
        {
            trace("");
        }
        ++i;
        
        while (true)
        {
            trace("");
        }
        ++i;
        
        do
        {
            trace("");
        }
        while ((true));
        ++i;
        
        do
        {
            trace("");
        }
        while ((true));
        ++i;
        
        do
        {
            trace("");
        }
        while ((true));
        ++i;
        
        switch (i)
        {
            case 1:
                trace("");
            default:
        }
        ++i;
        
        switch (i)
        {
            case 1:
                trace("");
            default:
        }
        ++i;
    }
}
