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

	Greet customers (same remote, from ...Modules.Tasks.SendToTable, shown as "Greet Customers"):
	      ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
	          Name = "SendToTable", GroupId = <group folder name>,
	          FurnitureModel = <the table>, Tycoon = <tycoon> })
	  fired while the group's State is CustomerState.Entered, at a free table with enough chairs.
	  Verified live: it works from 32.8 studs away and the server seats the group.

	Serve dishes (two steps, from ...Modules.Tasks.ServeFood + ...Systems.Restaurant.GrabFood):
	      ReplicatedStorage.Events.Restaurant.GrabFood:InvokeServer(<plate>)
	      ReplicatedStorage.Events.Restaurant.TaskCompleted:FireServer({
	          Name = "Serve", GroupId = <group>, CustomerId = <customer>,
	          FoodModel = <that same plate>, Tycoon = <tycoon> })
	  fired while the customer's State is CustomerState.WaitingForDish, with a plate from
	  <tycoon>.Objects.Food whose Name equals CustomerData.Order (and whose KidFlag matches a
	  Kid customer). Verified live: grab works from ~17 studs, the serve lands within 0.25s from
	  ~1400 studs away, and serving without grabbing first is rejected by the server.

	Cook dishes (server-driven step machine, from ...Systems.Cook):
	      ReplicatedStorage.Events.Restaurant.Interactions.Interacted:FireServer(<tycoon>, <Cook spec>)
	      ReplicatedStorage.Events.Cook.CookInputRequested:FireServer("Interact", <station>, <equipment>)
	      ReplicatedStorage.Events.Cook.CookInputRequested:FireServer("CompleteTask", <station>, <equipment>)
	  the server answers every step through Events.Cook.CookUpdated (DirectToEquipment ->
	  UpdateInteraction -> ... -> Finish) and names the station it wants. Interact opens the step,
	  CompleteTask ends it; the gesture minigame stays entirely client side, so the server never
	  sees it. Verified live: one cook finishes in ~0.6-1.5s without touching the station and the
	  dish lands in <tycoon>.Objects.Food under the food key from the Start replication.

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
	greet = true,
	serve = true,
	serves = 0,
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

S.greet = S.greet ~= false
S.serve = S.serve ~= false
S.serves = tonumber(S.serves) or 0

S.cook = S.cook ~= false
S.cooks = tonumber(S.cooks) or 0
S.cookConn = nil

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
-- greet customers
--------------------------------------------------------------------------------

-- A group is greetable while its State is CustomerState.Entered, and the payload names the
-- TABLE the group should sit at. The table rules are the game's own (Tutorial:HighlightTables):
-- a child of <tycoon>.Items.Surface, FurnitureUtility:IsTable(name), with a Base.PlateHeight,
-- not InUse, and at least NumCustomers connected chairs. Verified live: firing from 32.8 studs
-- away moved the group to GoingToTable within 0.25s and the server seated it.
local GREET_REFIRE_DELAY = 1
local lastGreet = {}
local greetDeps

local function getGreetDeps()
	if greetDeps then
		return greetDeps
	end

	local furniture = findPath(ReplicatedStorage, "Source.Utility.FurnitureUtility")
	local tableConnection = findPath(ReplicatedStorage, "Source.Utility.Furniture.TableConnectionUtility")
	local customersModule = findPath(LocalPlayer, "PlayerScripts.Source.Systems.Restaurant.Customers")
	local stateEnum = findPath(ReplicatedStorage, "Source.Enums.Restaurant.Customer.CustomerState")
	if not (furniture and tableConnection and customersModule and stateEnum) then
		return nil
	end

	local ok, deps = pcall(function()
		return {
			Furniture = require(furniture),
			TableConnection = require(tableConnection),
			Customers = require(customersModule),
			CustomerState = require(stateEnum),
		}
	end)
	if ok then
		greetDeps = deps
	end
	return greetDeps
end

