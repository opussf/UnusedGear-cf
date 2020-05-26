UnusedGear_MSG_ADDONNAME = "UnusedGear";
UnusedGear_MSG_VERSION   = GetAddOnMetadata(UnusedGear_MSG_ADDONNAME,"Version");
UnusedGear_MSG_AUTHOR    = "opussf";

-- Colours
COLOR_RED = "|cffff0000";
COLOR_GREEN = "|cff00ff00";
COLOR_BLUE = "|cff0000ff";
COLOR_PURPLE = "|cff700090";
COLOR_YELLOW = "|cffffff00";
COLOR_ORANGE = "|cffff6d00";
COLOR_GREY = "|cff808080";
COLOR_GOLD = "|cffcfb52b";
COLOR_NEON_BLUE = "|cff4d4dff";
COLOR_END = "|r";

UnusedGear = {}
UnusedGear_Options = {
	["targetBag"] = 0
}
UnusedGear_savedata = {}
-- itemLog = { link = { log, movedCount, lastMoved } }
-- ignoreItems = { link = true }
--[[
INEED.bindTypes = {
	[ITEM_SOULBOUND] = "Bound",
	[ITEM_BIND_ON_PICKUP] = "Bound",
}
INEED.scanTip = CreateFrame( "GameTooltip", "INEEDTip", UIParent, "GameTooltipTemplate" )
INEED.scanTip2 = _G["INEEDTipTextLeft2"]
INEED.scanTip3 = _G["INEEDTipTextLeft3"]
INEED.scanTip4 = _G["INEEDTipTextLeft4"]

]]

UnusedGear.armorTypes = {
	["Miscellaneous"] = 0,
	["Cloth"] = 1,
	["Leather"] = 2,
	["Mail"] = 3,
	["Plate"] = 4
}
UnusedGear.maxArmorType = 0

UnusedGear.maxArmorTypeByClass = {
	["DEATH KNIGHt"] = "Plate",
	["DEMON HUNTER"] = "Leather",
	["DRUID"] = "Leather",
	["HUNTER"] = "Mail",
	["MAGE"] = "Cloth",
	["MONK"] = "Leather",
	["PALADIN"] = "Plate",
	["PRIEST"] = "Cloth",
	["ROGUE"] = "Leather",
	["SHAMAN"] = "Mail",
	["WARLOCK"] = "Cloth",
	["WARRIOR"] = "Plate"
}

function UnusedGear.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_GREEN..UnusedGear_MSG_ADDONNAME.."> "..COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end
function UnusedGear.OnLoad()
	UnusedGear_Frame:RegisterEvent( "MERCHANT_SHOW" )
	UnusedGear_Frame:RegisterEvent( "SCRAPPING_MACHINE_SHOW" )
	UnusedGear_Frame:RegisterEvent( "EQUIPMENT_SETS_CHANGED" )
	UnusedGear_Frame:RegisterEvent( "AUCTION_HOUSE_SHOW" )
	UnusedGear_Frame:RegisterEvent( "BANKFRAME_OPENED" )
	UnusedGear_Frame:RegisterEvent( "ADDON_LOADED" )
	UnusedGear_Frame:RegisterEvent( "VARIABLES_LOADED" )
	UnusedGear_Frame:RegisterEvent( "PLAYER_LEAVING_WORLD" )
	local localizedClass, englishClass, classIndex = UnitClass( "player" )
	UnusedGear.maxArmorType = UnusedGear.armorTypes[ UnusedGear.maxArmorTypeByClass[ englishClass ] ]

	--AutoProfit:RegisterEvent("MERCHANT_CLOSED");
	--ap.ForAllJunk();
end

function UnusedGear.ADDON_LOADED()
	-- Unregister the event for this method.
	UnusedGear_Frame:UnregisterEvent("ADDON_LOADED")

	GameTooltip:HookScript( "OnTooltipSetItem", UnusedGear.hookSetItem )
	ItemRefTooltip:HookScript( "OnTooltipSetItem", UnusedGear.hookSetItem )
	UnusedGear.name = UnitName("player")
	UnusedGear.realm = GetRealmName()
end

function UnusedGear.VARIABLES_LOADED()
	-- Unregister the event for this method.
	UnusedGear_Frame:UnregisterEvent( "VARIABLES_LOADED" )

	UnusedGear_savedata[UnusedGear.realm] = UnusedGear_savedata[UnusedGear.realm] or {}
	UnusedGear_savedata[UnusedGear.realm][UnusedGear.name] = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name] or {}

	UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].itemLog = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].itemLog or {}
	UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].ignoreItems = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].ignoreItems or {}

	UnusedGear.myItemLog = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].itemLog
	UnusedGear.myIgnoreItems = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].ignoreItems
end
function UnusedGear.PLAYER_LEAVING_WORLD()
	for link, item in pairs( UnusedGear.myItemLog ) do
		if( ( item.lastSeen and item.lastSeen+3600 < time() ) or not item.lastSeen ) then -- one hour expire
			UnusedGear.myItemLog[link] = nil
		end
	end
end
function UnusedGear.MERCHANT_SHOW()
	--UnusedGear.Print( "MERCHANT_SHOW" )
	UnusedGear.BuildGearSets()
	UnusedGear.ExtractItems()
end
UnusedGear.SCRAPPING_MACHINE_SHOW = UnusedGear.MERCHANT_SHOW
UnusedGear.AUCTION_HOUSE_SHOW = UnusedGear.MERCHANT_SHOW
UnusedGear.BANKFRAME_OPENED = UnusedGear.MERCHANT_SHOW

