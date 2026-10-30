--!strict
-- NovaUI — автономная UI-библиотека для Roblox Studio / разрешённых собственных проектов.
-- Не содержит игровых механик, загрузчиков, обходов или сетевых перехватов.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local NovaUI = {}
NovaUI.__index = NovaUI

export type WindowOptions = {
	Title: string?,
	Subtitle: string?,
	Accent: Color3?,
	ToggleKey: Enum.KeyCode?,
	Size: UDim2?,
}

local DEFAULT = {
	Background = Color3.fromRGB(14, 16, 23),
	Surface = Color3.fromRGB(21, 24, 34),
	Surface2 = Color3.fromRGB(27, 31, 44),
	SurfaceHover = Color3.fromRGB(35, 40, 56),
	Text = Color3.fromRGB(241, 244, 255),
	Muted = Color3.fromRGB(151, 161, 184),
	Border = Color3.fromRGB(57, 64, 87),
	Accent = Color3.fromRGB(122, 105, 255),
	Success = Color3.fromRGB(76, 214, 151),
	Danger = Color3.fromRGB(255, 99, 120),
}

local function create(className: string, properties: {[string]: any}?)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	return object
end

local function round(object: GuiObject, radius: number)
	create("UICorner", {CornerRadius = UDim.new(0, radius), Parent = object})
	return object
end

local function outline(object: GuiObject, color: Color3, transparency: number?)
	return create("UIStroke", {
		Color = color,
		Transparency = transparency or 0,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = object,
	})
end

local function padding(object: GuiObject, amount: number, vertical: number?)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, amount),
		PaddingRight = UDim.new(0, amount),
		PaddingTop = UDim.new(0, vertical or amount),
		PaddingBottom = UDim.new(0, vertical or amount),
		Parent = object,
	})
end

local function list(object: GuiObject, gap: number, horizontal: boolean?)
	return create("UIListLayout", {
		Padding = UDim.new(0, gap),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = object,
	})
end

local function tween(object: Instance, properties: {[string]: any}, duration: number?, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	local info = TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
	local animation = TweenService:Create(object, info, properties)
	animation:Play()
	return animation
end

local function safeCall(callback: ((...any) -> ())?, ...: any)
	if not callback then return end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(function()
			callback(table.unpack(args, 1, args.n))
		end)
		if not ok then
			warn("[NovaUI callback] " .. tostring(err))
		end
	end)
end

local function normalizeKey(value: any): Enum.KeyCode?
	if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
		return value
	end
	if type(value) == "string" then
		return Enum.KeyCode[value]
	end
	return nil
end

local function formatNumber(value: number): string
	if math.abs(value - math.round(value)) < 0.0001 then
		return tostring(math.round(value))
	end
	return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
end

local function textLabel(text: string, color: Color3, size: number, weight: Enum.FontWeight?)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", weight or Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		TextSize = size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BorderSizePixel = 0,
	})
end

local function setVisibleAfter(object: GuiObject, animation: Tween, value: boolean)
	animation.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed then
			object.Visible = value
		end
	end)
end

-- Window --------------------------------------------------------------------
local Window = {}
Window.__index = Window

function Window:_accent(object: Instance, property: string)
	table.insert(self._accentObjects, {Object = object, Property = property})
	local dynamicObject: any = object
	dynamicObject[property] = self.Theme.Accent
end

function Window:_setAccent(color: Color3)
	self.Theme.Accent = color
	for _, target in ipairs(self._accentObjects) do
		if target.Object and target.Object.Parent then
			local dynamicObject: any = target.Object
			dynamicObject[target.Property] = color
		end
	end
end

function Window:SetAccent(color: Color3)
	assert(typeof(color) == "Color3", "SetAccent expects Color3")
	self:_setAccent(color)
	return self
end

function Window:_store(flag: string?, value: any)
	if flag and flag ~= "" then
		self.Values[flag] = value
	end
end

function Window:_callback(callback: ((any) -> ())?, value: any)
	safeCall(callback, value)
end

function Window:_registerSearch(tab: any, item: GuiObject, queryText: string)
	table.insert(tab._searchItems, {Object = item, Text = string.lower(queryText)})
end

function Window:_applySearch(query: string)
	local tab = self._selectedTab
	if not tab then return end
	query = string.lower(query)
	for _, entry in ipairs(tab._searchItems) do
		if entry.Object and entry.Object.Parent then
			entry.Object.Visible = query == "" or string.find(entry.Text, query, 1, true) ~= nil
		end
	end
end

