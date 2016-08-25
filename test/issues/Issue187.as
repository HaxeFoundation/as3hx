package {
    import flash.geom.Matrix3D;
    import flash.geom.Vector3D;
    public class Issue187 {
        static private var sPoint3D:Vector3D;
        public function Issue187() {
        }
        
        public static function createPerspectiveProjectionMatrix(
                x:Number, y:Number, width:Number, height:Number,
                stageWidth:Number=0, stageHeight:Number=0, cameraPos:Vector3D=null,
                out:Matrix3D=null):Matrix3D
        {
            if (cameraPos == null)
            {
                cameraPos = sPoint3D;
                cameraPos.setTo(
                        stageWidth / 2, stageHeight / 2,   // -> center of stage
                        stageWidth / Math.tan(0.5) * 0.5);
            }
        }
    }
}