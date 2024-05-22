local telescope_ghissue = require("telescope_ghissue")

return require("telescope").register_extension({
	exports = {
		show_issue = telescope_ghissue.showissue,
	},
})
