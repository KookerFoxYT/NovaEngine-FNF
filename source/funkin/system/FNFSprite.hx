package funkin.system;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxPoint;

@:dox(hide) enum abstract SpriteType(String) to String from String {
    var IMAGE = "IMAGE";
    var SPARROW = "SPARROW";
    var PACKER = "PACKER";
}

@:dox(hide) enum abstract AnimationContext(String) to String from String {
    var NORMAL = "NORMAL";
    var SING = "SING";
}

/**
 * An extension of `FlxSprite` with offsets for specific animations.
 */
 class FNFSprite extends flixel.FlxSprite {
    public var offsets:Map<String, FlxPoint> = [];
    
    /**
     * A function to load certain types of assets onto this sprite.
     * @param type The asset type.
     * @param path The path to the asset.
     */
    public function load(type:SpriteType, data:Dynamic) {
        switch(type) {
            case IMAGE: loadGraphic(data);
            case SPARROW, PACKER: frames = data;
            default:
                Console.error('$type isn\'t a valid type of image for this Sprite to load!');
        }
        return this;
    }

    override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String) {
        super.loadGraphic(Graphic, Animated, Width, Height, Unique, Key);
        return this;
    }

    override public function makeGraphic(width:Int, height:Int, color:FlxColor = FlxColor.WHITE, unique:Bool = false, ?key:Null<String>):FNFSprite {
        super.makeGraphic(width,height,color,unique,key);
        return this;
    }

    public function addAnim(name:String, prefix:String, fps:Int = 24, loop:Bool = false, ?offsets:FlxPoint) {
        animation.addByPrefix(name, prefix, fps, loop);

        // offsets are inverted becuase flixel is like
        // forward = negative, negative = forward
        // by default
        if(offsets != null)
            this.offsets.set(name, new FlxPoint(-offsets.x, -offsets.y));
        else
            this.offsets.set(name, new FlxPoint(0, 0));
    }

    public function addAnimByIndices(name:String, prefix:String, indices:Array<Int>, fps:Int = 24, loop:Bool = false, ?offsets:FlxPoint) {
        animation.addByIndices(name, prefix, indices, "", fps, loop);

        // offsets are inverted becuase flixel is like
        // forward = negative, negative = forward
        // by default
        if(offsets != null)
            this.offsets.set(name, new FlxPoint(-offsets.x, -offsets.y));
        else
            this.offsets.set(name, new FlxPoint(0, 0));
    }

    public function setOffset(name:String, x:Float = 0, y:Float = 0) {
        // offsets are inverted becuase flixel is like
        // forward = negative, negative = forward
        // by default
        this.offsets.set(name, new FlxPoint(-x, -y));
    }

    public var lastAnimContext:AnimationContext = NORMAL;

    public function playAnim(name:String, force:Bool = false, ?context:AnimationContext = NORMAL, reversed:Bool = false, frame:Int = 0) {
        if(!animation.exists(name)) return Console.warn('Animation "$name" doesn\'t exist!');
        lastAnimContext = context;
        animation.play(name, force, reversed, frame);
        if(offsets.exists(name))
            offset.copyFrom(offsets[name]);
        else
            offset.set(0, 0);
    }
}