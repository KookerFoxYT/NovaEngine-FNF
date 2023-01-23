package funkin.scripting.events;

import funkin.game.Note;

class GhostTapEvent extends CancellableEvent {
    /**
     * The amount of health you lose when missing this note.
     */
    public var healthLoss:Float = 0.0475;

    /**
     * Whether or not the player should play a singing animation
     * when hitting this note.
     */
    public var cancelSingAnim:Bool = false;

    public function new(?healthLoss:Float = 0) {
        super();
        this.healthLoss = healthLoss;
    }
}