-- This file is part of mimgui project
-- Licensed under the MIT License
-- Copyright (c) 2018, FYP <https://github.com/THE-FYP>

local imgui = require 'mimgui.imgui'
local lib = imgui.lib
local ffi = require 'ffi'

ffi.cdef [[
typedef struct IDirect3DDevice9 *LPDIRECT3DDEVICE9, *PDIRECT3DDEVICE9;
typedef struct IDirect3DVertexBuffer9 *LPDIRECT3DVERTEXBUFFER9, *PDIRECT3DVERTEXBUFFER9;
typedef struct IDirect3DIndexBuffer9 *LPDIRECT3DINDEXBUFFER9, *PDIRECT3DINDEXBUFFER9;
typedef struct IDirect3DTexture9 *LPDIRECT3DTEXTURE9, *PDIRECT3DTEXTURE9;
typedef const char *LPCTSTR;
typedef const void *LPCVOID;
typedef unsigned int UINT;
typedef void *HWND;
typedef signed __int64 INT64, *PINT64;
typedef unsigned int UINT_PTR, *PUINT_PTR;
typedef long LONG_PTR, *PLONG_PTR;
typedef UINT_PTR WPARAM;
typedef LONG_PTR LPARAM;
typedef LONG_PTR LRESULT;
typedef struct ImGui_ImplDX9_Context
{
	LPDIRECT3DDEVICE9        pd3dDevice;
	LPDIRECT3DVERTEXBUFFER9  pVB;
	LPDIRECT3DINDEXBUFFER9   pIB;
    ffi.gc(d3dcontext, function(cd)
        imgui.SetCurrentContext(context)
        -- void ImGui_ImplDX9_Shutdown(ImGui_ImplDX9_Context* context);
        lib.ImGui_ImplDX9_Shutdown(cd)
        imgui.DestroyContext(context)
    end)
    return setmetatable(obj, {__index = ImplDX9}
    self:SwitchContext()
    imgui.Render()
    -- void ImGui_ImplDX9_RenderDrawData(ImGui_ImplDX9_Context* context, ImDrawData* draw_data);
    lib.ImGui_ImplDX9_RenderDrawData(self.d3dcontext, imgui.GetDrawData())
end
exture)
end

function ImplDX9:CreateTextureFromFileInMem
		return nil
	end
    -- void ImGui_ImplDX9_ReleaseTexture(LPDIRECT3DTEXTURE9 tex);
    return ffi.gc(tex, lib.ImGui_ImplDX9_ReleaseTexture)
end

function ImplDX9:ReleaseTexture(tex)
    ffi.gc(tex, nil)
    lib.ImGui_ImplDX9_ReleaseTexture(tex)
end

function ImplDX9:CreateFontsTexture()
    self:SwitchContext()
    -- bool ImGui_ImplDX9_CreateFontsTexture(ImGui_ImplDX9_Context* context);
    return lib.ImGui_ImplDX9_CreateFontsTexture(self.d3dcontext)
end

function ImplDX9:InvalidateFontsTexture()
    self:SwitchContext()
    -- void ImGui_ImplDX9_InvalidateFontsTexture(ImGui_ImplDX9_Context* context);
    lib.ImGui_ImplDX9_InvalidateFontsTexture(self.d3dcontext)
end

return ImplDX9
