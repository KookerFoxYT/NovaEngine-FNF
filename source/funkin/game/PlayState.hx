package funkin.game;

import flixel.addons.transition.FlxTransitionableState;
import funkin.system.FNFSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.FlxCamera;
import flixel.system.FlxSound;
import funkin.system.Conductor;
import funkin.system.MusicBeatState;
import funkin.scripting.ScriptHandler;
import funkin.scripting.ScriptPack;
import funkin.scripting.events.*;
import funkin.cutscenes.*;
import flixel.math.FlxMath;
import funkin.game.Song;
import haxe.io.Path;

using StringTools;

enum abstract CharacterType(String) to String from String {
	var DAD = "DAD";
	var OPPONENT = "OPPONENT";
	var GF = "GF";
	var GIRLFRIEND = "GIRLFRIEND";
	var SPEAKERS = "SPEAKERS";
	var BF = "BF";
	var PLAYER = "PLAYER";
	var BOYFRIEND = "BOYFRIEND";
}

class PlayState extends MusicBeatState {
	/**
	 * The currently loaded song data.
	 */
	public static var SONG:Song;
	public static var current:PlayState;

	// Stage
	/**
	 * The stage.
	 */
	public var stage:Stage;

	/**
	 * The default zoom for the game camera.
	 */
	public var defaultCamZoom:Float = 1.05;

	// Game
	/**
	 * Whether or not we're playing a week in story mode.
	 */
	public static var isStoryMode:Bool = false;

	/**
	 * Score for the current week.
	 */
	public static var campaignScore:Int = 0;

	/**
	 * Zoom for the pixel assets.
	 */
	public static var daPixelZoom:Float = 6;

	/**
	 * Whenever the game should play the cutscenes. Defaults to whenever the game is currently in Story Mode or not.
	 */
	public var playCutscenes:Bool = isStoryMode;

	/**
	 * Controls whether or not we are in a cutscene.
	 */
	public var inCutscene:Bool = false;

	/**
	 * A pack of scripts for the stage and song
	 */
	public var scripts:ScriptPack;

	/**
	 * Whenever the game is in downscroll or not. (Can be set)
	 */
	public var downscroll(get, set):Bool;

	/**
	 * Controls how fast the notes move.
	 */
	public var scrollSpeed:Float = 2.7;

	function get_downscroll():Bool {
		return camHUD.downscroll;
	}
	function set_downscroll(v:Bool) {
		return camHUD.downscroll = v;
	}
	
	/**
	 * The camera for the UI (score, notes, time, etc)
	 */
	public var camHUD:HUDCamera;
	
	public var camOther:FlxCamera;

	public var UI:UIGroup;

	/**
	 * Vocals sound (Voices.ogg).
	 */
	public var vocals:FlxSound;

	/**
	 * Whether or not the song is starting.
	 */
	public var startingSong:Bool = true;

	/**
	 * Whether or not the song is ending.
	 */
	public var endingSong:Bool = false;

	/**
	 * Length of the intro countdown.
	 */
	public var introLength:Int = 5;

	/**
	 * Array of sprites for the intro.
	 */
	public var introSprites:Array<String> = [
		null, 
		"game/countdown/default/ready", 
		"game/countdown/default/set", 
		"game/countdown/default/go"
	];

	 /**
	  * Array of sounds for the intro.
	  */
	public var introSounds:Array<String> = [
		"game/countdown/default/intro3", 
		"game/countdown/default/intro2", 
		"game/countdown/default/intro1", 
		"game/countdown/default/introGo"
	];

	/**
	 * Whether or not the camera should zoom in every 4 beats.
	 */
	public var camBumping:Bool = true;

	/**
	 * How much the camera should zoom to the beat.
	 * 4 = Every 4 beats.
	 * 2 = Every 2 beats.
	 * 1 = Every beat.
	 */
	public var camBumpingInterval:Int = 4;

	/**
	 * Whether or not the camera should zoom out after bumping.
	 */
	public var camZooming:Bool = true;

	/**
	 * Dad character
	 */
	public var dad:Character;
	public var dads:Array<Character> = [];

	/**
	 * Girlfriend character
	 */
	public var gf:Character;
	public var gfs:Array<Character> = [];

	/**
	 * Boyfriend character
	 */
	public var boyfriend:Character;
	public var boyfriends:Array<Character> = [];

	/**
	 * Boyfriend character
	 */
	public var bf(get, set):Character;
	function get_bf():Character {
		return boyfriend;
	}
	function set_bf(newChar:Character):Character {
		return boyfriend = newChar;
	}

