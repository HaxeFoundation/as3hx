package {
    public class Issue204 {
        public function Issue204() {
            var i:int;
            var j:int;
            function test(i:int, n:Number):void {
                trace(i + n);
            }
            var f:Function = function():void {}
            var i:int = 10;
            var n:Number = 0.1;
            test(i,n);
        }
    }
}

