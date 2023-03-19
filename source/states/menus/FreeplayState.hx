package states.menus;

import flixel.addons.ui.FlxUIInputText;
import music.Song.ChartFormat;
import flixel.util.FlxColor;
import states.MusicBeat.MusicBeatState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import states.PlayState;
import flixel.math.FlxMath;
import objects.ui.HealthIcon;
import openfl.media.Sound;
import sys.thread.Mutex;
import sys.thread.Thread;
import objects.fonts.Alphabet;
import flixel.group.FlxGroup.FlxTypedGroup;
import backend.Controls;

@:dox(hide) typedef SongMetadata = {
    var name:String;
    var ?displayName:Null<String>;
    var character:String;
    var difficulties:Array<String>;
    var ?bgColor:Null<FlxColor>;
    var ?bpm:Null<Float>;
    var ?chartFormat:Null<ChartFormat>;
}

class FreeplayState extends MusicBeatState {
    var bgTween:FlxTween;

    public var bg:FNFSprite;
    public var scoreBG:FlxSprite;
	public var scoreText:FlxText;
	public var diffText:FlxText;
    public var lerpScore:Float = 0;
	public var intendedScore:Int = 0;

    public var songs:Array<SongMetadata> = [];
    public var loadedSongs:Array<SongMetadata> = [];
    
    public var grpSongs:FlxTypedGroup<Alphabet>;
    public var grpIcons:FlxTypedGroup<HealthIcon>;

    public var curSelected:Int = 0;
    public var curDifficulty:Int = 1;

    public var curSongPlaying:Int = -1;

	public var songThread:Thread;
	public var threadActive:Bool = true;
	public var mutex:Mutex;
	public var songToPlay:Sound;

    public var searchingForSong:Bool = false;
    public var searchBox:FlxUIInputText;

    override function create() {
        super.create();

        DiscordRPC.changePresence(
			"In the Freeplay Menu", 
			null
		);

        if (FlxG.sound.music == null || (FlxG.sound.music != null && !FlxG.sound.music.playing))
			CoolUtil.playMusic(Paths.music("freakyMenu"));

        if(!runDefaultCode) return;

        mutex = new Mutex();

        bg = new FNFSprite().loadGraphic(Paths.image("menus/base/menuBGDesat"));
        bg.screenCenter();
        add(bg);

        add(grpSongs = new FlxTypedGroup<Alphabet>());
        add(grpIcons = new FlxTypedGroup<HealthIcon>());

        loadXML();
        reloadSongs();

        scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.antialiasing = false;
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

        var smallBannerBG = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 1, 0xFF000000);
        smallBannerBG.alpha = 0.6;
        smallBannerBG.scrollFactor.set();

        var smallBannerText = new FlxText(5, FlxG.height, 0, 'Press ${CoolUtil.keyToString(Controls.controlsList['SWITCH_MOD'][0])} to switch mods / Press ${CoolUtil.keyToString(Controls.controlsList['GAMEPLAY_MODIFIERS'][0])} to change gameplay modifiers / Press ${CoolUtil.keyToString(Controls.controlsList['SONG_SEARCH'][0])} to search for songs', 17);
        smallBannerText.setFormat(Paths.font("vcr.ttf"), 17, FlxColor.WHITE, RIGHT);
        smallBannerText.y -= smallBannerText.height + 5;
        smallBannerText.scrollFactor.set();

        smallBannerBG.scale.y = smallBannerText.height + 5;
        smallBannerBG.updateHitbox();
        smallBannerBG.y -= smallBannerBG.height;

        add(smallBannerBG);
        add(smallBannerText);

        searchBox = new FlxUIInputText(0, smallBannerBG.y, 450, "", 18, FlxColor.WHITE, FlxColor.BLACK);
        @:privateAccess {
            searchBox.fieldBorderSprite.alpha = 0.6;
            searchBox.backgroundSprite.alpha = 0;
        }
        searchBox.y -= (smallBannerBG.height + 10);
        searchBox.callback = (text:String, action:String) -> {
            reloadSongs(songs.filter((song:SongMetadata) -> {
                return song.displayName.toLowerCase().startsWith(text.toLowerCase());
            }));
            changeSelection();
        };
        searchBox.visible = false;
        add(searchBox);

