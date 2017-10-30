import * as scommon from "./ovale_common";
import * as sdk from "./ovale_deathknight_spells";
import * as sdh from "./ovale_demonhunter_spells";
import * as sdr from "./ovale_druid_spells";
import * as sh from "./ovale_hunter_spells";
import * as sm from "./ovale_mage_spells";
import * as smk from "./ovale_monk_spells";
import * as sp from "./ovale_paladin_spells";
import * as spr from "./ovale_priest_spells";
import * as sr from "./ovale_rogue_spells";
import * as ss from "./ovale_shaman_spells";
import * as swl from "./ovale_warlock_spells";
import * as swr from "./ovale_warrior_spells";
import * as tm from "./ovale_trinkets_mop";
import * as tw from "./ovale_trinkets_wod";

export function registerScripts(){
    scommon.register();
    sdk.register();
    sdh.register();
    sdr.register();
    sh.register();
    sm.register();
    smk.register();
    sp.register();
    spr.register();
    sr.register();
    ss.register();
    swl.register();
    swr.register();

    tm.register();
    tw.register();
}
