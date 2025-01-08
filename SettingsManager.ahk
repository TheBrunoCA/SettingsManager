#Requires AutoHotkey v2

#Include utils\MapRedefined.ahk
#Include utils\ArrayRedefined.ahk

_valueOrCallback(item) {
    if item is Func
        return item.Call()
    return item
}

class SettingsItemTypes {
    static EDIT := 'EDIT'
    static NUMBER := 'NUMBER'
    static CHECKBOX := 'CHECKBOX'
    static DROPDOWN := 'DROPDOWN'
    static FILE_PATH := 'FILE_PATH'
    static FOLDER_PATH := 'FOLDER_PATH'

    static TypeExists(_type) {
        return this.HasOwnProp(_type)
    }
}

/**
 * @description Represents a setting item
 */
class SettingsItem {

    /**
     * @description Creates a new instance of SettingsItem
     * @param {string|function} Name - The name of the setting, can be a callback expecting no parameters
     * @param {string|function} Type - The type of the setting, can be a callback expecting no parameters
     * @param {string|function} Section - The section of the setting, can be a callback expecting no parameters
     * @param {string|function} DefaultValue - The default value of the setting, can be a callback expecting no parameters
     * @param {string|function} HumanReadableName - The human readable name of the setting, can be a callback expecting no parameters
     * @param {string|function} HumanReadableDescription - The human readable description of the setting, can be a callback expecting no parameters
     * @param {string|fucntion} HumanReadableSection - The human readable section of the setting, can be a callback expecting no parameters
     * @param {string|function} DdlValues - The dropdown values, can be a callback expecting no parameters
     * @param {function} SaveCallback - When saving the setting, this callback will be called with the new value as a parameter and the return value will be saved
     * @param {function} OnSaveCallback - This callback will be called when the setting is saved with the new value as a parameter
     * @param {function} GetCallback - When getting the setting, this callback will be called with the currently stored value as a parameter and must return the value as the setting value
     * @param {function} OnGetCallback - This callback will be called when the setting is retrieved with the currently stored value as a parameter
     * @param {function} OnChangeCallback - This callback will be called when the setting is changed on the gui. Will receive the gui, control, value and the default callback parameters
     * @param {boolean|function} Required - Whether the setting is required, can be a callback expecting no parameters
     * @param {boolean|function} Visible - Whether the setting is visible, can be a callback expecting no parameters
     * @param {string|function} ExtraOptions - Extra options for the setting, can be a callback expecting no parameters
     * @param {string|fucntion} ButtonExtraOptions - Extra options for the button, can be a callback expecting no parameters. Only used for file and folder paths
     * @param {string|function} FontStyle - The font style of the setting, can be a callback expecting no parameters
     */
    __New(_name, _type, _section, _defaultValue, _humanReadableName?, _humanReadableDescription?, _humanReadableSection?,
        _ddlValues?, _saveCallback?, _onSaveCallback?,
        _getCallback?, _onGetCallback?,
        _onChangeCallback?, _required := false, _visible := true, _extraOptions?, _buttonExtraOptions?, _fontStyle?) {

        if !SettingsItemTypes.TypeExists(_type)
            throw Error("Invalid setting type: " _type)

        this._name := _name ?? ''
        this._type := _type ?? ''
        this._section := _section ?? ''
        this._defaultValue := _defaultValue ?? ''
        this._humanReadableName := _humanReadableName ?? ''
        this._humanReadableDescription := _humanReadableDescription ?? ''
        this._humanReadableSection := _humanReadableSection ?? ''
        this._ddlValues := _ddlValues ?? ''
        this.SaveCallback := _saveCallback ?? ''
        this.OnSaveCallback := _onSaveCallback ?? ''
        this.GetCallback := _getCallback ?? ''
        this.OnGetCallback := _onGetCallback ?? ''
        this.OnChangeCallback := _onChangeCallback ?? ''
        this._required := _required
        this._visible := _visible
        this._extraOptions := _extraOptions ?? ''
        this._buttonExtraOptions := _buttonExtraOptions ?? ''
        this._fontStyle := _fontStyle ?? ''
    }

    Name => _valueOrCallback(this._name)
    Type => _valueOrCallback(this._type)
    Section => _valueOrCallback(this._section)
    DefaultValue => _valueOrCallback(this._defaultValue)
    HumanReadableName => _valueOrCallback(this._humanReadableName)
    HumanReadableDescription => _valueOrCallback(this._humanReadableDescription)
    HumanReadableSection => _valueOrCallback(this._humanReadableSection)
    DdlValues => _valueOrCallback(this._ddlValues)
    Required => _valueOrCallback(this._required)
    Visible => _valueOrCallback(this._visible)
    ExtraOptions => _valueOrCallback(this._extraOptions)
    ButtonExtraOptions => _valueOrCallback(this._buttonExtraOptions)
    FontStyle => _valueOrCallback(this._fontStyle)
}

