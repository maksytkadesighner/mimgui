--[[require 'libstd.deps' {
	'fyp:mimgui',
	'fa-icons-4'
}]]
local imgui, ffi = require 'mimgui', require 'ffi'
local new, str = imgui.new, ffi.string
local faicons = require 'fa-icons'
local vk = require 'vkeys'
local encoding = require 'encoding'
local cyr = encoding.CP1251
encoding.default = 'UTF-8'

local demo = {
	show = new.bool(),
	fonts = {},
	fontsArray = {},
	fontSelected = new.int(-1),
	fontChanged = false,
	fontSize = new.int(0),
	fontSizeChanged = false,
	guyImage = nil,
	iconsText = nil,
	imguiDemo = new.bool(),
	textBuffer = new.char[256](),
}

local function loadIconicFont(fontSize)
	-- Load iconic font in merge mode
	local config = imgui.ImFontConfig()
	config.MergeMode = true
	config.PixelSnapH = true
	local iconRanges = new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
	imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85(), fontSize, config, iconRanges)
end

imgui.OnInitialize(function() -- Called once
	-- Find all installed fonts
	local search, file = findFirstFile(getFolderPath(0x14) .. '\\*.ttf')
	while file do
		table.insert(demo.fonts, file)
		file = findNextFile(search)
	end
	demo.fontsArray = new['const char*'][#demo.fonts](demo.fonts)

	-- Load image from memory
	demo.guyImage = imgui.CreateTextureFromFileInMemory(guyImageData, #guyImageData)

	-- Disable ini config. By default it is saved to moonloader/config/mimgui/%scriptfilename%.ini
	imgui.GetIO().IniFilename = nil

	-- Add font with icons
	demo.fontSize[0] = imgui.GetIO().Fonts.ConfigData.Data[0].SizePixels
	loadIconicFont(demo.fontSize[0])

	-- All icons string
	local icons = {}
	for k, v in pairs(faicons) do
		icons[#icons + 1] = v
	end
	demo.iconsText = table.concat(icons, '\t')
end)

local frameDrawer = imgui.OnFrame(function() return demo.show[0] end,
-- Before frame. Called every frame
function()
	-- Fonts must be modified outside of frame draw. "Before frame" callback is the best place for it
	if demo.fontChanged then
		demo.fontChanged = false
		local glyphRanges = imgui.GetIO().Fonts.Fonts.Data[0].ConfigData.GlyphRanges
		local fontPath = ('%s\\%s'):format(getFolderPath(0x14), demo.fonts[demo.fontSelected[0] + 1])
		imgui.GetIO().Fonts:Clear()
		imgui.GetIO().Fonts:AddFontFromFileTTF(fontPath, demo.fontSize[0], nil, glyphRanges)
		loadIconicFont(demo.fontSize[0])
		-- Font texture invalidation forces the font texture to rebuild. It is necessary after font modifications
		imgui.InvalidateFontsTexture()
	end
	if demo.fontSizeChanged then
		demo.fontSizeChanged = false
		local fonts = imgui.GetIO().Fonts.ConfigData
		for i = 0, fonts:size() - 1 do
			fonts.Data[i].SizePixels = demo.fontSize[0]
		end
		imgui.GetIO().Fonts:ClearTexData()
		imgui.InvalidateFontsTexture()
	end
end,
-- Draw frame
function(self)
	imgui.SetNextWindowSize(imgui.ImVec2(330, 320), imgui.Cond.FirstUseEver)
	imgui.Begin(faicons('heart') .. ' mimgui v' .. imgui._VERSION, demo.show, imgui.WindowFlags.NoCollapse)
	if imgui.BeginTabBar('##1') then
		
		if imgui.BeginTabItem('Fonts') then
			imgui.Text('Font settings')
			imgui.Separator()
			local font = imgui.GetIO().Fonts.Fonts.Data[0]
			imgui.Text('Current font: %s', font:GetDebugName())
			if imgui.Combo('Select font', demo.fontSelected, demo.fontsArray, #demo.fonts) then
				demo.fontChanged = true
			end
			if imgui.IsItemHovered() then
				imgui.SetTooltip('Some fonts may crash the game')
			end
			if imgui.SliderInt('Font size', demo.fontSize, 4, 72) then
				demo.fontSizeChanged = true
			end
			imgui.Spacing()
			imgui.Text('Icons')
			imgui.Separator()
			imgui.BeginChild('icons', nil, true)
			imgui.TextWrapped(demo.iconsText)
			imgui.EndChild()
			imgui.EndTabItem()
		end
		
		if imgui.BeginTabItem('Behavior') then
			imgui.Text('Frame drawer behavior configuration')
			imgui.Separator()
			local checkbox = new.bool(self.HideCursor)
			if imgui.Checkbox('Hide cursor', checkbox) then
				self.HideCursor = checkbox[0]
			end
			checkbox[0] = self.LockPlayer
			if imgui.Checkbox('Lock player', checkbox) then
				self.LockPlayer = checkbox[0]
			end
			if self.HideCursor then
				imgui.Text('Press CTRL+SHIFT+C to restore cursor')
			end
			imgui.EndTabItem()
		end
		
		if imgui.BeginTabItem('Image') then
			imgui.Text('A gloomy guy')
			imgui.Separator()
			imgui.Image(demo.guyImage, imgui.ImVec2(80, 80))
			imgui.EndTabItem()
		end
		
		if imgui.BeginTabItem('Encoding') then
			imgui.Text('Текст на русском')
			imgui.Separator()
			imgui.InputText('##input', demo.textBuffer, ffi.sizeof(demo.textBuffer) - 1)
			imgui.SameLine()
			if imgui.Button('Записать в лог') then
				print(cyr(str(demo.textBuffer)))
			end
			if imgui.Button('Загрузить текст из файла "moonloader/text.txt"') then
				local f = io.open('moonloader/text.txt', 'r')
				if f then
					local text = f:read('*a')
					imgui.StrCopy(demo.textBuffer, cyr:decode(text))
					f:close()
				end
			end
			imgui.EndTabItem()
		end

		if imgui.BeginTabItem('Style') then
			imgui.ShowStyleEditor()
			imgui.EndTabItem()
		end

		if imgui.BeginTabItem('ImGui') then
			imgui.Checkbox('ImGui Demo', demo.imguiDemo)
			imgui.Spacing()
			imgui.Text('Guide:')
			imgui.ShowUserGuide()
			imgui.EndTabItem()			
		end
		imgui.EndTabBar()
	end
	imgui.End()
end)

imgui.OnFrame(function() return demo.imguiDemo[0] end, function()
	imgui.ShowDemoWindow(demo.imguiDemo)
end)

function main()
	while true do
		wait(20)
		if wasKeyPressed(vk.VK_3) then
			demo.show[0] = not demo.show[0]
		end
		if isKeyDown(vk.VK_CONTROL) and isKeyDown(vk.VK_SHIFT) and wasKeyPressed(vk.VK_C) then
			frameDrawer.HideCursor = false
		end
	end
end

-- File: 'guy.jpg' (3958 bytes)
-- Exported using binary_to_compressed_lua.cpp
guyImageData = "\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xDB\x00\x43\x00\x06\x04\x05\x06\x05\x04\x06\x06\x05\x06\x07\x07\x06\x08\x0A\x10\x0A\x0A\x09\x09\x0A\x14\x0E\x0F\x0C\x10\x17\x14\x18\x18\x17\x14\x16\x16\x1A\x1D\x25\x1F\x1A\x1B\x23\x1C\x16\x16\x20\x2C\x20\x23\x26\x27\x29\x2A\x29\x19\x1F\x2D\x30\x2D\x28\x30\x25\x28\x29\x28\xFF\xDB\x00\x43\x01\x07\x07\x07\x0A\x08\x0A\x13\x0A\x0A\x13\x28\x1A\x16\x1A\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\x28\xFF\xC0\x00\x11\x08\x00\xA0\x00\xA0\x03\x01\x22\x00\x02\x11\x01\x03\x11\x01\xFF\xC4\x00\x1C\x00\x00\x02\x02\x03\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x02\x07\x01\x04\x06\x05\x03\xFF\xC4\x00\x3C\x10\x00\x01\x03\x03\x03\x02\x03\x05\x07\x01\x06\x07\x00\x00\x00\x00\x01\x00\x02\x03\x04\x05\x11\x06\x07\x21\x12\x31\x08\x41\x51\x13\x61\x81\x91\xC1\x14\x15\x22\x32\x71\xB1\xD1\x16\x23\x33\x42\x62\x63\xA1\x18\x24\x55\x92\x93\xA2\xB2\xFF\xC4\x00\x14\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xC4\x00\x14\x11\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x0C\x03\x01\x00\x02\x11\x03\x11\x00\x3F\x00\x6A\x50\x84\x20\x16\x3D\xF9\x59\x2B\xE1\x3C\xF1\x53\xC6\x5F\x34\x8D\x63\x5A\x32\x49\x38\x41\xF5\x25\x79\x57\xBD\x41\x6C\xB2\xC2\x65\xB9\x55\xC7\x0B\x47\xA9\x0A\xA4\xDD\x4D\xF1\xB7\xE9\xF0\x68\xAC\x19\xAE\xB8\xB8\x11\xD2\xD0\x78\x2A\xA5\xB4\x69\x0D\x77\xBB\x17\x21\x57\x7A\x92\x58\x2D\xC5\xDD\x59\x24\x0E\x0F\xB9\x05\xAB\xAE\x7C\x43\xD8\x6D\x1D\x71\x59\x7F\xE7\xEA\x07\x18\x69\x21\x55\xF5\x7B\xD1\xAE\xB5\x4B\x8B\x2C\x96\xE9\xA1\x0E\x3F\x87\x1C\xFD\x15\xB7\xA7\xBC\x3D\x69\x8B\x64\xAD\x96\xA1\x9F\x6A\x78\xEE\x5C\x48\x56\x75\x9B\x4B\x5A\x2C\xF1\x35\x94\x34\x51\x44\x1A\x31\xDB\x28\x15\x37\x69\xFD\xE3\xBD\x46\x27\x94\x4E\xD0\x7B\x61\xC0\x7D\x56\xF5\x2E\xD5\x6E\x6D\x7D\x38\x92\xAA\xE7\x51\x0B\xCF\xF8\x33\x9F\xAA\x6E\x1A\xD0\x32\x03\x40\x1E\xE0\xA4\x00\x1D\x90\x27\x35\xFB\x53\xB9\x34\x6D\x2F\xA7\xAF\xA9\x99\xC0\x67\x1D\x44\x7D\x57\x3F\x2C\x5B\xAF\x64\x69\xEA\x15\x41\xAD\xE7\x39\xCA\x79\x48\x1E\x60\x2F\x9C\x94\xD0\xCA\x31\x24\x4C\x23\xCC\x16\x84\x09\x75\x97\x79\xB5\xE6\x9F\x00\xDC\xE9\x67\xA9\x63\x7B\x82\xD2\x38\xF9\x2B\x63\x42\xF8\x8D\xB3\x5D\x4B\x20\xBF\x43\xF7\x7C\xE7\xCD\xCE\x27\x27\xE4\xAE\x5A\xCD\x33\x68\xAD\x85\xF1\x54\x50\xC4\x58\xEE\x0F\xE1\x1C\xAA\x8F\x5E\x78\x7C\xB2\xDE\x62\x96\x6B\x4E\x29\x6A\xB1\x96\xF4\xE5\x05\xC3\x66\xBF\xDB\x6F\x10\x36\x6B\x7D\x5C\x52\xB1\xC3\x8C\x38\x72\xBD\x4C\xF9\x8E\x42\x42\xAA\x6D\x5A\xFB\x6C\xEE\x6F\xF6\x5E\xDD\xB0\x44\xFC\xB5\xC0\xF5\x07\x00\xAE\x8D\xAC\xF1\x0B\x4D\x72\x7C\x36\xED\x4C\xDF\xB3\x55\x13\xD2\x24\x20\x9E\xA3\xF4\x40\xC7\x03\xCA\xCA\xD5\xA1\xAB\x82\xB6\x06\x4D\x4B\x23\x64\x89\xE3\x20\xB4\xE5\x6D\x76\x40\x21\x08\x40\x1E\xCA\x20\x9C\xFB\x94\xBD\x72\xB4\xEE\x15\xB0\xD0\x51\xCD\x53\x53\x20\x64\x4C\x69\x71\x27\xC9\x07\x9F\xAB\x35\x1D\x16\x9B\xB5\xCB\x5B\x5F\x2B\x58\xC6\x34\x90\x09\xEE\x94\x6D\x5B\xB9\x1A\xB3\x71\xEF\xAF\xB5\xE9\xB6\xCD\x1D\x21\x7F\x40\x2C\x24\x8C\x67\xD7\x0B\x3B\x8B\xAA\x6F\x1B\xAD\xAD\x05\x92\xD9\xED\x1B\x6B\x8E\x4E\x90\xE6\x0C\x83\xEA\x99\x2D\xAC\xDB\x7B\x5E\x8A\xB4\xC4\xCA\x78\x9A\xEA\xB7\x34\x19\x24\x23\x9C\xE1\x07\x1D\xB5\x7B\x1D\x43\x63\x8A\x0B\x86\xA0\xC5\x65\xD0\x8E\xA7\x17\x8C\xE0\x9F\x8A\xBB\x69\xE9\xA1\xA6\x8C\x47\x04\x6D\x63\x07\x18\x68\xC2\x9E\x0F\xA7\x65\x31\xD9\x01\x80\x8C\x04\x21\x01\x8E\x56\x30\x16\x50\x80\x46\x10\x84\x18\xC0\x59\xC0\xE1\x08\x41\xA5\x71\xB6\xD1\xDC\x21\x7C\x75\x70\x32\x46\x38\x60\xE5\xA0\xF0\xA8\x7D\xCC\xF0\xFB\x6F\xB9\xFB\x6B\x86\x9F\x78\xA5\xAB\x03\xA8\x46\xD6\xFE\x63\xFA\xE5\x30\xA7\xB2\x81\x1E\x7E\x7E\xA8\x13\x6D\xB6\xDC\x2B\xF6\xDA\xEA\x51\x62\xD5\x46\x53\x44\xE7\xF4\x82\xF2\x70\xD1\x9E\xE9\xB9\xB2\xDD\xE8\xEF\x34\x11\x55\x50\xCE\xC9\x63\x78\xCF\x04\x2E\x1B\x75\xF6\xBA\xD7\xAD\xA8\x24\x73\xE3\x0C\xAE\x6B\x0F\xB3\x90\x0E\x7A\xBC\x92\xF7\xA0\xF5\x4D\xF3\x69\xB5\x87\xDC\xDA\x84\xC8\x2D\x8E\x93\x01\xC7\x90\x1A\x4F\x7E\x3D\xC1\x03\x9D\xD4\x7A\xB1\xE4\xA4\xBC\xFB\x35\xCE\x96\xED\x41\x0D\x5D\x14\xA2\x48\xA4\x68\x70\x20\xFA\xAF\x41\x04\x49\x3D\xFB\x04\xB9\xF8\x93\xD6\xB3\xCF\x53\x06\x92\xB1\xBC\xBA\xB6\x77\x74\xC8\x18\x7B\x03\x85\x71\xEE\x26\xA8\xA5\xD2\x9A\x6E\xAA\xBE\xB2\x4E\x92\xD6\x9E\x91\xDF\x25\x2F\xBE\x1F\xEC\x4E\xD6\xBA\xC6\xE3\xAB\x2F\x4C\x73\xDE\x1E\x0C\x24\x8C\x8C\x64\x8F\xD9\x05\xB7\xB2\xBB\x79\x4D\xA4\xB4\xFD\x3B\xE7\x81\x8E\xAF\x78\xEA\x74\x84\x73\x93\xCA\xB4\x70\xA2\xC0\x1A\xD0\xD1\xD8\x70\xA6\x80\xC0\x42\x10\x80\x42\x10\x80\x42\x10\x80\x42\x10\x80\x42\x10\x80\x46\x10\x84\x18\xC0\x1E\x4A\xAC\xDF\x3D\xBB\xA6\xD6\x5A\x6E\x77\x44\x03\x2B\xA1\x69\x7B\x1C\x1B\x92\x4E\x31\x85\x6A\x1E\xCB\xE6\xEC\x38\x61\xC3\x23\xD1\x02\xBF\xE1\xA7\x5A\x3E\xD9\x72\xAB\xD3\x17\xC9\x5C\x27\x89\xC5\x91\xB9\xE7\x1F\xE2\xC0\x1C\xFE\x89\xA1\x6B\x83\x9A\x0B\x4E\x41\xE7\x29\x47\xF1\x1F\xA4\xE7\xD2\x7A\x96\x97\x53\xD8\xE3\x2D\x0E\x7F\x53\x9C\xDE\x30\x40\xC9\xFD\xD3\x1B\xB6\x7A\x82\x2D\x43\xA4\x68\x2A\x99\x28\x7C\x9E\xC9\xA1\xF8\x3E\x60\x0C\xA0\xA2\xBC\x59\xDD\x2A\x2A\x6B\xE8\x2C\x54\xCE\xEA\xF6\xCE\x01\xCC\x07\xDC\x0A\xBB\xB6\x9F\x4F\x53\xE9\xCD\x1D\x43\x4B\x4F\x10\x8D\xC5\x81\xCE\xC0\xC7\x24\x02\x96\xFB\xD4\xEF\xD6\x7E\x22\xFA\x5A\xF3\x25\x34\x2F\x6B\x40\xEE\x01\x0D\x20\xFE\xC9\xBF\xA5\x67\x45\x3C\x4D\x1C\x06\xB1\xA3\x1F\x04\x1F\x4E\xC7\x9F\x35\xC7\xEE\x9E\xA3\xAB\xD3\x1A\x5A\x7A\xFA\x0A\x77\x4F\x3B\x01\x21\xA0\x13\xD8\x7B\x97\x60\x3B\x72\xBE\x15\xB4\xB0\xD6\xD3\x3E\x0A\x88\xC3\xE2\x78\xC1\x69\x08\x29\x8D\xA1\xDE\xCA\x3D\x4E\x5D\x47\x7B\x22\x92\xBD\xA4\xF0\xEE\x07\xCC\xAB\x70\xDF\xAD\x4D\xC6\x6E\x34\x83\x3C\xFF\x00\x7A\xD5\x44\xEE\x27\x87\xEF\xBC\xEE\xCD\xAF\xD3\x32\xB6\x92\x42\x72\xF1\xD4\x1B\x85\xE0\x41\xE1\xEB\x53\xB9\xF9\xA9\xBE\x4B\x8F\xF2\xCA\x3F\x84\x0C\xA0\xBF\x5A\x3B\x8B\x8D\x26\x4F\xFA\xAD\xE7\xFD\xD4\x24\xD4\x96\x88\xC8\x6B\xAE\x54\xB9\x3F\xEA\xB7\xF9\x4B\x8B\xFC\x3D\x5F\xD8\xF0\x5D\x7F\x98\x46\x3B\x93\x2B\x47\xD1\x6A\x4D\xB0\x37\xC9\xA4\xC5\x2E\xA2\x12\x91\xE4\x67\x69\xFA\x20\x65\xEA\x35\x3D\x9A\x06\x82\xEB\x95\x21\xCF\x60\x25\x69\xFA\xAA\xF3\x74\xB7\x9A\xCF\xA4\xA8\x8B\x29\x25\x6D\x4D\x5B\xC7\xE0\x11\x9E\xA1\xEB\xC9\x05\x55\x8E\xF0\xEB\xA9\xE4\x73\x3D\xA5\xE5\xC4\x0F\xF5\x47\xF0\xB7\x2C\x3E\x1A\xAA\x7E\xFA\x8A\x7B\xF5\x7B\xA7\xA6\x61\x04\x80\xE0\x49\xF8\x61\x05\xEF\xB7\x1A\x96\x5D\x4F\xA5\xE0\xB9\x4D\x0B\xA2\x91\xF9\xCB\x48\x3F\x0E\xEA\xA2\xDC\x7D\xDE\xBA\x68\xBD\xC3\x65\x2D\x64\x0F\x36\x82\x5A\x32\x32\x7B\x8F\x25\x7D\xD9\xED\xB4\xF6\xAB\x7C\x54\x74\x8C\x0C\x8A\x36\x80\x00\x1E\xE5\xC6\x6E\xA6\xDB\x5B\xB5\xDD\xAC\xC5\x33\x7D\x9D\x53\x79\x64\x8D\x03\x3F\x32\x83\xD4\xA5\xD7\xB6\x09\xED\xD1\x55\xBA\xE3\x4E\xD6\xB9\xA1\xDD\x26\x40\x0F\xCB\x2B\x62\x0D\x6F\x60\x9E\x32\xF6\x5C\xA9\x9A\x07\xAC\x8D\x1F\x54\xBC\xFF\x00\xC3\x45\xCF\xA9\xCC\x17\x79\x44\x23\xF2\x8F\x68\xDF\xE1\x61\xFE\x1A\xAE\xAD\x18\x8E\xEF\x20\x6F\xBD\xED\xFE\x10\x31\x5F\xD6\x56\x1F\xFA\x9D\x37\xFE\x56\xFF\x00\x2B\xE3\x51\xAE\xB4\xF5\x38\xCB\xEE\x54\xF8\x3E\x92\x34\xFD\x55\x05\x0F\x86\xCA\xB7\x03\xD7\x7C\x9C\x3B\xD1\xB2\x34\xFD\x14\x8F\x86\x6A\x99\x32\x24\xBC\xD4\x11\xE5\xF8\x9B\xFC\x20\xEA\xB5\xEE\xFD\xD0\x5B\x6E\x74\xD6\xDB\x04\x6E\xAC\xA8\x92\x46\xB4\x90\x32\x3F\x30\x1D\xC1\xF7\xAB\xA6\xC3\x57\x2D\x7D\xA2\x9A\xAA\x76\x7B\x39\x64\x6E\x4B\x7D\x15\x1B\xB7\xDE\x1E\x28\xF4\xF5\xED\xB7\x0A\xFA\xA9\x2A\x5F\x19\xCB\x43\xBA\x48\x57\xFB\x18\x23\x63\x58\xD1\x80\x3B\x20\xE4\x77\x56\xC1\x0E\xA1\xD1\xD7\x0A\x69\x58\x1C\xEF\x64\xEE\x8E\x33\x82\xA8\xFF\x00\x0B\x77\xB7\xD0\x5D\xAE\x3A\x7E\xA5\xF8\xE8\x91\xC1\x81\xC7\xFC\xD8\xFA\x26\x7A\x46\x36\x46\xB9\x8E\x00\xB0\x8C\x10\x93\x5B\x91\x1A\x37\xC4\x1C\x6E\x8F\xFB\x38\x66\x91\xAE\x20\x76\xE4\x92\x80\xF0\xCE\xDF\xB7\x6E\x55\x75\x55\x40\x32\x3B\xDB\x39\xC1\xC7\x92\x3F\x11\x4E\x6B\x40\xE9\x09\x43\xF0\x8F\x17\x56\xAA\xBA\xBF\x00\x86\xBF\x8C\xFE\xA5\x37\xA3\xB2\x00\x84\x63\xB2\x10\x80\x58\xCA\xC9\xF3\x51\x07\x3D\x90\x56\x7B\xFD\x7E\xAC\xB0\xE8\x4A\x9A\x9A\x19\x5F\x14\xD9\x68\x0E\x6F\x04\x64\xE1\x2A\xFB\x53\xB8\xBA\x93\xFA\xCE\x92\x29\x6E\x33\xCB\x1C\xAF\xC3\x98\xE7\x71\xC9\x09\xD9\xD5\xBA\x6E\x87\x53\xDA\xDF\x43\x72\x60\x74\x4E\xEF\xC6\x71\x85\xC0\xE9\xDD\x8D\xD3\x36\x3B\xB3\x6B\xE0\x6B\x9D\x23\x0E\x5A\x0B\x07\x08\x2D\x68\x1E\x5F\x13\x5C\x7B\x91\x9F\xD1\x4C\xBB\xA4\x12\x78\x00\x65\x61\xAD\x0D\x00\x34\x00\x07\x65\xAD\x75\x25\x96\xBA\xB7\x03\x87\x08\x9C\x41\xF8\x14\x1E\x43\x35\x95\x99\xF7\x83\x6C\x6D\x5B\x0D\x60\xE3\xA3\x23\xF9\x5D\x10\x24\x8C\x82\x91\x2D\x1D\x3C\xF5\x3B\xEB\x2B\xE4\x99\xCE\x70\xA8\x3C\xFB\xB2\x13\xD5\x09\x3E\xCD\xA5\x04\xF9\xF5\x5C\xF6\xBB\xBD\x0B\x0E\x9A\xAC\xAF\x24\xE6\x36\x12\x31\xEB\x85\xD0\x79\x15\xE3\xEA\xAB\x1C\x1A\x86\xCB\x3D\x05\x51\x21\x92\xB4\x8E\xD9\xC6\x50\x27\x1A\x73\x7D\x35\x0C\x1A\xC0\x3A\x7A\x99\x26\xA1\x96\x7E\x9E\x87\xBB\xF2\xB4\x9F\x44\xE8\x58\x6E\x02\xE7\x68\xA4\xAC\x6F\x02\x68\xC3\xBE\x69\x73\xB4\xF8\x67\x8E\x0D\x43\xF6\xBA\x9A\xC9\x0D\x2B\x24\xEB\x6B\x01\x69\xE3\x3D\x93\x1D\x67\xB7\x45\x6B\xB6\xC1\x49\x07\xF7\x71\x34\x34\x67\x8E\xC8\x37\xB3\xCA\xC9\xEC\xA2\xA4\x83\x00\x04\xA4\x78\xA2\xB5\xB2\xDB\xAD\xED\x37\x36\x37\xF1\xC9\x23\x5A\x5D\xFA\x02\x9B\x83\xD9\x2A\xFE\x31\x2A\x0C\x55\x76\x71\x81\x86\xCA\x1D\xFF\x00\xAA\x0E\x7F\xC2\x7D\x73\xA3\xD6\x95\xF0\x34\x0C\x48\xF3\xDF\xF5\x29\xC8\x1D\x82\x45\x7C\x3B\x5C\x05\xB3\x74\xCC\x32\x9E\x80\xF9\x9C\xDC\x76\xEC\x4A\x7A\x23\x39\x63\x4F\xA8\x05\x04\x90\x84\x20\x11\x8E\x72\x84\x20\x10\x84\x20\xC6\x0A\xF1\xB5\x85\x49\xA5\xD3\x57\x29\x5B\x82\x44\x0F\xFF\x00\xE4\xAF\x68\xF0\x17\x3B\xAF\xA9\xE4\xAA\xD2\x77\x18\xA1\x77\x4B\x8C\x2F\xE7\x38\xFF\x00\x09\x40\x98\xEC\x8B\x7E\xF3\xDD\x93\x3C\x98\x0E\x2E\x2F\x3C\xF7\xEC\x9E\xD8\xC6\x1A\x01\x48\xAE\xC0\x53\xBE\x9F\x74\xFD\x8B\xC0\x7B\xD8\x5C\x09\x1C\xFA\x27\xAC\x64\x01\x94\x12\x40\x58\xC7\x2B\x28\x04\x60\x7A\x21\x08\x04\x21\x08\x0C\x72\x94\x9F\x18\x44\x4D\x7E\xB6\x45\x93\x82\xE6\xF0\x3F\x44\xDB\x12\x94\x1F\x11\x75\xB1\x5E\xF7\x4E\xD7\x6B\x81\xA0\xB9\xAE\x61\x77\x4F\x7E\xC5\x07\x17\xAD\x69\x9B\xA0\xB7\xC5\xD2\x06\xB9\x94\xF1\xCA\xD9\x01\x03\x83\xD4\x33\xF5\x4E\xFE\x9F\xB8\x43\x74\xB3\x52\x55\xD3\xBB\xAA\x39\x23\x69\x07\xE0\x12\xDD\xE2\xF7\x4A\xBE\x58\xE0\xBE\x53\xC7\x92\xD3\xFD\xA3\x80\xF2\x03\x01\x75\x5E\x14\x75\x58\xB9\xE8\xF1\x6C\xA8\x99\xCF\xA9\xA5\xEF\xD4\x79\xC1\x3C\x7E\xC8\x2F\x81\x9F\x35\x20\xA2\x33\xE6\xA4\x10\x08\x42\x10\x07\xB2\x88\xEE\xA4\xA3\xDF\xD5\x01\x9E\x39\xE1\x69\x5E\xE0\xFB\x45\xA2\xB2\x11\xC9\x7C\x2F\x03\xF5\xC1\x0B\x61\xD5\x10\xB5\xC4\x3A\x40\x0F\xA1\x58\x35\x74\xE1\xBC\xCA\xDC\x20\x52\x76\x63\x4C\x5D\x2D\xFB\xC3\x5D\x24\xF4\x53\x36\x99\xAF\x78\x12\x39\x84\x03\xDB\xCD\x37\xCB\x46\x3F\xB0\xC4\xE3\x24\x5E\xCD\x8E\x71\xC9\x70\xF3\x5F\x71\x57\x01\x38\x12\xB7\x21\x07\xDC\xF6\x51\xE7\xCB\x95\xF3\x15\x30\xB8\x64\x3C\x61\x4D\xAE\x6B\x86\x5A\x78\xF5\x41\x20\x70\x56\x54\x79\xC8\x03\xB2\x92\x01\x47\x3C\x12\x14\x8F\x65\x1F\x4C\x04\x1F\x1A\xD9\xC5\x3D\x24\xB3\x3C\x80\x18\xDC\x94\x9D\xE8\x2A\x67\xEB\x6D\xF7\xAB\xAC\x98\x07\x32\x96\x5C\x73\xDB\x01\xC4\x26\x2F\x7B\x75\x24\x7A\x73\x42\xD7\xCE\xE7\x62\x47\xC6\xE6\xB3\xDE\x71\x95\x5A\x78\x54\xD3\xB2\x7D\x9A\xB7\x50\x56\x44\x5B\x2D\x4B\xDD\xD2\x48\xF2\xEA\xC8\xFD\xD0\x5C\x9B\x89\xA7\x62\xD4\xFA\x62\xB6\xDF\x23\x41\x73\xD9\xF8\x73\xF3\x49\x9E\xD5\xDE\x2B\x36\xFB\x74\x1D\x41\x56\x5D\x0C\x6F\x9B\xA6\x46\xF9\x63\x27\x09\xF2\x20\x1E\x12\x93\xE2\x97\x40\x4D\x47\x79\xFE\xA8\xB5\xB5\xDF\x8C\xE6\x5E\x91\xF9\x71\x8C\x20\x6C\x29\x66\x6D\x45\x34\x52\x46\xE0\x5A\xE6\x83\x91\xEF\x0B\xEF\x94\xBD\x78\x73\xDD\x88\x6F\x16\xF8\xEC\xD7\x89\xD9\x1D\x64\x43\xA5\x85\xC7\x05\xC9\x84\x6B\x81\x68\x20\xF1\x84\x12\x42\x02\x10\x05\x50\x5B\xFB\xBA\xB5\x5A\x72\x66\xDA\x2C\x38\x7D\xC1\xFC\x10\x39\x23\x95\x7E\x9E\xCB\x80\xB8\x6D\x8D\x9A\xE1\xAC\x1B\x7F\xAB\x63\xA5\x9C\x64\x86\xB8\xE5\xBE\x5E\x58\x40\xAB\x8A\x5D\xD5\xBB\x30\xD7\x06\xDC\x5A\x1F\xF8\x80\x04\x81\xF0\xE5\x61\x96\x4D\xD7\x94\x00\xD6\xDC\xBF\xEF\x3F\xCA\x78\xA2\x82\x28\x98\x19\x1C\x4C\x6B\x40\xC0\x00\x29\x86\x34\x76\x63\x47\xC1\x02\x3C\xEB\x46\xED\x42\xD2\xC3\x15\xC8\x8C\xF7\xEA\x3F\xCA\xF8\x7D\x83\x75\x63\x93\xA8\xC7\x72\xC9\xFF\x00\x31\xFE\x53\xD0\x5A\xD3\x9C\xB4\x2C\x7B\x38\xF8\xCC\x6D\xF9\x20\x45\xDF\x51\xBA\x74\x71\x92\xE8\x6E\x1D\x23\x93\x9C\xFF\x00\x2B\xB0\xDA\x7D\xF0\xB8\xD9\xEF\x1F\x75\x6B\x00\xF0\xC2\xEC\x75\x3B\x82\xDF\x2E\x72\x9B\x57\xD2\xC0\xF6\x90\xF8\x63\x70\x3D\xC1\x68\x55\x26\xE2\xEC\x8D\x9F\x56\x5C\x19\x59\x18\xFB\x34\xA0\xE4\xF4\x1E\x9C\x9C\xFB\x82\x0B\x5E\xD9\x5D\x05\xCA\x82\x0A\xBA\x47\x87\xC3\x33\x43\xD8\xE0\x72\x08\x5B\x6B\xC7\xD2\xB6\x76\x58\xB4\xFD\x0D\xB6\x27\x39\xCD\xA7\x88\x47\x92\x72\x78\x5E\xC2\x03\xC9\x7C\xFA\x80\xE4\x9C\x61\x4D\xDD\x95\x6B\xBD\x9A\xEA\x97\x47\x69\x6A\x92\x24\x1F\x6D\x99\xA5\x91\x30\x1E\x73\x8C\x84\x14\xDE\xFB\xDE\xA6\xD6\xDB\x85\x6F\xD2\x96\xF7\xF5\x53\xB5\xED\xF6\xB8\x3C\x1C\x82\x0F\xEC\x99\x4D\x1F\x68\x8A\xC9\xA7\xE8\xE8\xA1\x8D\xAC\x11\xC6\xD0\x43\x46\x39\xC0\xCA\xA1\x3C\x38\xE8\x6A\x9A\x9A\xF9\xF5\x5D\xF0\x39\xF3\x54\x1E\xB8\x8B\xC6\x71\xCE\x47\x7F\xD5\x32\x80\x01\x8C\x20\x96\x02\xF2\xB5\x15\x9E\x96\xF9\x6B\x9E\x8A\xBA\x26\xBE\x29\x5A\x5A\x72\x3B\x2F\x55\x47\xB1\x3E\x48\x10\x6D\xD0\xD0\xD7\x7D\xB5\xD5\x5F\x6D\xA1\x12\x36\x90\xBF\xAA\x29\x1B\x9E\x3D\xC4\xA6\x4F\x60\xB7\x3E\x9B\x55\xD9\x1B\x4B\x71\x9D\x8C\xB8\xC4\xD6\xB4\x82\x70\x5C\xAC\x4D\x6D\xA5\x68\x35\x65\xA2\x5A\x1A\xF8\xDA\xEE\xA1\x80\xEC\x72\xD4\x97\xEE\x4E\x86\xBD\xED\x66\xA5\x15\x16\x99\x66\x75\x23\x9C\x5C\xD9\x23\x24\x01\x8F\x22\x81\xF1\x69\x07\x24\x10\x42\xCF\xC1\x2F\xBB\x23\xBE\x14\x37\xBA\x58\xAD\xB7\xF9\x59\x4D\x58\xCE\x3D\xA4\x8E\x00\x39\x5F\xB4\xF3\xC5\x51\x10\x92\x07\xB6\x46\x11\x90\x47\x62\x83\xEC\x56\x47\x65\x8F\x3C\x2C\xA0\x10\x84\x20\x02\x30\x84\x20\x30\x84\x21\x01\xD9\x63\x39\x38\xE5\x61\xEE\x0C\x69\x73\x88\x00\x0E\x49\x55\x66\xE9\x6F\x05\xA3\x47\x52\x96\x53\xCD\x1D\x55\x77\x61\x1B\x1C\x09\x1F\x02\x83\xAA\xD7\xDA\xCE\xDB\xA3\xAC\xF3\x56\x5C\xA6\x68\x7B\x5A\x4B\x19\x9C\x17\x14\xB7\x69\xAB\x75\xE3\x79\x75\xE9\xB9\x5D\xE9\xA6\x8E\xC9\x01\x06\x3C\x8C\x31\xC0\x1C\x63\xF5\xC2\xD5\xB1\xD8\x35\x36\xF5\x6A\x11\x5B\x7A\x6C\xD4\xB6\x86\xB8\x10\x08\x2D\x04\x67\xE5\xD9\x35\x9A\x5A\xC1\x49\xA7\x2C\xF0\x5B\xE8\x63\x6B\x59\x13\x43\x72\x07\x25\x06\xDD\x9E\xDF\x05\xAE\x82\x2A\x4A\x56\x06\x45\x13\x43\x40\x1E\xEE\x16\xFE\x02\x87\x7E\xFF\x00\x05\x3C\x20\x10\x84\x20\x30\xBC\x8B\xFD\x8A\xDF\x7D\xA2\x7D\x35\xC6\x9A\x39\x5A\xE0\x46\x5C\x01\x21\x7A\xEA\x27\xB7\xBD\x02\x99\xB9\xFB\x07\x57\x47\x24\xB7\x2D\x2C\xE2\x3A\x0F\x50\x63\x49\xCA\xE4\xF4\x7E\xF2\x6A\x5D\x0F\x54\xCA\x0B\xDC\x52\x3E\x28\x8F\x4B\x98\xF6\x82\xEF\x99\x29\xDE\x2C\x0E\x69\x0E\x00\x83\xE4\x79\x0B\x86\xD6\x7B\x63\xA7\xB5\x56\x5D\x59\x47\x1B\x25\x39\xCB\xE3\x68\x69\x3F\x20\x83\xCC\xD1\x3B\xC9\xA6\x75\x44\x71\xB1\xB5\x6C\xA7\xA9\x70\xE6\x29\x1D\xC8\x3F\x05\x63\xD3\xD5\x41\x51\x18\x7C\x12\xB5\xEC\x23\x20\x84\xAD\xEA\xEF\x0D\xB5\xB0\x4E\xFA\x9D\x2D\x72\xF6\x24\xF2\x1A\x3A\xBA\xBE\x61\x70\xB3\x41\xB9\xFA\x2E\xA9\xD4\xDE\xC6\xE1\x51\x04\x27\x1E\xD3\xF1\x10\x7E\x65\x03\xC8\x4F\xA2\xC8\xEE\x92\x7A\x3D\xF6\xD6\x96\xE7\x08\xAA\xA9\x89\x2C\x38\x20\xC7\xCA\xE9\x68\xFC\x4C\xDC\x63\x88\xB2\xAA\xD5\x2B\x9F\xDB\x21\xAD\x08\x1B\x42\xA2\x31\xE4\x52\x99\x17\x89\xAA\xF6\x48\xEC\xDA\xA6\x23\xCB\x86\xAD\x2A\xDF\x11\x7A\x8A\xB9\x8E\x8E\xDD\x6D\x73\x5E\xE3\xC7\xE0\x05\x03\x79\x53\x51\x0C\x0C\xEB\x9D\xE1\x8D\xF5\x2B\x8A\xD5\xDB\x9F\xA6\x34\xD5\x33\xDD\x57\x72\x81\xD2\x81\xC4\x61\xDC\x92\x95\xEA\xFB\xD6\xE8\xEB\x78\xFD\x83\x28\x6B\x23\x89\xC3\xF3\x46\xC2\xDF\xD8\xAF\x6F\x46\xF8\x7B\xBE\xDD\xA7\x8A\xA3\x54\x55\xCB\xEC\xB2\x09\x64\x85\xDD\x5F\x32\x50\x69\xEB\x2D\xF3\xD4\x3A\xA6\xB2\x5A\x0D\x33\x0B\x99\x04\x84\xC6\x08\x68\xC9\x07\xDE\x17\x45\xB6\x1B\x1B\x59\x79\x74\x77\xAD\x5D\x52\xF9\x65\x73\xFA\x84\x4F\x73\xB3\xFE\xEA\xF1\xD1\xFB\x67\xA7\xB4\xCC\x2C\x6D\x2D\x14\x52\x3D\xA7\xF3\x48\xD0\xE3\x9F\x88\x5D\xB3\x18\xD6\x34\x36\x26\xB5\xAD\x1E\x40\x60\x20\xD3\xB3\xDB\x29\xAD\x34\x51\xD3\x51\xC4\xC8\x98\xD0\x06\x1A\x00\x5E\x82\x88\xCE\x7D\xEA\x48\x04\x21\x08\x3F\xFF\xD9"