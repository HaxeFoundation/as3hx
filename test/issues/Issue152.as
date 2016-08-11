package {
    public class Issue152 {
        private var vertexShader:Array;
        public function Issue152() {
            vertexShader.push(
                1, // add offset 1
                2, // add offset 2
                3, // add offset 3
                4
            );
        }
    }
}