function Window:_setPageVisible(tab: any, shown: boolean)
	if shown then
		tab.Page.Visible = true
		tab.Page.GroupTransparency = 1
		tween(tab.Page, {GroupTransparency = 0}, 0.18)
	else
		tab.Page.Visible = false
	end
end

function Window:SelectTab(tab: any)
	if self._selectedTab == tab then return tab end
	for _, current in ipairs(self.Tabs) do
		local active = current == tab
		self:_setPageVisible(current, active)
		tween(current.Button, {
			BackgroundColor3 = active and self.Theme.SurfaceHover or self.Theme.Surface,
			TextColor3 = active and self.Theme.Text or self.Theme.Muted,
		}, 0.16)
		current.Indicator.Visible = active
	end
	self._selectedTab = tab
	self.SearchBox.Text = ""
	return tab
end

function Window:SetVisible(visible: boolean)
	if self._destroyed then return end
	if visible == self.Visible then return end
	self.Visible = visible
	if visible then
		self.Main.Visible = true
		self.Main.GroupTransparency = 1
		self.Scale.Scale = 0.96
		tween(self.Main, {GroupTransparency = 0}, 0.2)
		tween(self.Scale, {Scale = 1}, 0.26, Enum.EasingStyle.Back)
	else
		local fade = tween(self.Main, {GroupTransparency = 1}, 0.15)
		tween(self.Scale, {Scale = 0.96}, 0.15)
		setVisibleAfter(self.Main, fade, false)
	end
end

function Window:ToggleVisible()
	self:SetVisible(not self.Visible)
end

function Window:Notify(options: any)
	if type(options) == "string" then options = {Text = options} end
	options = options or {}
	local title = options.Title or "Уведомление"
	local message = options.Text or options.Content or ""
	local duration = tonumber(options.Duration) or 3.5
	local kind = string.lower(options.Type or "info")
	local tint = kind == "success" and self.Theme.Success or (kind == "error" or kind == "danger") and self.Theme.Danger or self.Theme.Accent

	local card = create("Frame", {
		Name = "Toast",
		BackgroundColor3 = self.Theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = self.ToastHolder,
	})
	round(card, 10)
	outline(card, self.Theme.Border, 0.25)
	padding(card, 12, 10)
	local accent = create("Frame", {BackgroundColor3 = tint, BorderSizePixel = 0, Size = UDim2.new(0, 3, 1, -18), Position = UDim2.new(0, 0, 0, 9), Parent = card})
	round(accent, 3)
	local body = create("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -11, 0, 0), Position = UDim2.new(0, 11, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = card})
	list(body, 3)
	local head = textLabel(title, self.Theme.Text, 13, Enum.FontWeight.Bold); head.Size = UDim2.new(1, 0, 0, 16); head.Parent = body
	local copy = textLabel(message, self.Theme.Muted, 12); copy.TextWrapped = true; copy.TextYAlignment = Enum.TextYAlignment.Top; copy.AutomaticSize = Enum.AutomaticSize.Y; copy.Size = UDim2.new(1, 0, 0, 0); copy.Parent = body

	card.GroupTransparency = 1
	tween(card, {GroupTransparency = 0}, 0.18)
	task.delay(duration, function()
		if not card.Parent then return end
		local out = tween(card, {GroupTransparency = 1}, 0.18)
		out.Completed:Connect(function() if card then card:Destroy() end end)
	end)
	return card
end

function Window:ExportConfig(): {[string]: any}
	local copy = {}
	for key, value in pairs(self.Values) do
		if typeof(value) == "Color3" then
			copy[key] = {__novaType = "Color3", R = value.R, G = value.G, B = value.B}
		elseif typeof(value) == "EnumItem" then
			copy[key] = {__novaType = "KeyCode", Name = value.Name}
		else
			copy[key] = value
		end
	end
	return copy
end

function Window:ApplyConfig(config: {[string]: any})
	for flag, value in pairs(config or {}) do
		if type(value) == "table" and value.__novaType == "Color3" then
			value = Color3.new(value.R, value.G, value.B)
		elseif type(value) == "table" and value.__novaType == "KeyCode" then
			value = normalizeKey(value.Name)
		end
		local control = self._controls[flag]
		if control and control.Set then control:Set(value) end
	end
end

function Window:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	self.ScreenGui:Destroy()
end

-- Tabs ----------------------------------------------------------------------
local Section
local Tab = {}
Tab.__index = Tab

function Tab:Select()
	self.Window:SelectTab(self)
	return self
end

function Tab:Section(options: any)
	options = options or {}
	local section = setmetatable({}, Section)
	section.Window = self.Window
	section.Tab = self
	section.Title = options.Title or "Секция"

	local card = create("Frame", {
		Name = "Section_" .. section.Title,
		BackgroundColor3 = self.Window.Theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.Body,
	})
	round(card, 10); outline(card, self.Window.Theme.Border, 0.38)
	local cardList = list(card, 7)
	cardList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	padding(card, 11, 10)

	local header = textLabel(section.Title, self.Window.Theme.Text, 13, Enum.FontWeight.Bold)
	header.Size = UDim2.new(1, 0, 0, 17); header.Parent = card
	if options.Description then
		local description = textLabel(options.Description, self.Window.Theme.Muted, 11)
		description.TextWrapped = true; description.TextYAlignment = Enum.TextYAlignment.Top; description.AutomaticSize = Enum.AutomaticSize.Y; description.Size = UDim2.new(1, 0, 0, 0); description.Parent = card
	end
	local body = create("Frame", {Name = "Controls", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = card})
	list(body, 5)
	section.Card, section.Body = card, body
	return section
end

-- Sections / Controls -------------------------------------------------------
Section = {}
Section.__index = Section

function Section:_row(title: string, height: number?)
	local row = create("Frame", {
		Name = "Control_" .. title,
		BackgroundColor3 = self.Window.Theme.Surface2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height or 42),
		Parent = self.Body,
	})
	round(row, 7)
	local hoverStroke = outline(row, self.Window.Theme.Border, 0.62)
	self.Window:_registerSearch(self.Tab, row, title)
	return row, hoverStroke
