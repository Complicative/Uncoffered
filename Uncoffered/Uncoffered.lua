Uncoffered = {
  name = "Uncoffered",
  version = "1.0.5",
  author = "@Complicative",
}

Uncoffered.Settings = {
  --Saved Settings
  --None for now
}

--------------------------------------

local debug = false

--Local Utility Functions
local function cStart(hex) return "|c" .. hex end                                                         --returns colour start for a string

local function cEnd() return "|r" end                                                                     --return colour end string

local function getTimeStamp() return cStart("888888") .. "[" .. os.date('%H:%M:%S') .. "] " .. cEnd() end --returns a timestamp in gray

local pColoredStr = function(num1, num2, c1, c2)                                                          --returns a percantage of num1 in colour c1 if num1 > num2. c2 if num1 < num2
  local color = function() if num1 > num2 then return c1 else return c2 end end
  return string.format("%s%.2f%s%s", cStart(color()), num1 * 100, "%", cEnd())
end

------------------------------------


function Uncoffered.IsCollectedFromSetId(setId, i)
  --returns if item is collected
  local _, slot = GetItemSetCollectionPieceInfo(setId, i)
  return IsItemSetCollectionSlotUnlocked(setId, slot)
end

function Uncoffered.GetItemLinkFromId(id)
  local cofferId = id
  --returns an ItemLink from id
  return "|H1:item:" ..
      cofferId .. ":0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
end

function Uncoffered.GetIdFromItemLink(itemLink) return GetItemLinkItemId(itemLink) end --returns Id from ItemLink

function Uncoffered.GetMysteryFromNormal(itemLink)
  --returns ItemLink of the Mystery Coffer, that the Normal Coffer is related to
  local cofferId = Uncoffered.GetIdFromItemLink(itemLink)
  --Finds the cofferId in Database and returns the cofferid it is saved in. Hardcoded Database!
  for k, v in pairs(UncofferedData.CofferDB) do
    for i = 1, #v do
      if cofferId == v[i] then
        return Uncoffered.GetItemLinkFromId(k)
      end
    end
  end
  return nil
end

function Uncoffered.GetNormalInfo(itemLink, type)
  --returns info on a normal coffer
  --type == 0 -> Undaunted Coffer
  --type == 1 --> Imperial City Coffer

  local cofferId = Uncoffered.GetIdFromItemLink(itemLink)
  local cofferName = GetItemLinkName(itemLink)

  --Ids of the sets that can drop from the coffer
  --IC coffers only have 1 set, so every set2 var will be 0 or nil!
  local _, _, _, _, _, set1Id = GetItemLinkContainerSetInfo(itemLink, 1)
  local _, _, _, _, _, set2Id = GetItemLinkContainerSetInfo(itemLink, 2)

  local set1Collected = 0
  local set2Collected = 0
  local total --IC coffer drop only 1 set -> Undaunted Coffers drop 6 shoulder pieces. IC Coffers drop 3.
  if type == 0 then total = 6 end
  if type == 1 then total = 3 end

  for i = 4, 6 do --1 to 3 are the mask pieces. We need only the shoulders
    if Uncoffered.IsCollectedFromSetId(set1Id, i) then
      set1Collected = set1Collected + 1
    end
    if Uncoffered.IsCollectedFromSetId(set2Id, i) then
      set2Collected = set2Collected + 1
    end
  end

  local totalCollected = set1Collected + set2Collected
  local pCollected = (totalCollected / total)
  local pUncollected = 1 - pCollected

  --returns all the collected info
  return cofferId, cofferName, totalCollected, total, pCollected, pUncollected, set1Id, set2Id
end

function Uncoffered.GetMysteryInfo(itemLink, type)
  --returns info on a mystery coffer
  --type == 0 -> Undaunted Coffer
  --type == 1 --> Imperial City Coffer

  local cofferId = Uncoffered.GetIdFromItemLink(itemLink)
  local cofferName = GetItemLinkName(itemLink)
  local totalCollected = 0
  --cofferAmount comes from hardcoded Database
  local setsAmount = #UncofferedData.CofferDB[cofferId]
  local total
  --Undaunted Coffers drop double the shoulder
  if type == 0 then total = (setsAmount * 3 * 2) end
  if type == 1 then total = (setsAmount * 3) end

  --Table for saving the % of each normal coffer. Used to find the one with the best and output in the tooltip as advice, which one to open.
  local normalTable = {}

  for i = 1, setsAmount do
    --Counts the collected amount of shoulder and saves the highest amount of uncollected % in the table
    local normalId = UncofferedData.CofferDB[cofferId][i]
    local normalItemLink = (Uncoffered.GetItemLinkFromId(normalId))
    local _, _, tCollected = Uncoffered.GetNormalInfo(normalItemLink, type)
    totalCollected = totalCollected + tCollected
    table.insert(normalTable, Uncoffered.GetItemLinkFromId(normalId))
  end
  local pCollected = (totalCollected / total)
  local pUncollected = 1 - pCollected
  local pCollectedPow = pCollected ^ 5
  if type == 0 then pCollectedPow = pCollected ^ 5 end
  if type == 1 then pCollectedPow = pCollected ^ 2 end
  local pUncollectedPow = 1 - pCollectedPow

  --returns all the collected info
  return cofferId, cofferName, totalCollected, total, pCollected, pUncollected, pCollectedPow, pUncollectedPow
  , normalTable
