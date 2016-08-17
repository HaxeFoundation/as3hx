package {
    import flash.geom.Point;
    public class Issue167 {
        public function Issue167(p:Point = null) {
            p ||= new Point();
            
            var n:Number;
            n ||= 1;
            
            var i:int;
            i ||= 1;
            
            var s:String;
            s ||= "string";
            
            var b:Boolean;
            b ||= true;
        }
    }
}