end

function Section:Label(options: any)
	if type(options) == "string" then options = {Text = options} end
	options = options or {}
	local row = self:_row(options.Text or "Метка", 32)
	row.BackgroundTransparency = 1
	local label = textLabel(options.Text or "Метка", options.Color or self.Window.Theme.Muted, 12)
	label.Position = UDim2.new(0, 10, 0, 0); label.Size = UDim2.new(1, -20, 1, 0); label.Parent = row
	return {Set = function(_, value) label.Text = tostring(value) end}
end

function Section:Paragraph(options: any)
	options = options or {}
	local title = options.Title or "Информация"
	local content = options.Content or options.Text or ""
	local row = create("Frame", {Name = "Paragraph_" .. title, BackgroundColor3 = self.Window.Theme.Surface2, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = self.Body})
	round(row, 7); padding(row, 10, 9); list(row, 3)
	self.Window:_registerSearch(self.Tab, row, title .. " " .. content)
	local h = textLabel(title, self.Window.Theme.Text, 12, Enum.FontWeight.SemiBold); h.Size = UDim2.new(1, 0, 0, 15); h.Parent = row
	local p = textLabel(content, self.Window.Theme.Muted, 11); p.TextWrapped = true; p.TextYAlignment = Enum.TextYAlignment.Top; p.Size = UDim2.new(1, 0, 0, 0); p.AutomaticSize = Enum.AutomaticSize.Y; p.Parent = row
	return {Set = function(_, value) p.Text = tostring(value) end}
end

function Section:Divider()
	local line = create("Frame", {BackgroundColor3 = self.Window.Theme.Border, BackgroundTransparency = 0.45, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Parent = self.Body})
	return line
end

function Section:Button(options: any)
	options = options or {}
	local title = options.Title or options.Name or "Кнопка"
	local row, stroke = self:_row(title, 40)
	local button = create("TextButton", {BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Size = UDim2.fromScale(1, 1), Parent = row})
	local label = textLabel(title, self.Window.Theme.Text, 12, Enum.FontWeight.SemiBold); label.Position = UDim2.new(0, 11, 0, 0); label.Size = UDim2.new(1, -48, 1, 0); label.Parent = row
	local arrow = textLabel(options.Icon or "›", self.Window.Theme.Accent, 22, Enum.FontWeight.Bold); arrow.TextXAlignment = Enum.TextXAlignment.Center; arrow.Position = UDim2.new(1, -35, 0, 0); arrow.Size = UDim2.new(0, 25, 1, 0); arrow.Parent = row
	self.Window:_accent(arrow, "TextColor3")
	button.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = self.Window.Theme.SurfaceHover}, 0.12); tween(stroke, {Transparency = 0.15}, 0.12) end)
	button.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = self.Window.Theme.Surface2}, 0.12); tween(stroke, {Transparency = 0.62}, 0.12) end)
	button.Activated:Connect(function()
		tween(row, {BackgroundColor3 = self.Window.Theme.Accent}, 0.07)
		task.delay(0.08, function() if row.Parent then tween(row, {BackgroundColor3 = self.Window.Theme.SurfaceHover}, 0.16) end end)
		safeCall(options.Callback)
	end)
	return {Press = function() safeCall(options.Callback) end}
