package core.handlers;

interface MusicHandler {
    public function beatHit(value:Int):Void;
    public function stepHit(value:Int):Void;
    public function sectionHit(value:Int):Void;
}