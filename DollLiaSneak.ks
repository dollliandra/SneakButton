'use strict';

//////////////////////////////////////////////////////
// Doll.Lia Sneak Button Toggle                     //
//  Version 0.1a                                    //
//////////////////////////////////////////////////////               

//region MCM
if (KDEventMapGeneric['afterModSettingsLoad'] != undefined) {
    KDEventMapGeneric['afterModSettingsLoad']["DLSneak"] = (e, data) => {
        // Sanity check to make sure KDModSettings is NOT null. 
        if (KDModSettings == null) { 
            KDModSettings = {} 
            console.log("KDModSettings was null!")
        };
        if (KDModConfigs != undefined) {
            KDModConfigs["DLSneak"] = [

                {refvar: "DLSneak_Spacer", type: "text"},
                {refvar: "DLSneak_Placeholder",    type: "boolean", default: true, block: undefined},

            ]
        }
        let settingsobject = (KDModSettings.hasOwnProperty("DLSneak") == false) ? {} : Object.assign({}, KDModSettings["DLSneak"]);
        KDModConfigs["DLSneak"].forEach((option) => {
            if (settingsobject[option.refvar] == undefined) {
                settingsobject[option.refvar] = option.default
            }
        })
        KDModSettings["DLSneak"] = settingsobject;

        DLSneak_Config()
    }
}

//  Trigger helper functions after the MCM is exited.
if (KDEventMapGeneric['afterModConfig'] != undefined) {
    KDEventMapGeneric['afterModConfig']["DLSneak"] = (e,  data) => {
        DLSneak_Config()
    }
}

// Run all helper functions on game load OR post-MCM config.
////////////////////////////////////////////////////////////
function DLSneak_Config(){

    // Helper Functions (if I ever make any)

    KDLoadPerks();              // Refresh the perks list so that things show up.
    KDRefreshSpellCache = true;
}










// #region Sneak Code
////////////////////////////////////////////////////


// Make the Crouch button pass the turn.
KDInputTypes["crouch"] = (data) => {
    KDGameData.Crouch = !KDGameData.Crouch;
    KinkyDungeonAdvanceTime(1);             // Change this value to 1 to pass turn
    return "";
}


// Code to overwrite "Sneaky" upgrade with
/////////////////////////////////////////////////
let DLSneak_Sneaky = {name: "Sneaky", tags: ["buff", "utility"], school: "Any", spellPointCost: 1, manacost: 0, components: [], level:1, passive: true, type:"", onhit:"", time: 0, delay: 0, range: 0, lifetime: 0, power: 0, damage: "inert", events: [
    {type: "Buff", trigger: "tick", power: 0.5, buffType: "Sneak", mult: 1, tags: ["SlowDetection", "move", "cast"],
        prereq: "Waiting",
    },
]}

// Find the index of "Sneaky" and overwrite its contents.
let testIndex = KinkyDungeonSpellList["Any"].findIndex((i) =>  {return i.name == "Sneaky"})
if(testIndex){      // Sanity check for if "Sneaky" is ever removed from the game.
    KinkyDungeonSpellList["Any"][testIndex] = DLSneak_Sneaky;
}