end

function Section:Toggle(options: any)
	options = options or {}
	local title = options.Title or options.Name or "Переключатель"
	local value = options.Default == true
	local row = self:_row(title, 42)
	local button = create("TextButton", {BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Size = UDim2.fromScale(1, 1), Parent = row})
	local label = textLabel(title, self.Window.Theme.Text, 12, Enum.FontWeight.Medium); label.Position = UDim2.new(0, 11, 0, 0); label.Size = UDim2.new(1, -78, 1, 0); label.Parent = row
	local track = create("Frame", {BackgroundColor3 = self.Window.Theme.Border, BorderSizePixel = 0, Position = UDim2.new(1, -51, 0.5, -10), Size = UDim2.new(0, 39, 0, 20), Parent = row})
	round(track, 20)
	local knob = create("Frame", {BackgroundColor3 = Color3.fromRGB(235, 238, 250), BorderSizePixel = 0, Position = UDim2.new(0, 3, 0.5, -7), Size = UDim2.new(0, 14, 0, 14), Parent = track})
	round(knob, 14)
	local control = {}
	function control:Set(nextValue: boolean, silent: boolean?)
		value = nextValue == true
		self.Window:_store(options.Flag, value)
		tween(track, {BackgroundColor3 = value and self.Window.Theme.Accent or self.Window.Theme.Border}, 0.16)
		tween(knob, {Position = value and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}, 0.18, Enum.EasingStyle.Back)
		if not silent then self.Window:_callback(options.Callback, value) end
	end
	function control:Get() return value end
	button.Activated:Connect(function() control:Set(not value) end)
	control:Set(value, true)
	if options.Flag then self.Window._controls[options.Flag] = control end
	return control
end

function Section:Slider(options: any)
	options = options or {}
	local title = options.Title or options.Name or "Слайдер"
	local min = tonumber(options.Min) or 0
	local max = tonumber(options.Max) or 100
	if max <= min then max = min + 1 end
	local step = math.max(tonumber(options.Rounding or options.Step) or 1, 0.000001)
	local value = tonumber(options.Default) or min
	local row = self:_row(title, 53)
	local label = textLabel(title, self.Window.Theme.Text, 12, Enum.FontWeight.Medium); label.Position = UDim2.new(0, 11, 0, 5); label.Size = UDim2.new(1, -78, 0, 17); label.Parent = row
	local amount = textLabel("", self.Window.Theme.Accent, 11, Enum.FontWeight.SemiBold); amount.TextXAlignment = Enum.TextXAlignment.Right; amount.Position = UDim2.new(1, -72, 0, 5); amount.Size = UDim2.new(0, 60, 0, 17); amount.Parent = row
	self.Window:_accent(amount, "TextColor3")
	local track = create("Frame", {BackgroundColor3 = self.Window.Theme.Border, BorderSizePixel = 0, Position = UDim2.new(0, 11, 1, -16), Size = UDim2.new(1, -22, 0, 5), Parent = row})
	round(track, 5)
	local fill = create("Frame", {BackgroundColor3 = self.Window.Theme.Accent, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), Parent = track})
	round(fill, 5); self.Window:_accent(fill, "BackgroundColor3")
	local hitbox = create("TextButton", {BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Position = UDim2.new(0, -5, 0, -8), Size = UDim2.new(1, 10, 1, 16), Parent = track})
	local control = {}
	local function quantize(n: number)
		return math.clamp(math.round((n - min) / step) * step + min, min, max)
	end
	function control:Set(nextValue: number, silent: boolean?)
		value = quantize(tonumber(nextValue) or min)
		local alpha = (value - min) / (max - min)
		amount.Text = (options.Prefix or "") .. formatNumber(value) .. (options.Suffix or "")
		tween(fill, {Size = UDim2.new(alpha, 0, 1, 0)}, 0.12)
		self.Window:_store(options.Flag, value)
		if not silent then self.Window:_callback(options.Callback, value) end
	end
	function control:Get() return value end
	local dragging = false
	local function update(input: InputObject)
		local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		control:Set(min + (max - min) * alpha)
	end
	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input) end
	end)
	table.insert(self.Window._connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
	end))
	table.insert(self.Window._connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end))
	control:Set(value, true)
	if options.Flag then self.Window._controls[options.Flag] = control end
	return control