/**
 * @description Represents a settings manager
 */
class SettingsManager {
    static _defaultFilePath := A_WorkingDir '\config.ini'
    setDefaultFilePath(path) {
        SplitPath(path, , &OutDir)
        if !DirExist(OutDir) {
            try {
                DirCreate(OutDir)
            }
            catch as e {
                if this.loggerCallback
                    this.loggerCallback.Call("Failed to create directory: " OutDir)
                throw Error("Failed to create directory: " OutDir)
            }
        }
        SettingsManager._defaultFilePath := path
    }
    getDefaultFilePath() => SettingsManager._defaultFilePath

    static _defaultSchema := Map()
    setDefaultSchema(schema) {
        if !this.validateSchema(schema) {
            if this.loggerCallback
                this.loggerCallback.Call("Failed to set default schema")
            throw Error("Failed to set default schema")
        }
        SettingsManager._defaultSchema := schema
    }

    getDefaultSchema() => SettingsManager._defaultSchema
    addToDefaultSchema(key, item) {
        if !this.validateSchemaItem(item) {
            if this.loggerCallback
                this.loggerCallback.Call("Invalid schema item type: " Type(item))
            throw Error("Invalid schema item type: " Type(item))
        }
        SettingsManager._defaultSchema[key] := item
    }

    static _defaultGuiOptions := 'Resize -MinimizeBox -MaximizeBox'
    setDefaultGuiOptions(options) {
        SettingsManager._defaultGuiOptions := options
    }
    getDefaultGuiOptions() => SettingsManager._defaultGuiOptions

    static _defaultGuiFontStyle := 's10'
    setDefaultGuiFontStyle(style) {
        SettingsManager._defaultGuiFontStyle := style
    }
    getDefaultGuiFontStyle() => SettingsManager._defaultGuiFontStyle

    static _defaultGuiControlLeftMargin := 10
    setDefaultGuiControlLeftMargin(margin) {
        SettingsManager._defaultGuiControlLeftMargin := margin
    }
    getDefaultGuiControlLeftMargin() => SettingsManager._defaultGuiControlLeftMargin

    static _defaultGuiControlWidth := 300
    setDefaultGuiControlWidth(width) {
        SettingsManager._defaultGuiControlWidth := width
    }
    getDefaultGuiControlWidth() => SettingsManager._defaultGuiControlWidth

    static _defaultGuiYControlMargin := 15
    setDefaultGuiYControlMargin(margin) {
        SettingsManager._defaultGuiYControlMargin := margin
    }
    getDefaultGuiYControlMargin() => SettingsManager._defaultGuiYControlMargin

    static _defaultGuiWindowTitle := 'Settings'
    setDefaultGuiWindowTitle(title) {
        SettingsManager._defaultGuiWindowTitle := title
    }
    getDefaultGuiWindowTitle() => SettingsManager._defaultGuiWindowTitle

    static _defaultGuiDefaultTab := 1
    setDefaultGuiDefaultTab(tab) {
        SettingsManager._defaultGuiDefaultTab := tab
    }
    getDefaultGuiDefaultTab() => SettingsManager._defaultGuiDefaultTab

