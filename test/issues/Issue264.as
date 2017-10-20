package {
  public class Issue264 {
    public function Issue264() {
      
      var obj:Object = new Object();
      var message:String;
      
      // error inside
      if (obj.error is Error) {
        message = obj.error.message;
      }
      // error event inside
      else if (obj.error is ErrorEvent) {
        message = obj.error.text;
      }
      // unknown
      else {
        message = obj.error.toString();
      }
      
    }
  }
}