function UnusedGear.EQUIPMENT_SETS_CHANGED()
	--UnusedGear.Print( "EQUIPMENT_SETS_CHANGED" )
end
function UnusedGear.BuildGearSets()
	UnusedGear.itemsInSets = {}
	for setNum = 0, C_EquipmentSet.GetNumEquipmentSets(), 1 do
		equipmentSetName = C_EquipmentSet.GetEquipmentSetInfo( setNum )
		if( equipmentSetName ) then
			local setItemArray = C_EquipmentSet.GetItemIDs( setNum )
			for i, itemID in pairs( setItemArray ) do
				if( not UnusedGear.itemsInSets[ itemID ] ) then
					UnusedGear.itemsInSets[ itemID ] = {}
				end
				table.insert( UnusedGear.itemsInSets[ itemID ], equipmentSetName )
			end
		end
	end
end
-- moveTests { testfunction, truthmessage, falsemessage }
moveTests = {
	{ function( link ) return not UnusedGear.myIgnoreItems[link]; end, nil, "Ignored" },
	{ function( link ) _, _, iRarity = GetItemInfo( link ); return iRarity < 6; end, nil, "Rarity is too high" },
	{ function( link )
			_, _, _, _, _, iType, iSubType = GetItemInfo( link )
			iArmorType = UnusedGear.armorTypes[ iSubType ]
			return( ( iType == "Armor" and iArmorType ) or iType == "Weapon" or iSubType == "Shields" )
		end, "Armor, weapon, or shield", nil }, --"non equipable item" },
	{ function( link ) iID = tonumber( UnusedGear.GetItemIdFromLink( link ) ); return not UnusedGear.itemsInSets[ iID ]; end,
			"not in itemsets", "in an itemset" },
	{ function( link ) iName = GetItemInfo( link ); return not string.find( iName, "Tabard" ); end, nil, nil }, --"not a Tabard", "is a Tabard" },
}
function UnusedGear.ForAllGear( action, message )
	-- work through all the times
	moveCount = 0
	for bag = 0, 4 do
		if GetContainerNumSlots( bag ) > 0 then  -- This slot has a bag
			if not GetBagSlotFlag( bag, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP ) then  -- this bag is not ignored
				for slot = 0, GetContainerNumSlots( bag ) do -- work through this bag
					itemLog = {}
					toMove, moved = true, false  -- assume to moved
					local texture, itemCount, locked, quality, readable, lootable, link =
							GetContainerItemInfo( bag, slot )
					if( link ) then  -- only do work with slots that have items
						test = 1
						while( toMove and test <= #moveTests ) do
							testStruct = moveTests[test]
							testResult = testStruct[1]( link )
							toMove = toMove and testResult  -- any failure will set this to false
							testLog = testStruct[ testResult and 2 or 3 ]
							if testLog then table.insert( itemLog, testStruct[ testResult and 2 or 3 ] ) end
							--print( test..":"..(toMove and "True" or "False" ) )
							test = test + 1
						end
					end
					if toMove then
						targetBagID, targetSlot = UnusedGear.GetLastFreeSlotInBag( UnusedGear_Options.targetBag )
						if( targetBagID ) then
							ClearCursor()
							PickupContainerItem( bag,  slot )
							if( targetBagID == 0 ) then
								PutItemInBackpack()
								table.insert( itemLog, "Moved to Backpack" )
							else
								PutItemInBag( targetBagID + 19 )
								table.insert( itemLog, "Moved to bag:"..targetBagID )
							end
							moveCount = moveCount + 1
							moved = true
						end
					end
					if( link ) then
						UnusedGear.myItemLog[link] = UnusedGear.myItemLog[link] or { ["countMoved"] = 0 }

						if( UnusedGear.myItemLog[link].countMoved > 20 ) then
							table.insert( itemLog, "moved many times.\nI'm ignoring this item in the future.")
							UnusedGear.myIgnoreItems[link] = time()
						end
						UnusedGear.myItemLog[link]["log"] = table.concat( itemLog, "; " )
						UnusedGear.myItemLog[link]["lastSeen"] = time()
						if moved then
							UnusedGear.myItemLog[link]["lastMoved"] = time()
							UnusedGear.myItemLog[link]["countMoved"] = UnusedGear.myItemLog[link].countMoved + 1
						end
					end
				end
			end
		end
	end
end
function UnusedGear.ExtractItems()
	UnusedGear.ForAllGear( "", "" )
end
function UnusedGear.GetItemIdFromLink( itemLink )
	-- returns just the integer itemID
	-- itemLink can be a full link, or just "item:999999999"
	if itemLink then
		return strmatch( itemLink, "item:(%d*)" )
	end
end
function UnusedGear.GetLastFreeSlotInBag( bagID )
	freeSlots, typeid = GetContainerNumFreeSlots( bagID )
	if( freeSlots > 0 ) then
		for slot = GetContainerNumSlots( bagID ), 0, -1 do
			local texture = GetContainerItemInfo( bagID, slot )
			if not texture then
				return bagID, slot
			end
		end
	end
end
function UnusedGear.hookSetItem( tooltip, ... ) -- is passed the tooltip frame as a table
	local item, link = tooltip:GetItem()  -- name, link
	if( UnusedGear.myItemLog[link] and UnusedGear.myItemLog[link].log ) then
		tooltip:AddDoubleLine( UnusedGear.myItemLog[link].log,
				( UnusedGear.myItemLog[link].countMoved > 0 and "Moved:"..UnusedGear.myItemLog[link].countMoved or "" ) )
	end
end