	public var bfs(get, set):Array<Character>;
	function get_bfs():Array<Character> {
		return boyfriends;
	}
	function set_bfs(newChars:Array<Character>):Array<Character> {
		return boyfriends = newChars;
	}

	/**
	 * The amount of health the player has.
	 * Limited to the values of `minHealth` and `maxHealth`.
	 */
	public var health(default, set):Float = 1;
	function set_health(value:Float) {
		return health = FlxMath.bound(value, minHealth, maxHealth);
	}

	/**
	 * The minimum amount of health the player can have.
	 */
	public var minHealth:Float = 0;

	/**
	 * The maximum amount of health the player can have.
	 */
	public var maxHealth:Float = 2;

	/**
	 * Cutscene script path.
	 */
	public var cutscene:String = null;

	/**
	 * End cutscene script path.
	 */
	public var endCutscene:String = null;

	/**
	 * A map containing all scripts for note types.
	 */
	public var noteTypes:Map<String, ScriptModule> = [];

	override function create() {
		super.create();
		
		current = this;

		(scripts = new ScriptPack()).setParent(this);

		// CACHING && LOADING!!!

		camHUD = new HUDCamera();
		camHUD.bgColor = 0x0;
		FlxG.cameras.add(camHUD, false);

		camOther = new FlxCamera();
		camOther.bgColor = 0x0;
		FlxG.cameras.add(camOther, false);

		downscroll = Preferences.save.downscroll;

		if(SONG == null)
			SONG = ChartLoader.load(FNF, Paths.chart("tutorial"));

		Conductor.bpm = SONG.bpm;
		Conductor.mapBPMChanges(SONG);
		Conductor.position = -90000;

		FlxG.sound.playMusic(Paths.inst(SONG.name), 0, false);
		FlxG.sound.list.add(vocals = (Paths.exists(Paths.voices(SONG.name)) ? new FlxSound().loadEmbedded(Paths.voices(SONG.name), false) : new FlxSound()));

		add(stage = new Stage("default"));
		add(stage.dadLayer);
		add(stage.gfLayer);
		add(stage.bfLayer);

		add(gf = new Character(stage.gfPos.x, stage.gfPos.y, "gf"));
		add(dad = new Character(stage.dadPos.x, stage.dadPos.y, "dad"));
		add(boyfriend = new Character(stage.bfPos.x, stage.bfPos.y, "bf", true));

		gfs = [gf];
		dads = [dad];
		boyfriends = [bf];

		// Load global song scripts
		for(item in Paths.getFolderContents("songs", true, true)) {
			for(extension in Paths.scriptExtensions) {
				if(item.endsWith("."+extension))
					scripts.add(ScriptHandler.loadModule(item));
			}
		}

		// Load song specific scripts
		for(item in Paths.getFolderContents('songs/${SONG.name.toLowerCase()}', true, true)) {
			for(extension in Paths.scriptExtensions) {
				if(item.endsWith("."+extension))
					scripts.add(ScriptHandler.loadModule(item));
			}
		}

		// Load note types
		for(item in Paths.getFolderContents('data/notetypes', true, true)) {
			for(extension in Paths.scriptExtensions) {
				if(item.endsWith("."+extension)) {
					var typeName:String = Path.withoutDirectory(item.removeExtension());
					var script = ScriptHandler.loadModule(item);
					script.load();
					script.call("onCreate");
					noteTypes[typeName] = script;
				}
			}
		}

		// END OF CACHING & LOADING!

		scripts.load();
		scripts.call("onCreate");
		FlxG.camera.zoom = defaultCamZoom;

		add(UI = new UIGroup());
		UI.cameras = [camHUD];

		var oldNotes:Array<Note> = [];
		for(section in SONG.sections) {
			if(section == null) continue;
			for(i => note in section.notes) {
				var mustHit:Bool = section.playerSection;
				if (note.direction > (SONG.keyAmount - 1)) mustHit = !section.playerSection;

				var strumLine:StrumLine = mustHit ? UI.playerStrums : UI.cpuStrums;
				var prevNote:Note = oldNotes.length > 0 ? oldNotes.last() : null;

				var realNote:Note = GameplayUtil.generateNote(note.strumTime, strumLine.keyAmount, note.direction, SONG.noteSkin, mustHit, note.altAnim, strumLine, note.type);
				realNote.prevNote = prevNote;
				oldNotes.push(realNote);
				strumLine.notes.add(realNote);

				var susLength:Float = note.sustainLength / Conductor.stepCrochet;
				if(susLength > 0.75) susLength++;

				var flooredSus:Int = Math.floor(susLength);
				if(flooredSus > 0) {
					for(sus in 0...flooredSus) {
						prevNote = oldNotes.last();
						var susNote:Note = GameplayUtil.generateNote(note.strumTime + (Conductor.stepCrochet * sus), strumLine.keyAmount, note.direction, SONG.noteSkin, mustHit, note.altAnim, strumLine, note.type);
						susNote.isSustainNote = true;
						susNote.stepCrochet = Conductor.stepCrochet;
						susNote.isSustainTail = sus >= flooredSus-1;
						susNote.alpha = 0.6;
						susNote.playCorrectAnim();
						susNote.prevNote = prevNote;
						oldNotes.push(susNote);
						strumLine.notes.add(susNote);
					}
				}
			}
		}

		UI.cpuStrums.notes.sortNotes();
		UI.playerStrums.notes.sortNotes();
	}

