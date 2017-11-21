package {
    public class Issue314 {
        public function Issue314() {}
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