    /**
     * @description Creates a new instance of SettingsManager
     * @param {string|function} _configFilePath - The path to the config file, can be a callback expecting no parameters
     * @param {map} _schema - The schema, an map of SettingsItem objects
     * @param {string|function} _guiOptions - The options for the gui, can be a callback expecting no parameters
     * @param {string|function} _guiFontStyle - The font style for the gui, can be a callback expecting no parameters
     * @param {number|function} _guiControlLeftMargin - The left margin for the gui, can be a callback expecting no parameters
     * @param {number|function} _guiControlWidth - The width for the gui, can be a callback expecting no parameters
     * @param {number|function} _guiYControlMargin - The y margin for the gui controls, can be a callback expecting no parameters
     * @param {string|function} _guiWindowTitle - The window title for the gui, can be a callback expecting no parameters
     * @param {number|function} _guiDefaultTab - The default tab for the gui, can be a callback expecting no parameters
     * @param {function} _onGuiCloseCallback - The callback to be called when the gui is closed, will receive the gui as a parameter and other default callback parameters
     * @param {function} _onGuiSizeCallback - The callback to be called when the gui is resized, minimized or maximized, will receive the gui as a parameter and other default callback parameters
     * @param {function} _loggerCallback - The callback to be called when logging, must be a function with a single string parameter
     */
    __New(_configFilePath?, _schema?, _guiOptions?, _guiFontStyle?, _guiControlLeftMargin?, _guiControlWidth?,
        _guiYControlMargin?, _guiWindowTitle?, _guiDefaultTab?, _onGuiCloseCallback?, _onGuiSizeCallback?,
        _loggerCallback?) {
        this.loggerCallback := _loggerCallback ?? ''
        this._configFilePath := _configFilePath ?? this.getDefaultFilePath()
        this.Schema := _schema ?? this.getDefaultSchema()
        this.validateSchema(this.Schema)
        this._guiOptions := _guiOptions ?? this.getDefaultGuiOptions()
        this._guiFontStyle := _guiFontStyle ?? this.getDefaultGuiFontStyle()
        this._guiControlLeftMargin := _guiControlLeftMargin ?? this.getDefaultGuiControlLeftMargin()
        this._guiControlWidth := _guiControlWidth ?? this.getDefaultGuiControlWidth()
        this.GuiTabWidth := this._guiControlWidth + this._guiControlLeftMargin * 2
        this._guiYControlMargin := _guiYControlMargin ?? this.getDefaultGuiYControlMargin()
        this._guiWindowTitle := _guiWindowTitle ?? this.getDefaultGuiWindowTitle()
        this._guiDefaultTab := _guiDefaultTab ?? this.getDefaultGuiDefaultTab()
        this.OnGuiCloseCallback := _onGuiCloseCallback ?? ''
        this.OnGuiSizeCallback := _onGuiSizeCallback ?? ''
    }

    ConfigFilePath => _valueOrCallback(this._configFilePath)
    GuiOptions => _valueOrCallback(this._guiOptions)
    GuiFontStyle => _valueOrCallback(this._guiFontStyle)
    GuiControlLeftMargin => _valueOrCallback(this._guiControlLeftMargin)
    GuiControlWidth => _valueOrCallback(this._guiControlWidth)
    GuiYControlMargin => _valueOrCallback(this._guiYControlMargin)
    GuiWindowTitle => _valueOrCallback(this._guiWindowTitle)
    GuiDefaultTab => _valueOrCallback(this._guiDefaultTab)

    setSchema(_schema) {
        if !this.validateSchema(_schema) {
            if this.loggerCallback
                this.loggerCallback.Call("Failed to set schema")
            throw Error("Failed to set schema")
        }
        this.Schema := _schema
    }
    getSchema() => this.Schema
    addToSchema(key, item) {
        if !this.validateSchemaItem(item) {
            if this.loggerCallback
                this.loggerCallback.Call("Invalid schema item type: " Type(item))
            throw Error("Invalid schema item type: " Type(item))
        }
        this.Schema[key] := item
    }

    Get(Key) {
        if this.loggerCallback
            this.loggerCallback.Call("Getting setting: " Key)

        schema := this.getSchema()

        if !schema.HasKey(Key) {
            if this.loggerCallback
                this.loggerCallback.Call("Invalid key: " Key)
            throw Error("Invalid key: " Key)
        }

        item := schema[Key]
        itemName := item.Name
        itemSection := item.Section
        itemDefaultValue := item.DefaultValue
        itemGetCallback := item.GetCallback
        itemOnGetCallback := item.OnGetCallback

        result := IniRead(this.ConfigFilePath, itemSection, itemName, itemDefaultValue)

        if itemGetCallback is Func
            result := itemGetCallback.Call(result)

        if itemOnGetCallback is Func
            itemOnGetCallback.Call(result)

        if this.loggerCallback
            this.loggerCallback.Call("Got setting: " Key " - " result)

        return result == '' ? itemDefaultValue : result
    }

    Set(Key, Value) {
        if this.loggerCallback
            this.loggerCallback.Call("Setting: " Key " - " Value)

        schema := this.getSchema()

        if !schema.HasKey(Key) {
            if this.loggerCallback
                this.loggerCallback.Call("Invalid key: " Key)
            throw Error("Invalid key: " Key)
        }

        item := schema[Key]
        itemName := item.Name
        itemSection := item.Section
        itemDefaultValue := item.DefaultValue
        itemSaveCallback := item.SaveCallback
        itemOnSaveCallback := item.OnSaveCallback

        if itemSaveCallback is Func
            value := itemSaveCallback.Call(value)

        try {
            IniWrite(value, this.ConfigFilePath, itemSection, itemName)

            if itemOnSaveCallback is Func
                itemOnSaveCallback.Call(value)

            if this.loggerCallback
                this.loggerCallback.Call("Saved setting: " Key " - " String(value))

        } catch Error as e {
            if this.loggerCallback
                this.loggerCallback.Call("Failed to save setting: " Key)
            throw Error("Failed to save setting: " Key)
        }
    }

