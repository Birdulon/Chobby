function GetTabPanelHandler(name, buttonWindow, displayPanel, initialTabs, tabsVertical, backFunction)
	
	local externalFunctions = {}
	
	local BUTTON_HEIGHT = 70
	local BUTTON_SPACING = 5

	-------------------------------------------------------------------
	-- Local variables
	-------------------------------------------------------------------
	local buttonsHolder
	
	local titleBackControl
	local buttonOffset = 0
	
	local tabs = {}
	
	-------------------------------------------------------------------
	-- Local functions
	-------------------------------------------------------------------
	
	local function ToggleShow(obj, tab, openOnly)
		local control = tab.control
		
		if displayPanel.visible then
			if displayPanel:GetChildByName(control.name) then
				if not openOnly then
					displayPanel:ClearChildren()
				end
				return
			end
		end
		displayPanel:ClearChildren()
		displayPanel:AddChild(control)
		if not displayPanel.visible then
			displayPanel:Show()
		end
		
		ButtonUtilities.SetButtonSelected(obj)
	end
	
	local function SetButtonPositionAndSize(index)
		if tabsVertical then
			tabs[index].button:SetPos(
				nil, 
				(index - 1) * (BUTTON_HEIGHT + BUTTON_SPACING) + buttonOffset, 
				nil, 
				BUTTON_HEIGHT
			)
			tabs[index].button:SetPosRelative(
				"0%",
				nil,
				"100%"
			)
		else
			local buttonSize = 100/#tabs
			local pos = (index - 1)*buttonSize .. "%"
			tabs[index].button:SetPosRelative(
				(index - 1)*buttonSize .. "%",
				0,
				buttonSize .. "%",
				"100%"
			)
		end
	end
	
	local function UpdateButtonLayout(newTabsVertical)
		if newTabsVertical ~= nil then
			tabsVertical = newTabsVertical
		end
		for i = 1, #tabs do
			SetButtonPositionAndSize(i)
		end
	end
	
	-------------------------------------------------------------------
	-- External Functions
	-------------------------------------------------------------------
	function externalFunctions.UpdateLayout(panelParent, newTabsVertical)
		displayPanel = panelParent
		UpdateButtonLayout(newTabsVertical)
	end
	
	function externalFunctions.Hide()
		if buttonsHolder.visible then
			buttonsHolder:Hide()
		end
	end
	
	function externalFunctions.Show()
		if not buttonsHolder.visible then
			buttonsHolder:Show()
		end
	end
	
	function externalFunctions.IsVisible()
		return buttonsHolder.visible
	end
	
	function externalFunctions.IsTabSelected()
		for i = 1, #tabs do
			if tabs[i].control and tabs[i].control.parent then
				return true
			end
		end
		return false
	end
	
	function externalFunctions.OpenTab(tabIndex)
		if tabs[tabIndex] then
			ToggleShow(tabs[tabIndex].button, tabs[tabIndex], true)
		end
	end
	
	function externalFunctions.GetManagedControlByName(controlName)
		for i = 1, #tabs do
			if tabs[i].control and tabs[i].control.name == controlName then
				return tabs[i].control, i
			end
		end
		return false
	end
	
	function externalFunctions.Destroy()
		for i = 1, #tabs do
			if tabs[i].control then
				tabs[i].control:Dispose()
			end
			tabs[i].button:Dispose()
		end
		tabs = nil
	end
	
	function externalFunctions.RemoveTab(name)
		local index = 1
		local found = false
		Spring.Echo("removing tab", name)
		while index <= #tabs do
			if found then
				tabs[index] = tabs[index + 1]
				index = index + 1
			elseif tabs[index].name == name then
				tabs[index].button:Dispose()
				found = true
			else
				index = index + 1
			end
		end
		if found then
			UpdateButtonLayout()
		end
	end
	
	function externalFunctions.SetActivity(name, activityCount)
		for i = 1, #tabs do
			if tabs[i].name == name and tabs[i].activityLabel then
				local activityLabel
				if activityCount > 0 then
					activityLabel = "(" .. tostring(activityCount) .. ")"
				else
					activityLabel = ""
				end
				tabs[i].activityLabel:SetCaption(activityLabel)
			end
		end
	end
	
	function externalFunctions.SetTabCaption(name, caption)
		for i = 1, #tabs do
			if tabs[i].name == name and tabs[i].activityLabel then
				ButtonUtilities.SetCaption(tabs[i].button, caption)
			end
		end
	end
	
	function externalFunctions.AddTab(name, humanName, control, onClick, rank, selected, entryCheck)
		local newTab = {}
		
		newTab.name = name
		newTab.rank = rank or (#tabs + 1)
		newTab.control = control
		newTab.entryCheck = entryCheck
		local button
		if control then
			button = Button:New {
				name = name .. "_button",
				x = "0%",
				y = "0%",
				width = "100%",
				height = "100%",
				caption = humanName,
				font = Configuration:GetFont(3),
				parent = buttonsHolder,
				OnClick = {
					function(obj) 
						if newTab.entryCheck then
							newTab.entryCheck(ToggleShow, obj, newTab)
						else
							ToggleShow(obj, newTab)
						end
					end
				},
			}
			
			newTab.activityLabel = Label:New {
				name = "activity_label",
				y = 5,
				right = 5,
				width = 50,
				height = 15,
				valign = "top",
				align = "right",
				parent = button,
				font = Configuration:GetFont(1),
				caption = "",
			}
			
			if selected then
				ToggleShow(button, newTab)
			end
			
			control.OnOrphan = control.OnOrphan or {}
			control.OnOrphan[#control.OnOrphan + 1] = function(obj)
				ButtonUtilities.SetButtonDeselected(button)
				
				if (displayPanel:IsEmpty() or displayPanel:GetChildByName(control.name))
						and displayPanel.visible then
					displayPanel:Hide()
				end
			end
		else
			button = Button:New {
				x = "0%",
				y = "0%",
				width = "100%",
				height = "100%",
				caption = humanName,
				font = Configuration:GetFont(3),
				parent = buttonsHolder,
				OnClick = {onClick},
			}
		end

		newTab.button = button
		
		local index = #tabs + 1
		while index > 1 and newTab.rank < tabs[index - 1].rank do
			tabs[index] = tabs[index - 1]
			index = index - 1
		end
		tabs[index] = newTab
		
		UpdateButtonLayout()
	end
	
	-------------------------------------------------------------------
	-- Initialization
	-------------------------------------------------------------------
	buttonsHolder = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		name = "buttons_" .. name,
		parent = buttonWindow,
		padding = {0, 0, 0, 0},
		children = {}
	}
	
	if backFunction then
		buttonOffset = 50
		
		Button:New {
			name = name .. "_back_button",
			x = 2,
			y = 5,
			width = 45,
			height = 45,
			caption = "",
			padding = {2,2,2,2},
			children = {
				Image:New {
					x = 0,
					y = 0,
					right = 0,
					bottom = 0,
					file = "luaui/widgets/chobby/images/left.png",
				}
			},
			parent = buttonsHolder,
			OnClick = {function (obj) backFunction(externalFunctions) end},
		}
		TextBox:New {
			x = 50,
			y = 18,
			right = 0,
			height = 30,
			valign = "center",
			align = "center",
			parent = buttonsHolder,
			fontsize = Configuration:GetFont(3).size,
			text = i18n(name),
		}
		-- Add heading and back button
	end
	
	for i = 1, #initialTabs do
		externalFunctions.AddTab(
			initialTabs[i].name, 
			i18n(initialTabs[i].name), 
			initialTabs[i].control,
			nil, nil, nil,
			initialTabs[i].entryCheck
		)
	end
	
	return externalFunctions
end