end

function Section:Dropdown(options: any)
	options = options or {}
	local title = options.Title or options.Name or "Список"
	local values = options.Values or {}
	local selected = options.Default
	local isMulti = options.Multi == true
	local selectedSet: {[any]: boolean} = {}
	if isMulti and type(selected) == "table" then for _, item in ipairs(selected) do selectedSet[item] = true end end
	local container = create("Frame", {Name = "Dropdown_" .. title, BackgroundColor3 = self.Window.Theme.Surface2, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 42), ClipsDescendants = true, Parent = self.Body})
	round(container, 7); local border = outline(container, self.Window.Theme.Border, 0.62)
	self.Window:_registerSearch(self.Tab, container, title .. " " .. table.concat(values, " "))
	local header = create("TextButton", {BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 42), Parent = container})
	local label = textLabel(title, self.Window.Theme.Text, 12, Enum.FontWeight.Medium); label.Position = UDim2.new(0, 11, 0, 0); label.Size = UDim2.new(0.55, -11, 0, 42); label.Parent = header
	local current = textLabel("", self.Window.Theme.Muted, 11); current.TextXAlignment = Enum.TextXAlignment.Right; current.Position = UDim2.new(0.45, 0, 0, 0); current.Size = UDim2.new(0.55, -39, 0, 42); current.Parent = header
	local chevron = textLabel("⌄", self.Window.Theme.Accent, 18, Enum.FontWeight.Bold); chevron.TextXAlignment = Enum.TextXAlignment.Center; chevron.Position = UDim2.new(1, -31, 0, 0); chevron.Size = UDim2.new(0, 22, 0, 40); chevron.Parent = header; self.Window:_accent(chevron, "TextColor3")
	local optionsArea = create("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 8, 0, 44), Size = UDim2.new(1, -16, 0, 0), Parent = container})
	local layout = list(optionsArea, 4)
	local expanded = false
	local buttons: {[any]: TextButton} = {}
	local control = {}
	local function chosenList()
		local out = {}
		for _, choice in ipairs(values) do if selectedSet[choice] then table.insert(out, choice) end end
		return out
	end
	local function refresh()
		if isMulti then
			local picked = chosenList()
			current.Text = #picked == 0 and "Выбрать" or table.concat(picked, ", ")
		else current.Text = selected and tostring(selected) or "Выбрать" end
		for choice, button in pairs(buttons) do
			local on = isMulti and selectedSet[choice] or selected == choice
			tween(button, {BackgroundColor3 = on and self.Window.Theme.Accent or self.Window.Theme.Surface}, 0.12)
			button.TextColor3 = on and Color3.fromRGB(255,255,255) or self.Window.Theme.Muted
		end
	end
	local function resize(open: boolean)
		expanded = open
		local height = open and (50 + #values * 31 + math.max(#values - 1, 0) * 4) or 42
		tween(container, {Size = UDim2.new(1, 0, 0, height)}, 0.19)
		tween(chevron, {Rotation = open and 180 or 0}, 0.19)
		tween(border, {Transparency = open and 0.16 or 0.62}, 0.16)
	end
	function control:Set(nextValue: any, silent: boolean?)
		if isMulti then
			selectedSet = {}
			if type(nextValue) == "table" then for _, choice in ipairs(nextValue) do selectedSet[choice] = true end end
			self.Window:_store(options.Flag, chosenList())
			if not silent then self.Window:_callback(options.Callback, chosenList()) end
		else
			selected = nextValue
			self.Window:_store(options.Flag, selected)
			if not silent then self.Window:_callback(options.Callback, selected) end
		end
		refresh()
	end
	function control:Get() return isMulti and chosenList() or selected end
	function control:SetValues(nextValues: {any})
		values = nextValues or {}
		for _, button in pairs(buttons) do button:Destroy() end
		table.clear(buttons)
		for _, choice in ipairs(values) do
			local button = create("TextButton", {BackgroundColor3 = self.Window.Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = tostring(choice), TextColor3 = self.Window.Theme.Muted, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 27), Parent = optionsArea})
			round(button, 5); padding(button, 8, 0); buttons[choice] = button
			button.Activated:Connect(function()
				if isMulti then selectedSet[choice] = not selectedSet[choice]; control:Set(chosenList()) else control:Set(choice); resize(false) end
			end)
		end
		refresh()
	end
	header.Activated:Connect(function() resize(not expanded) end)
	control:SetValues(values)
	control:Set(isMulti and (type(selected) == "table" and selected or {}) or selected, true)
	if options.Flag then self.Window._controls[options.Flag] = control end
	return control
end

function Section:Textbox(options: any)
	options = options or {}
	local title = options.Title or options.Name or "Текст"
	local value = tostring(options.Default or "")
	local row = self:_row(title, 48)
	local label = textLabel(title, self.Window.Theme.Text, 12, Enum.FontWeight.Medium); label.Position = UDim2.new(0, 11, 0, 0); label.Size = UDim2.new(0.42, -11, 1, 0); label.Parent = row
	local input = create("TextBox", {BackgroundColor3 = self.Window.Theme.Surface, BorderSizePixel = 0, ClearTextOnFocus = false, PlaceholderText = options.Placeholder or "Введите текст…", PlaceholderColor3 = self.Window.Theme.Muted, Text = value, TextColor3 = self.Window.Theme.Text, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0.42, 0, 0.5, -14), Size = UDim2.new(0.58, -11, 0, 28), Parent = row})
	round(input, 6); outline(input, self.Window.Theme.Border, 0.62); padding(input, 8, 0)
	local control = {}
	function control:Set(nextValue: any, silent: boolean?)
		value = tostring(nextValue or ""); input.Text = value; self.Window:_store(options.Flag, value); if not silent then self.Window:_callback(options.Callback, value) end
	end
	function control:Get() return value end
	input.FocusLost:Connect(function(enterPressed) if options.EnterOnly and not enterPressed then input.Text = value; return end control:Set(input.Text) end)
	control:Set(value, true)
	if options.Flag then self.Window._controls[options.Flag] = control end
	return control
