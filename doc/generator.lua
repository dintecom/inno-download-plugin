function findNotes(n)
	local r = n:gsub("{note%-%d}", function(s)
		local num = s:match("%d")
		return '<sup><a href="#note-' .. num .. '">' .. num .. '</a></sup>'
		end)
	return r
end

outfile = io.stdout

function prn(...)
	args = {...}
	for k, v in pairs(args) do
		outfile:write(findNotes(v))
	end
end

function sortedpairs(t)
	local keys = {}
	local i = 1
	for key, val in pairs(t) do
		keys[i] = key
		i = i + 1
	end
	table.sort(keys)
	return coroutine.wrap(function()
		for i, key in ipairs(keys) do
			coroutine.yield(key, t[key])
		end
	end)
end


function writePage(page, title)
	outfile = io.open((page.title or title) .. ".htm", "w")
	
	prn "<html>\n<head>\n  <title>"
	prn(page.title or title)
	prn "</title>\n  <link rel=\"stylesheet\" type=\"text/css\" href=\"styles.css\"/>\n</head>\n<body>\n"

	prn("<pre class=\"proto\">", page.proto, "</pre>\n")
	prn("<p>", page.desc or "", "</p>\n<dl>\n")
	
	if page.params ~= nil then
		prn("<dt>Parameters:</dt><dd><p><table>\n");
		local i = 0;
		for name, desc in pairs(page.params) do
			if i == 0 then
				prn("  <tr><td><tt>", name, "</tt></td><td class=\"wide\">", desc, "</td></tr>\n")
			else
				prn("  <tr><td><tt>", name, "</tt></td><td>", desc, "</td></tr>\n")
			end
			i = i + 1
		end
		prn("</table></p></dd>\n")
	end
	
	if page.options ~= nil then
		prn("<dt>Options:</dt><dd><p><table>\n");
		prn("  <tr><th>Name</th><th class=\"wide\">Description</th><th>Default</th></tr>\n")
		for name, desc in sortedpairs(page.options) do
			prn("  <tr><td><tt>", name, "</tt></td><td>", desc[1], "</td><td><tt>", desc[2],"</tt></td></tr>\n")
		end
		prn("</table></p></dd>\n")
	end
	
	if page.returns ~= nil then
		prn("<dt>Returns:</dt><dd>\n")
		prn("  <p>", page.returns, "</p>\n")
		prn("</dd>\n")
	end;
	
	if page.example ~= nil then
		prn("<dt>Example:</dt><dd>\n")
		prn("<pre>", page.example, "</pre>\n")
		prn("</dd>\n")
	end;

	if page.notes ~= nil then
		prn("<dt>Notes:</dt><dd><p>\n")
		for i, note in ipairs(page.notes) do
			prn("  <a id=\"note-" .. i .. "\"><sup>" .. i .. "</sup></a>", note, "<br/>\n")
		end
		prn("</p></dd>\n")
	end
	
	if page.seealso ~= nil then
		prn("<dt>See also:</dt><dd><p>\n")
		for i, sa in ipairs(page.seealso) do
			prn([[  <a href="]], _G[sa].title or sa, [[.htm">]], sa, "</a><br/>\n")
		end
		prn("</p></dd>\n")
	end

	prn "</dl>\n</body>\n</html>\n"
	outfile:close()
end

function writePages(ref)
	io.write "Generating reference...\n"
	for i, page in ipairs(ref) do
		io.write("    ", page, "\n")
		writePage(_G[page], page)
	end
end

function buildReference()
	t = {}
	local i = 1
	for k, v in pairs(_G) do
		if k:sub(1, 3) == "idp" then
			t[i] = k
			i = i + 1
		end
	end
	
	table.sort(t)
	return t
end

function writeRefPage(ref)
	io.write "Generating HTML contents...\n"
	outfile = io.open("Reference.htm", "w")
	prn "<html>\n<head>\n  <title>Reference</title>\n  <link rel=\"stylesheet\" type=\"text/css\" href=\"styles.css\"/>\n</head>\n<body>\n"
	for i, page in ipairs(ref) do
		prn('<a href="', (_G[page].title or page), '.htm">', page, "</a><br/>\n")
	end
	prn "</body>\n</html>"
	outfile:close()
end

function writeTOC(ref)
	io.write "Generating HTMLHelp contents...\n"
	outfile = io.open("Contents.hhc", "w")
	prn[[
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<HTML>
<HEAD>
<meta name="GENERATOR" content="Microsoft&reg; HTML Help Workshop 4.1">
<!-- Sitemap 1.0 -->
</HEAD><BODY>
<UL>
	<LI> <OBJECT type="text/sitemap">
		<param name="Name" value="Reference">
		<param name="Local" value="Reference.htm">
		</OBJECT>
	<UL>
]]
	for k, page in ipairs(ref) do
		prn([[
		<LI> <OBJECT type="text/sitemap">
			<param name="Name" value="]], page, [[">
			<param name="Local" value="]], (_G[page].title or page), [[.htm">
			</OBJECT>
]])
	end
	prn[[
	</UL>
</UL>
</BODY></HTML>
]]

	outfile:close()
end

function writeHHP(ref)
	io.write "Generating HTMLHelp project file...\n"
	outfile = io.open("idp.hhp", "w")
	prn[[
[OPTIONS]
Compatibility=1.1 or later
Compiled file=idp.chm
Contents file=Contents.hhc
Default Window=main
Default topic=Reference.htm
Display compile progress=No
Full-text search=Yes
Index file=Index.hhk
Language=0x409 ���������� (���)
Title=Inno Download Plugin

[WINDOWS]
main=,"Contents.hhc","Index.hhk","Reference.htm","Reference.htm",,,,,0x42520,,0x10383e,[88,80,869,673],,,,,,,0


[FILES]
Reference.htm
]]
	for k, page in ipairs(ref) do
		prn((_G[page].title or page), ".htm\n")
	end
	
	outfile:close();
end