	public function switchIcon(player:Int, name:String) {
		switch(player) {
			case 0: 
				UI.iconP2.loadIcon(name);
				UI.iconP2.scale.set(1, 1);
				UI.iconP2.updateHitbox();
				UI.iconP2.y = UI.healthBar.y - (UI.iconP2.height * 0.5);

			default:
				UI.iconP1.loadIcon(name);
				UI.iconP1.scale.set(1, 1);
				UI.iconP1.updateHitbox();
				UI.iconP1.y = UI.healthBar.y - (UI.iconP1.height * 0.5);
		}
	}

	override function createPost() {
		startCutscene();
		super.createPost();
		scripts.call("onCreatePost");
	}

	public function callOnNoteType(noteType:String, method:String, ?parameters:Array<String>) {
		if(!noteTypes.exists(noteType)) return;
		noteTypes[noteType].call(method, parameters);
	}

	public function eventOnNoteType<T:CancellableEvent>(noteType:String, method:String, event:T):T {
		if(!noteTypes.exists(noteType)) return event;
		noteTypes[noteType].call(method, [event]);
		return event;
	}

	public function characterSing(?type:Null<CharacterType>, ?keyAmount:Null<Int> = 4, noteData:Int, ?suffix:String = "") {
		if(type == null) type = DAD;
		if(keyAmount == null) keyAmount = 4;

		switch(type) {
			case DAD, OPPONENT: 
				for(character in dads)
					character.playAnim(Note.getSingAnim(keyAmount, noteData)+suffix, true);

			case GF, GIRLFRIEND, SPEAKERS:
				for(character in gfs)
					character.playAnim(Note.getSingAnim(keyAmount, noteData)+suffix, true);

			case BF, PLAYER, BOYFRIEND:
				for(character in boyfriends)
					character.playAnim(Note.getSingAnim(keyAmount, noteData)+suffix, true);
		}
	}

	public function startCutscene() {
		// If we're not allowed to play a cutscene
		// Then just start the countdown instead
		// if(!playCutscenes) {
		// 	startCountdown();
		// 	return;
		// }

		var videoCutscene = Paths.video('${PlayState.SONG.name.toLowerCase()}-cutscene');
		persistentUpdate = false;
		if (cutscene != null) {
			openSubState(new ScriptedCutscene(cutscene, function() {
				startCountdown();
			}));
		} 
		else if (Paths.exists(videoCutscene)) {
			FlxTransitionableState.skipNextTransIn = true;
			inCutscene = true;
			openSubState(new VideoCutscene(videoCutscene, function() {
				startCountdown();
			}));
			persistentDraw = false;
		} 
		else
			startCountdown();
	}