end

function Uncoffered.GetBestNormalFromMystery(itemLink, type)
  --returns the normal coffer, with the highest chances for a new item, thats related to the mystery coffer
  --type == 0 -> Undaunted Coffer
  --type == 1 --> Imperial City Coffer

  --gets the table with the % of every related normal coffer
  local cofferId, _, _, _, _, _, _, _, normalTable = Uncoffered.GetMysteryInfo(itemLink, type)

  local highestP = 0
  local highestName = ""
  local highestId
  local highestItemLink
  --finds the highest % and the name of the coffer (Same Order in the hardcoded Database)
  for i = 1, #normalTable do
    local cId, cName, _, _, _, pUncollected, _, _ = Uncoffered.GetNormalInfo(normalTable[i], type)
    if highestP < pUncollected then
      highestP = pUncollected
      highestItemLink = normalTable[i]
      highestId = cId
      highestName = cName
    end
  end

  --returns the highest % and the name of the coffer
  return highestItemLink, highestId, highestName, highestP
end

local function GetToolTipTextMystery(itemLink, type)
  --writes and returns string with the tooltip text for a mystery coffer
  --type == 0 -> Undaunted Coffer
  --type == 1 --> Imperial City Coffer

  --get all the info needed for the tooltip
  local _, cofferName, totalCollected, total, _, _, _, pUncollectedPow = Uncoffered.GetMysteryInfo(itemLink, type)
  local _, _, highestName, highestP = Uncoffered.GetBestNormalFromMystery(itemLink, type)

  local str = ""

  --sets the vars for the difference between IC and Undaunted Coffers
  local toOpen, normalCost
  if type == 0 then
    toOpen, normalCost = "5", "5|t24:24:esoui/art/currency/undauntedkey_64.dds|t"
  end
  if type == 1 then
    toOpen, normalCost = "2", "20k|t24:24:esoui/art/currency/currency_telvar_64.dds|t"
  end

  --If everything is collected, we don't need any fancy tooltip
  if totalCollected == total then
    return string.format("%s%s/%s Collected.\nEverything has been collected. Well done!%s", cStart("888888"),
      totalCollected, total, cEnd())
  end

  --concats the string
  str = str .. string.format("%d/%d Collected\n", totalCollected, total)
  str = str ..
      string.format("Open %dx %s: %s\n", toOpen, cofferName, pColoredStr(pUncollectedPow, highestP, "00FF00", "FF0000"))
  str = str ..
      string.format("Best %s Coffer: %s (%s)", normalCost, highestName,
        pColoredStr(highestP, pUncollectedPow, "00FF00", "FF0000"))
  return str --returns the finished string
end

local function GetToolTipTextNormal(itemLink, type)
  --writes and returns string with the tooltip text for a normal coffer
  --type == 0 -> Undaunted Coffer
  --type == 1 --> Imperial City Coffer

  --get all the info needed for the tooltip
  local _, cofferName, totalCollected, total, _, pUncollected = Uncoffered.GetNormalInfo(itemLink, type)
  local _, mysteryName, _, totalMystery, _, _, _, pMysteryPow = Uncoffered.GetMysteryInfo(
  Uncoffered.GetMysteryFromNormal(itemLink)
  , type)

  --writes and returns string with the tooltip text for a normal coffer
  local str = ""
  local toOpen

  --sets the vars for the difference between IC and Undaunted Coffers
  if type == 1 then toOpen = 2 end
  if type == 0 then toOpen = 5 end

  --If everything is collected, we don't need any fancy tooltip
  if totalCollected == total then
    return string.format("%s%s/%s Collected.\nEverything has been collected. Well done!%s", cStart("888888"),
      totalCollected, total, cEnd())
  end

  --concats the string
  str = str .. string.format("%d/%d Collected\n", totalCollected, total)
  --@SimpsForBreda uncomment the line below
  str = str ..
      string.format("New %s item from %dx %s: %.2f%%\n", cofferName, toOpen, mysteryName,
        (1 - ((totalMystery - (total - totalCollected)) / totalMystery) ^ toOpen) * 100)
  str = str .. string.format("Chance for any new shoulder:\n")
  str = str .. string.format("1x %s: %s\n", cofferName, pColoredStr(pUncollected, pMysteryPow, "00FF00", "FF0000"))
  str = str ..
      string.format("%dx %s: %s", toOpen, mysteryName, pColoredStr(pMysteryPow, pUncollected, "00FF00", "FF0000"))

  return str --returns the finished string
