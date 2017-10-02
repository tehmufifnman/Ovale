import { L } from "./Localization";
import { OvalePool } from "./Pool";
import { OvaleProfiler } from "./Profiler";
import { OvaleDebug } from "./Debug";
import { RegisterPrinter, Ovale } from "./Ovale";
import { Tokenizer, TokenizerDefinition } from "./Lexer";
import { OvaleCondition } from "./Condition";
import { OvaleLexer, LexerFilter } from "./Lexer";
import { OvaleScripts } from "./Scripts";
import { OvaleSpellBook } from "./SpellBook";
import { OvaleStance } from "./Stance";

let OvaleASTBase = Ovale.NewModule("OvaleAST");
let format = string.format;
let gsub = string.gsub;
let _ipairs = ipairs;
let _next = next;
let _pairs = pairs;
let _rawset = rawset;
let _setmetatable = setmetatable;
let strlower = string.lower;
let strsub = string.sub;
let tconcat = table.concat;
let tinsert = table.insert;
let _tonumber = tonumber;
let _tostring = tostring;
let tsort = table.sort;
let _type = type;
let _wipe = wipe;
let API_GetItemInfo = GetItemInfo;

let KEYWORD = {
    ["and"]: true,
    ["if"]: true,
    ["not"]: true,
    ["or"]: true,
    ["unless"]: true
}
let DECLARATION_KEYWORD = {
    ["AddActionIcon"]: true,
    ["AddCheckBox"]: true,
    ["AddFunction"]: true,
    ["AddIcon"]: true,
    ["AddListItem"]: true,
    ["Define"]: true,
    ["Include"]: true,
    ["ItemInfo"]: true,
    ["ItemRequire"]: true,
    ["ItemList"]: true,
    ["ScoreSpells"]: true,
    ["SpellInfo"]: true,
    ["SpellList"]: true,
    ["SpellRequire"]: true
}
let PARAMETER_KEYWORD = {
    ["checkbox"]: true,
    ["help"]: true,
    ["if_buff"]: true,
    ["if_equipped"]: true,
    ["if_spell"]: true,
    ["if_stance"]: true,
    ["if_target_debuff"]: true,
    ["itemcount"]: true,
    ["itemset"]: true,
    ["level"]: true,
    ["listitem"]: true,
    ["pertrait"]: true,
    ["specialization"]: true,
    ["talent"]: true,
    ["trait"]: true,
    ["text"]: true,
    ["wait"]: true
}
let SPELL_AURA_KEYWORD = {
    ["SpellAddBuff"]: true,
    ["SpellAddDebuff"]: true,
    ["SpellAddPetBuff"]: true,
    ["SpellAddPetDebuff"]: true,
    ["SpellAddTargetBuff"]: true,
    ["SpellAddTargetDebuff"]: true,
    ["SpellDamageBuff"]: true,
    ["SpellDamageDebuff"]: true
}
let STANCE_KEYWORD = {
    ["if_stance"]: true,
    ["stance"]: true,
    ["to_stance"]: true
}
{
    for (const [keyword, value] of _pairs(SPELL_AURA_KEYWORD)) {
        DECLARATION_KEYWORD[keyword] = value;
    }
    for (const [keyword, value] of _pairs(DECLARATION_KEYWORD)) {
        KEYWORD[keyword] = value;
    }
    for (const [keyword, value] of _pairs(PARAMETER_KEYWORD)) {
        KEYWORD[keyword] = value;
    }
}

let ACTION_PARAMETER_COUNT = {
    ["item"]: 1,
    ["macro"]: 1,
    ["spell"]: 1,
    ["texture"]: 1,
    ["setstate"]: 2
}
let STATE_ACTION = {
    ["setstate"]: true
}
let STRING_LOOKUP_FUNCTION = {
    ["ItemName"]: true,
    ["L"]: true,
    ["SpellName"]: true
}
let UNARY_OPERATOR = {
    ["not"]: {
        1: "logical",
        2: 15
    },
    ["-"]: {
        1: "arithmetic",
        2: 50
    }
}
let BINARY_OPERATOR = {
    ["or"]: {
        1: "logical",
        2: 5,
        3: "associative"
    },
    ["xor"]: {
        1: "logical",
        2: 8,
        3: "associative"
    },
    ["and"]: {
        1: "logical",
        2: 10,
        3: "associative"
    },
    ["!="]: {
        1: "compare",
        2: 20
    },
    ["<"]: {
        1: "compare",
        2: 20
    },
    ["<="]: {
        1: "compare",
        2: 20
    },
    ["=="]: {
        1: "compare",
        2: 20
    },
    [">"]: {
        1: "compare",
        2: 20
    },
    [">="]: {
        1: "compare",
        2: 20
    },
    ["+"]: {
        1: "arithmetic",
        2: 30,
        3: "associative"
    },
    ["-"]: {
        1: "arithmetic",
        2: 30
    },
    ["%"]: {
        1: "arithmetic",
        2: 40
    },
    ["*"]: {
        1: "arithmetic",
        2: 40,
        3: "associative"
    },
    ["/"]: {
        1: "arithmetic",
        2: 40
    },
    ["^"]: {
        1: "arithmetic",
        2: 100
    }
}

let indent:LuaArray<string> = {};
indent[0] = "";
function INDENT(key: number) {
    const ret = indent[key];
    if (ret == undefined) {
        return indent[key] = INDENT(key - 1) + " ";
    }
    return ret;
}

interface Annotation {
    controlList: LuaArray<Node>;
    parametersList: LuaArray<Node>;
    nodeList: LuaArray<Node>;
}

export type NodeType = "function" | "string" | "variable" | "value" | "number" | "spell_aura_list" | "item_info" |
     "item_require" | "spell_info" | "spell_require" | "score_spells" |
     "add_function" | "icon" | "script" | "checkbox" | "list_item" | "list" |
     "logical" | "group" | "unless" | "comment" | "if" | "simc_pool_resource" |
     "simc_wait" | "custom_function" | "wait" | "action" | "operand";

export type OperatorType = "not" | "or" | "and";

export interface Node {
    child: LuaArray<Node>;
    type: NodeType;
    name: string;
    itemId: number;
    spellId: number;
    value: any;
    key: string;
    previousType: NodeType;
    rawPositionalParams: LuaArray<any>;
    origin: number;
    rate: number;
    positionalParams:any;
    rawNamedParams: LuaObj<any>;
    namedParams:any;
    paramsAsString: string;
    postOrder:LuaArray<Node>;
    functionHash: string;
    asString: string;
    nodeId: number;
    func: string;
    secure: boolean;
    operator:OperatorType;
    expressionType:  "unary" | "binary";
    simc_pool_resource:boolean;
    simc_wait: boolean;
    for_next: boolean;
    extra_amount: number;
    comment: string;

    // Not sure (used in EmitActionList)
    action: string;
    asType: "boolean" | "value"
}



const TokenizeComment:Tokenizer = function(token) {
    return ["comment", token];
}

const TokenizeLua:Tokenizer = function(token) {
    token = strsub(token, 3, -3);
    return ["lua", token];
}

const TokenizeName:Tokenizer = function(token) {
    if (KEYWORD[token]) {
        return ["keyword", token];
    } else {
        return ["name", token];
    }
}

const TokenizeNumber:Tokenizer = function(token) {
    return ["number", token];
}

const TokenizeString:Tokenizer = function(token) {
    token = strsub(token, 2, -2);
    return ["string", token];
}
const TokenizeWhitespace:Tokenizer = function(token) {
    return ["space", token];
}

const Tokenize:Tokenizer = function(token) {
    return [token, token];
}
const NoToken:Tokenizer = function() {
    return undefined;
}

const MATCHES:LuaArray<TokenizerDefinition> = {
    1: {
        1: "^%s+",
        2: TokenizeWhitespace
    },
    2: {
        1: "^%d+%.?%d*",
        2: TokenizeNumber
    },
    3: {
        1: "^[%a_][%w_]*",
        2: TokenizeName
    },
    4: {
        1: "^((['\"])%2)",
        2: TokenizeString
    },
    5: {
        1: `^(['\"]).-\\%1`,
        2: TokenizeString
    },
    6: {
        1: `^(['\"]).-[^\]%1`,
        2: TokenizeString
    },
    7: {
        1: "^#.-\n",
        2: TokenizeComment
    },
    8: {
        1: "^!=",
        2: Tokenize
    },
    9: {
        1: "^==",
        2: Tokenize
    },
    10: {
        1: "^<=",
        2: Tokenize
    },
    11: {
        1: "^>=",
        2: Tokenize
    },
    12: {
        1: "^.",
        2: Tokenize
    },
    13: {
        1: "^$",
        2: NoToken
    }
}

