package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;

class ScriptsMacro {
    public static function addAdditionalClasses() {
        Compiler.include("flixel");
        Compiler.include("flixel.addons");
        Compiler.include("flixel.addons.display");
        Compiler.include("flixel.addons.ui");
        #if sys
        Compiler.include("sys");
        #end
        Compiler.include("DateTools");
        Compiler.include("EReg");
        Compiler.include("Lambda");
        Compiler.include("StringBuf");
        Compiler.include("haxe.crypto");
        Compiler.include("haxe.display");
        Compiler.include("haxe.exceptions");
        Compiler.include("haxe.extern");

        // FOR ABSTRACTS
        Compiler.addGlobalMetadata('haxe.xml', '@:build(hscript.UsingHandler.build())');
    }

    public static function build():Array<Field> {
        var fields:Array<Field> = Context.getBuildFields();

        for(f in fields) {
            switch(f.kind) {
                case FFun(func):
                    if (f.access == null) f.access = [];
                    if (f.access.contains(AInline))
                        f.access.remove(AInline);
                    f.access.push(ADynamic);
                default:
                    // do nothing u piece of shit
            }
        }

        return fields;
    }
}
#end