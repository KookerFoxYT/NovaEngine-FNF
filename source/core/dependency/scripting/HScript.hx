package core.dependency.scripting;

import core.dependency.ScriptHandler;
import hscript.Expr;
import hscript.Interp;

/**
 * The class used for handling HScript functionality.
 */
class HScript extends ScriptModule {
    public var interp:Interp;

    private function __errorHandler(error:Error) {
        var fn = '$fileName:${error.line}: ';
        var err = error.toString();
        if (err.startsWith(fn)) err = err.substr(fn.length);

        Logs.trace('Error occured on script: $fileName at Line ${error.line} - $err', ERROR);
    }

    public function new(path:String, fileName:String = "hscript") {
        super(path, fileName);

        var expr:Expr = null;
        try {
            if(!FileSystem.exists(path))
                throw 'Script doesn\'t exist at path: $path';
            
            expr = ScriptHandler.parser.parseString(File.getContent(path));
        } 
        catch(e) {
            expr = null;
            Logs.trace('Error occured while loading script at path: $path - $e', ERROR);
        }
        
        // If the script failed to load, just treat it as a dummy script!
        if(expr == null) return;

        interp = new Interp();
        interp.errorHandler = __errorHandler;

        interp.variables.set("trace", Reflect.makeVarArgs((args) -> {
            var v:String = Std.string(args.shift());
            for (a in args) v += ", " + Std.string(a);
            this.trace(v);
        }));

        for(name => value in ScriptHandler.preset)
            interp.variables.set(name, value);

        interp.execute(expr);
    }

    /**
     * Gets a variable from this script and returns it.
     * @param val The name of the variable to get.
     */
    override public function get(val:String):Dynamic {
        if(interp == null) return null;
        return interp.variables.get(val);
    }

    /**
     * Sets a variable from this script.
     * @param val The name of the variable to set.
     * @param value The value to set the variable to.
     */
     override public function set(val:String, value:Dynamic) {
        if(interp == null) return;
        interp.variables.set(val, value);
    }

    /**
     * Calls a function from this script and returns whatever the function returns (Can be `null`!).
     * @param funcName The name of the function to call.
     * @param parameters The parameters/arguments to give the function when calling it.
     */
     override public function call(funcName:String, parameters:Array<Dynamic>):Dynamic {
        if(interp == null) return null;

        var func:Dynamic = interp.variables.get(funcName);
        if(func != null && Reflect.isFunction(func))
            return (parameters != null && parameters.length > 0) ? Reflect.callMethod(null, func, parameters) : func();

        return null;
    }

    override public function trace(v:Dynamic) {
        if(interp == null) return Logs.trace(v, TRACE);

        var pos = interp.posInfos();
        Logs.trace('$fileName - Line ${pos.lineNumber}: $v', TRACE);
    }

    override public function destroy() {
        interp = null;
        super.destroy();
    }

    override public function setParent(parent:Dynamic) {
        if(interp == null) return;
        this.parent = interp.scriptObject = parent;
    }
}