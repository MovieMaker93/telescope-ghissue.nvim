local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local utils = require("telescope.previewers.utils")
local plenary = require("plenary")
local log = require("plenary.log").new({
	plugin = "telescope_devfortunato",
	level = "info",
})

---@class TIModule
---@field config TIConfig
---@field setup fun(TIConfig): TIModule
---
---
---@class TIConfig
local M = {}

-- local reqUrl = "/repos/nvim-telescope/telescope.nvim/issues?labels=good%20first%20issue"
-- M.testing = function()
-- 	return vim.system(
-- 		{ "gh", "api", reqUrl },
-- 		{ text = true },
-- 		vim.schedule_wrap(function(out)
-- 			-- print(out.stdout)
-- 			local decoded = vim.json.decode(out.stdout, {
-- 				luanil = {
-- 					object = true,
-- 					array = true,
-- 				},
-- 			})
-- 			-- for _, issue in pairs(decoded) do
-- 			-- 	print(vim.inspect(issue.html_url))
-- 			-- end
-- 			return decoded
-- 		end)
-- 	)
-- end

M._plenary = function(args)
	local job_opts = {
		command = "curl",
		args = { "localhost:3000/", args },
		-- args = vim.tbl_flatten({ "api", reqUrl }),
	}
	log.info("Running job", job_opts)

	local job = plenary.job:new(job_opts):sync()
	return job
end

-- Define a custom entry maker
M.make_entry = function(entry)
	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 25 },
			{ remaining = true },
		},
	})

	local function make_display()
		return displayer({
			{ entry.title, "TelescopeResultsIdentifier" },
			{ entry.url, "TelescopeResultsComment" },
		})
	end

	return {
		value = entry,
		display = make_display,
		ordinal = entry.title,
	}
end

M.showissue = function(opts)
	local tbl = M._plenary({ "issues" })
	local decoded = vim.fn.json_decode(tbl)
	for _, value in ipairs(decoded) do
		table.insert(tbl, { url = value.html_url, title = value.title })
	end

	pickers
		.new(opts, {
			prompt_title = "Issue github List",
			finder = finders.new_table({
				results = tbl,
				entry_maker = M.make_entry,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr)
				-- Define actions on selected item
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					log.info("Selection:", selection)
					actions.close(prompt_bufnr)
					vim.cmd("exec \"!open '" .. selection.value.url .. "'\"")
					-- vim.fn.system({ "xdg-open", selection.value.url })
				end)
				return true
			end,
			previewer = previewers.new_termopen_previewer({
				get_command = function(entry)
					return { "echo", entry.value.title }
				end,
			}),
		})
		:find()
end

---@param config TIConfig
M.setup = function(config)
	M.config = config
end

return M
