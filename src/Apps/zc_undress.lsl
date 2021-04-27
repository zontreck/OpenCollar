/*
This file is a part of zCollar.
Copyright 2021

: Contributors :
Aria (Tashia Redrose)
    * April 2021    -       Rebranded as a zCollar script: zc_undress
    * Sep 2020      -        Began rewrite of oc_undress
et al.

Licensed under the GPLv2. See LICENSE for full details.
https://github.com/zontreck/zCollar
*/
#include "MasterFile.lsl"

string g_sParentMenu = "Apps";
string g_sSubMenu = "Undress";



Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Undress App]";
    list lButtons = ["Rm. Clothes", "Clothing Locks"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (llSubStringIndex(llToLower(sStr),llToLower(g_sSubMenu)) && llToLower(sStr) != "menu "+llToLower(g_sSubMenu)) return;
    if (iNum & C_OWNER && llToLower(sStr) == "runaway") {
        g_lOwner=[];
        g_lTrust=[];
        g_lBlock=[];
        return;
    }
    if (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+llToLower(g_sSubMenu)) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        //integer iWSuccess = 0; 
        //string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        //string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        //string sText;
        /// [prefix] g_sSubMenu sChangetype sChangevalue
    }
}

key g_kWearer;
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_iLocked=FALSE;
integer g_iOutfitScan;
integer g_iOutfitLstn=-1;

//integer TIMEOUT_READY = 30497;
//integer TIMEOUT_REGISTER = 30498;
//integer TIMEOUT_FIRED = 30499;



key g_kMenuUser;
integer g_iMenuUser;

list g_lLayers = ["gloves","jacket","pants","shirt","shoes","skirt","socks","underpants","undershirt","skin","eyes","hair","shape", "universal", "physics", "tattoo", "alpha"];

//integer g_iBitMask;
list g_lMasks;
ApplyMask(){
    integer i=0;
    integer end = llGetListLength(g_lLayers);
    for(i=0;i<end;i++){
        if(llListFindList(g_lMasks,[llList2String(g_lLayers,i)])!=-1)
            llOwnerSay("@remoutfit:"+llList2String(g_lLayers,i)+"=n");
        else
            llOwnerSay("@remoutfit:"+llList2String(g_lLayers,i)+"=y");
    }
}
CLock(key kAv, integer iAuth){
    string sPrompt = "[Undress - Clothing Locks]\n\nThis menu will allow you to lock or unlock clothing layers";
    list lButtons = [];
    
    // Create checkboxes
    integer i = 0;
    integer end = llGetListLength(g_lLayers);
    for(i=0;i<end;i++){
        if(llListFindList(g_lMasks,[llList2String(g_lLayers,i)])!=-1)
            lButtons += Checkbox(TRUE,llList2String(g_lLayers, i));
        else
            lButtons += Checkbox(FALSE,llList2String(g_lLayers,i));
    }
    
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "undress~locks");
}


list Uncheckbox(string sBtn){
    list ret = [0,""];
    list lTmp = llParseString2List(sBtn,[" "],[]);
    ret = llListReplaceList(ret, [llListFindList(g_lCheckboxes,[llList2String(lTmp,0)])], 0,0);
    ret = llListReplaceList(ret, [llDumpList2String(llList2List(lTmp,1,-1), " ")], 1,1);
    return ret;
}


