package {
    public class Issue71 {
        public function Issue71() {
            $test({});
            var $localVar:Object = {
                $key:"value"
            }
        }
        
        private var $name:String;
        
        private function $test($param:Object):void {
            trace($param);
            trace($name);
        }
    }
}