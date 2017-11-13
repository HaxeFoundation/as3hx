package {
    public class Issue2611 {
        public function randomGen(param1:int) : int
        {
            var _loc2_:int = Math.floor(Math.random() * param1);
            return _loc2_;
        }
    }
}