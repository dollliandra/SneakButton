'use strict';

//////////////////////////////////////////////////////
// Doll.Lia Sneak Button Toggle                     //
//  Version 0.2                                     //
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

                //{refvar: "DLSneak_Spacer", type: "text"},
                {refvar: "DLSneak_CrouchTakesTurn",    type: "boolean", default: true, block: undefined},
                {refvar: "DLSneak_CrouchTakesTurnDesc", type: "text"},
                {refvar: "DLSneak_SneakRoll",    type: "boolean", default: true, block: undefined},
                {refvar: "DLSneak_SneakRollDesc", type: "text"},
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

    // Helper Functions
    DLSE_SneakSpells()

    KDLoadPerks();              // Refresh the perks list so that things show up.
    KDRefreshSpellCache = true;
}




function DLSE_SneakSpells(){
    // 4 lines per spell.
    if(KDModSettings["DLSneak"]["DLSneak_SneakRoll"] && !KinkyDungeonLearnableSpells[3][1].includes("DLSneak_CrouchSprint")){
        KinkyDungeonLearnableSpells[3][1].splice((KinkyDungeonLearnableSpells[3][1].indexOf("Sneaky")+1),0,"DLSneak_CrouchSprint");}  // Add the spell if not already added
    else if(!KDModSettings["DLSneak"]["DLSneak_SneakRoll"] && KinkyDungeonLearnableSpells[3][1].includes("DLSneak_CrouchSprint")){
        KinkyDungeonLearnableSpells[3][1].splice((KinkyDungeonLearnableSpells[3][1].indexOf("DLSneak_CrouchSprint")),1);}             // Remove the spell if already added
}



// #region Sneak Button Code
////////////////////////////////////////////////////


// Change the mechanics of the Crouch button.
//////////////////////////////////////////////
KDInputTypes["crouch"] = (data) => {
    // If the player cannot kneel, don't allow the toggle. Send a proper message.
    if(KinkyDungeonPlayerTags.get("ForceStand") || KinkyDungeonPlayerTags.get("BlockKneel")){
        KinkyDungeonSendTextMessage(8, TextGet("KDSneakFail_ForcedStand"), "#ff5555", 1, true);
        return "";
    }
    // If the character cannot stand, don't actually toggle.
    if(KDForcedToGround()){
        if(KinkyDungeonPlayerTags.get("Petsuits")){
            KinkyDungeonSendTextMessage(8, TextGet("KDSneakFail_Petsuits"), "#ff5555", 1, true);
        }else{
            KinkyDungeonSendTextMessage(8, TextGet("KDSneakFail_ForcedToGround"), "#ff5555", 1, true);
        }
        return "";
    }
    // if(!KDGameData.Crouch){
    //     // TODO - More fun sound here.
    //     KinkyDungeonPlaySound(KinkyDungeonRootDirectory + "Audio/Footstep.ogg", undefined, 0.9);
    // }

    KDGameData.Crouch = !KDGameData.Crouch;
    if(KDModSettings["DLSneak"]["DLSneak_CrouchTakesTurn"]){
        KinkyDungeonAdvanceTime(1);             // Change this value to 1 to pass turn
    }else{
        KinkyDungeonAdvanceTime(0);             // Default behavior
    }
    return "";
}


// Code to disable crouch if you are put into a petsuit, etc.
// TODO - Do a better solution than this, like when you are stuffed in a suit,etc.
// > For some reason, petsuits won't do this with "postApply" event, but hogties do.
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
////////////////////////////////
// Sneaky Rework - Event Code //
////////////////////////////////
// Add necessary mappings just in case that they do not exist
if(!KDEventMapSpell.afterPlayerAttack){KDEventMapSpell["afterPlayerAttack"] = {};}

// Event that uncrouches the player after an attack.
KDAddEvent(KDEventMapSpell, "afterPlayerAttack", "DLSneak_Sneaky", (e, _weapon, data) => {
    // If Crouched AND the enemy was unaware of you.
    if(!KDForcedToGround() && KDGameData.Crouch && !data.enemy.aware){
        // If we can stand within two turns, we instantly stand up.
        let KneelStats = KDGetKneelStats(1, false);
        if(KneelStats.kneelRate >= 0.5){
            KDGameData.Crouch = false;          // Toggle off Crouch
            KDGameData.KneelTurns = 0;          // Blank KneelTurns so the player can stand.
            KinkyDungeonDressPlayer();          // "Dress" the player to make the player visibly stand.
            KinkyDungeonCalculateSlowLevel();   // Recalculate the slow level.

            KDGameData.MovePoints = 0;          // Clear lingering stun from movement, if any.
        }
    }
});



//#region Crouch Sprint
////////////////////////////////
let DLSneak_CrouchSprint = {name: "DLSneak_CrouchSprint", tags: ["buff", "utility"], school: "Any", spellPointCost: 1, prerequisite: "Sneaky", manacost: 0, components: [], level:1, passive: true, type:"", onhit:"", time: 0, delay: 0, range: 0, lifetime: 0, power: 0, damage: "inert",
    events: [
        {type: "DLSneak_CrouchSprint", trigger: "canSprint",},
        {type: "DLSneak_CrouchSprint", trigger: "calcSprint",},
    ]
}

// Event that allows sprinting while crouched.
KDAddEvent(KDEventMapSpell, "canSprint", "DLSneak_CrouchSprint", (_e, _spell, data) => {
    // TODO - Remove this KDForcedToGround() call once I fix the Crouch petsuit toggle bug.
    if (KDGameData.Crouch && KDHasSpell("DLSneak_CrouchSprint") && !KDForcedToGround()) {
        data.mustStand = false;         // Enable sprinting without standing.
    }
});

// Event to make sprinting cost more while crouched.
KDAddEvent(KDEventMapSpell, "calcSprint", "DLSneak_CrouchSprint", (_e, _spell, data) => {
    if (KDGameData.Crouch && KDHasSpell("DLSneak_CrouchSprint")) {
        data.boost -= 3;
    }
});

KinkyDungeonSpellList["Special"].push(DLSneak_CrouchSprint);