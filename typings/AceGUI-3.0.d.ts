interface AceLayout {
}

type LayoutFunc = (content: AceGUIWidgetBase, children: LuaArray<AceGUIWidgetBase>) => void;

interface AceGUIWidgetBase {
    SetParent(parent: AceGUIWidgetBase):void;
    SetCallback(name: string, func:(widget: AceGUIWidgetBase) => void):void;
    Fire(name: string, ...args:any[]):void;
    SetWidth(width: number):void;
    SetRelativeWidth(width: number):void;
    SetHeight(height: number):void;
    IsVisible(): boolean;
    IsShown(): boolean;
    Release():void;
    SetPoint(anchor: UIPosition, reference: UIFrame, refAnchor: UIPosition, x:number, y: number):void;
    ClearAllPoints():void;
    GetNumPoints(): number;
    GetPoint(index: number): [UIAnchor, UIRegion, UIAnchor, number, number];
    GetUserDataTable(): LuaObj<string>;
    SetUserData<T>(key: string, value: T):void;
    GetUserData<T>(key: string):T;
    IsFullHeight(): boolean;
    SetFullHeight(isFull: boolean):void;
    IsFullWidth(): boolean;
    SetFullWidth(isFull: boolean):void;
}

interface AceGUIWidgetContainerBase extends AceGUIWidgetBase {
    PauseLayout():void;
    ResumeLayout():void;
    PerformLayout():void;
    DoLayout():void;
    AddChild(child: AceGUIWidgetBase, beforeWidget?: AceGUIWidgetBase):void;
    AddChildren(...children: AceGUIWidgetBase[]):void;
    ReleaseChildren():void;
    SetLayout(layout: AceLayout):void;
}

interface AceGUIWidgetCheckBox extends AceGUIWidgetBase {
    SetDisabled(disabled: boolean):void;
    SetValue(value: boolean):void;
    GetValue(): boolean;
    SetTriState(type: "radio" | "checkbox"):void;
    ToggleChecked():void;
    SetLabel(label: string):void;
    SetDescrption(desc: string):void;
    SetImage(path: string, ...coords:number[]):void;
}

type AceGUIDWidgetDropDownItemType = "Dropdown-Item-Toggle" | "Dropdown-Item-Header"
    | "Dropdown-Item-Execute" | "Dropdown-Item-Menu" | "Dropdown-Item-Separator";

interface AceGUIWidgetDropDown extends AceGUIWidgetBase {
    SetDisabled(disabled: boolean):void;
    ClearFocus(): void;
    SetText(text: string):void;
    SetLabel(text: string):void;   
    SetValue<T>(value: T):void;
    GetValue<T>(): T;
    SetItemValue<T>(item: string, value: T):void;
    SetItemDisabled(item: string, disabled: boolean):void;
    SetList<T>(list: LuaObj<T>, order?: LuaArray<string>, itemType?: AceGUIDWidgetDropDownItemType):void;
    AddItem<T>(value: T, text: string, itemType?: AceGUIDWidgetDropDownItemType)
    SetMultiselect(multi: boolean):void;
    GetMultiselect():boolean;
}

type Widgeted<T> = T & { obj: T }
type Framed<T> = T & { frame: Widgeted<T> }

interface AceGUI {
    WidgetBase: new() => AceGUIWidgetBase;
    WidgetContainerBase: new() => AceGUIWidgetContainerBase;
    Create(name: "CheckBox"): AceGUIWidgetCheckBox;
    Create(name: "Dropdown"): AceGUIWidgetDropDown;
    Create(name: string): AceGUIWidgetBase;
    Release(widget: AceGUIWidgetBase):void;
    SetFocus(widget: AceGUIWidgetBase):void;
    ClearFocus();
    RegisterAsContainer<T extends { content: UIFrame, frame: UIFrame}>(container: new() => T):new() => Widgeted<T & AceGUIWidgetContainerBase>;
    RegisterAsWidget<T extends { frame: UIFrame}>(widget: new() => T): new() => Widgeted<T & AceGUIWidgetBase>;
    RegisterWidgetType<T>(name: string, widget: AceGUIWidgetBase, version: number):void;
    RegisterLayout(name: string, layoutFunc: LayoutFunc):void;
    GetLayout(name: string): LayoutFunc;
    GetNextWidgetNum(type: string): number;
    GetWidgetCount(type: string): number;   
    GetWidgetVersion(type: string): string; 
}

declare module "AceGUI-3.0" {
    let aceAddon:AceGUI; 
    export default aceAddon;
}