local function findFreeTable(deps, tycoon, seats, taken)
	local items = tycoon:FindFirstChild("Items")
	local surface = items and items:FindFirstChild("Surface")
	if not surface then
		return nil
	end

	for _, furniture in ipairs(surface:GetChildren()) do
		if not taken[furniture] and deps.Furniture:IsTable(furniture.Name) then
			local base = furniture:FindFirstChild("Base")
			local plate = base and base:FindFirstChild("PlateHeight")
			if plate and not furniture:GetAttribute("InUse") then
				local chairs = deps.TableConnection:FindChairs(tycoon, furniture)
				if #chairs >= seats then
					return furniture
				end
			end
		end
	end
end

local function greetOnce()
	local deps = getGreetDeps()
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

	local now = os.clock()
	local taken = {}
	for groupId, groupData in store.Groups do
		if groupData.State == deps.CustomerState.Entered then
			local last = lastGreet[groupId]
			if not last or (now - last) >= GREET_REFIRE_DELAY then
				local furniture = findFreeTable(deps, tycoon, groupData.NumCustomers or 0, taken)
				if furniture then
					lastGreet[groupId] = now
					taken[furniture] = true
					TaskCompleted:FireServer({
						Name = "SendToTable",
						GroupId = groupId,
						FurnitureModel = furniture,
						Tycoon = tycoon,
					})
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- serve dishes
--------------------------------------------------------------------------------

-- Serve is a two-step task. Take a cooked plate out of <tycoon>.Objects.Food with
-- ReplicatedStorage.Events.Restaurant.GrabFood:InvokeServer(plate), then name that same plate
-- in TaskCompleted {Name = "Serve", GroupId, CustomerId, FoodModel = plate, Tycoon}.
-- Verified live: the grab succeeds from ~17 studs away, the serve moves the customer
-- WaitingForDish -> WaitingToEat within 0.25s even ~1400 studs away, and serving without
-- grabbing first is rejected. A served plate is NOT removed - it stays in Objects.Food with
-- Taken = true - so the only reliable sign of success is the customer leaving WaitingForDish.
-- A plate whose serve never lands has to be released with CancelGrabRequested or it stays
-- reserved at the counter.
local pendingServe
local serveDeps

local function getServeDeps()
	if serveDeps then
		return serveDeps
	end

	local customersModule = findPath(LocalPlayer, "PlayerScripts.Source.Systems.Restaurant.Customers")
	local customerType = findPath(ReplicatedStorage, "Source.Enums.Restaurant.Customer.CustomerType")
	local grabRemote = findPath(ReplicatedStorage, "Events.Restaurant.GrabFood")
	local cancelRemote = findPath(ReplicatedStorage, "Events.Restaurant.CancelGrabRequested")
	if not (customersModule and customerType and grabRemote and cancelRemote) then
		return nil
	end

	local ok, deps = pcall(function()
		return {
			Customers = require(customersModule),
			CustomerType = require(customerType),
			Grab = grabRemote,
			Cancel = cancelRemote,
		}
	end)
	if ok then
		serveDeps = deps
	end
	return serveDeps
end

local function freePlates(tycoon)
	local objects = tycoon:FindFirstChild("Objects")
	local food = objects and objects:FindFirstChild("Food")
	if not food then
		return {}
	end

	local plates = {}
	for _, plate in ipairs(food:GetChildren()) do
		if not plate:GetAttribute("Taken") then
			table.insert(plates, plate)
		end
	end
	return plates
end

local function findWaitingCustomer(deps, tycoon, foodKey, kidFlag)
	local store = deps.Customers:GetStorage(tycoon)
	if not store then
		return nil
	end

	for groupId, groupData in store.Groups do
		for customerId, customerData in groupData.Customers do
			if customerData.State == "WaitingForDish" and tostring(customerData.Order) == tostring(foodKey) then
				if kidFlag == nil or kidFlag == (customerData.CustomerType == deps.CustomerType.Kid) then
					return groupId, customerId
				end
			end
		end
	end
end

local function fireServe(deps, tycoon, groupId, customerId, plate)
	TaskCompleted:FireServer({
		Name = "Serve",
		GroupId = groupId,
		CustomerId = customerId,
		FoodModel = plate,
		Tycoon = tycoon,
	})