end

function Section:Keybind(options: any)
	options = options or {}
	local title = options.Title or options.Name or "Клавиша"
	local key = normalizeKey(options.Default) or Enum.KeyCode.Unknown
	local row = self:_row(title, 42)
	local label = textLabel(title, self.Window.Theme.Text, 12, Enum.FontWeight.Medium); label.Position = UDim2.new(0, 11, 0, 0); label.Size = UDim2.new(1, -132, 1, 0); label.Parent = row
	local bindButton = create("TextButton", {BackgroundColor3 = self.Window.Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "", TextColor3 = self.Window.Theme.Muted, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold), TextSize = 11, Position = UDim2.new(1, -111, 0.5, -13), Size = UDim2.new(0, 99, 0, 26), Parent = row})
	round(bindButton, 6); outline(bindButton, self.Window.Theme.Border, 0.6)
	local waiting = false
	local control = {}
	local function draw() bindButton.Text = waiting and "Нажмите клавишу" or (key == Enum.KeyCode.Unknown and "Не задано" or key.Name) end
	function control:Set(nextKey: any, silent: boolean?)
		key = normalizeKey(nextKey) or Enum.KeyCode.Unknown
		self.Window:_store(options.Flag, key); draw(); if not silent then self.Window:_callback(options.Changed, key) end
	end
	function control:Get() return key end
	bindButton.Activated:Connect(function() waiting = true; draw(); tween(bindButton, {BackgroundColor3 = self.Window.Theme.Accent}, 0.12) end)
	table.insert(self.Window._connections, UserInputService.InputBegan:Connect(function(input, processed)
		if waiting then
			if input.UserInputType == Enum.UserInputType.Keyboard then waiting = false; tween(bindButton, {BackgroundColor3 = self.Window.Theme.Surface}, 0.12); control:Set(input.KeyCode) end
			return
		end
		if not processed and key ~= Enum.KeyCode.Unknown and input.KeyCode == key then safeCall(options.Callback, key) end
	end))
	control:Set(key, true)
	if options.Flag then self.Window._controls[options.Flag] = control end
	return control
end

