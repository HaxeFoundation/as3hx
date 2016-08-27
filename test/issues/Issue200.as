package {
    import flash.utils.getQualifiedClassName;
    public class Issue200 {
        public function Issue200() {
            getQualifiedClassName(this);
            getQualifiedClassName(Issue200);
        }
    }
}