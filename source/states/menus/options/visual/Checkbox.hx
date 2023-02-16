package states.menus.options.visual;

import objects.ui.Checkbox as CheckboxSprite;

class Checkbox extends Option {
    public var saveData:String;
    public var callback:Bool->Void;

    /**
     * Whether or not this option was softcoded via a mod.
     */
    public var isModded:Bool = false;

    public var checkbox:CheckboxSprite;
    
    public function new(text:String, saveData:String, ?callback:Bool->Void) {
        super(text);
        this.saveData = saveData;
        this.callback = callback;

        alphabet.x += 120;
        alphabet.xAdd += 120;

        var value:Bool = false;
        if(Reflect.field(SettingsAPI, saveData) != null)
            value = Reflect.field(SettingsAPI, saveData);

        @:privateAccess {
            if(Reflect.field(SettingsAPI.__save.data, saveData) != null && Reflect.field(SettingsAPI, saveData) == null) {
                value = Reflect.field(SettingsAPI.__save.data, saveData);
                isModded = true;
            }
        }

        add(checkbox = new CheckboxSprite(0, 0, value));
        checkbox.tracked = alphabet;
        checkbox.trackingOffset.set(-120, -40);
        checkbox.trackingMode = LEFT;
    }

    override function select() {
        if(isModded) {
            @:privateAccess
            Reflect.setField(SettingsAPI.__save.data, saveData, !Reflect.field(SettingsAPI.__save.data, saveData));
        } else
            Reflect.setField(SettingsAPI, saveData, !Reflect.field(SettingsAPI, saveData));
        
        @:privateAccess
        checkbox.value = (isModded) ? Reflect.field(SettingsAPI.__save.data, saveData) : Reflect.field(SettingsAPI, saveData);

        if(callback != null)
            callback(checkbox.value);
    }
}