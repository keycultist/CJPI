local pluginEnvironment = script.Parent
local pluginSettings = pluginEnvironment.Settings
local pluginUtils = pluginEnvironment.Utils
local pluginModules = pluginEnvironment.Modules
local insertService = game:GetService("InsertService")
local Selection = game:GetService("Selection")

local marketplace = game:GetService("MarketplaceService")
local pluginId = 0 
local pluginVersion = "1.0.0" 


local toolbar = plugin:CreateToolbar("CJPI")

local Button = toolbar:CreateButton("CJPI", "Show or hide the CJPI UI", "rbxassetid://86650229495342")

local widgetInfo  = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float,
	false,
	false,
	200,
	200,
	150,
	150)
local widget = plugin:CreateDockWidgetPluginGuiAsync("CJPI", widgetInfo)
widget.Title = "Canard JSON Parser/Importer"
script.Background.Parent = widget

rigSelected = false

local originalWeldOffsets = {}

local function checkIfUpdated()
	local success, result = pcall(function()
		return marketplace:GetProductInfoAsync(pluginId)
	end)

	if success then
		if result then
			if result.Description ~= pluginVersion then
				print("Plugin has updated to version "..result.Description..".")
				widget.Background.Version.Text = "New update: "..result.Description
				widget.Background.Version.TextColor3 = Color3.fromRGB(255, 170, 0)
			else
				widget.Background.Version.Text = pluginVersion
			end
		end
	else
		warn(result)
	end
end


function ValidateCharacter(character)
	if not character:IsA("Model") then
		return 
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end
	
	return true
end

function loadJSON(customizationData)
	local selectedObjects = Selection:Get()
	local character = selectedObjects[1]

	if not character or not ValidateCharacter(character) then
		warn("Please select a valid character rig.")
		return
	end

	if typeof(customizationData) ~= "table" then
		warn("Invalid customization data.")
		return
	end

	local savedAccessories = customizationData.Accessories or {}

	local assetIds = {}
	
	local height = tonumber(customizationData.Height)

	if height then
		if height >= 0.5 and height <= 2 then
			character:ScaleTo(height)
		else
			warn("Invalid character height:", height)
		end
	end
	
	if customizationData.ShirtID and customizationData.ShirtID ~= "" then
		local shirt = character:FindFirstChildOfClass("Shirt")

		if not shirt then
			shirt = Instance.new("Shirt")
			shirt.Parent = character
		end

		shirt.ShirtTemplate = customizationData.ShirtID
	end

	if customizationData.PantsID and customizationData.PantsID ~= "" then
		local pants = character:FindFirstChildOfClass("Pants")

		if not pants then
			pants = Instance.new("Pants")
			pants.Parent = character
		end

		pants.PantsTemplate = customizationData.PantsID
	end
	
	if customizationData.FaceID and customizationData.FaceID ~= "" then
		local head = character:FindFirstChild("Head")

		if head then
			local face = head:FindFirstChild("face")

			if not face or not face:IsA("Decal") then
				face = Instance.new("Decal")
				face.Name = "face"
				face.Face = Enum.NormalId.Front
				face.Parent = head
			end

			local faceID = tostring(customizationData.FaceID)

			if not faceID:match("^rbxassetid://") then
				faceID = "rbxassetid://" .. faceID
			end

			face.Texture = faceID
		else
			warn("Selected rig has no Head.")
		end
	end

	for _, transforms in pairs(savedAccessories) do
		local assetId = typeof(transforms) == "table"
			and tonumber(transforms.AssetID)

		if not assetId or assetId <= 0 then
			warn("Attempted to load an invalid accessory preset")
			return
		end

		table.insert(assetIds, assetId)
	end

	local loadedAccessories = {}

	for _, assetId in ipairs(assetIds) do
		local success, asset = pcall(function()
			return insertService:LoadAsset(assetId)
		end)

		if not success or not asset then
			warn("Failed to load accessory asset:", assetId)

			for _, loaded in ipairs(loadedAccessories) do
				loaded:Destroy()
			end

			return
		end

		local accessory = asset:FindFirstChildWhichIsA("Accessory", true)

		if not accessory then
			asset:Destroy()

			for _, loaded in ipairs(loadedAccessories) do
				loaded:Destroy()
			end

			warn("Asset contains no accessory:", assetId)
			return
		end

		accessory:SetAttribute("AssetID", assetId)
		accessory.Parent = nil
		table.insert(loadedAccessories, accessory)
		asset:Destroy()
	end

	for _, accessory in ipairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			accessory:Destroy()
		end
	end

	table.clear(originalWeldOffsets)

	for _, accessory in ipairs(loadedAccessories) do
		accessory.Parent = character
	end

end

Button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

Selection.SelectionChanged:Connect(function()
	local selectedObjects = Selection:Get()
	local character = selectedObjects[1]

	if character and ValidateCharacter(character) then
		widget.Background.TextLabel.Text = "Rig Selected: " .. character.Name
		rigSelected = true
	else
		widget.Background.TextLabel.Text = "No valid rig selected"
		rigSelected = false
	end
end)


widget.Background.TextButton.Activated:Connect(function()
	if rigSelected == true then
		local JSON = widget.Background.TextBox.Text
		JSON = game:GetService("HttpService"):JSONDecode(JSON)
		loadJSON(JSON)
	end
end)

task.spawn(function()
	while task.wait(240) do 
		checkIfUpdated()
	end
end)