function Section:Colorpicker(options: any)
	options = options or {}
	local title = options.Title or options.Name or "Цвет"
	local palette = options.Palette or {
		Color3.fromRGB(122,105,255), Color3.fromRGB(69,156,255), Color3.fromRGB(58,204,174), Color3.fromRGB(76,214,151),
		Color3.fromRGB(244,180,65), Color3.fromRGB(255,117,91), Color3.fromRGB(255,99,120), Color3.fromRGB(220,101,255),
		Color3.fromRGB(245,245,245), Color3.fromRGB(168,177,198), Color3.fromRGB(70,76,96), Color3.fromRGB(25,27,38),
	}
	local value = typeof(options.Default) == "Color3" and options.Default or self.Window.Theme.Accent
	local container = create("Frame", {Name = "Color_" .. title, BackgroundColor3 = self.Window.Theme.Surface2, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 42), ClipsDescendants = true, Parent = self.Body})
	round(container, 7); local border = outline(container, self.Window.Theme.Border, 0.62); self.Window:_registerSearch(self.Tab, container, title)
	local head = create("TextButton", {BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Size = UDim2.new(1, 0, 0, 42), Parent = container})
	local label = textLabel(title, self.Window.Theme.Text, 12, Enum.FontWeight.Medium); label.Position = UDim2.new(0, 11, 0, 0); label.Size = UDim2.new(1, -67, 1, 0); label.Parent = head
	local swatch = create("Frame", {BackgroundColor3 = value, BorderSizePixel = 0, Position = UDim2.new(1, -42, 0.5, -12), Size = UDim2.new(0, 30, 0, 24), Parent = head}); round(swatch, 6); outline(swatch, Color3.fromRGB(255,255,255), 0.75)
	local choices = create("Frame", {BackgroundTransparency = 1, Position = UDim2.new(0, 11, 0, 48), Size = UDim2.new(1, -22, 0, 72), Parent = container})
	local grid = create("UIGridLayout", {CellSize = UDim2.new(0.25, -5, 0, 31), CellPadding = UDim2.new(0, 6, 0, 6), FillDirectionMaxCells = 4, SortOrder = Enum.SortOrder.LayoutOrder, Parent = choices})
	local expanded = false
	local control = {}
	function control:Set(nextColor: Color3, silent: boolean?)
		if typeof(nextColor) ~= "Color3" then return end
		value = nextColor; swatch.BackgroundColor3 = value; self.Window:_store(options.Flag, value); if not silent then self.Window:_callback(options.Callback, value) end
	end
	function control:Get() return value end
	for _, color in ipairs(palette) do
		local choose = create("TextButton", {BackgroundColor3 = color, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = choices}); round(choose, 6)
		choose.Activated:Connect(function() control:Set(color); expanded = false; tween(container, {Size = UDim2.new(1, 0, 0, 42)}, 0.18); tween(border, {Transparency = 0.62}, 0.16) end)
	end
	head.Activated:Connect(function() expanded = not expanded; tween(container, {Size = UDim2.new(1, 0, 0, expanded and 130 or 42)}, 0.18); tween(border, {Transparency = expanded and 0.16 or 0.62}, 0.16) end)
	control:Set(value, true)
	if options.Flag then self.Window._controls[options.Flag] = control end
	return control
end