	public function startCountdown() {
		Conductor.position = Conductor.crochet * -5;
		inCutscene = false;

		var swagCounter:Int = 0;

		new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			for(character in dads) character.dance();
			for(character in gfs) character.dance();
			for(character in bfs) character.dance();
			countdown(swagCounter++);
		}, introLength);
	}

	public function countdown(swagCounter:Int) {
		var event:CountdownEvent = scripts.event("onCountdown", new CountdownEvent(
			swagCounter, 
			introSprites[swagCounter],
			introSounds[swagCounter],
			1, 1, true
		));

		var sprite:FNFSprite = null;
		var sound:FlxSound = null;
		var tween:FlxTween = null;

		if (!event.cancelled) {
			if (event.spritePath != null) {
				var spr = event.spritePath;
				if (!Assets.exists(spr)) spr = Paths.image('$spr');

				sprite = new FNFSprite().load(IMAGE, spr);
				sprite.scrollFactor.set();
				sprite.scale.set(event.scale, event.scale);
				sprite.updateHitbox();
				sprite.screenCenter();
				add(sprite);
				tween = FlxTween.tween(sprite, {alpha: 0}, Conductor.crochet / 1000, {
					ease: FlxEase.cubeInOut,
					onComplete: function(twn:FlxTween) {
						sprite.destroy();
					}
				});
			}
			if (event.soundPath != null) {
				var sfx = event.soundPath;
				if (!Assets.exists(sfx)) sfx = Paths.sound(sfx);
				sound = FlxG.sound.play(sfx, event.volume);
			}
		}
		event.sprite = sprite;
		event.sound = sound;
		event.spriteTween = tween;
		event.cancelled = false;

		scripts.event("onCountdownPost", event);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false) {
		endingSong = true;
		FlxG.sound.music.onComplete = null;

        persistentUpdate = false;
        persistentDraw = true;

		if((Preferences.save.noteOffset * FlxG.sound.music.pitch) <= 0 || ignoreNoteOffset) {
			endSong();
		} else {
			new FlxTimer().start((Preferences.save.noteOffset * FlxG.sound.music.pitch) / 1000, function(tmr:FlxTimer) {
				endSong();
			});
		}
	}

	public function endSong() {
		if(inCutscene) return;
		
		endingSong = true;

		// story mode prob gonna be added last

		var ret:Dynamic = scripts.call("onEndSong", [], true);
        if(ret != false) {
			if(FlxG.sound.music != null) FlxG.sound.music.stop();
			if(vocals != null) vocals.stop();

			CoolUtil.playMusic(Paths.music("freakyMenu"));
			FlxG.sound.music.time = 0;
			FlxG.switchState(new funkin.menus.FreeplayState());
		}
	}

	public function startSong() {
		startingSong = false;
		
		FlxG.sound.music.pause();
		FlxG.sound.music.time = Conductor.position = 0;
		FlxG.sound.music.onComplete = finishSong.bind();
		FlxG.sound.music.volume = 1;
		FlxG.sound.music.play();
		vocals.play();

		scripts.call("onStartSong");
	}

	public function resyncVocals() {
		@:privateAccess
		if(vocals._sound != null && SONG.needsVoices) {
            FlxG.sound.music.pause();
            vocals.pause();

            Conductor.position = FlxG.sound.music.time;
            vocals.time = FlxG.sound.music.time;

            if(vocals.time < vocals.length)
                vocals.play();

            FlxG.sound.music.play();
		} 
		else 
			Conductor.position = FlxG.sound.music.time;

		scripts.call("onResyncVocals");
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		scripts.call("onUpdate", [elapsed]);

		vocals.pitch = FlxG.sound.music.pitch;
		if(!inCutscene && !endingSong) Conductor.position += (elapsed * 1000) * FlxG.sound.music.pitch;
		if(Conductor.position >= 0 && startingSong && !inCutscene) startSong();

		if(camZooming) {
			FlxG.camera.zoom = MathUtil.fixedLerp(FlxG.camera.zoom, defaultCamZoom, 0.05);
			camHUD.zoom = MathUtil.fixedLerp(camHUD.zoom, camHUD.initialZoom, 0.05);
		}

		if(UI.playerStrums.input.pressed.contains(true)) {
			for(character in bfs)
				character.holdTimer = 0;
		}
		else if(!UI.playerStrums.input.pressed.contains(true) && boyfriend.lastAnimContext == SING && boyfriend.holdTimer >= Conductor.stepCrochet * boyfriend.singDuration * 0.0011) {
			for(character in bfs)
				character.dance();
		}

		// If the vocals are out of sync, resync them!
		@:privateAccess
		var shouldResync = (vocals._sound != null && SONG.needsVoices && vocals.time < vocals.length) ? !Conductor.isAudioSynced(vocals) : !Conductor.isAudioSynced(FlxG.sound.music);
		if(shouldResync && !startingSong && !endingSong && !inCutscene) resyncVocals();

		scripts.call("onUpdatePost", [elapsed]);
	}

	@:dox(hide) override function beatHit(curBeat:Int) {
		if(camBumpingInterval < 1) camBumpingInterval = 1;
		if(camBumping && FlxG.camera.zoom < 1.35 && curBeat % camBumpingInterval == 0) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}
		scripts.call("onBeatHit", [curBeat]);
		super.beatHit(curBeat);
	}

	@:dox(hide) override function stepHit(curStep:Int) {
		scripts.call("onStepHit", [curStep]);
		super.stepHit(curStep);
	}

	@:dox(hide) override function sectionHit(curSection:Int) {
		if(SONG.sections[curSection] != null && SONG.sections[curSection].changeBPM)
			Conductor.bpm = SONG.sections[curSection].bpm;

		scripts.call("onSectionHit", [curSection]);
		super.sectionHit(curSection);
	}

	override function destroy() {
		current = null;
		scripts.call("onDestroy");
		scripts.destroy();
		super.destroy();
	}
}
