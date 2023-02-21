package core.dependency.scripting.events;

import states.PlayState;
import core.song.Ranking;
import objects.*;
import objects.ui.*;

class NoteHitEvent extends CancellableEvent {
    /**
     * The note that belongs to this event.
     * Modify it in anyway you like.
     */
    public var note:Note;

    /**
     * The data for the judgement/rating you got hitting this note.
     * Includes things like the timing, score, and rating.
     */
    public var judgeData:Judgement;

    /**
     * The rating you got when hitting this note.
     * Defaults are `sick`, `good`, `bad`, and `shit`.
     */
    public var rating:String = "sick";

    /**
	 * The path to the sprites used for note ratings.
	 */
    public var ratingSprites:String = 'game/${PlayState.assetModifier}/${PlayState.changeableSkin}/ratings';

     /**
      * The path to the sprites used for note combo.
      */
    public var comboSprites:String = 'game/${PlayState.assetModifier}/${PlayState.changeableSkin}/combo';
 
    public var ratingAntialiasing:Bool = true;
    public var comboAntialiasing:Bool = true;

    public var ratingScale:Float = 0.7;
    public var comboScale:Float = 0.5;

    /**
     * The accuracy you gained when hitting this note.
     */
    public var accuracy:Float = 1;

    /**
     * The score you got when hitting this note.
     */
    public var score:Int;

    /**
     * Whether or not the characters shouldn't sing when hitting this note.
     */
    public var cancelSingAnim:Bool = false;

    /**
     * Whether or not a splash should be shown when the note is hit.
     */
    public var showSplash:Bool = false;

    /**
     * Whether or not your combo should go up when hitting this note.
     */
    public var countAsCombo:Bool = true;

    /**
     * Whether or not your rating should show up when hitting this note.
     */
    public var showRating:Bool = true;

    /**
     * Whether or not your combo should show up when hitting this note.
     */
    public var showCombo:Bool = true;

    /**
     * The amount of health you gain from hitting this note.
     */
    public var healthGain:Float = 0.023 * SettingsAPI.healthGainMultiplier;

    /**
     * The characters that pressed the note.
     * Defaults to only the Opponent or Player. (based on current section)
     */
    public var characters:Array<Character>;

    public function new(note:Note, judgeData:Judgement, score:Int, showSplash:Bool) {
        super();
        this.note = note;
        this.judgeData = judgeData;
        this.healthGain += judgeData.health;
        this.rating = judgeData.name;
        this.accuracy = judgeData.accuracy;
        this.score = score;
        this.showSplash = showSplash;
        this.cancelSingAnim = (note.noteType == "No Animation");
    }
}