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


// Change the mechanics of the Crouch button.
//////////////////////////////////////////////
KDInputTypes["crouch"] = (data) => {
    // If the character cannot stand, don't actually toggle.
    if(KDForcedToGround()){
        // Display message to inform the player
        KinkyDungeonSendTextMessage(8, TextGet("KDSneakFail_ForcedToGround"), "#ff5555", 1, true);

        // TODO - More evocative messages if petsuited
        return "";
    }

    KDGameData.Crouch = !KDGameData.Crouch;
    KinkyDungeonAdvanceTime(1);             // Change this value to 1 to pass turn
    return "";
}


// Code to disable crouch if you are put into a petsuit, etc.
// TODO - Do a better solution than this, like when you are stuffed in a suit,etc.
// > For some reason, petsuits won't do this with "postApply" event, but hogties to.
KDAddEvent(KDEventMapGeneric, "tick", "DLSneak_UntoggleCrouch", (e, data) => {
    // Toggle off crouch if the player cannot stand.
    if(KDGameData.Crouch && KDForcedToGround()){
        KDGameData.Crouch = false;
    }
});


// Code to overwrite "Sneaky" upgrade with
/////////////////////////////////////////////////
let DLSneak_Sneaky = {name: "Sneaky", tags: ["buff", "utility"], school: "Any", spellPointCost: 1, manacost: 0, components: [], level:1, passive: true, type:"", onhit:"", time: 0, delay: 0, range: 0, lifetime: 0, power: 0, damage: "inert",
    events: [
        {type: "Buff", trigger: "tick", power: 0.5, buffType: "Sneak", mult: 1, tags: ["SlowDetection", "move", "cast"],
            prereq: "DLSneaky_Sneaking",
        },
        {type: "DLSneak_Sneaky", trigger: "afterPlayerAttack",},
    ]
}

// Find the index of "Sneaky" and overwrite its contents.
let testIndex = KinkyDungeonSpellList["Any"].findIndex((i) =>  {return i.name == "Sneaky"})
if(testIndex){      // Sanity check for if "Sneaky" is ever removed from the game.
    KinkyDungeonSpellList["Any"][testIndex] = DLSneak_Sneaky;
}

// Very basic implementation - Give the sneak boost when you are Crouching.
KDPrereqs["DLSneaky_Sneaking"] = (enemy, _e, _data) => {
    return KDGameData.Crouch;
}





//#region Event Code
///////////////////////
// Add necessary mappings just in case that they do not exist
if(!KDEventMapSpell.afterPlayerAttack){KDEventMapSpell["afterPlayerAttack"] = {};}

// Event that uncrouches the player after an attack.
KDAddEvent(KDEventMapSpell, "afterPlayerAttack", "DLSneak_Sneaky", (e, _weapon, data) => {
    // If Crouched AND the enemy was unaware of you.
    if(!KDForcedToGround() && KDGameData.Crouch && !data.enemy.aware){
        // If we can stand within two turns, we instantly stand up.
        // > If we have a minKneel, we cannot stand up.
        let KneelStats = KDGetKneelStats(1, false);
        if(KneelStats.kneelRate < 0.5 || KneelStats.minKneel > 0){
            KDGameData.Crouch = false;          // Toggle off Crouch
            KDGameData.KneelTurns = 0;          // Blank KneelTurns so the player can stand.
            KinkyDungeonDressPlayer();          // "Dress" the player to make the player visibly stand.
            KinkyDungeonCalculateSlowLevel();   // Recalculate the slow level.
        }
    }
});