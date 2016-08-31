package {
    import flash.utils.Dictionary;
    public class Issue226 {
        public function Issue226() {
            var dictionary:Dictionary = new Dictionary();
            dictionary["key"] = true;
            delete dictionary["key"];
        }
    }
}