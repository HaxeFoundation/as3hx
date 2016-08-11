package {
    public class Issue150 {
        public function Issue150() {
            var fragmentShader:String = [
                tex("ft0", "v1", 1, _mapTexture, false), // read map texture
                "sub ft1, ft0, fc0",          // subtract 0.5 -> range [-0.5, 0.5]
                "mul ft1.xy, ft1.xy, ft0.ww", // zero displacement when alpha == 0
                "m44 ft2, ft1, fc1",          // multiply matrix with displacement values
                "add ft3,  v0, ft2",          // add displacement values to texture coords
                tex("oc", "ft3", 0, texture)  // read input texture at displaced coords
            ].join("\n");
            
            var s1:String = [1, 2, 3, 4, 5].join("\n");
            
            var s2:String = [1,
                2, 3, 4, 5].join("\n");
                
            var s2:String = [1, 2, 3,/*comment*/ 4, 5].join("\n");
        }
    }
}