end

local function releasePlate(deps)
	pcall(function()
		deps.Cancel:FireServer()
	end)
end

local function serveOnce()
	local deps = getServeDeps()
	if not deps then
		return
	end

	local tycoon = getTycoon()
	if not tycoon then
		return
	end

	if pendingServe then
		-- the plate is not deleted by the server, so check the customer instead: once it is no
		-- longer WaitingForDish the serve landed and the plate is done with
		local ok, customerData = pcall(function()
			return deps.Customers:GetCustomerData(tycoon, pendingServe.GroupId, pendingServe.CustomerId)
		end)
		if ok and customerData and customerData.State == "WaitingForDish" then
			-- the serve was rejected, or a worker served that customer first
			releasePlate(deps)
			pendingServe = nil
			return
		end
		S.serves = S.serves + 1
		pendingServe = nil
	end

	-- one grab per tick, and only for a dish somebody is already waiting for
	for _, plate in ipairs(freePlates(tycoon)) do
		if findWaitingCustomer(deps, tycoon, plate.Name, nil) then
			local ok, grabbed, info = pcall(function()
				return deps.Grab:InvokeServer(plate)
			end)
			if ok and grabbed then
				local kidFlag = type(info) == "table" and info.KidFlag or nil
				local targetPlayer = type(info) == "table" and info.TargetPlayerName or nil
				local targetCar = type(info) == "table" and info.TargetCarId or nil
				local groupId, customerId = findWaitingCustomer(deps, tycoon, plate.Name, kidFlag)
				if targetPlayer or targetCar or not groupId then
					-- cooked for another player's order, or nobody wants it any more
					releasePlate(deps)
				else
					fireServe(deps, tycoon, groupId, customerId, plate)
					pendingServe = {
						GroupId = groupId,
						CustomerId = customerId,
					}
				end
			end
			break
		end
	end
end

--------------------------------------------------------------------------------
-- cook dishes
--------------------------------------------------------------------------------

-- Cooking is a server-driven step machine, not a single task payload. The player opens a cook
-- with the "Cook" interaction the server places on the order counter (the same spec table the
-- client would fire when the prompt is pressed). The server then answers each step through
-- CookUpdated and names the station + equipment it wants; Interact opens the step and
-- CompleteTask ends it. The step minigame (clicks/hold/spin) is client side only - its progress
-- never reaches the server - so these two fires are the whole step. Verified live: the dish is
-- produced in ~0.6-1.5s and a served plate then appears in <tycoon>.Objects.Food.
local COOK_INTERACT_DELAY = 0.1
local COOK_COMPLETE_DELAY = 0.15
local COOK_START_COOLDOWN = 1

local cookDeps
local lastCookStart = 0

local function getCookDeps()
	if cookDeps then
		return cookDeps
	end

	local interactionsModule = findPath(LocalPlayer, "PlayerScripts.Source.Systems.Restaurant.Interactions")
	local cookModule = findPath(LocalPlayer, "PlayerScripts.Source.Systems.Cook")
	local inputRemote = findPath(ReplicatedStorage, "Events.Cook.CookInputRequested")
	local interactedRemote = findPath(ReplicatedStorage, "Events.Restaurant.Interactions.Interacted")
	local updatedRemote = findPath(ReplicatedStorage, "Events.Cook.CookUpdated")
	if not (interactionsModule and cookModule and inputRemote and interactedRemote and updatedRemote) then
		return nil
	end

	local ok, deps = pcall(function()
		return {
			Interactions = require(interactionsModule),
			Cook = require(cookModule),
			Input = inputRemote,
			Interacted = interactedRemote,
			Updated = updatedRemote.OnClientEvent,
		}
	end)
	if ok then
		cookDeps = deps
	end
	return cookDeps
end

