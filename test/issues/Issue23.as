package {
    public class Issue23 {
        
        public function Issue23(i:int, n:Number, ss:String) {
            var a:int = i as int;
            var a2:int = int(i);
            var a3:int = int(n);
            var a4:int = int(s);
            
            var b:Number = n as Number;
            var b2:Number = Number(n);
            var b3:Number = Number(i);
            var b4:Number = Number(s);
            
            var s:String = n as String;
            var s2:String = ss as String;
            var s3:String = String(ss);
            var s4:String = i as String;
            var s5:String = String(i);
        }
    }
}