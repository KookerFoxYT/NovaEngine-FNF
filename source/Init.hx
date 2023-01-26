package;

import core.Controls;
import flixel.FlxState;

class Init extends FlxState {
    override function create() {
        Logs.init();
        Controls.init();
        SettingsAPI.init();
        Conductor.init();

        FlxG.fixedTimestep = false;

        FlxG.signals.preStateCreate.add((state:FlxState) -> {
            Paths.assetCache.clear();
            Controls.load();
            SettingsAPI.load();
            Conductor.reset();
            FlxSprite.defaultAntialiasing = SettingsAPI.antialiasing;
        });

        trace("testing trace lmao!");

        FlxG.switchState(new states.menus.TitleState());
    }
}