-- the server creates the "Cook" prompt on the order counter and ships the spec to the client;
-- reuse that exact table instead of building one
local function findCookSpec(deps, tycoon)
	local bucket = deps.Interactions.PromptData and deps.Interactions.PromptData[tycoon]
	if not bucket then
		return nil
	end
	for _, spec in pairs(bucket) do
		if spec.Key == "Cook" then
			return spec
		end
	end
	return nil
end

local function onCookUpdated(deps, replication, ...)
	if S.gen ~= myGen or not S.cook then
		return
	end

	if replication == "DirectToEquipment" then
		local model, equipment = ...
		task.spawn(function()
			task.wait(COOK_INTERACT_DELAY)
			if S.gen ~= myGen or not S.cook then
				return
			end
			-- "I am at the station": the server answers with this step's UpdateInteraction
			pcall(function()
				deps.Input:FireServer("Interact", model, equipment)
			end)
		end)
	elseif replication == "UpdateInteraction" then
		local _, model, equipment, active = ...
		if active == true then
			task.spawn(function()
				task.wait(COOK_COMPLETE_DELAY)
				if S.gen ~= myGen or not S.cook then
					return
				end
				-- the step's gesture never reaches the server, so this ends the step
				pcall(function()
					deps.Input:FireServer("CompleteTask", model, equipment)
				end)
			end)
		end
	elseif replication == "Finish" then
		-- CancelCooking answers with Finish(false); a finished dish comes back as nil
		local cancelled = ...
		if cancelled ~= false then
			S.cooks += 1
		end
	end
end

local function connectCook()
	local deps = getCookDeps()
	if not deps then
		return
	end
	-- a live-reload keeps the previous run's connection alive, so replace it explicitly
	if S.cookConn then
		pcall(function()
			S.cookConn:Disconnect()
		end)
		S.cookConn = nil
	end
	S.cookConn = deps.Updated:Connect(function(replication, ...)
		onCookUpdated(deps, replication, ...)
	end)
end

local function cancelCook()
	local deps = getCookDeps()
	if not deps then
		return
	end
	pcall(function()
		deps.Input:FireServer("CancelCooking")
	end)
end

local function cookOnce()
	local deps = getCookDeps()
	if not deps then
		return
	end

	if S.cookConn == nil then
		connectCook()
	end

	-- one cook at a time: while the server drives one, the handler owns it
	local ok, cooking = pcall(function()
		return deps.Cook.IsCooking
	end)
	if ok and cooking then
		return
	end

	if os.clock() - lastCookStart < COOK_START_COOLDOWN then
		return
	end

	local tycoon = getTycoon()
	local spec = tycoon and findCookSpec(deps, tycoon)
	if not spec then
		return
	end

	lastCookStart = os.clock()
	pcall(function()
		deps.Interacted:FireServer(tycoon, spec)
	end)
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

main:AddLabel({ text = "Greet Customers" })

main:AddToggle({
	text = "Auto greet customers",
	flag = "ACM_Greet",
	state = S.greet,
	callback = function(value)
		S.greet = value
	end,
})

main:AddLabel({ text = "Serve Dishes" })

main:AddToggle({
	text = "Auto serve dishes",
	flag = "ACM_Serve",
	state = S.serve,
	callback = function(value)
		S.serve = value
		if not value and pendingServe then
			-- do not leave a grabbed plate reserved at the counter
			local deps = getServeDeps()
			if deps then
				releasePlate(deps)
			end
			pendingServe = nil
		end
	end,
})

main:AddLabel({ text = "Cook Dishes" })

main:AddToggle({
	text = "Auto cook dishes",
	flag = "ACM_Cook",
	state = S.cook,
	callback = function(value)
		S.cook = value
		if value then
			connectCook()
		else
			-- do not leave the counter mid-recipe with the character locked at a station
			local deps = getCookDeps()
			local ok, cooking = pcall(function()
				return deps and deps.Cook.IsCooking
			end)
			if ok and cooking then
				cancelCook()
			end
		end
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
		if S.greet then
			greetOnce()
		end
		if S.serve then
			serveOnce()
		end
		if S.cook then
			cookOnce()
		end
		task.wait(S.interval)
	end
end)
