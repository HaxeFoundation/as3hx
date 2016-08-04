package {
    public class Issue32 {
        public function Issue32() {
            var a:Array = [];
            var b:Array = a.concat();
            var c:Array = a.concat([1, 2, 3, 4]);
            var d:Vector.<int> = new <int>[];
            var e:Vector.<int> = d.concat();
            var f:Vector.<int> = d.concat(new <int>[1,2,3,4]);
        }
    }
}