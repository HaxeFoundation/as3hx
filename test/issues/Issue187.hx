import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class Issue187
{
    private static var sPoint3D : Vector3D;
    public function new()
    {
    }
    
    public static function createPerspectiveProjectionMatrix(
            x : Float, y : Float, width : Float, height : Float,
            stageWidth : Float = 0, stageHeight : Float = 0, cameraPos : Vector3D = null,
            out : Matrix3D = null) : Matrix3D
    {
        if (cameraPos == null)
        {
            cameraPos = sPoint3D;
            cameraPos.setTo(
                    stageWidth / 2, stageHeight / 2, // -> center of stage
                    stageWidth / Math.tan(0.5) * 0.5
            );
        }
    }
}