    /*
    Settings[name] {
        get {
            if this.loggerCallback
                this.loggerCallback.Call("Getting setting: " name)
    
            result := IniRead(this.ConfigFilePath, this.getSchema()[name].Section, this.getSchema()[name].Name, this.getSchema()[name]
                .DefaultValue)
    
            if this.getSchema()[name].GetCallback is Func
                result := this.getSchema()[name].GetCallback.Call(result)
    
            if this.getSchema()[name].OnGetCallback is Func
                this.getSchema()[name].OnGetCallback.Call(result)
    
            if this.loggerCallback
                this.loggerCallback.Call("Got setting: " name " - " result)
    
            return result
        }
        set {
            if this.loggerCallback
                this.loggerCallback.Call("Saving setting: " name)
    
            if this.getSchema()[name].SaveCallback is Func
                value := this.getSchema()[name].SaveCallback.Call(value)
    
            try {
                IniWrite(value, this.ConfigFilePath, this.getSchema()[name].Section, this.getSchema()[name].Name)
    
                if this.getSchema()[name].OnSaveCallback is Func
                    this.getSchema()[name].OnSaveCallback.Call(value)
    
                if this.loggerCallback
                    this.loggerCallback.Call("Saved setting: " name " - " value)
    
            } catch Error as e {
                if this.loggerCallback
                    this.loggerCallback.Call("Failed to save setting: " name)
                throw Error("Failed to save setting: " name)
            }
        }
    }
    */

    validateSchemaItem(item) {
        if Type(item) != 'SettingsItem' {
            if this.loggerCallback
                this.loggerCallback.Call("Invalid schema item type: " Type(item))
            throw Error("Invalid schema item type: " Type(item))
        }
        return true
    }

    validateSchema(schema) {
        if Type(schema) != 'Map' {
            if this.loggerCallback
                this.loggerCallback.Call("Invalid schema type: " Type(schema))
            throw Error("Invalid schema type: " Type(schema))
        }
        for key, item in schema {
            if !this.validateSchemaItem(item) {
                if this.loggerCallback
                    this.loggerCallback.Call("Invalid schema item type: " Type(item))
                throw Error("Invalid schema item type: " Type(item))
            }
        }
        return true
    }

