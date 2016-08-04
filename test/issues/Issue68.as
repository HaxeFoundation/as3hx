package {
    public class Issue68 {
        public function Issue68() {
            var a:Array = [];
            var b:Array = a.slice();
            var c:Array = a.slice(0, 1);
            var d:Vector.<int> = new <int>[];
            var e:Vector.<int> = d.slice();
            var f:Vector.<int> = d.slice(0, 1);
        }
    }
}