        changeSelection();
        positionHighscore();
    }

    public function reloadSongs(?songs:Array<SongMetadata>) {
        if(songs == null) songs = this.songs;

        // Make a template song if none could load
        if(songs == null || songs.length < 1) songs = [{
            name: "No songs found",
            character: "face",
            difficulties: ["ERROR"]
        }];

        // Remove all of the songs
        grpSongs.forEach((a:Alphabet) -> {
            a.kill();
            a.destroy();
        });
        grpSongs.clear();

        grpIcons.forEach((a:HealthIcon) -> {
            a.kill();
            a.destroy();
        });
        grpIcons.clear();

        curSongPlaying = -1;
        curSelected = 0;

        // Reload the songs
        for(i => song in songs) {
            var songText = new Alphabet(0, (70 * i) + 30, Bold, (song.displayName != null) ? song.displayName : song.name);
            songText.isMenuItem = true;
            songText.targetY = i;
            songText.alpha = 0.6;
            songText.ID = i;
            grpSongs.add(songText);

            var icon = new HealthIcon().loadIcon(song.character);
            icon.tracked = songText;
            grpIcons.add(icon);
        }

        loadedSongs = songs;
    }

	public function positionHighscore() {
        scoreText.x = FlxG.width - scoreText.width - 6;
        scoreBG.scale.x = FlxG.width - scoreText.x + 6;
        scoreBG.x = FlxG.width - scoreBG.scale.x / 2;
        diffText.x = scoreBG.x + scoreBG.width / 2;
        diffText.x -= diffText.width / 2;
    }

    public function loadXML() {
        var path:String = Paths.xml("data/freeplaySongList", true);
        if(!FileSystem.exists(path)) return;

        try {
            var xml:Xml = Xml.parse(File.getContent(path)).firstElement();
            if(xml == null) return;

            var data = new haxe.xml.Access(xml);
            for (song in data.nodes.song) {
                var songName:String = song.has.name ? song.att.name : "???";
                songs.push({
                    name: songName,
                    displayName: (song.has.displayName && song.att.displayName != "") ? song.att.displayName : songName,
                    character: song.has.character ? song.att.character : "face",
                    difficulties: song.has.difficulties ? CoolUtil.trimArray(song.att.difficulties.split(",")) : ["easy", "normal", "hard"],
                    bgColor: song.has.bgColor ? FlxColor.fromString(song.att.bgColor) : 0xFF9271FD,
                    bpm: song.has.bpm ? Std.parseFloat(song.att.bpm) : 100,
                    chartFormat: song.has.chartFormat ? song.att.chartFormat : AUTO_DETECT
                });
            }
        } catch(e) {
            songs = [];
			WindowUtil.showMessage('Failed to load the freeplay song list XML', '$e', MSG_ERROR);
		}
    }

    public function toggleSongSearch() {
        searchingForSong = !searchingForSong;
        searchBox.visible = searchBox.hasFocus = searchingForSong;
        searchBox.text = "";
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(!runDefaultCode) return;

        if(controls.SONG_SEARCH && !searchBox.hasFocus)
            toggleSongSearch();

        if(!searchingForSong) {
            if(controls.GAMEPLAY_MODIFIERS) {
                persistentUpdate = false;
                persistentDraw = true;
                openSubState(new GameplayModifiers());
            }

            if(controls.ACCEPT) {
                threadActive = false;
                var selectedDiff:String = loadedSongs[curSelected].difficulties[curDifficulty];
                PlayState.SONG = Song.loadChart(loadedSongs[curSelected].name, selectedDiff);
                PlayState.isStoryMode = false;
                PlayState.campaignScore = 0;
                PlayState.storyDifficulty = selectedDiff;
                FlxG.switchState(new PlayState());
            }
            
            if(controls.SWITCH_MOD) {
                persistentUpdate = false;
                persistentDraw = true;
                openSubState(new ModSwitcher());
            }

            if(controls.UI_UP_P) changeSelection(-1);
            if(controls.UI_DOWN_P) changeSelection(1);

            if(FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);

            if(controls.UI_LEFT_P) changeDifficulty(-1);
            if(controls.UI_RIGHT_P) changeDifficulty(1);

            if(controls.BACK) {
                threadActive = false;
                CoolUtil.playMenuSFX(CANCEL);
                FlxG.switchState(new MainMenuState());
            }
        }

        // Update score text
        lerpScore = MathUtil.lerp(lerpScore, intendedScore, 0.4);
        scoreText.text = "PERSONAL BEST:" + Math.round(lerpScore);
        positionHighscore();

        // Play the song's inst with a thread
        mutex.acquire();
        if (songToPlay != null) {
            CoolUtil.playMusic(songToPlay);
            if (FlxG.sound.music.fadeTween != null) FlxG.sound.music.fadeTween.cancel();
            FlxG.sound.music.volume = 0.0;
            FlxG.sound.music.fadeIn(1.0, 0.0, 1.0);
            FlxG.sound.music.pitch = 1;
            Conductor.changeBPM(loadedSongs[curSelected].bpm);
            songToPlay = null;
        }
        mutex.release();
    }

    public function changeSelection(?change:Int = 0) {
        curSelected = FlxMath.wrap(curSelected + change, 0, grpSongs.length - 1);

        if(bgTween != null) bgTween.cancel();
        var color:FlxColor = (loadedSongs[curSelected].bgColor != null) ? loadedSongs[curSelected].bgColor : 0xFF9271FD;
        bgTween = FlxTween.color(bg, 0.35, bg.color, color);

        grpSongs.forEach((member:Alphabet) -> {
            member.targetY = member.ID - curSelected;
            member.alpha = (curSelected == member.ID) ? 1 : 0.6;
        });
        CoolUtil.playMenuSFX(SCROLL);
        changeDifficulty();
        changeSongPlaying();
    }

    function changeDifficulty(?change:Int = 0) {
        var diffs:Array<String> = loadedSongs[curSelected].difficulties;

        curDifficulty = FlxMath.wrap(curDifficulty + change, 0, diffs.length - 1);
        intendedScore = Highscore.getScore(loadedSongs[curSelected].name.toLowerCase(), diffs[curDifficulty]);

        var arrows:Array<String> = diffs.length <= 1 ? ["", ""] : ["< ", " >"];
        diffText.text = '${arrows[0]}${diffs[curDifficulty].toUpperCase()}${arrows[1]}';
        positionHighscore();
    }

    function changeSongPlaying() {
		if(songThread == null) {
			songThread = Thread.create(function() {
				while (true) {
					if (!threadActive) return;
					var index:Null<Int> = Thread.readMessage(false);
					if (index != null) {
						if (index == curSelected && index != curSongPlaying) {
							var inst:Sound = Sound.fromFile(Paths.songInst(loadedSongs[curSelected].name, true));
							if (index == curSelected && threadActive && FileSystem.exists(Paths.songVoices(loadedSongs[curSelected].name, true))) {
								mutex.acquire();
								songToPlay = inst;
								mutex.release();
								curSongPlaying = curSelected;
							}
						}
					}
				}
			});
		}
		songThread.sendMessage(curSelected);
	}
}