end

local function GetInfoText(itemLink)
  --returns final tooltip text. Whatever string is returned here, will end up in the tooltip
  --decision about what type of coffer it is, happens here

  local cofferId = Uncoffered.GetIdFromItemLink(itemLink)
  local type

  if UncofferedData.CofferDB[cofferId] ~= nil then
    --Mystery Coffer
    if cofferId == 184208 then type = 1 else type = 0 end --IC or Undaunted Coffer
    return GetToolTipTextMystery(itemLink, type)          --gets the tooltip string and returns it
  end

  if Uncoffered.GetMysteryFromNormal(itemLink) ~= nil then
    --Normal Coffer
    local mysteryCoffer = Uncoffered.GetMysteryFromNormal(itemLink)
    if Uncoffered.GetIdFromItemLink(mysteryCoffer) == 184208 then type = 1 else type = 0 end --IC or Undaunted Coffer
    return GetToolTipTextNormal(itemLink, type)                                              --gets the tooltip string and returns it
  end
end

local function AddInfo(tooltip, item)
  --don't mess with this. Mostly stolen, cause tooltips are hard
  if item then
    tooltip:AddVerticalPadding(8)
    ZO_Tooltip_AddDivider(tooltip)
    tooltip:AddLine(item, "", 1, 1, 1, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, true)
  end
end

local function TooltipHook(tooltipControl, method, linkFunc)
  --don't mess with this. Stolen, cause tooltips are hard
  local origMethod = tooltipControl[method]

  tooltipControl[method] = function(self, ...)
    origMethod(self, ...)
    AddInfo(self, GetInfoText(linkFunc(...)))
  end
end

local function ReturnItemLink(itemLink)
  --don't mess with this. Stolen, cause tooltips are hard
  return itemLink
end

---------------------------------------------
-- OnAddOnLoaded --
---------------------------------------------

function Uncoffered.OnAddOnLoaded(event, addonName) --initialize the addon
  if addonName ~= Uncoffered.name then return end

  --don't mess with this. Stolen, cause tooltips are hard
  TooltipHook(ItemTooltip, "SetStoreItem", GetStoreItemLink)
  TooltipHook(ItemTooltip, "SetBagItem", GetItemLink)
  TooltipHook(ItemTooltip, "SetTradeItem", GetTradeItemLink)
  TooltipHook(ItemTooltip, "SetBuybackItem", GetBuybackItemLink)
  TooltipHook(ItemTooltip, "SetAttachedMailItem", GetAttachedItemLink)
  TooltipHook(ItemTooltip, "SetLootItem", GetLootItemLink)
  TooltipHook(ItemTooltip, "SetTradingHouseItem", GetTradingHouseSearchResultItemLink)
  TooltipHook(ItemTooltip, "SetTradingHouseListing", GetTradingHouseListingItemLink)
  TooltipHook(ItemTooltip, "SetLink", ReturnItemLink)

  TooltipHook(PopupTooltip, "SetLink", ReturnItemLink)



  --Saved Settings (None currently)
end

----------------------------------------------
-- Events Setup --
----------------------------------------------
EVENT_MANAGER:RegisterForEvent(Uncoffered.name, EVENT_ADD_ON_LOADED, Uncoffered.OnAddOnLoaded)

----------------------------------------------
-- Slash Commands --
----------------------------------------------

local function printCoffers(id)
  for i = 1, #UncofferedData.CofferDB[id] do
    d(getTimeStamp() .. Uncoffered.GetItemLinkFromId(UncofferedData.CofferDB[id][i]))
  end
end

SLASH_COMMANDS["/uncoffered"] = function(args)
  if args == "debug" then
    debug = not debug
    d(getTimeStamp() .. "debug has been set to " .. tostring(debug))
    return
  end
  if args == "print" then
    d(getTimeStamp() .. "---------------------------")
    d(
    "This is a debug function. I left it in, with debug off, since I think, it could be usefull in non-debug mode as well.")
    d(getTimeStamp() .. "---------------------------")
    d(getTimeStamp() .. Uncoffered.GetItemLinkFromId(153513))
    printCoffers(153513)
    d(getTimeStamp() .. "---------------------------")
    d(getTimeStamp() .. Uncoffered.GetItemLinkFromId(153514))
    printCoffers(153514)
    d(getTimeStamp() .. "---------------------------")
    d(getTimeStamp() .. Uncoffered.GetItemLinkFromId(153515))
    printCoffers(153515)
    d(getTimeStamp() .. "---------------------------")
    d(getTimeStamp() .. Uncoffered.GetItemLinkFromId(184208))
    printCoffers(184208)
    d(getTimeStamp() .. "---------------------------")
    return
  end

  CHAT_SYSTEM:AddMessage(string.format("%s by %s, Version: %s", Uncoffered.name, Uncoffered.author, Uncoffered.version))
end
