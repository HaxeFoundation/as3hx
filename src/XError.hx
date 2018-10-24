package;
import js.Error;

/**
 * ...
 * @author xmi
 */
#if js
class XError extends js.Error {
    public function new(name:String, message:String = null) {
        super();
        untyped Object.defineProperty(this, 'name', {
            enumerable: false,
            writable: false,
            value: name
        });

        untyped Object.defineProperty(this, 'message', {
            enumerable: false,
            writable: true,
            value: message || ''
        });

        if (untyped Error.hasOwnProperty('captureStackTrace')) { // V8
            untyped Error.captureStackTrace(this, XError);
        } else {
            untyped Object.defineProperty(this, 'stack', {
                enumerable: false,
                writable: false,
                value: (new Error(message)).stack
            });
        }
    }
}

#elseif flash
typedef XError = flash.errors.Error;
#else
typedef XError = Error;
#end