-- Library -------------------------------------------------------------------
function NovaUI:CreateWindow(options: WindowOptions?)
	options = options or {}
	local player = Players.LocalPlayer
	assert(player, "NovaUI must be created on the client (LocalScript)")
	local playerGui = player:WaitForChild("PlayerGui")
	local window = setmetatable({}, Window)
	window.Theme = table.clone(DEFAULT)
	window.Theme.Accent = options.Accent or DEFAULT.Accent
	window.Values, window.Tabs, window._controls, window._connections, window._accentObjects = {}, {}, {}, {}, {}
	window.Visible, window._destroyed = true, false

	local screen = create("ScreenGui", {Name = "NovaUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})
	window.ScreenGui = screen
	local toastHolder = create("Frame", {Name = "Notifications", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 18), Size = UDim2.new(0, 315, 1, -36), Parent = screen})
	list(toastHolder, 8); window.ToastHolder = toastHolder
	local main = create("CanvasGroup", {Name = "Main", BackgroundColor3 = window.Theme.Background, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = options.Size or UDim2.fromOffset(760, 510), Parent = screen})
	round(main, 14); outline(main, window.Theme.Border, 0.22); window.Main = main
	local sizeConstraint = create("UISizeConstraint", {MinSize = Vector2.new(560, 390), MaxSize = Vector2.new(940, 650), Parent = main})
	local scale = create("UIScale", {Scale = 1, Parent = main}); window.Scale = scale
	local shade = create("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(27,30,45)), ColorSequenceKeypoint.new(0.15, window.Theme.Background), ColorSequenceKeypoint.new(1, window.Theme.Background)}), Rotation = 90, Parent = main})

	local top = create("Frame", {Name = "Topbar", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58), Parent = main})
	local title = textLabel(options.Title or "Nova", window.Theme.Text, 18, Enum.FontWeight.Bold); title.Position = UDim2.new(0, 20, 0, 9); title.Size = UDim2.new(0, 260, 0, 20); title.Parent = top
	local subtitle = textLabel(options.Subtitle or "Универсальный интерфейс", window.Theme.Muted, 11); subtitle.Position = UDim2.new(0, 20, 0, 31); subtitle.Size = UDim2.new(0, 270, 0, 15); subtitle.Parent = top
	local search = create("TextBox", {Name = "Search", BackgroundColor3 = window.Theme.Surface, BorderSizePixel = 0, ClearTextOnFocus = false, PlaceholderText = "Поиск…", PlaceholderColor3 = window.Theme.Muted, Text = "", TextColor3 = window.Theme.Text, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(1, -260, 0.5, -14), Size = UDim2.new(0, 153, 0, 28), Parent = top})
	round(search, 7); outline(search, window.Theme.Border, 0.62); padding(search, 9, 0); window.SearchBox = search
	local function topButton(symbol: string, x: number, callback: () -> ())
		local b = create("TextButton", {BackgroundColor3 = window.Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = symbol, TextColor3 = window.Theme.Muted, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold), TextSize = 14, Position = UDim2.new(1, x, 0.5, -14), Size = UDim2.new(0, 28, 0, 28), Parent = top})
		round(b, 7); b.Activated:Connect(callback); b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = window.Theme.SurfaceHover, TextColor3 = window.Theme.Text}, 0.12) end); b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = window.Theme.Surface, TextColor3 = window.Theme.Muted}, 0.12) end); return b
	end
	topButton("—", -98, function() window:SetVisible(false) end)
	topButton("×", -64, function() window:Destroy() end)

	local separator = create("Frame", {BackgroundColor3 = window.Theme.Border, BackgroundTransparency = 0.45, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(1, 0, 0, 1), Parent = main})
	local sidebar = create("Frame", {Name = "Sidebar", BackgroundColor3 = window.Theme.Surface, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 59), Size = UDim2.new(0, 180, 1, -59), Parent = main})
	local nav = create("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = window.Theme.Border, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 8, 0, 10), Size = UDim2.new(1, -16, 1, -20), Parent = sidebar})
	padding(nav, 3, 3); list(nav, 5)
	local pageHolder = create("Frame", {Name = "Pages", BackgroundTransparency = 1, Position = UDim2.new(0, 180, 0, 59), Size = UDim2.new(1, -180, 1, -59), Parent = main})

	-- Drag from neutral top-bar area; controls do not start a drag.
	local dragStart: Vector2? = nil; local startPos: UDim2? = nil; local dragging = false
	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if input.Position.X < search.AbsolutePosition.X - 12 then dragging = true; dragStart = input.Position; startPos = main.Position end
		end
	end)
	table.insert(window._connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and dragStart and startPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))
	table.insert(window._connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end))
	search:GetPropertyChangedSignal("Text"):Connect(function() window:_applySearch(search.Text) end)
	local toggleKey = options.ToggleKey or Enum.KeyCode.RightControl
	table.insert(window._connections, UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == toggleKey then window:ToggleVisible() end
	end))

	function window:Tab(tabOptions: any)
		tabOptions = tabOptions or {}
		local tab = setmetatable({}, Tab)
		tab.Window, tab._searchItems = self, {}
		local tabTitle = tabOptions.Title or "Вкладка"
		local button = create("TextButton", {Name = "Tab_" .. tabTitle, BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = tabOptions.Icon and (tabOptions.Icon .. "  " .. tabTitle) or tabTitle, TextColor3 = self.Theme.Muted, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 37), Parent = nav})
		round(button, 7); padding(button, 10, 0)
		local indicator = create("Frame", {BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0, Visible = false, Position = UDim2.new(0, 0, 0.5, -10), Size = UDim2.new(0, 3, 0, 20), Parent = button}); round(indicator, 3); self:_accent(indicator, "BackgroundColor3")
		local page = create("CanvasGroup", {Name = "Page_" .. tabTitle, BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Size = UDim2.fromScale(1, 1), Parent = pageHolder})
		local scroll = create("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = self.Theme.Border, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 15, 0, 14), Size = UDim2.new(1, -30, 1, -28), Parent = page})
		padding(scroll, 0, 2); list(scroll, 9)
		tab.Button, tab.Indicator, tab.Page, tab.Body = button, indicator, page, scroll
		button.Activated:Connect(function() self:SelectTab(tab) end)
		table.insert(self.Tabs, tab)
		if #self.Tabs == 1 then self:SelectTab(tab) end
		return tab
	end

	return window
end

return NovaUI
