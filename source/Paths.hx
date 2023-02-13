package;

import core.modding.ModUtil;
import openfl.utils.Assets;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import core.dependency.CacheManager;
import core.utilities.IniParser;

enum abstract DirectoryFilter(Int) to Int from Int {
    var DIRS_AND_FILES = 0;
    var DIRS_ONLY = 1;
    var FILES_ONLY = 2;
}

class Paths {
    public static var assetCache:Cache = new Cache();

    public static var scriptExts:Array<String> = ["hx", "hxs", "hsc", "hscript", "lua"];

    public static final FALLBACK_XML:String = '<?xml version="1.0" encoding="utf-8"?>
    <TextureAtlas imagePath="fallback.png">
        <SubTexture name="fallback0000" x="0" y="0" width="16" height="16"/>
    </TextureAtlas>';

    // Functions that return data only
    public static function returnGraphic(path:String):Dynamic {
        if(!assetCache.exists(path)) {
            var bitmap = BitmapData.fromFile(path);
            if(bitmap == null) bitmap = Assets.getBitmapData("flixel/images/logo/default.png");

            var graphic = FlxGraphic.fromBitmapData(bitmap, false, path, false);
            graphic.persist = true;
            graphic.destroyOnNoUse = false;
            assetCache.set(path, new CacheAsset(graphic, IMAGE));
        }
        return assetCache.get(path).value;
    }

    public static function returnSound(path:String):Dynamic {
        if(!assetCache.exists(path))
            assetCache.set(path, new CacheAsset(Sound.fromFile(path), SOUND));
        
        return assetCache.get(path).value;
    }

    public static function returnText(path:String):Dynamic {
        if(!assetCache.exists(path))
            assetCache.set(path, new CacheAsset(FileSystem.exists(path) ? File.getContent(path) : "", TEXT));
        
        return assetCache.get(path).value;
    }

    public static function returnJSON(path:String):Dynamic {
        if(!assetCache.exists(path))
            assetCache.set(path, new CacheAsset(try {
                if(!FileSystem.exists(path))
                    Logs.trace("JSON at path: "+path+" doesn't exist!", ERROR);

                Json.parse(FileSystem.exists(path) ? File.getContent(path) : '{"error":null}');
            } 
            catch(e) {
                Logs.trace("Error occured while loading JSON at path: "+path+" - "+e, ERROR);
                {error:null};
            }, 
            JSON));
        
        return assetCache.get(path).value;
    }

    public static function returnINI(path:String):Dynamic {
        if(!assetCache.exists(path))
            assetCache.set(path, new CacheAsset(IniParser.parse(File.getContent(path)), INI));
        
        return assetCache.get(path).value;
    }

    // Useful functions
    public static function getFolderContents(path:String, ?returnFullPath:Bool = false, ?directoryFilter:DirectoryFilter = DIRS_AND_FILES):Array<String> {
        path = getPath(path);
        if(!FileSystem.exists(path)) return [];

        var coolList:Array<String> = [];

        for(item in FileSystem.readDirectory(path)) {
            var fullPath:String = '$path/$item';
            if(!FileSystem.exists(fullPath))
                continue;

            switch(directoryFilter) {
                case FILES_ONLY:
                    if(FileSystem.isDirectory(fullPath))
                        continue;

                case DIRS_ONLY:
                    if(!FileSystem.isDirectory(fullPath))
                        continue;

                default: // fuck you
            }

            coolList.push(returnFullPath ? fullPath : item);
        }

        return coolList;
    }

    // Functions that can return a path only when needed or data (default)
    public static function getPath(path:String, ?mod:Null<String>) {
        if(mod == null) mod = ModUtil.currentMod;

        var pathFromMod:String = './mods/$mod/$path';
        if(FileSystem.exists(pathFromMod))
            return pathFromMod;
        
        return './assets/$path';
    }

    public static function font(path:String) return getPath('fonts/$path');
    public static function video(path:String) return getPath('videos/$path.mp4');

    public static function image(path:String, ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var p:String = getPath('images/$path.png', mod);
        return pathOnly ? p : returnGraphic(p);
    }

