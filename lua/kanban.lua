local M = {}

M.ops = require("kanban.ops").get_ops({})
M.fn = require("kanban.fn")
M.theme = require("kanban.theme")
M.active = false

function M.setup(options)
	M.ops = require("kanban.ops").get_ops(options)
	require("kanban.create_command").create_command(M)
	M.keymap = require("kanban.keymap").keymap
	vim.api.nvim_create_user_command("KanbanOpen", M.kanban_open, {})
	M.theme.init(M)
	require("cmp").setup.filetype({ "kanban" }, {
		completion = {
			autocomplete = true,
		},
	})
end

function M.kanban_open()
	if M.active then
		vim.api.nvim_err_writeln("kanban is already active!!")
		return
	else
		M.active = true
	end
	M.items = {}
	M.items.kwindow = {}
	M.markdown = require("kanban.markdown")
	for i in pairs(M.ops.kanban_md_path) do
		print("[" .. i .. "] " .. M.ops.kanban_md_path[i])
	end
	local md_path_index = tonumber(vim.fn.input("Select -> "))
	if not M.ops.kanban_md_path[md_path_index] then
		md_path_index = 1
	end
	M.kanban_md_path = M.ops.kanban_md_path[md_path_index]
	local md = M.markdown.reader.read(M, M.kanban_md_path)
	if #md.lists == 0 then
		vim.api.nvim_err_writeln("No task data ..")
		M.active = false
		return
	end

	-- create window panel
	M.fn.kwindow.add(M)

	-- create list panel
	M.items.lists = {}
	for i in pairs(md.lists) do
		M.fn.lists.add(M, md.lists[i].title, false)
	end

	-- create task panel
	local animation = M.ops.animation
	M.ops.animation = false
	local max_task_show_int = M.fn.tasks.utils.get_max_task_show_int(M)
	for i in pairs(md.lists) do
		local list = md.lists[i]
		if #list.tasks == 0 then
			M.fn.tasks.add(M, i, nil, "bottom", true)
		else
			for j in pairs(list.tasks) do
				local task = list.tasks[j]
				local open_bool = j <= max_task_show_int
				M.fn.tasks.add(M, i, task, "bottom", open_bool)
			end
		end
	end
	if #M.items.lists > 0 then
		vim.fn.win_gotoid(M.items.lists[1].tasks[1].win_id)
	end
	M.ops.animation = animation
end

return M
