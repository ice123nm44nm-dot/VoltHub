--[[
	Auto Collect Money + Auto Take Orders  —  Restaurant Tycoon 2  (uwuware UI)

	Money flow (from the game's own client code):
	  server drops a `Bill` model on a table (Tycoon.Items.Surface.<table>.Bill, attribute Value),
	  the client's CollectBill module answers the E prompt with
	      ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
	          Name = "CollectBill", FurnitureModel = <table>, Tycoon = <tycoon> })
	  and the server pays out and deletes the Bill. This script sends exactly that, for every
	  table that has an uncollected bill — no walking, no prompt, no character movement.

	Take orders (same remote, from ...Modules.Tasks.TakeOrder):
	      ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
	          Name = "TakeOrder", GroupId = <group folder name>, CustomerId = <customer model name>,
	          Tycoon = <tycoon> })
	  fired only while the customer's state is CustomerState.Ordering, which is the same condition
	  the client uses to show its E prompt. Verified live: it works from 47.9 studs away, the server
	  ignores a customer that is not Ordering, and firing repeatedly advances the customer once.

	Collect dishes (same remote, from ...Modules.Tasks.CollectDishes):
	      ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
	          Name = "CollectDishes", FurnitureModel = <the table>, Tycoon = <tycoon> })
	  FurnitureModel is the table itself, not its Trash child; a table is collectable when
	  <table>.Trash has the attribute Collectable == true.

	UI: uwuware (loadstring'd). Note the copy that actually loads is the older single-window
	build, so panels are created with library:CreateWindow + window:AddToggle/AddSlider/... .
	A second CreateWindow does not auto-resize in that build, so everything lives in one window.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local RestaurantEvents = Events:WaitForChild("Restaurant")
local TaskCompleted = RestaurantEvents:WaitForChild("TaskCompleted")
local NotificationAdded = Events:WaitForChild("NotificationAdded")

local UI_URL = "https://raw.githubusercontent.com/GhostDuckyy/UI-Libraries/3b0bcba89893baa65d36b12b33e70e93ebc8b122/uwuware/source.lua"

--------------------------------------------------------------------------------
-- state (kept in getgenv so it survives a live-reload)
--------------------------------------------------------------------------------

local genv = (getgenv and getgenv()) or _G
genv.__autoCollectMoney = genv.__autoCollectMoney or {
	enabled = true,
	notify = true,
	interval = 0.5,
	minValue = 0,
	bills = 0,
	earned = 0,
	lastValue = 0,
	takeOrders = true,
	orders = 0,
	collectDishes = true,
	dishes = 0,
	base = nil,
	gen = 0,
}
local S = genv.__autoCollectMoney

-- Snap any persisted value back onto its slider grid and clamp it. Without this a
-- leftover 0.6000000000000001 keeps printing in the interval box, because the slider
-- writes the value straight into its text field instead of re-rounding it.
S.interval = math.clamp(math.floor((tonumber(S.interval) or 0.5) / 0.25 + 0.5) * 0.25, 0.25, 3)
S.minValue = math.clamp(math.floor((tonumber(S.minValue) or 0) / 5 + 0.5) * 5, 0, 500)

-- fields added after the first release: default them for an older saved table
S.takeOrders = S.takeOrders ~= false
S.orders = tonumber(S.orders) or 0

S.collectDishes = S.collectDishes ~= false
S.dishes = tonumber(S.dishes) or 0

-- Reload guard: a live-reload replaces the module but any thread the previous run
-- spawned keeps running, so each run claims a generation and the loop dies when it
-- is no longer the current one.
S.gen = (S.gen or 0) + 1
local myGen = S.gen

-- live-reload hands each run a STATE table via getgenv(); reach it that way rather
-- than as a bare global so the file type-checks cleanly.
local function onCleanup(fn)
	local live = genv.STATE
	if type(live) == "table" and live.onCleanup then
		live.onCleanup(fn)
	end
end

-- wipe the ScreenGui left behind by a previous run before building a new one
if S.base then
	pcall(function()
		S.base:Destroy()
	end)
	S.base = nil
end

--------------------------------------------------------------------------------
-- collection
--------------------------------------------------------------------------------

-- LocalPlayer.Tycoon is an ObjectValue the game keeps pointed at the plot you own.
local function getTycoon()
	local holder = LocalPlayer:FindFirstChild("Tycoon")
	local tycoon = holder and holder.Value
	if tycoon and tycoon.Parent then
		return tycoon
	end
	return nil
end

-- Tables are the children of <tycoon>.Items.Surface; a collectable bill is a `Bill`
-- child the server has not marked Taken yet.
local function findCollectableBill(tycoon)
	local items = tycoon:FindFirstChild("Items")
	local surface = items and items:FindFirstChild("Surface")
	if not surface then
		return nil
	end

	local bestTable, bestValue
	for _, furniture in ipairs(surface:GetChildren()) do
		local bill = furniture:FindFirstChild("Bill")
		if bill and not bill:GetAttribute("Taken") then
			local value = bill:GetAttribute("Value") or 0
			if value >= S.minValue and (not bestValue or value > bestValue) then
				bestTable, bestValue = furniture, value
			end
		end
	end

	return bestTable, bestValue
end

local function collectOnce(manual)
	local tycoon = getTycoon()
	if not tycoon then
		return false
	end

	local table, value = findCollectableBill(tycoon)
	if not table then
		if manual then
			NotificationAdded:Fire("Auto Collect: no bills on the tables right now")
		end
		return false
	end

	-- the exact payload the game's own CollectBill module fires
	TaskCompleted:FireServer({
		Name = "CollectBill",
		FurnitureModel = table,
		Tycoon = tycoon,
	})

	S.bills += 1
	S.earned += value
	S.lastValue = value

	if S.notify then
		NotificationAdded:Fire(("Money Collected +$%d"):format(value))
	end
	return true
end

--------------------------------------------------------------------------------
-- collect dishes
--------------------------------------------------------------------------------

-- A table is collectable when its `Trash` child has the Collectable attribute, and the
-- payload names the TABLE (not the Trash) - the same condition the game's own
-- CollectDishes module checks before showing its E prompt.
local DISH_REFIRE_DELAY = 0.5
local lastDish = setmetatable({}, { __mode = "k" })

local function collectDishesOnce()
	local tycoon = getTycoon()
	if not tycoon then
		return
	end

	local items = tycoon:FindFirstChild("Items")
	local surface = items and items:FindFirstChild("Surface")
	if not surface then
		return
	end

	local now = os.clock()
	for _, furniture in ipairs(surface:GetChildren()) do
		local trash = furniture:FindFirstChild("Trash")
		if trash and trash:GetAttribute("Collectable") == true then
			local last = lastDish[furniture]
			if not last or (now - last) >= DISH_REFIRE_DELAY then
				lastDish[furniture] = now
				TaskCompleted:FireServer({
					Name = "CollectDishes",
					FurnitureModel = furniture,
					Tycoon = tycoon,
				})
				S.dishes += 1
				return
			end
		end
	end
end

--------------------------------------------------------------------------------
-- take orders
--------------------------------------------------------------------------------

-- Walk the path with FindFirstChild rather than WaitForChild so a slow join can never
-- block the loop: while something is still missing the sweep just does nothing and
-- tries again on the next tick.
local function findPath(root, path)
	local node = root
	for segment in string.gmatch(path, "[^%.]+") do
		node = node:FindFirstChild(segment)
		if not node then
			return nil
		end
	end
	return node
end

local takeDeps
local function getTakeDeps()
	if takeDeps then
		return takeDeps
	end

	local taskEnum = findPath(ReplicatedStorage, "Source.Enums.Restaurant.Task")
	local stateEnum = findPath(ReplicatedStorage, "Source.Enums.Restaurant.Customer.CustomerState")
	local customersModule = findPath(LocalPlayer, "PlayerScripts.Source.Systems.Restaurant.Customers")
	if not (taskEnum and stateEnum and customersModule) then
		return nil
	end

	local ok, deps = pcall(function()
		return {
			Task = require(taskEnum),
			CustomerState = require(stateEnum),
			Customers = require(customersModule),
		}
	end)
	if ok then
		takeDeps = deps
	end
	return takeDeps
end

-- <tycoon>.ClientCustomers.<groupId>.<customerId>, and the module's own state table is
-- TycoonStorage[tycoon].Groups[groupId].Customers[customerId].State.
local TAKE_REFIRE_DELAY = 1
local lastTakeOrder = {}

local function takeOrderFor(deps, tycoon, groupId, customerId)
	local key = groupId .. "/" .. customerId
	local now = os.clock()
	local last = lastTakeOrder[key]
	if last and (now - last) < TAKE_REFIRE_DELAY then
		return
	end

	-- the state can change between the sweep and here, so check once more
	if deps.Customers:GetCustomerState(tycoon, groupId, customerId) ~= deps.CustomerState.Ordering then
		return
	end

	lastTakeOrder[key] = now
	TaskCompleted:FireServer({
		Name = deps.Task.TakeOrder,
		GroupId = groupId,
		CustomerId = customerId,
		Tycoon = tycoon,
	})

	S.orders += 1
end

local function sweepOrders()
	local deps = getTakeDeps()
	if not deps then
		return
	end

	local tycoon = getTycoon()
	if not tycoon then
		return
	end

	local store = deps.Customers:GetStorage(tycoon)
	if not store then
		return
	end

	for groupId, groupData in store.Groups do
		local customerList = groupData.Customers
		if customerList then
			for customerId, customerData in customerList do
				if customerData.State == deps.CustomerState.Ordering then
					takeOrderFor(deps, tycoon, groupId, customerId)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- uwuware UI
--------------------------------------------------------------------------------

local library = loadstring(game:HttpGet(UI_URL))()
if type(library) ~= "table" then
	library = genv.library
end
if type(library) ~= "table" then
	error("uwuware failed to load from " .. UI_URL)
end

local main = library:CreateWindow("Auto Collect Money")

main:AddLabel({ text = "Auto-collects $ bills" })

main:AddToggle({
	text = "Enabled",
	flag = "ACM_Enabled",
	state = S.enabled,
	callback = function(value)
		S.enabled = value
	end,
})

main:AddToggle({
	text = "Notify on collect",
	flag = "ACM_Notify",
	state = S.notify,
	callback = function(value)
		S.notify = value
	end,
})

main:AddSlider({
	text = "Interval (s)",
	flag = "ACM_Interval",
	min = 0.25,
	max = 3,
	float = 0.25,
	value = S.interval,
	callback = function(value)
		S.interval = value
	end,
})

main:AddSlider({
	text = "Min bill value ($)",
	flag = "ACM_MinValue",
	min = 0,
	max = 500,
	float = 5,
	value = S.minValue,
	callback = function(value)
		S.minValue = value
	end,
})

main:AddButton({
	text = "Collect one now",
	callback = function()
		collectOnce(true)
	end,
})

main:AddButton({
	text = "Reset session stats",
	callback = function()
		S.bills, S.earned, S.lastValue = 0, 0, 0
	end,
})

main:AddLabel({ text = "Take Orders" })

main:AddToggle({
	text = "Auto take orders",
	flag = "ACM_TakeOrders",
	state = S.takeOrders,
	callback = function(value)
		S.takeOrders = value
	end,
})

main:AddLabel({ text = "Collect Dishes" })

main:AddToggle({
	text = "Auto collect dishes",
	flag = "ACM_Dishes",
	state = S.collectDishes,
	callback = function(value)
		S.collectDishes = value
	end,
})

library:Init()
S.base = library.base
onCleanup(function()
	if S.base and S.base.Parent then
		pcall(function()
			S.base:Destroy()
		end)
	end
	S.base = nil
end)

task.spawn(function()
	while S.gen == myGen do
		if S.enabled then
			collectOnce()
		end
		if S.takeOrders then
			sweepOrders()
		end
		if S.collectDishes then
			collectDishesOnce()
		end
		task.wait(S.interval)
	end
end)