    public static function getSparrowAtlas(path:String, ?mod:Null<String>):FlxAtlasFrames {
        var xmlData:String = xml('images/$path', mod);
        return FlxAtlasFrames.fromSparrow(image(path, false, mod), xmlData.length > 0 ? xmlData : FALLBACK_XML);
    }

    public static function getPackerAtlas(path:String, ?mod:Null<String>):FlxAtlasFrames {
        var txtData:String = txt('images/$path');
        if(txtData.length > 0)
            return FlxAtlasFrames.fromSpriteSheetPacker(image(path, false, mod), txtData);

        return FlxAtlasFrames.fromSparrow(image(path, false, mod), FALLBACK_XML);
    }

    public static function songInst(song:String, ?diff:String = "normal", ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var songPaths:Array<String> = [
            getPath('songs/${song.toLowerCase()}/Inst-$diff.ogg', mod)
        ];
        for(p in songPaths) {
            if(FileSystem.exists(p))
                return pathOnly ? p : returnSound(p);
        }
        var p:String = getPath('songs/${song.toLowerCase()}/Inst.ogg', mod);
        return pathOnly ? p : returnSound(p);
    }

    public static function songVoices(song:String, ?diff:String = "normal", ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var songPaths:Array<String> = [
            getPath('songs/${song.toLowerCase()}/Voices-$diff.ogg', mod)
        ];
        for(p in songPaths) {
            if(FileSystem.exists(p))
                return pathOnly ? p : returnSound(p);
        }
        var p:String = getPath('songs/${song.toLowerCase()}/Voices.ogg', mod);
        return pathOnly ? p : returnSound(p);
    }

    public static function music(path:String, ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var p:String = getPath('music/$path.ogg', mod);
        return pathOnly ? p : returnSound(p);
    }

    public static function sound(path:String, ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var p:String = getPath('sounds/$path.ogg', mod);
        return pathOnly ? p : returnSound(p);
    }

    public static function soundRandom(path:String, min:Int, max:Int, ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        return sound(path + FlxG.random.int(min, max), pathOnly, mod);
    }

    public static function txt(path:String, ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var p:String = getPath('$path.txt', mod);
        return pathOnly ? p : returnText(p);
    }

    public static function xml(path:String, ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var p:String = getPath('$path.xml', mod);
        return pathOnly ? p : returnText(p);
    }

    public static function ini(path:String, ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var p:String = getPath('$path.ini', mod);
        return pathOnly ? p : returnINI(p);
    }

    public static function json(path:String, ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var p:String = getPath('$path.json', mod);
        return pathOnly ? p : returnJSON(p);
    }

    public static function frag(path:String, ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var p:String = getPath('$path.frag', mod);
        return pathOnly ? p : returnText(p);
    }

    public static function vert(path:String, ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var p:String = getPath('$path.vert', mod);
        return pathOnly ? p : returnText(p);
    }

    public static function script(path:String, ?pathOnly:Bool = true, ?mod:Null<String>):Dynamic {
        for(ext in scriptExts) {
            var pathToCheck:String = getPath('$path.$ext', mod);
            if(FileSystem.exists(pathToCheck))
                return pathOnly ? pathToCheck : returnText(pathToCheck);
        }

        var p:String = getPath('$path.hx', mod);
        return pathOnly ? p : returnText(p);
    }

    public static function songJson(song:String, ?diff:String = "normal", ?pathOnly:Bool = false, ?mod:Null<String>):Dynamic {
        var songPaths:Array<String> = [
            getPath('songs/$song/$song-$diff.json', mod),
            getPath('data/$song/$song-$diff.json', mod),
            getPath('data/$song/$diff.json', mod),
            getPath('data/charts/$song/$diff.json', mod),
            getPath('data/charts/$song/$song-$diff.json', mod),
        ];
        for(p in songPaths) {
            if(FileSystem.exists(p))
                return pathOnly ? p : returnJSON(p);
        }
        var p:String = getPath('songs/$song/$diff.json', mod);
        return pathOnly ? p : returnJSON(p);
    }
}