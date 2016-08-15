package {
    import flash.utils.ByteArray;
    public class Issue63 {
        public function Issue63() {
            var a:Vector.<Number> = new Vector.<Number>();
            a.length = 10;
            var bytes:ByteArray = new ByteArray();
            bytes.length = 0;
        }
    }
}