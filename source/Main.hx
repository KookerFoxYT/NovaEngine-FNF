package;

import flixel.FlxGame;
import flixel.math.FlxMath;
import openfl.display.Sprite;

class Main extends Sprite {
	public static var gameSettings = {
		width: 1280,
		height: 720,
		framerate: 1000,
		skipSplash: true,
		fullscreen: false
	};

	public static var engineName:String = "Nova Engine";
	public static var engineVersion(get, never):String;
	private static function get_engineVersion():String {
		return lime.app.Application.current.meta.get("version");
	}

	public static var fpsOverlay:FPSOverlay;

	public static function framerateAdjust(input:Float) {
		return FlxMath.bound(FlxG.elapsed * 60 * input, 0, 1);
	}

	public function new() {
		super();
		addChild(new FlxGame(gameSettings.width, gameSettings.height, Init, gameSettings.framerate, gameSettings.framerate, gameSettings.skipSplash, gameSettings.fullscreen));
		addChild(fpsOverlay = new FPSOverlay(10, 3));
	}
}
