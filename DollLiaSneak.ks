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










// Mod Code HERE
////////////////////////////////////////////////////