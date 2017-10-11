let _wipe = wipe;

export interface CheckBox {
    text?: string;
    checked?: boolean;
    triggerEvaluation?: boolean;
}
export const checkBoxes: LuaObj<CheckBox> = {}

interface ListItem {

}

interface List {
    items: LuaObj<ListItem>;
    default: string;
    triggerEvaluation?: boolean;
}
export const lists: LuaObj<List> = {}


export function ResetControls() {
    _wipe(checkBoxes);
    _wipe(lists);
}