    ShowSettingsGui() {

        items := this.Schema.Values()
        items.Sort(, (x) => x.HumanReadableSection ? x.HumanReadableSection : x.Section)

        sections := items.Select(x => x.HumanReadableSection ? x.HumanReadableSection : x.Section).Distinct()

        guiControlLeftMargin := this.GuiControlLeftMargin
        guiControlWidth := this.GuiControlWidth
        guiYControlMargin := this.GuiYControlMargin
        guiWindowTitle := this.GuiWindowTitle
        guiDefaultTab := this.GuiDefaultTab

        sgui := Gui(this.GuiOptions, guiWindowTitle)
        sgui.OnEvent('Close', this.OnGuiCloseCallback is Func ? this.OnGuiCloseCallback.Bind(this, sgui) : (*) => sgui.Destroy())
        sgui.OnEvent('Size', this.OnGuiSizeCallback is Func ? this.OnGuiSizeCallback.Bind(this, sgui) : (*) => false)
        sgui.SetFont(this.GuiFontStyle)

        sgui.AddText('Center xm' guiControlLeftMargin ' ym w' guiControlWidth, guiWindowTitle)

        sgui.controls := Map()

        sgui.tabs := sgui.AddTab3('xm w' this.GuiTabWidth, sections)

        for item in items {
            if !item.Visible
                continue

            itemName := item.Name
            itemSection := item.Section
            itemHRName := item.HumanReadableName
            itemHRSection := item.HumanReadableSection
            itemHRDescription := item.HumanReadableDescription
            itemTab := itemHRSection == '' ? itemSection : itemHRSection
            itemFontStyle := item.FontStyle
            itemType := item.Type
            itemExtraOptions := item.ExtraOptions
            itemOnChangeCallback := item.OnChangeCallback

            if itemFontStyle
                sgui.SetFont(itemFontStyle)

            sgui.tabs.UseTab(itemTab)

            label := itemHRName
            if item.Required {
                label .= ' *'
            }

            sgui.controls[itemName '_label'] := sgui.AddText('xm' guiControlLeftMargin ' y+' guiYControlMargin ' w' guiControlWidth,
                label)
            if itemHRDescription {
                sgui.controls[itemName '_label']._helpFunc := (_item, _sgui, *) => _showHelpPopup(_item, _sgui)
                sgui.controls[itemName '_label'].OnEvent('Click', sgui.controls[itemName '_label']._helpFunc.Bind(item, sgui))
            }

            switch itemType {
                case SettingsItemTypes.EDIT:
                    sgui.controls[itemName] := sgui.AddEdit(itemExtraOptions ' xm' guiControlLeftMargin ' y+ w' guiControlWidth,
                        this.Get(itemName))
                    sgui.controls[itemName].OnEvent('Change', itemOnChangeCallback is Func ? itemOnChangeCallback.Bind(
                        sgui, sgui.controls[
                            itemName],
                        sgui.controls[itemName].Text) : (*) => true)

                case SettingsItemTypes.NUMBER:
                    sgui.controls[itemName] := sgui.AddEdit(itemExtraOptions ' Number xm' guiControlLeftMargin ' y+ w' guiControlWidth,
                        this.Get(itemName))
                    sgui.controls[itemName].OnEvent('Change', itemOnChangeCallback is Func ? itemOnChangeCallback.Bind(
                        sgui, sgui.controls[
                            itemName],
                        sgui.controls[itemName].Text) : (*) => true)

                case SettingsItemTypes.CHECKBOX:
                    sgui.controls[itemName] := sgui.AddCheckbox(itemExtraOptions ' xm' guiControlLeftMargin ' y+ w' guiControlWidth
                    )
                    sgui.controls[itemName].Value := this.Get(itemName)
                    sgui.controls[itemName].OnEvent('Click', itemOnChangeCallback is Func ? itemOnChangeCallback.Bind(
                        sgui, sgui.controls[
                            itemName],
                        sgui.controls[itemName].Value) : (*) => true)

                case SettingsItemTypes.DROPDOWN:
                    ddlValues := item.DdlValues
                    if !ddlValues is Array {
                        if this.loggerCallback
                            this.loggerCallback.Call("Invalid dropdown values type: " Type(ddlValues))
                        throw Error("Invalid dropdown values type: " Type(ddlValues))
                    }
                    sgui.controls[itemName] := sgui.AddDDL(itemExtraOptions ' xm' guiControlLeftMargin ' y+ w' guiControlWidth,
                        ddlValues)
                    sgui.controls[itemName].Choose(this.Get(itemName) != '' ? this.Get(itemName) : 0)
                    sgui.controls[itemName].OnEvent('Change', itemOnChangeCallback is Func ? itemOnChangeCallback.Bind(
                        sgui, sgui.controls[
                            itemName],
                        sgui.controls[itemName].Text) : (*) => true)

                case SettingsItemTypes.FILE_PATH, SettingsItemTypes.FOLDER_PATH:
                    ed := sgui.AddEdit(itemExtraOptions ' xm' guiControlLeftMargin ' y+ w' guiControlWidth,
                        this.Get(itemName))
                    ed.OnEvent('Change', itemOnChangeCallback is Func ? itemOnChangeCallback.Bind(sgui, ed, ed.Value
                    ) : (*) => true)
                    btn := sgui.AddButton(item.ButtonExtraOptions ' xm' guiControlLeftMargin ' y+ w' guiControlWidth,
                        'Browse...')
                    btn.OnEvent('Click', _browsePath.Bind(ed, itemType))
                    sgui.controls[itemName] := ed
            }
        }

        sgui.tabs.UseTab(0)

        saveBtn := sgui.AddButton('xm' guiControlLeftMargin ' y+' guiYControlMargin ' w' guiControlWidth,
            'Save')
        saveBtn.OnEvent('Click', _saveGuiValues.Bind(sgui.controls, sgui))

        sgui.tabs.Choose(guiDefaultTab)
        sgui.Show('Autosize')

        _saveGuiValues(controls, gui, args*) {
            for item in items {
                value := controls[item.Name].Text
                if item.Type == 'CHECKBOX' {
                    value := controls[item.Name].Value
                }
                this.Set(item.Name, value)
            }
            gui.Destroy()
        }

        _browsePath(editControl, type, args*) {
            if type == SettingsItemTypes.FILE_PATH {
                path := FileSelect(, editControl.Value, "Select a file")
                if path {
                    editControl.Value := path
                }
            } else if type == SettingsItemTypes.FOLDER_PATH {
                path := DirSelect(editControl.Value, , "Select a folder")
                if path {
                    editControl.Value := path
                }
            }
        }

        _showHelpPopup(item, sgui, *) {
            MsgBox(item.HumanReadableDescription, item.Name, 'Owner' sgui.hwnd ' 0x1020')
        }
    }
}