default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT){
            llResetScript();
        } else if(iNum == READY){
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        } else if(iNum == STARTUP){
            state active;
        }
    }
}
state active
{
    on_rez(integer t){
        llResetScript();
    }
    state_entry()
    {
        if(llGetStartParameter()!=0)llResetScript();
        g_kWearer = llGetOwner();
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum == COMMAND) {
            list lTmp = llParseString2List(sStr,["|>"],[]);
            integer iMask = llList2Integer(lTmp,0);
            string sCmd = llList2String(lTmp,1);
            if(!(iMask&(C_OWNER|C_GROUP|C_TRUSTED|C_PUBLIC|C_WEARER)))return;
            
            UserCommand(iMask, sCmd, kID);
        }
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                integer iRespring = TRUE;
                if(sMenu == "Menu~Main"){
                    if(sMsg == UPMENU) {
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, CMD_ZERO, "menu "+g_sParentMenu, kAv);
                    }
                    else if(sMsg == "Rm. Clothes"){
                        // query viewer for worn clothing layers before proceeding
                        g_iOutfitScan = llRound(llFrand(43895819));
                        llListenRemove(g_iOutfitLstn);
                        g_kMenuUser = kAv;
                        g_iMenuUser = iAuth;
                        g_iOutfitLstn = llListen(g_iOutfitScan, "", g_kWearer, "");
                        llOwnerSay("@getoutfitnames="+(string)g_iOutfitScan);
                        iRespring=FALSE;
                    } else if(sMsg == "Clothing Locks"){
                        CLock(kAv,iAuth);
                        iRespring=FALSE;
                    }
                    
                    if(iRespring)
                        Menu(kAv,iAuth);
                } else if(sMenu == "undress~select"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv, iAuth);
                    } else {
                        llOwnerSay("@remoutfit:"+sMsg+"=force");
                    }
                    
                    if(iRespring){
                        g_iOutfitScan = llRound(llFrand(58439875));
                        llListenRemove(g_iOutfitLstn);
                        g_iOutfitLstn = llListen(g_iOutfitScan, "", g_kWearer, "");
                        llOwnerSay("@getoutfitnames="+(string)g_iOutfitScan);
                    }
                } else if(sMenu == "undress~locks"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv, iAuth);
                    }else {
                        // Checkbox was selected
                        list lLabel = Uncheckbox(sMsg);
                        integer index= llListFindList(g_lMasks, [llList2String(lLabel,1)]);
                        if(llList2String(lLabel,0) == "1"){
                            if(index!=-1)
                                g_lMasks = llDeleteSubList(g_lMasks, index,index);
                        }else {
                            if(index==-1)g_lMasks+=llList2String(lLabel,1);
                        }
                        
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "undress_mask="+llDumpList2String(g_lMasks,"|"),"");
                    }
                    
                    
                    if(iRespring)CLock(kAv,iAuth);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            string sToken = llList2String(lSettings,0);
            string sVar = llList2String(lSettings,1);
            string sVal = llList2String(lSettings,2);
            
            
            //integer ind = llListFindList(g_lSettingsReqs, [sToken+"_"+sVar]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            if(sToken=="global"){
                if(sVar=="locked"){
                    g_iLocked=(integer)sVal;
                } else if(sVar == "checkboxes"){
                    g_lCheckboxes = llParseString2List(sVal, [","],[]);
                }
            } else if(sToken == "undress"){
                if(sVar == "mask"){
                    g_lMasks = llParseString2List(sVal, ["|"],[]);
                    ApplyMask();
                }
            }
        } else if(iNum == LM_SETTING_EMPTY){
            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            if(sStr == "undress_mask"){
                g_lMasks = [];
                ApplyMask();
            }
        } else if(iNum == RLV_REFRESH)ApplyMask();
        else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            list lSettings = llParseString2List(sStr, ["_"],[]);
            if(llList2String(lSettings,0)=="global")
                if(llList2String(lSettings,1) == "locked") g_iLocked=FALSE;
        }else if(iNum == REBOOT)llResetScript();
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
    
    
    listen(integer c,string n,key i,string m){
        if(c == g_iOutfitScan){
            //llWhisper(0, "outfit worn reply: "+m);
            llListenRemove(g_iOutfitLstn);
            
            list lButtons;
            list lSystem = ["skin", "eyes", "hair", "shape"];
            list lPar = llParseString2List(m,[","],[]);
            integer ix=0;
            integer xend = llGetListLength(lPar);
            for(ix=0;ix<xend;ix++)
            {
                if(llListFindList(lSystem,[llList2String(lPar,ix)])==-1)lButtons+=llList2String(lPar,ix);
            }
            string sPrompt = "[Undress - Rm. Clothes]\nSelect a layer to remove";
            Dialog(g_kMenuUser, sPrompt,lButtons, [UPMENU],0,g_iMenuUser, "undress~select");
        }
    }
}