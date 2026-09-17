local wezterm = require("wezterm")
local act = wezterm.action

return {
	keys = {
		-- =============================================
		-- Tab 操作
		-- =============================================
		{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
		{ key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },
		{ key = "1", mods = "ALT", action = act.ActivateTab(0) },
		{ key = "2", mods = "ALT", action = act.ActivateTab(1) },
		{ key = "3", mods = "ALT", action = act.ActivateTab(2) },
		{ key = "4", mods = "ALT", action = act.ActivateTab(3) },
		{ key = "5", mods = "ALT", action = act.ActivateTab(4) },
		{ key = "6", mods = "ALT", action = act.ActivateTab(5) },
		{ key = "7", mods = "ALT", action = act.ActivateTab(6) },
		{ key = "8", mods = "ALT", action = act.ActivateTab(7) },
		{ key = "9", mods = "ALT", action = act.ActivateTab(-1) },
		{ key = "t", mods = "SHIFT|CTRL", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "w", mods = "SHIFT|CTRL", action = act.CloseCurrentTab({ confirm = true }) },
		{ key = "PageUp", mods = "SHIFT|CTRL", action = act.MoveTabRelative(-1) },
		{ key = "PageDown", mods = "SHIFT|CTRL", action = act.MoveTabRelative(1) },

		-- =============================================
		-- ペイン分割
		-- =============================================
		{ key = "-", mods = "ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "\\", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

		-- =============================================
		-- ペイン移動 (Alt + h/j/k/l)
		-- =============================================
		{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
		{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
		{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
		{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },

		-- =============================================
		-- ペインリサイズ (Alt+Shift + h/j/k/l)
		-- =============================================
		{ key = "H", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "J", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "K", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "L", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Right", 1 }) },

		-- =============================================
		-- ペインズーム / 閉じる
		-- =============================================
		-- =============================================
		-- Yazi ファイルマネージャ (Alt+E)
		--   左にペイン分割して yazi を起動
		-- =============================================
		{
			key = "e",
			mods = "ALT",
			action = act.SplitPane({
				direction = "Left",
				size = { Percent = 25 },
				command = { args = { "yazi" } },
			}),
		},

		{ key = "f", mods = "ALT", action = act.TogglePaneZoomState },
		{ key = "x", mods = "ALT", action = act.CloseCurrentPane({ confirm = true }) },

		-- =============================================
		-- ペイン均等化 (Alt+0)
		--   全ペインの幅と高さを均等にする
		-- =============================================
		{
			key = "0",
			mods = "ALT",
			action = wezterm.action_callback(function(window, pane)
				local tab = pane:tab()

				local function get_panes()
					return tab:panes_with_info()
				end

				local all = get_panes()
				if #all <= 1 then
					return
				end

				-- === Phase 1: 列（横幅）の均等化 ===
				local function get_columns()
					local panes = get_panes()
					table.sort(panes, function(a, b)
						return a.left < b.left
					end)
					local cols = {}
					for _, p in ipairs(panes) do
						local is_new = true
						for _, c in ipairs(cols) do
							if math.abs(p.left - c.left) <= 1 then
								is_new = false
								break
							end
						end
						if is_new then
							table.insert(cols, p)
						end
					end
					return cols
				end

				local cols = get_columns()
				if #cols > 1 then
					local total_w = 0
					for _, c in ipairs(cols) do
						total_w = total_w + c.width
					end
					local target_w = math.floor(total_w / #cols)

					for i = 1, #cols - 1 do
						cols = get_columns()
						if not cols[i] or not cols[i + 1] then
							break
						end
						local diff = cols[i].width - target_w
						if diff > 1 then
							window:perform_action(act.AdjustPaneSize({ "Left", diff }), cols[i + 1].pane)
						elseif diff < -1 then
							window:perform_action(act.AdjustPaneSize({ "Right", math.abs(diff) }), cols[i].pane)
						end
					end
				end

				-- === Phase 2: 行（高さ）の均等化 ===
				all = get_panes()
				table.sort(all, function(a, b)
					if math.abs(a.left - b.left) <= 1 then
						return a.top < b.top
					end
					return a.left < b.left
				end)

				-- 同じ列のペインをグループ化
				local col_groups = {}
				for _, p in ipairs(all) do
					local found = false
					for _, group in ipairs(col_groups) do
						if math.abs(p.left - group[1].left) <= 1 then
							table.insert(group, p)
							found = true
							break
						end
					end
					if not found then
						col_groups[#col_groups + 1] = { p }
					end
				end

				-- 各列内で高さを均等化
				for _, group in ipairs(col_groups) do
					if #group > 1 then
						table.sort(group, function(a, b)
							return a.top < b.top
						end)
						local total_h = 0
						for _, p in ipairs(group) do
							total_h = total_h + p.height
						end
						local target_h = math.floor(total_h / #group)

						for i = 1, #group - 1 do
							-- 最新のペイン情報を再取得
							local fresh = get_panes()
							local fresh_group = {}
							for _, p in ipairs(fresh) do
								if math.abs(p.left - group[1].left) <= 1 then
									fresh_group[#fresh_group + 1] = p
								end
							end
							table.sort(fresh_group, function(a, b)
								return a.top < b.top
							end)

							if fresh_group[i] and fresh_group[i + 1] then
								local diff = fresh_group[i].height - target_h
								if diff > 1 then
									window:perform_action(
										act.AdjustPaneSize({ "Up", diff }),
										fresh_group[i + 1].pane
									)
								elseif diff < -1 then
									window:perform_action(
										act.AdjustPaneSize({ "Down", math.abs(diff) }),
										fresh_group[i].pane
									)
								end
							end
						end
					end
				end
			end),
		},

		-- =============================================
		-- Claude Code 一発起動 (Alt+C)
		--   右にペイン分割して claude を起動
		-- =============================================
		{
			key = "c",
			mods = "ALT",
			action = act.SplitPane({
				direction = "Right",
				size = { Percent = 50 },
				command = { args = { "claude" } },
			}),
		},

		-- =============================================
		-- 6分割開発レイアウト (Alt+6)
		--   codex×3 | claude×3 を横6列で一括起動
		-- =============================================
		{
			key = "6",
			mods = "ALT",
			action = wezterm.action_callback(function(window, pane)
				-- 新しいタブを作成（デフォルトシェル = PowerShell）
				local cwd = "D:\\Dev\\Investment"
				local _, first_pane, _ = window:mux_window():spawn_tab({ cwd = cwd })

				-- 5回分割して6列を作成
				local panes = { first_pane }
				local current = first_pane
				local sizes = { 5 / 6, 4 / 5, 3 / 4, 2 / 3, 1 / 2 }

				for _, size in ipairs(sizes) do
					local new_pane = current:split({ direction = "Right", size = size, cwd = cwd })
					if new_pane then
						panes[#panes + 1] = new_pane
						current = new_pane
					end
				end

				-- シェルが起動するのを待ってからコマンドを送信
				wezterm.time.call_after(1, function()
					for i, p in ipairs(panes) do
						p:send_text((i <= 3 and "codex" or "claude") .. "\r\n")
					end
				end)
			end),
		},

		-- =============================================
		-- コピー / ペースト
		-- =============================================
		{ key = "c", mods = "SHIFT|CTRL", action = act.CopyTo("Clipboard") },
		{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
		{ key = "v", mods = "SHIFT|CTRL", action = act.PasteFrom("Clipboard") },
		{ key = "Insert", mods = "SHIFT", action = act.PasteFrom("PrimarySelection") },
		{ key = "Insert", mods = "CTRL", action = act.CopyTo("PrimarySelection") },
		{ key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },
		{ key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },

		-- =============================================
		-- 検索 / コピーモード
		-- =============================================
		{ key = "f", mods = "CTRL", action = act.Search("CurrentSelectionOrEmptyString") },
		{ key = "f", mods = "SHIFT|CTRL", action = act.Search("CurrentSelectionOrEmptyString") },
		{ key = "x", mods = "SHIFT|CTRL", action = act.ActivateCopyMode },

		-- =============================================
		-- フォントサイズ
		-- =============================================
		{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
		{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
		{ key = "0", mods = "CTRL", action = act.ResetFontSize },

		-- =============================================
		-- ウィンドウ / その他
		-- =============================================
		{ key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
		{ key = "n", mods = "SHIFT|CTRL", action = act.SpawnWindow },
		{ key = "k", mods = "CTRL", action = act.ClearScrollback("ScrollbackOnly") },
		{ key = "p", mods = "SHIFT|CTRL", action = act.ActivateCommandPalette },
		{ key = "r", mods = "SHIFT|CTRL", action = act.ReloadConfiguration },
		{ key = "l", mods = "SHIFT|CTRL", action = act.ShowDebugOverlay },
		{ key = "m", mods = "SHIFT|CTRL", action = act.Hide },
		{ key = "phys:Space", mods = "SHIFT|CTRL", action = act.QuickSelect },
		{
			key = "u",
			mods = "CTRL",
			action = act.CharSelect({ copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" }),
		},

		-- =============================================
		-- スクロール
		-- =============================================
		{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
		{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
		{ key = "End", mods = "SHIFT|CTRL", action = act.ScrollToBottom },
		{ key = "Home", mods = "SHIFT|CTRL", action = act.ScrollToTop },
	},

	key_tables = {
		copy_mode = {
			-- 移動 (Vim 標準: h/j/k/l)
			{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
			{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
			{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
			{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },

			-- 単語移動
			{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
			{ key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
			{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
			{ key = "Tab", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
			{ key = "Tab", mods = "SHIFT", action = act.CopyMode("MoveBackwardWord") },

			-- 行移動
			{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
			{ key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "^", mods = "SHIFT", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = "$", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = "Enter", mods = "NONE", action = act.CopyMode("MoveToStartOfNextLine") },

			-- ページ / スクロール
			{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
			{ key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
			{ key = "G", mods = "SHIFT", action = act.CopyMode("MoveToScrollbackBottom") },
			{ key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
			{ key = "H", mods = "SHIFT", action = act.CopyMode("MoveToViewportTop") },
			{ key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
			{ key = "M", mods = "SHIFT", action = act.CopyMode("MoveToViewportMiddle") },
			{ key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
			{ key = "L", mods = "SHIFT", action = act.CopyMode("MoveToViewportBottom") },
			{ key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
			{ key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
			{ key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
			{ key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
			{ key = "PageUp", mods = "NONE", action = act.CopyMode("PageUp") },
			{ key = "PageDown", mods = "NONE", action = act.CopyMode("PageDown") },

			-- ジャンプ
			{ key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
			{ key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
			{ key = "F", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
			{ key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
			{ key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
			{ key = "T", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
			{ key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
			{ key = ",", mods = "NONE", action = act.CopyMode("JumpReverse") },

			-- 選択
			{ key = "Space", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
			{ key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
			{ key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
			{ key = "O", mods = "SHIFT", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },

			-- コピー＆終了
			{
				key = "y",
				mods = "NONE",
				action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
			},

			-- 終了 (4通り)
			{ key = "q", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "c", mods = "CTRL", action = act.CopyMode("Close") },
			{ key = "g", mods = "CTRL", action = act.CopyMode("Close") },

			-- 矢印キー（フォールバック）
			{ key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
			{ key = "RightArrow", mods = "NONE", action = act.CopyMode("MoveRight") },
			{ key = "UpArrow", mods = "NONE", action = act.CopyMode("MoveUp") },
			{ key = "DownArrow", mods = "NONE", action = act.CopyMode("MoveDown") },
			{ key = "LeftArrow", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
			{ key = "RightArrow", mods = "ALT", action = act.CopyMode("MoveForwardWord") },
			{ key = "Home", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
			{ key = "End", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
		},

		search_mode = {
			{ key = "Enter", mods = "NONE", action = act.CopyMode("PriorMatch") },
			{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
			{ key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
			{ key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
			{ key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
			{ key = "PageUp", mods = "NONE", action = act.CopyMode("PriorMatchPage") },
			{ key = "PageDown", mods = "NONE", action = act.CopyMode("NextMatchPage") },
			{ key = "UpArrow", mods = "NONE", action = act.CopyMode("PriorMatch") },
			{ key = "DownArrow", mods = "NONE", action = act.CopyMode("NextMatch") },
		},
	},
}
