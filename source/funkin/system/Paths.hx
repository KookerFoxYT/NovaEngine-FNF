package funkin.system;

import flixel.graphics.frames.FlxAtlasFrames;

class Paths {
    public static var currentMod:String = "Friday Night Funkin'";
    
    public static var scriptExtensions:Array<String> = [
        "hx",
        "hxs",
        "hsc",
        "hscript",
        "lua"
    ];

    public static function exists(path:String) {
        return OpenFLAssets.exists(path);
    }

    public static function getAsset(path:String, ?library:Null<String>) {
        if(library != null && library.length > 0) library += ":";
        if(library == null) library = "";
        return '${library}assets/$path';
    }

    public static function image(path:String, ?library:Null<String>) {
        return getAsset('images/$path.png', library);
    }

    public static function getSparrowAtlas(path:String, ?library:Null<String>) {
        return FlxAtlasFrames.fromSparrow(image(path, library), xml('images/$path', library));
    }

    public static function getPackerAtlas(path:String, ?library:Null<String>) {
        return FlxAtlasFrames.fromSpriteSheetPacker(image(path, library), txt('images/$path', library));
    }

    public static function getTextureAtlas(path:String, ?library:Null<String>) {
        return FlxAtlasFrames.fromTexturePackerJson(image(path, library), json('images/$path', library));
    }

    public static function sound(path:String, ?library:Null<String>) {
        return getAsset('sounds/$path.ogg', library);
    }

    public static function music(path:String, ?library:Null<String>) {
        return getAsset('music/$path.ogg', library);
    }

    public static function frag(path:String, ?library:Null<String>) {
        return getAsset('shaders/$path.frag', library);
    }

    public static function vert(path:String, ?library:Null<String>) {
        return getAsset('shaders/$path.vert', library);
    }

    public static function inst(song:String, ?library:Null<String> = "songs") {
        return getAsset('songs/$song/Inst.ogg', library);
    }

    public static function voices(song:String, ?library:Null<String> = "songs") {
        return getAsset('songs/$song/Voices.ogg', library);
    }

    public static function json(path:String, ?library:Null<String>) {
        return getAsset('$path.json', library);
    }

    public static function txt(path:String, ?library:Null<String>) {
        return getAsset('$path.txt', library);
    }

    public static function xml(path:String, ?library:Null<String>) {
        return getAsset('$path.xml', library);
    }

    public static function script(path:String, ?library:Null<String>) {
        for(extension in scriptExtensions) {
            var path:String = getAsset('$path.$extension', library);
            if(exists(path)) return path;
        }

        return getAsset('$path.hxs', library);
    }
}