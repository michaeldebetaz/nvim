vim.filetype.add({
	extension = {
		gotmpl = "go.gotmpl",
		tmpl = "go.gotmpl",
	},
	pattern = {
		[".*%.go%.tmpl"] = "go.gotmpl",
	},
})
