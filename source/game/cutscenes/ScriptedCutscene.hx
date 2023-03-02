package game.cutscenes;

import backend.scripting.DummyScript;
import backend.dependency.ScriptHandler;

/**
 * A cutscene with a script attached to it.
 * Make sure to do `inCutscene = true;` to let the game know we're in a cutscene!
 * 
 * If you wanna play a video, do `playVideo(Paths.video("path/video.ext"));`!
 */
class ScriptedCutscene extends Cutscene {
    var scriptPath:String;
    
    public function new(scriptPath:String, callback:Void->Void) {
        super(callback);
        this.scriptPath = scriptPath;

        script = ScriptHandler.loadModule(Paths.script('data/cutscenes/$scriptPath'));
        script.setParent(this);
        script.call("onCreate", []);
    }

    override function create() {
        super.create();
        if (script is DummyScript) {
            Logs.trace('Could not find script for scripted cutscene at data/cutscenes/$scriptPath', ERROR);
            close();
        }
    }

    public function startVideo(path:String, ?callback:Void->Void) {
        #if VIDEO_CUTSCENES
        var sprite = new VideoSprite();
        sprite.cameras = [game.camOther];
        sprite.finishCallback = () -> {
            sprite.kill();
            sprite.destroy();
            game.remove(sprite, true);
            close();
        }
        sprite.play(path, false);
        game.add(sprite);
        #else
        close();
        #end
    }
}