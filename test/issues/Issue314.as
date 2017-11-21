package {
    public class Issue303 {
        public function Issue303() {}
        public function hide1(param1:*) : *
        {
            this[param1] = false;
            this[param1].visible = false;
        }
        public function hide2(param1:*) : *
        {
            this[param1] = "nothing";
            this[param1].collision.currentObject = "nothing";
        }
    }
}