const FILTERS:LexerFilter = {
    comments: TokenizeComment,
    space: TokenizeWhitespace
}

class SelfPool extends OvalePool<Node> {
    constructor(private ovaleAst: OvaleASTClass) {
        super("OvaleAST_pool");
    }

    Clean(node: Node): void {
        if (node.child) {
            this.ovaleAst.self_childrenPool.Release(node.child);
            node.child = undefined;
        }
        if (node.postOrder) {
            this.ovaleAst.self_postOrderPool.Release(node.postOrder);
            node.postOrder = undefined;
        }
    }
}
  
class OvaleASTClass extends OvaleDebug.RegisterDebugging(OvaleProfiler.RegisterProfiling(OvaleASTBase)) {
    self_indent:number = 0;
    self_outputPool = new OvalePool<LuaArray<string>>("OvaleAST_outputPool");
    self_controlPool = new OvalePool<Node>("OvaleAST_controlPool");
    self_parametersPool = new OvalePool<Node>("OvaleAST_parametersPool");
    self_childrenPool = new OvalePool<LuaArray<Node>>("OvaleAST_childrenPool");
    self_postOrderPool = new OvalePool<LuaArray<Node>>("OvaleAST_postOrderPool");
    postOrderVisitedPool = new OvalePool<LuaObj<boolean>>("OvaleAST_postOrderVisitedPool");
    self_pool = new SelfPool(this);
    PARAMETER_KEYWORD = PARAMETER_KEYWORD;
  
    constructor() {
        super();
    }
    
    print_r(node, indent?, done?, output?) {
        done = done || {}
        output = output || {}
        indent = indent || '';
        for (const [key, value] of _pairs(node)) {
            if (_type(value) == "table") {
                if (done[value]) {
                    tinsert(output, indent + "[" + _tostring(key) + "] => (self_reference)");
                } else {
                    done[value] = true;
                    if (value.type) {
                        tinsert(output, indent + "[" + _tostring(key) + "] =>");
                    } else {
                        tinsert(output, indent + "[" + _tostring(key) + "] => {");
                    }
                    this.print_r(value, indent + "    ", done, output);
                    if (!value.type) {
                        tinsert(output, indent + "}");
                    }
                }
            } else {
                tinsert(output, indent + "[" + _tostring(key) + "] => " + _tostring(value));
            }
        }
        return output;
    }

    GetNumberNode(value, nodeList, annotation) {
        annotation.numberFlyweight = annotation.numberFlyweight || {}
        let node = annotation.numberFlyweight[value];
        if (!node) {
            node = this.NewNode(nodeList);
            node.type = "value";
            node.value = value;
            node.origin = 0;
            node.rate = 0;
            annotation.numberFlyweight[value] = node;
        }
        return node;
    }

    PostOrderTraversal(node: Node, array: LuaArray<Node>, visited: LuaObj<boolean>) {
        if (node.child) {
            for (const [_, childNode] of _ipairs(node.child)) {
                if (!visited[childNode.nodeId]) {
                    this.PostOrderTraversal(childNode, array, visited);
                    array[lualength(array) + 1] = node;
                }
            }
        }
        array[lualength(array) + 1] = node;
        visited[node.nodeId] = true;
    }

    FlattenParameterValue(parameterValue, annotation) {
        let value = parameterValue;
        if (_type(parameterValue) == "table") {
            let node = parameterValue;
            if (node.type == "comma_separated_values") {
                value = this.self_parametersPool.Get();
                for (const [k, v] of _ipairs(node.csv)) {
                    value[k] = this.FlattenParameterValue(v, annotation);
                }
                annotation.parametersList = annotation.parametersList || {
                }
                annotation.parametersList[lualength(annotation.parametersList) + 1] = value;
            } else {
                let isBang = false;
                if (node.type == "bang_value") {
                    isBang = true;
                    node = node.child[1];
                }
                if (node.type == "value") {
                    value = node.value;
                } else if (node.type == "variable") {
                    value = node.name;
                } else if (node.type == "string") {
                    value = node.value;
                }
                if (isBang) {
                    value = "!" + _tostring(value);
                }
            }
        }
        return value;
    }

    GetPrecedence(node) {
        let precedence = node.precedence;
        if (!precedence) {
            let operator = node.operator;
            if (operator) {
                if (node.expressionType == "unary" && UNARY_OPERATOR[operator]) {
                    precedence = UNARY_OPERATOR[operator][2];
                } else if (node.expressionType == "binary" && BINARY_OPERATOR[operator]) {
                    precedence = BINARY_OPERATOR[operator][2];
                }
            }
        }
        return precedence;
    }

    HasParameters(node) {
        return node.rawPositionalParams && _next(node.rawPositionalParams) || node.rawNamedParams && _next(node.rawNamedParams);
    }

// let UNPARSE_VISITOR = undefined;
// let Unparse = undefined;
// let UnparseAddCheckBox = undefined;
// let UnparseAddFunction = undefined;
// let UnparseAddIcon = undefined;
// let UnparseAddListItem = undefined;
// let UnparseBangValue = undefined;
// let UnparseComment = undefined;
// let UnparseCommaSeparatedValues = undefined;
// let UnparseDefine = undefined;
// let UnparseExpression = undefined;
// let UnparseFunction = undefined;
// let UnparseGroup = undefined;
// let UnparseIf = undefined;
// let UnparseItemInfo = undefined;
// let UnparseItemRequire = undefined;
// let UnparseList = undefined;
// let UnparseNumber = undefined;
// let UnparseParameters = undefined;
// let UnparseScoreSpells = undefined;
// let UnparseScript = undefined;
// let UnparseSpellAuraList = undefined;
// let UnparseSpellInfo = undefined;
// let UnparseSpellRequire = undefined;
// let UnparseString = undefined;
// let UnparseUnless = undefined;
// let UnparseVariable = undefined;

    Unparse(node) {
        if (node.asString) {
            return node.asString;
        } else {
            let visitor;
            if (node.previousType) {
                visitor = this.UNPARSE_VISITOR[node.previousType];
            } else {
                visitor = this.UNPARSE_VISITOR[node.type];
            }
            if (!visitor) {
                this.Error("Unable to unparse node of type '%s'.", node.type);
            } else {
                return visitor(node);
            }
        }
    }

