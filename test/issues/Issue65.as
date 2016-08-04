package {
    public class Issue65 {
        public function Issue65() {
            var array:Array;
            for (var i:int=0; i < array.length; i++) {
                var current:Object = array[i];
                if (!current)
                    continue;
            }
        }
    }
}