    UnparseAddCheckBox = function (node) {
        let s;
        if (node.rawPositionalParams && _next(node.rawPositionalParams) || node.rawNamedParams && _next(node.rawNamedParams)) {
            s = format("AddCheckBox(%s %s %s)", node.name, this.Unparse(node.description), this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
        } else {
            s = format("AddCheckBox(%s %s)", node.name, this.Unparse(node.description));
        }
        return s;
    }
    UnparseAddFunction = function (node) {
        let s;
        if (this.HasParameters(node)) {
            s = format("AddFunction %s %s%s", node.name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams), this.UnparseGroup(node.child[1]));
        } else {
            s = format("AddFunction %s%s", node.name, this.UnparseGroup(node.child[1]));
        }
        return s;
    }
    UnparseAddIcon = function (node) {
        let s;
        if (this.HasParameters(node)) {
            s = format("AddIcon %s%s", this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams), this.UnparseGroup(node.child[1]));
        } else {
            s = format("AddIcon%s", this.UnparseGroup(node.child[1]));
        }
        return s;
    }
    UnparseAddListItem = function (node) {
        let s;
        if (this.HasParameters(node)) {
            s = format("AddListItem(%s %s %s %s)", node.name, node.item, this.Unparse(node.description), this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
        } else {
            s = format("AddListItem(%s %s %s)", node.name, node.item, this.Unparse(node.description));
        }
        return s;
    }
    UnparseBangValue = function (node) {
        return "!" + this.Unparse(node.child[1]);
    }
    UnparseComment = function (node) {
        if (!node.comment || node.comment == "") {
            return "";
        } else {
            return "#" + node.comment;
        }
    }
    UnparseCommaSeparatedValues = function (node) {
        let output = this.self_outputPool.Get();
        for (const [k, v] of _ipairs(node.csv)) {
            output[k] = this.Unparse(v);
        }
        let outputString = tconcat(output, ",");
        this.self_outputPool.Release(output);
        return outputString;
    }
    UnparseDefine = function (node) {
        return format("Define(%s %s)", node.name, node.value);
    }
    UnparseExpression = function (node) {
        let expression;
        let precedence = this.GetPrecedence(node);
        if (node.expressionType == "unary") {
            let rhsExpression;
            let rhsNode = node.child[1];
            let rhsPrecedence = this.GetPrecedence(rhsNode);
            if (rhsPrecedence && precedence >= rhsPrecedence) {
                rhsExpression = "{ " + this.Unparse(rhsNode) + " }";
            } else {
                rhsExpression = this.Unparse(rhsNode);
            }
            if (node.operator == "-") {
                expression = "-" + rhsExpression;
            } else {
                expression = node.operator + " " + rhsExpression;
            }
        } else if (node.expressionType == "binary") {
            let lhsExpression, rhsExpression;
            let lhsNode = node.child[1];
            let lhsPrecedence = this.GetPrecedence(lhsNode);
            if (lhsPrecedence && lhsPrecedence < precedence) {
                lhsExpression = "{ " + this.Unparse(lhsNode) + " }";
            } else {
                lhsExpression = this.Unparse(lhsNode);
            }
            let rhsNode = node.child[2];
            let rhsPrecedence = this.GetPrecedence(rhsNode);
            if (rhsPrecedence && precedence > rhsPrecedence) {
                rhsExpression = "{ " + this.Unparse(rhsNode) + " }";
            } else if (rhsPrecedence && precedence == rhsPrecedence) {
                if (BINARY_OPERATOR[node.operator][3] == "associative" && node.operator == rhsNode.operator) {
                    rhsExpression = this.Unparse(rhsNode);
                } else {
                    rhsExpression = "{ " + this.Unparse(rhsNode) + " }";
                }
            } else {
                rhsExpression = this.Unparse(rhsNode);
            }
            expression = lhsExpression + " " + node.operator + " " + rhsExpression;
        }
        return expression;
    }
    UnparseFunction(node) {
        let s;
        if (this.HasParameters(node)) {
            let name;
            let filter = node.rawNamedParams.filter;
            if (filter == "debuff") {
                name = gsub(node.name, "^Buff", "Debuff");
            } else {
                name = node.name;
            }
            let target = node.rawNamedParams.target;
            if (target) {
                s = format("%s.%s(%s)", target, name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
            } else {
                s = format("%s(%s)", name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
            }
        } else {
            s = format("%s()", node.name);
        }
        return s;
    }
    UnparseGroup(node) {
        let output = this.self_outputPool.Get();
        output[lualength(output) + 1] = "";
        output[lualength(output) + 1] = INDENT(this.self_indent) + "{";
        this.self_indent = this.self_indent + 1;
        for (const [_, statementNode] of _ipairs(node.child)) {
            let s = this.Unparse(statementNode);
            if (s == "") {
                output[lualength(output) + 1] = s;
            } else {
                output[lualength(output) + 1] = INDENT(this.self_indent) + s;
            }
        }
        this.self_indent = this.self_indent - 1;
        output[lualength(output) + 1] = INDENT(this.self_indent) + "}";
        let outputString = tconcat(output, "\n");
        this.self_outputPool.Release(output);
        return outputString;
    }
    UnparseIf = function (node) {
        if (node.child[2].type == "group") {
            return format("if %s%s", this.Unparse(node.child[1]), this.UnparseGroup(node.child[2]));
        } else {
            return format("if %s %s", this.Unparse(node.child[1]), this.Unparse(node.child[2]));
        }
    }
    UnparseItemInfo = function (node) {
        let identifier = node.name && node.name || node.itemId;
        return format("ItemInfo(%s %s)", identifier, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseItemRequire = function (node) {
        let identifier = node.name && node.name || node.itemId;
        return format("ItemRequire(%s %s %s)", identifier, node.property, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseList = function (node) {
        return format("%s(%s %s)", node.keyword, node.name, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseNumber = function (node) {
        return _tostring(node.value);
    }
    UnparseParameters = function (positionalParams, namedParams) {
        let output = this.self_outputPool.Get();
        for (const [k, v] of _pairs(namedParams)) {
            if (k == "checkbox") {
                for (const [_, name] of _ipairs(v)) {
                    output[lualength(output) + 1] = format("checkbox=%s", this.Unparse(name));
                }
            } else if (k == "listitem") {
                for (const [list, item] of _pairs(v)) {
                    output[lualength(output) + 1] = format("listitem=%s:%s", list, this.Unparse(item));
                }
            } else if (_type(v) == "table") {
                output[lualength(output) + 1] = format("%s=%s", k, this.Unparse(v));
            } else if (k == "filter" || k == "target") {
            } else {
                output[lualength(output) + 1] = format("%s=%s", k, v);
            }
        }
        tsort(output);
        for (let k = lualength(positionalParams); k >= 1; k += -1) {
            tinsert(output, 1, this.Unparse(positionalParams[k]));
        }
        let outputString = tconcat(output, " ");
        this.self_outputPool.Release(output);
        return outputString;
    }
    UnparseScoreSpells = function (node) {
        return format("ScoreSpells(%s)", this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseScript = function (node: Node) {
        let output = this.self_outputPool.Get();
        let previousDeclarationType;
        for (const [_, declarationNode] of _ipairs(node.child)) {
            if (declarationNode.type == "item_info" || declarationNode.type == "spell_aura_list" || declarationNode.type == "spell_info" || declarationNode.type == "spell_require") {
                let s = this.Unparse(declarationNode);
                if (s == "") {
                    output[lualength(output) + 1] = s;
                } else {
                    output[lualength(output) + 1] = INDENT(this.self_indent + 1) + s;
                }
            } else {
                let insertBlank = false;
                if (previousDeclarationType && previousDeclarationType != declarationNode.type) {
                    insertBlank = true;
                }
                if (declarationNode.type == "add_function" || declarationNode.type == "icon") {
                    insertBlank = true;
                }
                if (insertBlank) {
                    output[lualength(output) + 1] = "";
                }
                output[lualength(output) + 1] = this.Unparse(declarationNode);
                previousDeclarationType = declarationNode.type;
            }
        }
        let outputString = tconcat(output, "\n");
        this.self_outputPool.Release(output);
        return outputString;
    }
    UnparseSpellAuraList = function (node) {
        let identifier = node.name && node.name || node.spellId;
        return format("%s(%s %s)", node.keyword, identifier, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseSpellInfo = function (node) {
        let identifier = node.name && node.name || node.spellId;
        return format("SpellInfo(%s %s)", identifier, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseSpellRequire = function (node) {
        let identifier = node.name && node.name || node.spellId;
        return format("SpellRequire(%s %s %s)", identifier, node.property, this.UnparseParameters(node.rawPositionalParams, node.rawNamedParams));
    }
    UnparseString(node) {
        return '"' + node.value + '"';
    }
    UnparseUnless(node) {
        if (node.child[2].type == "group") {
            return format("unless %s%s", this.Unparse(node.child[1]), this.UnparseGroup(node.child[2]));
        } else {
            return format("unless %s %s", this.Unparse(node.child[1]), this.Unparse(node.child[2]));
        }
    }
    UnparseVariable(node) {
        return node.name;
    }

    UNPARSE_VISITOR = {
        ["action"]: this.UnparseFunction,
        ["add_function"]: this.UnparseAddFunction,
        ["arithmetic"]: this.UnparseExpression,
        ["bang_value"]: this.UnparseBangValue,
        ["checkbox"]: this.UnparseAddCheckBox,
        ["compare"]: this.UnparseExpression,
        ["comma_separated_values"]: this.UnparseCommaSeparatedValues,
        ["comment"]: this.UnparseComment,
        ["custom_function"]: this.UnparseFunction,
        ["define"]: this.UnparseDefine,
        ["function"]: this.UnparseFunction,
        ["group"]: this.UnparseGroup,
        ["icon"]: this.UnparseAddIcon,
        ["if"]: this.UnparseIf,
        ["item_info"]: this.UnparseItemInfo,
        ["item_require"]: this.UnparseItemRequire,
        ["list"]: this.UnparseList,
        ["list_item"]: this.UnparseAddListItem,
        ["logical"]: this.UnparseExpression,
        ["score_spells"]: this.UnparseScoreSpells,
        ["script"]: this.UnparseScript,
        ["spell_aura_list"]: this.UnparseSpellAuraList,
        ["spell_info"]: this.UnparseSpellInfo,
        ["spell_require"]: this.UnparseSpellRequire,
        ["state"]: this.UnparseFunction,
        ["string"]: this.UnparseString,
        ["unless"]: this.UnparseUnless,
        ["value"]: this.UnparseNumber,
        ["variable"]: this.UnparseVariable
    }

    SyntaxError(tokenStream, ...__args) {
        this.Print(...__args);
        let context = {
            1: "Next tokens:"
        }
        for (let i = 1; i <= 20; i += 1) {
            let [tokenType, token] = tokenStream.Peek(i);
            if (tokenType) {
                context[lualength(context) + 1] = token;
            } else {
                context[lualength(context) + 1] = "<EOS>";
                break;
            }
        }
        this.Print(tconcat(context, " "));
    }

    Parse(nodeType, tokenStream, nodeList, annotation) {
        let visitor = this.PARSE_VISITOR[nodeType];
        if (!visitor) {
            this.Error("Unable to parse node of type '%s'.", nodeType);
        } else {
            return visitor(tokenStream, nodeList, annotation);
        }
    }
    ParseAddCheckBox(tokenStream, nodeList, annotation) {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "AddCheckBox")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; 'AddCheckBox' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; '(' expected.", token);
                ok = false;
            }
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; name expected.", token);
                ok = false;
            }
        }
        let descriptionNode;
        if (ok) {
            [ok, descriptionNode] = this.ParseString(tokenStream, nodeList, annotation);
        }
        let parameters;
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDCHECKBOX; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "checkbox";
            node.name = name;
            node.description = descriptionNode;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseAddFunction(tokenStream, nodeList, annotation) {
        let ok = true;
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "AddFunction")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; 'AddFunction' expected.", token);
            ok = false;
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDFUNCTION; name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        let bodyNode;
        if (ok) {
            [ok, bodyNode] = this.ParseGroup(tokenStream, nodeList, annotation);
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList, true);
            node.type = "add_function";
            node.name = name;
            node.child[1] = bodyNode;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            annotation.postOrderReference = annotation.postOrderReference || {
            }
            annotation.postOrderReference[lualength(annotation.postOrderReference) + 1] = bodyNode;
            annotation.customFunction = annotation.customFunction || {
            }
            annotation.customFunction[name] = node;
        }
        return [ok, node];
    }
    ParseAddIcon(tokenStream, nodeList, annotation) {
        let ok = true;
        let [tokenType, token] = tokenStream.Consume();
        if (!(tokenType == "keyword" && token == "AddIcon")) {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDICON; 'AddIcon' expected.", token);
            ok = false;
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        let bodyNode;
        if (ok) {
            [ok, bodyNode] = this.ParseGroup(tokenStream, nodeList, annotation);
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList, true);
            node.type = "icon";
            node.child[1] = bodyNode;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            annotation.postOrderReference = annotation.postOrderReference || {
            }
            annotation.postOrderReference[lualength(annotation.postOrderReference) + 1] = bodyNode;
        }
        return [ok, node];
    }
    ParseAddListItem(tokenStream, nodeList, annotation) {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "AddListItem")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; 'AddListItem' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; '(' expected.", token);
                ok = false;
            }
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token);
                ok = false;
            }
        }
        let item;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                item = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; name expected.", token);
                ok = false;
            }
        }
        let descriptionNode;
        if (ok) {
            [ok, descriptionNode] = this.ParseString(tokenStream, nodeList, annotation);
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ADDLISTITEM; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "list_item";
            node.name = name;
            node.item = item;
            node.description = descriptionNode;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseComment(tokenStream, nodeList, annotation): [boolean, Node] {
        return undefined;
    }
    ParseDeclaration(tokenStream, nodeList, annotation): [boolean, Node] {
        let ok = true;
        let node: Node;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "keyword" && DECLARATION_KEYWORD[token]) {
            if (token == "AddCheckBox") {
                [ok, node] = this.ParseAddCheckBox(tokenStream, nodeList, annotation);
            } else if (token == "AddFunction") {
                [ok, node] = this.ParseAddFunction(tokenStream, nodeList, annotation);
            } else if (token == "AddIcon") {
                [ok, node] = this.ParseAddIcon(tokenStream, nodeList, annotation);
            } else if (token == "AddListItem") {
                [ok, node] = this.ParseAddListItem(tokenStream, nodeList, annotation);
            } else if (token == "Define") {
                [ok, node] = this.ParseDefine(tokenStream, nodeList, annotation);
            } else if (token == "Include") {
                [ok, node] = this.ParseInclude(tokenStream, nodeList, annotation);
            } else if (token == "ItemInfo") {
                [ok, node] = this.ParseItemInfo(tokenStream, nodeList, annotation);
            } else if (token == "ItemRequire") {
                [ok, node] = this.ParseItemRequire(tokenStream, nodeList, annotation);
            } else if (token == "ItemList") {
                [ok, node] = this.ParseList(tokenStream, nodeList, annotation);
            } else if (token == "ScoreSpells") {
                [ok, node] = this.ParseScoreSpells(tokenStream, nodeList, annotation);
            } else if (SPELL_AURA_KEYWORD[token]) {
                [ok, node] = this.ParseSpellAuraList(tokenStream, nodeList, annotation);
            } else if (token == "SpellInfo") {
                [ok, node] = this.ParseSpellInfo(tokenStream, nodeList, annotation);
            } else if (token == "SpellList") {
                [ok, node] = this.ParseList(tokenStream, nodeList, annotation);
            } else if (token == "SpellRequire") {
                [ok, node] = this.ParseSpellRequire(tokenStream, nodeList, annotation);
            }
        } else {
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DECLARATION; declaration keyword expected.", token);
            tokenStream.Consume();
            ok = false;
        }
        return [ok, node];
    }
    ParseDefine(tokenStream, nodeList, annotation) {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "Define")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; 'Define' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; '(' expected.", token);
                ok = false;
            }
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; name expected.", token);
                ok = false;
            }
        }
        let value;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "-") {
                [tokenType, token] = tokenStream.Consume();
                if (tokenType == "number") {
                    value = -1 * _tonumber(token);
                } else {
                    this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number expected after '-'.", token);
                    ok = false;
                }
            } else if (tokenType == "number") {
                value = _tonumber(token);
            } else if (tokenType == "string") {
                value = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; number or string expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing DEFINE; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "define";
            node.name = name;
            node.value = value;
            annotation.definition = annotation.definition || {
            }
            annotation.definition[name] = value;
        }
        return [ok, node];
    }
    ParseExpression(tokenStream, nodeList, annotation, minPrecedence?) {
        minPrecedence = minPrecedence || 0;
        let ok = true;
        let node;
        {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                let opInfo = UNARY_OPERATOR[token];
                if (opInfo) {
                    let [opType, precedence] = [opInfo[1], opInfo[2]];
                    tokenStream.Consume();
                    let operator = token;
                    let rhsNode;
                    [ok, rhsNode] = this.ParseExpression(tokenStream, nodeList, annotation, precedence);
                    if (ok) {
                        if (operator == "-" && rhsNode.type == "value") {
                            let value = -1 * rhsNode.value;
                            node = this.GetNumberNode(value, nodeList, annotation);
                        } else {
                            node = this.NewNode(nodeList, true);
                            node.type = opType;
                            node.expressionType = "unary";
                            node.operator = operator;
                            node.precedence = precedence;
                            node.child[1] = rhsNode;
                        }
                    }
                } else {
                    [ok, node] = this.ParseSimpleExpression(tokenStream, nodeList, annotation);
                }
            }
        }
        while (ok) {
            let keepScanning = false;
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                let opInfo = BINARY_OPERATOR[token];
                if (opInfo) {
                    let [opType, precedence] = [opInfo[1], opInfo[2]];
                    if (precedence && precedence > minPrecedence) {
                        keepScanning = true;
                        tokenStream.Consume();
                        let operator = token;
                        let lhsNode = node;
                        let rhsNode;
                        [ok, rhsNode] = this.ParseExpression(tokenStream, nodeList, annotation, precedence);
                        if (ok) {
                            node = this.NewNode(nodeList, true);
                            node.type = opType;
                            node.expressionType = "binary";
                            node.operator = operator;
                            node.precedence = precedence;
                            node.child[1] = lhsNode;
                            node.child[2] = rhsNode;
                            let rotated = false;
                            while (node.type == rhsNode.type && node.operator == rhsNode.operator && BINARY_OPERATOR[node.operator][3] == "associative" && rhsNode.expressionType == "binary") {
                                node.child[2] = rhsNode.child[1];
                                rhsNode.child[1] = node;
                                node.asString = this.UnparseExpression(node);
                                node = rhsNode;
                                rhsNode = node.child[2];
                                rotated = true;
                            }
                            if (rotated) {
                                node.asString = this.UnparseExpression(node);
                            }
                        }
                    }
                }
            }
            if (!keepScanning) {
                break;
            }
        }
        if (ok && node) {
            node.asString = node.asString || this.Unparse(node);
        }
        return [ok, node];
    }

    ParseFunction(tokenStream, nodeList, annotation) {
        let ok = true;
        let name, lowername;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
                lowername = strlower(name);
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token);
                ok = false;
            }
        }
        let target;
        if (ok) {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType == ".") {
                target = name;
                [tokenType, token] = tokenStream.Consume(2);
                if (tokenType == "name") {
                    name = token;
                    lowername = strlower(name);
                } else {
                    this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; name expected.", token);
                    ok = false;
                }
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; '(' expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok && ACTION_PARAMETER_COUNT[lowername]) {
            let count = ACTION_PARAMETER_COUNT[lowername];
            if (count > lualength(positionalParams)) {
                this.SyntaxError(tokenStream, "Syntax error: action '%s' requires at least %d fixed parameter(s).", name, count);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing FUNCTION; ')' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            if (!namedParams.target) {
                if (strsub(lowername, 1, 6) == "target") {
                    namedParams.target = "target";
                    lowername = strsub(lowername, 7);
                    name = strsub(name, 7);
                }
            }
            if (!namedParams.filter) {
                if (strsub(lowername, 1, 6) == "debuff") {
                    namedParams.filter = "debuff";
                } else if (strsub(lowername, 1, 4) == "buff") {
                    namedParams.filter = "buff";
                } else if (strsub(lowername, 1, 11) == "otherdebuff") {
                    namedParams.filter = "debuff";
                } else if (strsub(lowername, 1, 9) == "otherbuff") {
                    namedParams.filter = "buff";
                }
            }
            if (target) {
                namedParams.target = target;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.name = name;
            node.lowername = lowername;
            if (STATE_ACTION[lowername]) {
                node.type = "state";
                node.func = lowername;
            } else if (ACTION_PARAMETER_COUNT[lowername]) {
                node.type = "action";
                node.func = lowername;
            } else if (STRING_LOOKUP_FUNCTION[name]) {
                node.type = "function";
                node.func = name;
                annotation.stringReference = annotation.stringReference || {
                }
                annotation.stringReference[lualength(annotation.stringReference) + 1] = node;
            } else if (OvaleCondition.IsCondition(lowername)) {
                node.type = "function";
                node.func = lowername;
            } else {
                node.type = "custom_function";
                node.func = name;
            }
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            node.asString = this.UnparseFunction(node);
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            annotation.functionCall = annotation.functionCall || {
            }
            annotation.functionCall[node.func] = true;
            annotation.functionReference = annotation.functionReference || {
            }
            annotation.functionReference[lualength(annotation.functionReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseGroup(tokenStream, nodeList, annotation) {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "{") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '{' expected.", token);
                ok = false;
            }
        }
        let child = this.self_childrenPool.Get();
        let [tokenType, token] = tokenStream.Peek();
        while (ok && tokenType && tokenType != "}") {
            let statementNode;
            [ok, statementNode] = this.ParseStatement(tokenStream, nodeList, annotation);
            if (ok) {
                child[lualength(child) + 1] = statementNode;
                [tokenType, token] = tokenStream.Peek();
            } else {
                break;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "}") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing GROUP; '}' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "group";
            node.child = child;
        } else {
            this.self_childrenPool.Release(child);
        }
        return [ok, node];
    }
    ParseIf = function (tokenStream, nodeList, annotation) {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "if")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing IF; 'if' expected.", token);
                ok = false;
            }
        }
        let conditionNode, bodyNode;
        if (ok) {
            [ok, conditionNode] = this.ParseExpression(tokenStream, nodeList, annotation);
        }
        if (ok) {
            [ok, bodyNode] =this.ParseStatement(tokenStream, nodeList, annotation);
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList, true);
            node.type = "if";
            node.child[1] = conditionNode;
            node.child[2] = bodyNode;
        }
        return [ok, node];
    }
    ParseInclude(tokenStream, nodeList, annotation) {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "Include")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; 'Include' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; '(' expected.", token);
                ok = false;
            }
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; script name expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing INCLUDE; ')' expected.", token);
                ok = false;
            }
        }
        let code = OvaleScripts.GetScript(name);
        if (!code) {
            this.Error("Script '%s' not found when parsing INCLUDE.", name);
            ok = false;
        }
        let node;
        if (ok) {
            let includeTokenStream = new OvaleLexer(name, code, MATCHES, FILTERS);
            [ok, node] = this.ParseScriptStream(includeTokenStream, nodeList, annotation);
            includeTokenStream.Release();
        }
        return [ok, node];
    }
    ParseItemInfo = function (tokenStream, nodeList, annotation) {
        let ok = true;
        let name, lowername;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "ItemInfo")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; 'ItemInfo' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; '(' expected.", token);
                ok = false;
            }
        }
        let itemId;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                itemId = token;
            } else if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; number or name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMINFO; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "item_info";
            node.itemId = itemId;
            node.name = name;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            if (name) {
                annotation.nameReference = annotation.nameReference || {
                }
                annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
            }
        }
        return [ok, node];
    }

    ParseItemRequire(tokenStream, nodeList, annotation) {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "ItemRequire")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; keyword expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; '(' expected.", token);
                ok = false;
            }
        }
        let itemId, name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                itemId = token;
            } else if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; number or name expected.", token);
                ok = false;
            }
        }
        let property;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                property = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; property name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing ITEMREQUIRE; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "item_require";
            node.itemId = itemId;
            node.name = name;
            node.property = property;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            if (name) {
                annotation.nameReference = annotation.nameReference || {
                }
                annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
            }
        }
        return [ok, node];
    }
    ParseList(tokenStream, nodeList, annotation) {
        let ok = true;
        let keyword;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "keyword" && (token == "ItemList" || token == "SpellList")) {
                keyword = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; keyword expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; '(' expected.", token);
                ok = false;
            }
        }
        let name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing LIST; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "list";
            node.keyword = keyword;
            node.name = name;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseNumber(tokenStream:OvaleLexer, nodeList, annotation) {
        let ok = true;
        let value;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                value = _tonumber(token);
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing NUMBER; number expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.GetNumberNode(value, nodeList, annotation);
        }
        return [ok, node];
    }
    ParseParameterValue(tokenStream, nodeList, annotation) {
        let ok = true;
        let node;
        let tokenType, token;
        let parameters;
        do {
            [ok, node] = this.ParseSimpleParameterValue(tokenStream, nodeList, annotation);
            if (ok && node) {
                [tokenType, token] = tokenStream.Peek();
                if (tokenType == ",") {
                    tokenStream.Consume();
                    parameters = parameters || this.self_parametersPool.Get();
                }
                if (parameters) {
                    parameters[lualength(parameters) + 1] = node;
                }
            }
        }
        while (!(!ok || tokenType != ","));
        if (ok && parameters) {
            node = this.NewNode(nodeList);
            node.type = "comma_separated_values";
            node.csv = parameters;
            annotation.parametersList = annotation.parametersList || {
            }
            annotation.parametersList[lualength(annotation.parametersList) + 1] = parameters;
        }
        return [ok, node];
    }
    ParseParameters = function (tokenStream, nodeList, annotation, isList?:boolean) {
        let ok = true;
        let positionalParams = this.self_parametersPool.Get();
        let namedParams = this.self_parametersPool.Get();
        while (ok) {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                let name, node;
                if (tokenType == "name") {
                    [ok, node] = this.ParseVariable(tokenStream, nodeList, annotation);
                    if (ok) {
                        name = node.name;
                    }
                } else if (tokenType == "number") {
                    [ok, node] = this.ParseNumber(tokenStream, nodeList, annotation);
                    if (ok) {
                        name = node.value;
                    }
                } else if (tokenType == "-") {
                    tokenStream.Consume();
                    [ok, node] = this.ParseNumber(tokenStream, nodeList, annotation);
                    if (ok) {
                        let value = -1 * node.value;
                        node = this.GetNumberNode(value, nodeList, annotation);
                        name = value;
                    }
                } else if (tokenType == "string") {
                    [ok, node] = this.ParseString(tokenStream, nodeList, annotation);
                    if (ok) {
                        name = node.value;
                    }
                } else if (PARAMETER_KEYWORD[token]) {
                    if (isList) {
                        this.SyntaxError(tokenStream, "Syntax error: unexpected keyword '%s' when parsing PARAMETERS; simple expression expected.", token);
                        ok = false;
                    } else {
                        tokenStream.Consume();
                        name = token;
                    }
                } else {
                    break;
                }
                if (ok && name) {
                    [tokenType, token] = tokenStream.Peek();
                    if (tokenType == "=") {
                        tokenStream.Consume();
                        if (name == "checkbox" || name == "listitem") {
                            let control = namedParams[name] || this.self_controlPool.Get();
                            if (name == "checkbox") {
                                [ok, node] = this.ParseSimpleParameterValue(tokenStream, nodeList, annotation);
                                if (ok && node) {
                                    if (!(node.type == "variable" || (node.type == "bang_value" && node.child[1].type == "variable"))) {
                                        this.SyntaxError(tokenStream, "Syntax error: 'checkbox' parameter with unexpected value '%s'.", this.Unparse(node));
                                        ok = false;
                                    }
                                }
                                if (ok) {
                                    control[lualength(control) + 1] = node;
                                }
                            } else {
                                [tokenType, token] = tokenStream.Consume();
                                let list;
                                if (tokenType == "name") {
                                    list = token;
                                } else {
                                    this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; name expected.", token);
                                    ok = false;
                                }
                                if (ok) {
                                    [tokenType, token] = tokenStream.Consume();
                                    if (tokenType != ":") {
                                        this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARAMETERS; ':' expected.", token);
                                        ok = false;
                                    }
                                }
                                if (ok) {
                                    [ok, node] = this.ParseSimpleParameterValue(tokenStream, nodeList, annotation);
                                }
                                if (ok && node) {
                                    if (!(node.type == "variable" || (node.type == "bang_value" && node.child[1].type == "variable"))) {
                                        this.SyntaxError(tokenStream, "Syntax error: 'listitem=%s' parameter with unexpected value '%s'.", this.Unparse(node));
                                        ok = false;
                                    }
                                }
                                if (ok) {
                                    control[list] = node;
                                }
                            }
                            if (!namedParams[name]) {
                                namedParams[name] = control;
                                annotation.controlList = annotation.controlList || {
                                }
                                annotation.controlList[lualength(annotation.controlList) + 1] = control;
                            }
                        } else {
                            [ok, node] = this.ParseParameterValue(tokenStream, nodeList, annotation);
                            namedParams[name] = node;
                        }
                    } else {
                        positionalParams[lualength(positionalParams) + 1] = node;
                    }
                }
            } else {
                break;
            }
        }
        if (ok) {
            annotation.parametersList = annotation.parametersList || {
            }
            annotation.parametersList[lualength(annotation.parametersList) + 1] = positionalParams;
            annotation.parametersList[lualength(annotation.parametersList) + 1] = namedParams;
        } else {
            positionalParams = undefined;
            namedParams = undefined;
        }
        return [ok, positionalParams, namedParams];
    }
    ParseParentheses = function (tokenStream, nodeList, annotation) {
        let ok = true;
        let leftToken, rightToken;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "(") {
                [leftToken, rightToken] = ["(", ")"];
            } else if (tokenType == "{") {
                [leftToken, rightToken] = ["{", "}"];
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '(' or '{' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            [ok, node] = this.ParseExpression(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != rightToken) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing PARENTHESES; '%s' expected.", token, rightToken);
                ok = false;
            }
        }
        if (ok) {
            node.left = leftToken;
            node.right = rightToken;
        }
        return [ok, node];
    }
    ParseScoreSpells = function (tokenStream, nodeList, annotation) {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "ScoreSpells")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; 'ScoreSpells' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; '(' expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SCORESPELLS; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "score_spells";
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseScriptStream(tokenStream: OvaleLexer, nodeList, annotation) {
        this.StartProfiling("OvaleAST_ParseScript");
        let ok = true;
        let child = this.self_childrenPool.Get();
        while (ok) {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType) {
                let declarationNode: Node;
                [ok, declarationNode] = this.ParseDeclaration(tokenStream, nodeList, annotation);
                if (ok) {
                    if (declarationNode.type == "script") {
                        for (const [_, node] of _ipairs(declarationNode.child)) {
                            child[lualength(child) + 1] = node;
                        }
                        this.self_pool.Release(declarationNode);
                    } else {
                        child[lualength(child) + 1] = declarationNode;
                    }
                }
            } else {
                break;
            }
        }
        let ast;
        if (ok) {
            ast = this.NewNode();
            ast.type = "script";
            ast.child = child;
        } else {
            this.self_childrenPool.Release(child);
        }
        this.StopProfiling("OvaleAST_ParseScript");
        return [ok, ast];
    }
    ParseSimpleExpression(tokenStream: OvaleLexer, nodeList, annotation) {
        let ok = true;
        let node;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "number") {
            [ok, node] = this.ParseNumber(tokenStream, nodeList, annotation);
        } else if (tokenType == "string") {
            [ok, node] = this.ParseString(tokenStream, nodeList, annotation);
        } else if (tokenType == "name") {
            [tokenType, token] = tokenStream.Peek(2);
            if (tokenType == "." || tokenType == "(") {
                [ok, node] = this.ParseFunction(tokenStream, nodeList, annotation);
            } else {
                [ok, node] = this.ParseVariable(tokenStream, nodeList, annotation);
            }
        } else if (tokenType == "(" || tokenType == "{") {
            [ok, node] = this.ParseParentheses(tokenStream, nodeList, annotation);
        } else {
            tokenStream.Consume();
            this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SIMPLE EXPRESSION", token);
            ok = false;
        }
        return [ok, node];
    }
    ParseSimpleParameterValue(tokenStream, nodeList, annotation) {
        let ok = true;
        let isBang = false;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType == "!") {
            isBang = true;
            tokenStream.Consume();
        }
        let expressionNode;
        [tokenType, token] = tokenStream.Peek();
        if (tokenType == "(" || tokenType == "-") {
            [ok, expressionNode] = this.ParseExpression(tokenStream, nodeList, annotation);
        } else {
            [ok, expressionNode] = this.ParseSimpleExpression(tokenStream, nodeList, annotation);
        }
        let node;
        if (isBang) {
            node = this.NewNode(nodeList, true);
            node.type = "bang_value";
            node.child[1] = expressionNode;
        } else {
            node = expressionNode;
        }
        return [ok, node];
    }
    ParseSpellAuraList(tokenStream, nodeList, annotation) {
        let ok = true;
        let keyword;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "keyword" && SPELL_AURA_KEYWORD[token]) {
                keyword = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; keyword expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; '(' expected.", token);
                ok = false;
            }
        }
        let spellId, name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                spellId = token;
            } else if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; number or name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLAURALIST; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "spell_aura_list";
            node.keyword = keyword;
            node.spellId = spellId;
            node.name = name;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            if (name) {
                annotation.nameReference = annotation.nameReference || {
                }
                annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
            }
        }
        return [ok, node];
    }
    ParseSpellInfo(tokenStream, nodeList, annotation) {
        let ok = true;
        let name, lowername;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "SpellInfo")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; 'SpellInfo' expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; '(' expected.", token);
                ok = false;
            }
        }
        let spellId;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                spellId = token;
            } else if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; number or name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLINFO; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "spell_info";
            node.spellId = spellId;
            node.name = name;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            if (name) {
                annotation.nameReference = annotation.nameReference || {
                }
                annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
            }
        }
        return [ok, node];
    }
    ParseSpellRequire(tokenStream, nodeList, annotation) {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "SpellRequire")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; keyword expected.", token);
                ok = false;
            }
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != "(") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; '(' expected.", token);
                ok = false;
            }
        }
        let spellId, name;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "number") {
                spellId = token;
            } else if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; number or name expected.", token);
                ok = false;
            }
        }
        let property;
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                property = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; property name expected.", token);
                ok = false;
            }
        }
        let positionalParams, namedParams;
        if (ok) {
            [ok, positionalParams, namedParams] = this.ParseParameters(tokenStream, nodeList, annotation);
        }
        if (ok) {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType != ")") {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing SPELLREQUIRE; ')' expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "spell_require";
            node.spellId = spellId;
            node.name = name;
            node.property = property;
            node.rawPositionalParams = positionalParams;
            node.rawNamedParams = namedParams;
            annotation.parametersReference = annotation.parametersReference || {
            }
            annotation.parametersReference[lualength(annotation.parametersReference) + 1] = node;
            if (name) {
                annotation.nameReference = annotation.nameReference || {
                }
                annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
            }
        }
        return [ok, node];
    }
    ParseStatement(tokenStream, nodeList, annotation) {
        let ok = true;
        let node;
        let [tokenType, token] = tokenStream.Peek();
        if (tokenType) {
            let parser;
            if (token == "{") {
                let i = 1;
                let count = 0;
                while (tokenType) {
                    if (token == "{") {
                        count = count + 1;
                    } else if (token == "}") {
                        count = count - 1;
                    }
                    i = i + 1;
                    [tokenType, token] = tokenStream.Peek(i);
                    if (count == 0) {
                        break;
                    }
                }
                if (tokenType) {
                    if (BINARY_OPERATOR[token]) {
                        [ok, node] = this.ParseExpression(tokenStream, nodeList, annotation);
                    } else {
                        [ok, node] = this.ParseGroup(tokenStream, nodeList, annotation);
                    }
                } else {
                    this.SyntaxError(tokenStream, "Syntax error: unexpected end of script.");
                }
            } else if (token == "if") {
                [ok, node] = this.ParseIf(tokenStream, nodeList, annotation);
            } else if (token == "unless") {
                [ok, node] = this.ParseUnless(tokenStream, nodeList, annotation);
            } else {
                [ok, node] = this.ParseExpression(tokenStream, nodeList, annotation);
            }
        }
        return [ok, node];
    }
    ParseString(tokenStream, nodeList, annotation) {
        let ok = true;
        let node;
        let value;
        if (ok) {
            let [tokenType, token] = tokenStream.Peek();
            if (tokenType == "string") {
                value = token;
                tokenStream.Consume();
            } else if (tokenType == "name") {
                if (STRING_LOOKUP_FUNCTION[token]) {
                    [ok, node] = this.ParseFunction(tokenStream, nodeList, annotation);
                } else {
                    value = token;
                    tokenStream.Consume();
                }
            } else {
                tokenStream.Consume();
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing STRING; string, variable, or function expected.", token);
                ok = false;
            }
        }
        if (ok && !node) {
            node = this.NewNode(nodeList);
            node.type = "string";
            node.value = value;
            annotation.stringReference = annotation.stringReference || {
            }
            annotation.stringReference[lualength(annotation.stringReference) + 1] = node;
        }
        return [ok, node];
    }
    ParseUnless(tokenStream, nodeList, annotation) {
        let ok = true;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (!(tokenType == "keyword" && token == "unless")) {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing UNLESS; 'unless' expected.", token);
                ok = false;
            }
        }
        let conditionNode, bodyNode;
        if (ok) {
            [ok, conditionNode] = this.ParseExpression(tokenStream, nodeList, annotation);
        }
        if (ok) {
            [ok, bodyNode] = this.ParseStatement(tokenStream, nodeList, annotation);
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList, true);
            node.type = "unless";
            node.child[1] = conditionNode;
            node.child[2] = bodyNode;
        }
        return [ok, node];
    }
    ParseVariable(tokenStream, nodeList, annotation) {
        let ok = true;
        let name;
        {
            let [tokenType, token] = tokenStream.Consume();
            if (tokenType == "name") {
                name = token;
            } else {
                this.SyntaxError(tokenStream, "Syntax error: unexpected token '%s' when parsing VARIABLE; name expected.", token);
                ok = false;
            }
        }
        let node;
        if (ok) {
            node = this.NewNode(nodeList);
            node.type = "variable";
            node.name = name;
            annotation.nameReference = annotation.nameReference || {
            }
            annotation.nameReference[lualength(annotation.nameReference) + 1] = node;
        }
        return [ok, node];
    }
    PARSE_VISITOR = {
        ["action"]: this.ParseFunction,
        ["add_function"]: this.ParseAddFunction,
        ["arithmetic"]: this.ParseExpression,
        ["bang_value"]: this.ParseSimpleParameterValue,
        ["checkbox"]: this.ParseAddCheckBox,
        ["compare"]: this.ParseExpression,
        ["comment"]: this.ParseComment,
        ["custom_function"]: this.ParseFunction,
        ["define"]: this.ParseDefine,
        ["expression"]: this.ParseExpression,
        ["function"]: this.ParseFunction,
        ["group"]: this.ParseGroup,
        ["icon"]: this.ParseAddIcon,
        ["if"]: this.ParseIf,
        ["item_info"]: this.ParseItemInfo,
        ["item_require"]: this.ParseItemRequire,
        ["list"]: this.ParseList,
        ["list_item"]: this.ParseAddListItem,
        ["logical"]: this.ParseExpression,
        ["score_spells"]: this.ParseScoreSpells,
        ["script"]: this.ParseScript,
        ["spell_aura_list"]: this.ParseSpellAuraList,
        ["spell_info"]: this.ParseSpellInfo,
        ["spell_require"]: this.ParseSpellRequire,
        ["string"]: this.ParseString,
        ["unless"]: this.ParseUnless,
        ["value"]: this.ParseNumber,
        ["variable"]: this.ParseVariable
    }

    OnInitialize() {
    }

    DebugAST() {
        this.self_pool.DebuggingInfo();
        this.self_parametersPool.DebuggingInfo();
        this.self_controlPool.DebuggingInfo();
        this.self_childrenPool.DebuggingInfo();
        this.self_outputPool.DebuggingInfo();
    }

    NewNode(nodeList?, hasChild?: boolean) {
        let node = this.self_pool.Get();
        if (nodeList) {
            let nodeId = lualength(nodeList) + 1;
            node.nodeId = nodeId;
            nodeList[nodeId] = node;
        }
        if (hasChild) {
            node.child = this.self_childrenPool.Get();
        }
        return node;
    }
    NodeToString(node) {
        let output = this.print_r(node);
        return tconcat(output, "\n");
    }
    ReleaseAnnotation(annotation: Annotation) {
        if (annotation.controlList) {
            for (const [_, control] of _ipairs(annotation.controlList)) {
                this.self_controlPool.Release(control);
            }
        }
        if (annotation.parametersList) {
            for (const [_, parameters] of _ipairs(annotation.parametersList)) {
                this.self_parametersPool.Release(parameters);
            }
        }
        if (annotation.nodeList) {
            for (const [_, node] of _ipairs(annotation.nodeList)) {
                this.self_pool.Release(node);
            }
        }
        for (const [key, value] of _pairs(annotation)) {
            if (_type(value) == "table") {
                _wipe(value);
            }
            annotation[key] = undefined;
        }
    }
    Release(ast) {
        if (ast.annotation) {
            this.ReleaseAnnotation(ast.annotation);
            ast.annotation = undefined;
        }
        this.self_pool.Release(ast);
    }
    ParseCode(nodeType, code, nodeList, annotation): [Node, LuaArray<Node>, any] {
        nodeList = nodeList || {
        }
        annotation = annotation || {
        }
        let tokenStream = new OvaleLexer("Ovale", code, MATCHES);
        let [ok, node] = this.Parse(nodeType, tokenStream, nodeList, annotation);
        tokenStream.Release();
        return [node, nodeList, annotation];
    }
    ParseScript(name, options?) {
        let code = OvaleScripts.GetScript(name);
        let ast;
        if (code) {
            options = options || {
                optimize: true,
                verify: true
            }
            let annotation = {
                nodeList: {
                },
                verify: options.verify
            }
            ast = this.ParseCode("script", code, annotation.nodeList, annotation);
            if (ast) {
                ast.annotation = annotation;
                this.PropagateConstants(ast);
                this.PropagateStrings(ast);
                this.FlattenParameters(ast);
                this.VerifyParameterStances(ast);
                this.VerifyFunctionCalls(ast);
                if (options.optimize) {
                    this.Optimize(ast);
                }
                this.InsertPostOrderTraversal(ast);
            } else {
                ast = this.NewNode();
                ast.annotation = annotation;
                this.Release(ast);
                ast = undefined;
            }
        }
        return ast;
    }
    
    PropagateConstants(ast) {
        this.StartProfiling("OvaleAST_PropagateConstants");
        if (ast.annotation) {
            let dictionary = ast.annotation.definition;
            if (dictionary && ast.annotation.nameReference) {
                for (const [_, node] of _ipairs<Node>(ast.annotation.nameReference)) {
                    if ((node.type == "item_info" || node.type == "item_require") && node.name) {
                        let itemId = dictionary[node.name];
                        if (itemId) {
                            node.itemId = itemId;
                        }
                    } else if ((node.type == "spell_aura_list" || node.type == "spell_info" || node.type == "spell_require") && node.name) {
                        let spellId = dictionary[node.name];
                        if (spellId) {
                            node.spellId = spellId;
                        }
                    } else if (node.type == "variable") {
                        let name = node.name;
                        let value = dictionary[name];
                        if (value) {
                            node.previousType = "variable";
                            node.type = "value";
                            node.value = value;
                            node.origin = 0;
                            node.rate = 0;
                        }
                    }
                }
            }
        }
        this.StopProfiling("OvaleAST_PropagateConstants");
    }
    PropagateStrings(ast) {
        this.StartProfiling("OvaleAST_PropagateStrings");
        if (ast.annotation && ast.annotation.stringReference) {
            for (const [_, node] of _ipairs<Node>(ast.annotation.stringReference)) {
                if (node.type == "string") {
                    let key = node.value;
                    let value = L[key];
                    if (key != value) {
                        node.value = value;
                        node.key = key;
                    }
                } else if (node.type == "variable") {
                    let value = node.name;
                    node.previousType = node.type;
                    node.type = "string";
                    node.value = value;
                } else if (node.type == "number") {
                    let value = _tostring(node.value);
                    node.previousType = "number";
                    node.type = "string";
                    node.value = value;
                } else if (node.type == "function") {
                    let key = node.rawPositionalParams[1];
                    if (_type(key) == "table") {
                        if (key.type == "value") {
                            key = key.value;
                        } else if (key.type == "variable") {
                            key = key.name;
                        } else if (key.type == "string") {
                            key = key.value;
                        }
                    }
                    let value;
                    if (key) {
                        let name = node.name;
                        if (name == "ItemName") {
                            value = API_GetItemInfo(key) || "item:" + key;
                        } else if (name == "L") {
                            value = L[key];
                        } else if (name == "SpellName") {
                            value = OvaleSpellBook.GetSpellName(key) || "spell:" + key;
                        }
                    }
                    if (value) {
                        node.previousType = "function";
                        node.type = "string";
                        node.value = value;
                        node.key = key;
                    }
                }
            }
        }
        this.StopProfiling("OvaleAST_PropagateStrings");
    }
    FlattenParameters(ast) {
        this.StartProfiling("OvaleAST_FlattenParameters");
        let annotation = ast.annotation;
        if (annotation && annotation.parametersReference) {
            let dictionary = annotation.definition;
            for (const [_, node] of _ipairs<Node>(annotation.parametersReference)) {
                if (node.rawPositionalParams) {
                    let parameters = this.self_parametersPool.Get();
                    for (const [key, value] of _ipairs(node.rawPositionalParams)) {
                        parameters[key] = this.FlattenParameterValue(value, annotation);
                    }
                    node.positionalParams = parameters;
                    annotation.parametersList = annotation.parametersList || {
                    }
                    annotation.parametersList[lualength(annotation.parametersList) + 1] = parameters;
                }
                if (node.rawNamedParams) {
                    let parameters = this.self_parametersPool.Get();
                    for (let [key, value] of _pairs(node.rawNamedParams)) {
                        if (key == "checkbox" || key == "listitem") {
                            let control = parameters[key] || this.self_controlPool.Get();
                            if (key == "checkbox") {
                                for (const [i, name] of _ipairs(value)) {
                                    control[i] = this.FlattenParameterValue(name, annotation);
                                }
                            } else {
                                for (const [list, item] of _pairs(value)) {
                                    control[list] = this.FlattenParameterValue(item, annotation);
                                }
                            }
                            if (!parameters[key]) {
                                parameters[key] = control;
                                annotation.controlList = annotation.controlList || {
                                }
                                annotation.controlList[lualength(annotation.controlList) + 1] = control;
                            }
                        } else {
                            if (_type(key) != "number" && dictionary && dictionary[key]) {
                                key = dictionary[key];
                            }
                            parameters[key] = this.FlattenParameterValue(value, annotation);
                        }
                    }
                    node.namedParams = parameters;
                    annotation.parametersList = annotation.parametersList || {
                    }
                    annotation.parametersList[lualength(annotation.parametersList) + 1] = parameters;
                }
                let output = this.self_outputPool.Get();
                for (const [k, v] of _pairs(node.namedParams)) {
                    if (k == "checkbox") {
                        for (const [_, name] of _ipairs(v)) {
                            output[lualength(output) + 1] = format("checkbox=%s", name);
                        }
                    } else if (k == "listitem") {
                        for (const [list, item] of _ipairs(v)) {
                            output[lualength(output) + 1] = format("listitem=%s:%s", list, item);
                        }
                    } else if (_type(v) == "table") {
                        output[lualength(output) + 1] = format("%s=%s", k, tconcat(v, ","));
                    } else {
                        output[lualength(output) + 1] = format("%s=%s", k, v);
                    }
                }
                tsort(output);
                for (let k = lualength(node.positionalParams); k >= 1; k += -1) {
                    tinsert(output, 1, node.positionalParams[k]);
                }
                if (lualength(output) > 0) {
                    node.paramsAsString = tconcat(output, " ");
                } else {
                    node.paramsAsString = "";
                }
                this.self_outputPool.Release(output);
            }
        }
        this.StopProfiling("OvaleAST_FlattenParameters");
    }
    VerifyFunctionCalls(ast) {
        this.StartProfiling("OvaleAST_VerifyFunctionCalls");
        if (ast.annotation && ast.annotation.verify) {
            let customFunction = ast.annotation.customFunction;
            let functionCall = ast.annotation.functionCall;
            if (functionCall) {
                for (const [name] of _pairs(functionCall)) {
                    if (ACTION_PARAMETER_COUNT[name]) {
                    } else if (STRING_LOOKUP_FUNCTION[name]) {
                    } else if (OvaleCondition.IsCondition(name)) {
                    } else if (customFunction && customFunction[name]) {
                    } else {
                        this.Error("unknown function '%s'.", name);
                    }
                }
            }
        }
        this.StopProfiling("OvaleAST_VerifyFunctionCalls");
    }
    VerifyParameterStances(ast) {
        this.StartProfiling("OvaleAST_VerifyParameterStances");
        let annotation = ast.annotation;
        if (annotation && annotation.verify && annotation.parametersReference) {
            for (const [_, node] of _ipairs<Node>(annotation.parametersReference)) {
                if (node.rawNamedParams) {
                    for (const [stanceKeyword] of _pairs(STANCE_KEYWORD)) {
                        let valueNode = node.rawNamedParams[stanceKeyword];
                        if (valueNode) {
                            if (valueNode.type == "comma_separated_values") {
                                valueNode = valueNode.csv[1];
                            }
                            if (valueNode.type == "bang_value") {
                                valueNode = valueNode.child[1];
                            }
                            let value = this.FlattenParameterValue(valueNode, annotation);
                            if (OvaleStance.STANCE_NAME[value]) {
                            } else if (_type(value) == "number") {
                            } else {
                                this.Error("unknown stance '%s'.", value);
                            }
                        }
                    }
                }
            }
        }
        this.StopProfiling("OvaleAST_VerifyParameterStances");
    }
    InsertPostOrderTraversal(ast) {
        this.StartProfiling("OvaleAST_InsertPostOrderTraversal");
        let annotation = ast.annotation;
        if (annotation && annotation.postOrderReference) {
            for (const [_, node] of _ipairs<Node>(annotation.postOrderReference)) {
                let array = this.self_postOrderPool.Get();
                let visited = this.postOrderVisitedPool.Get();
                this.PostOrderTraversal(node, array, visited);
                this.postOrderVisitedPool.Release(visited);
                node.postOrder = array;
            }
        }
        this.StopProfiling("OvaleAST_InsertPostOrderTraversal");
    }
    Optimize(ast) {
        this.CommonFunctionElimination(ast);
        this.CommonSubExpressionElimination(ast);
    }
    CommonFunctionElimination(ast) {
        this.StartProfiling("OvaleAST_CommonFunctionElimination");
        if (ast.annotation) {
            if (ast.annotation.functionReference) {
                let functionHash = ast.annotation.functionHash || {}
                for (const [_, node] of _ipairs<Node>(ast.annotation.functionReference)) {
                    if (node.positionalParams || node.namedParams) {
                        let hash = node.name + "(" + node.paramsAsString + ")";
                        node.functionHash = hash;
                        functionHash[hash] = functionHash[hash] || node;
                    }
                }
                ast.annotation.functionHash = functionHash;
            }
            if (ast.annotation.functionHash && ast.annotation.nodeList) {
                let functionHash = ast.annotation.functionHash;
                for (const [_, node] of _ipairs<Node>(ast.annotation.nodeList)) {
                    if (node.child) {
                        for (const [k, childNode] of _ipairs(node.child)) {
                            if (childNode.functionHash) {
                                node.child[k] = functionHash[childNode.functionHash];
                            }
                        }
                    }
                }
            }
        }
        this.StopProfiling("OvaleAST_CommonFunctionElimination");
    }
    CommonSubExpressionElimination(ast) {
        this.StartProfiling("OvaleAST_CommonSubExpressionElimination");
        if (ast && ast.annotation && ast.annotation.nodeList) {
            let expressionHash = {
            }
            for (const [_, node] of _ipairs<Node>(ast.annotation.nodeList)) {
                let hash = node.asString;
                if (hash) {
                    expressionHash[hash] = expressionHash[hash] || node;
                }
                if (node.child) {
                    for (const [i, childNode] of _ipairs(node.child)) {
                        hash = childNode.asString;
                        if (hash) {
                            let hashNode = expressionHash[hash];
                            if (hashNode) {
                                node.child[i] = hashNode;
                            } else {
                                expressionHash[hash] = childNode;
                            }
                        }
                    }
                }
            }
            ast.annotation.expressionHash = expressionHash;
        }
        this.StopProfiling("OvaleAST_CommonSubExpressionElimination");
    }
}

export const OvaleAST = new OvaleASTClass();