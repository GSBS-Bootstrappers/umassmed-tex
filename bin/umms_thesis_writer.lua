-- markdown to LaTeX custom writer for UMMS GSBS dissertations

-- work in progress for more details see: https://github.com/GSBS-Bootstrappers/umassmed-tex

-- LaTeX Character escaping
-- TODO: add replacement of "..." with ``...''
local function escape(s, in_attribute)
	return s:gsub("[\n&]",
		function(x)
			if x == '\n' then
				return '\n%'
			elseif x == '&' then
				return [[\&]]
			end
		end)
end

-- Helper function to convert an attributes table into
-- a string that can be put into HTML tags.
local function attributes(attr)
  local attr_table = {}
  for x,y in pairs(attr) do
    if y and y ~= nil then
      table.insert(attr_table, ' ' .. x .. '="' .. escape(y,true) .. '"')
    end
  end
  return table.concat(attr_table)
end

-- Run cmd on a temporary file containing inp and return result.
local function pipe(cmd, inp)
  local tmp = os.tmpname()
  local tmph = io.open(tmp, "w")
  tmph:write(inp)
  tmph:close()
  local outh = io.popen(cmd .. " " .. tmp,"r")
  local result = outh:read("*all")
  outh:close()
  os.remove(tmp)
  return result
end

-- Table to store footnotes, so they can be included at the end.
local notes = {}


-- Table to store local includes:
local includes = {}

-- Blocksep is used to separate block elements.
function Blocksep()
  return "\n\n"
end

local testTable = {}

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
-- This gives you a fragment.  You could use the metadata table to
-- fill variables in a custom lua template.  Or, pass `--template=...`
-- to pandoc, and pandoc will add do the template processing as
-- usual.

-- crm-note: this is called once the document is finished...would be a good time to
-- go through and run any doc level processing that needs to happen
-- -- maybe adding before and after package and doc parameters etc...
-- 		- geometry
-- 		- code highlighting
-- 		- caption positioning (below, etc.)
--

-- crm-note: still not sure the distinction between variable and metadata...

-- this function returns what is ultimately put into the document template

function Doc(body, metadata, variables)
	for _,data in pairs(metadata) do
--		print(data)
	end
	testTable = metadata
--	print "running Doc()"
--	for x,y in pairs(metadata) do
--		print(x, y)
--	end
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add(body)
  if #notes > 0 then
    add('<ol class="footnotes">')
    for _,note in pairs(notes) do
      add(note)
    end
    add('</ol>')
  end
  return table.concat(buffer,'\n') .. '\n'
end

-- The functions that follow render corresponding pandoc elements.
-- `s` is always a string, `attr` is always a table of attributes, and
-- `items` is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.

function Str(s)

--	TODO: why is this here:
	return s:gsub(" ", "~")
end

function Space()
  return " "
end

function SoftBreak()
  return "\n"
end

function LineBreak()
  return "\\\\\n "
end

function Emph(s)
  return "\\textit{" .. s .. "}"
end

function Strong(s)
  return "\\textbf{" .. s .. "}"
end

function Subscript(s)
  return "\\textsubscript{" .. s .. "}"
end

function Superscript(s)
  return "\\textsuperscript{" .. s .. "}"
end

function SmallCaps(s)
  return "\\textsc{" .. s .. "}"
end


-- this requires: \usepackage[normalem]{ulem}
function Strikeout(s)
  return '\\sout{' .. s .. '}'
end

function Link(s, src, tit, attr)
	-- if an internal link is found
	-- TODO: figure out this vs cite? and whether to put

	-- if the reference link begins with a "#"
	if string.find(src, "#") == 1 then
		src = string.sub(src, 2)

		return "\\protect\\hyperlink{" .. src .. "}{" .. s .. "}"
	else
		return "\\href{" .. src .. "}{" .. s .."}"
	end
end

-- for now inline images are not allowed, so inline images
-- are simply insertes as captioned images
-- nb: we can add inline image support later if this feature is needed
function Image(s, src, tit, attr)
	buffer = {}
	table.insert(buffer, "\n")
	table.insert(buffer, CaptionedImage(src, tit, s, attr))
	table.insert(buffer, "\n")
	return table.concat(buffer, "")
end

-- inline code (example: here is some`code`)
function Code(s, attr)
  return "\\texttt{" .. s .. "}"
end

function InlineMath(s)
  return "\\(" .. escape(s) .. "\\)"
end

function DisplayMath(s)
  return "\\[" .. escape(s) .. "\\]"
end

-- function called for footnotes ("lorum ipsum[^1] ...\n [^1]: this is footnote")
function Note(s)
  return "\\footnote{" .. s .. "}"
end

-- function handles general spans of text (eg: [this is a span]{.small-caps}
function Span(s, attr)

	-- for small caps
	if attr.class == "small-caps" then
		return "\\textsc{" .. s .. "}"

	-- for an abbreviation
	elseif attr.abbr ~= nil then
		local buffer = {}

		local abbr = pipe("pandoc -f markdown -t latex", attr.abbr)
		abbr = abbr:gsub("\n", "")

		table.insert(buffer, s)
		table.insert(buffer, "")
		table.insert(buffer, "\\nomenclature{"..s.."}{" .. abbr .. "}")
		return table.concat(buffer,'')

	-- for math
	elseif string.sub(attr.id,1,2) == "eq" then

		local env = "equation"

		-- if attr.env ~="align", then stip out `\begin{equation}` and `\end{equation}`
		-- from any contained equations
		-- and rearrange a bit so that each equation is on one line with its label, and then
		-- the line ends with a `\\`
		if attr.env == "align" then
			env = attr.env
			s = string.gsub(s, "\\begin{equation}\n", "")	-- remove \begin{equation} line
			s = string.gsub(s, "\n\\label{", " \\label{") 	-- put label on line above it
			s = string.gsub(s, "}\n\\end", "} \\\\\\end")	-- put `\\` after label
			s = string.gsub(s, "\\end{equation}", "")		-- remove \end{equation}
		end

		local buffer = {}
		table.insert(buffer, "\\begin{" .. env .. "}")
		table.insert(buffer, s)

		-- the align environment itself shouldn't have a a label, so this checks
		-- to make sure the environment is anything but
		if env ~= "align" then
			table.insert(buffer, "\\label{" .. attr.id .. "}")
		end

		table.insert(buffer, "\\end{" .. env .. "}")

		-- removes the final `\\` before returning
		return string.gsub(table.concat(buffer, "\n"), "\\\\\n\\end{", "\n\\end{")

	-- fallthrough
	else
		--return "\\label{span:" .. attr.id .."}{" .. s .. "}"
		return "hello"
	end

end

-- this takes the string inside the cite object (md: "[@blah]",
-- for latex s is the result of RawInline() call on the content "\cite{@blah}"...which is
-- usually "\\cite{@blah}"
-- cs is the list of citation objects
function Cite(s, cs)
  -- local ids = {}
  -- print(s)
  -- print(cs)
  -- for _,cit in ipairs(cs) do
  --   table.insert(ids, cit.citationId)
  --   -- Question: what else is in this 'cit' object?
  -- end
  return s
end

function Plain(s)
  return s
end

function Para(s)
  return "\n" .. s .. "\n"
end

-- lev is an integer, the header level.
function Header(lev, s, attr)
	local buffer = {}
	if lev == 1 then
		table.insert(buffer, "\\chapter{"..s.."}")
	elseif lev == 2 then
		table.insert(buffer, "\\section{"..s.."}")
	elseif lev == 3 then
		table.insert(buffer, "\\subsection{"..s.."}")
	elseif lev == 4 then
		table.insert(buffer, "\\subsubsection{"..s.."}")
	elseif lev == 5 then
		table.insert(buffer, "\\paragraph{"..s.."}")
	elseif lev == 6 then
		table.insert(buffer, "\\subparagraph{"..s.."}")
	else
		return error
	end
	if attr.id ~= nil then
		table.insert(buffer, "\\label{"..attr.id.."}")
	end
	return table.concat(buffer, "")

end

function BlockQuote(s)
  return "\n\\enquote{" .. s .. "}\n"
end

function HorizontalRule()
  return "\\hrulefill"
end


-- if a code block has a class, assume that is the language, and call highlighting-kate
-- to parse and highlight it
-- otherwise, check to see if it's a latex equation in need of a label
function CodeBlock(s, attr)
	local buffer = {}

	if attr.class ~= nil then
		table.insert(buffer, "```" .. attr.class)
	else
		table.insert(buffer, "```")
	end

	table.insert(buffer, s)

	table.insert(buffer, "```")

	local md_code = table.concat(buffer, "\n")

	local code = pipe("pandoc -f markdown -t latex", md_code)

	return code
end

function BulletList(items)
  local buffer = {}
  local count = 0
  for _, item in pairs(items) do
   		table.insert(buffer, "\n\t\\item " .. item)
  end

	return "\\begin{itemize}" .. table.concat(buffer) .. "\n\\end{itemize}"
end

function OrderedList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "\n\t\\item" .. item)
  end
  return "\\begin{enumerate}" .. table.concat(buffer) .. "\n\\end{enumerate}"
end

-- Revisit association list STackValue instance.
function DefinitionList(items)
  local buffer = {}
  for _,item in pairs(items) do
    for k, v in pairs(item) do
      table.insert(buffer,"<dt>" .. k .. "</dt>\n<dd>" ..
                        table.concat(v,"</dd>\n<dd>") .. "</dd>")
    end
  end
  return "<dl>\n" .. table.concat(buffer, "\n") .. "\n</dl>"
end

-- Convert pandoc table alignment to something HTML can use.
-- align is AlignLeft, AlignRight, AlignCenter, or AlignDefault.
function html_align(align)
  if align == 'AlignLeft' then
    return 'left'
  elseif align == 'AlignRight' then
    return 'right'
  elseif align == 'AlignCenter' then
    return 'center'
  else
    return 'left'
  end
end

function CaptionedImage(src, tit, caption, attr)
	local esc_caption = escape(caption)
--	if attr.caption then
--		if attr.caption == "side" then
--
--		elseif attr.caption == "below" then
--		end
--	end
--
--		this is the standard figure option:
--
	local buffer = {}
	table.insert(buffer, "\\afterpage{%")
	table.insert(buffer, "\\begin{figure}[p]%")
	table.insert(buffer, "\\centering%")

	if attr.draft == "true" then
		table.insert(buffer, [[\centering
  \fbox{
    \begin{minipage}[c][0.5\textheight][c]{0.9\textwidth}
      \centering{]]..src..[[}
    \end{minipage}
  }
  ]])
	else
		table.insert(buffer, "\\includegraphics[width=\\textwidth, height=\\textheight, keepaspectratio]{"..src.."}%")
	end

	-- send the short string through pandoc to process markdown syntax to latex
	local raw_short = attr.short
	local latex_short = ""
	if raw_short ~= nil then

		latex_short = pipe("pandoc -f markdown -t latex", raw_short)
		table.insert(buffer, "\\caption["..latex_short.."]{"..esc_caption.."}%")
	else
		table.insert(buffer, "\\caption["..esc_caption.."]{"..esc_caption.."}%")
	end
	if attr.id ~= "" and attr.id ~= nil then
		table.insert(buffer, "\\label{"..attr.id.."}%")
	end

	table.insert(buffer, "\\end{figure}%")
	table.insert(buffer, "\\clearpage")
	table.insert(buffer, "}")  -- close \afterpage{}
	return table.concat(buffer,'\n')


-- ffbox figure option:
--
--	local buffer = {}
--
--	table.insert(buffer, "\\begin{figure}")
--	table.insert(buffer, "\\ffigbox[\\FBwidth]{")
--
--	table.insert(buffer, "\\caption{"..caption.."}")
--	table.insert(buffer, "\\label{"..attr.id.."}".."}{")
--	table.insert(buffer, "\\includegraphics[width="..attr.width.."]{"..src.."}}")
--	table.insert(buffer, "\\end{figure}")
--	return table.concat(buffer,'\n')

end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
-- Caption may also have an attribute string with an id and a short caption:
-- 		:this is a caption {#tab:my-id short="this is a short caption"}
function Table(caption, aligns, widths, headers, rows)
	local table_buffer = {}

	local tab_attr = {}

	-- get_attr() parses a caption string, and tries to find an attribute string
	-- 	example:	('{#tab:my-table short="this is a short caption"}')
	-- then extracts the id and short caption. other attributes or classes are ignored for now.
	local function get_attr(s)
		local new_caption =""
		local my_attr = {}
		local attr_str = ""
		if string.find(s, "[ \n]{.+}") then
			attr_str = string.match(s, '[ \n]{(.+)}')
			new_caption = s:sub(1,s:find('[ \n]{(.+)}'))
		else
			return(nil)
		end
		if attr_str ~= nil then
			my_attr.short = string.match(attr_str, 'short="(.+)"')
			if string.find(attr_str, "#") then
				index_start, _ = string.find(attr_str, "#")
				first_space, _ = string.find(attr_str, " ")
				my_attr.id = string.match(attr_str:sub(index_start, first_space), '#(.+) ')
			else
				my_attr.id = nil
			end
		end

		return new_caption, my_attr
	end

	caption, tab_attr = get_attr(caption)

	local function add(s)
		table.insert(table_buffer, s)
	end

	add("\\afterpage{%")
	 -- \usepackage{booktabs}
	add("\\begin{table}[p]%")
	add("\\centering%")

	-- this is very fragile, trying to deal with some or all of these attributes being potentially
	-- absent TODO: refactor somehow
	if caption ~= nil then
		if tab_attr ~= nil then
			if tab_attr.id ~= nil then
				if tab_attr.short ~= nil then
					add("\\caption[" .. tab_attr.short .. "]{" .. caption .. "}%")

				else
					add("\\caption{" .. caption .. "}%")

				end

				add("\\label{".. tab_attr.id .. "}%")
							end
		else
			add("\\caption{" .. caption .. "}%")
		end
	end
	add("\\scriptsize%")
	-- todo add tabular alignment markers
	align_buffer = {}
	for i,p in pairs(aligns) do
		if aligns[i] == "AlignLeft" then
			table.insert(align_buffer, "l")
		elseif aligns[i] == "AlignRight" then
			table.insert(align_buffer, "r")
		else
			table.insert(align_buffer, "c")
		end
	end
	local aligns = table.concat(align_buffer, "")
	add("\\begin{tabular}{"..aligns.."}%")
	add("\\toprule%")



	-- if widths and widths[1] ~= 0 then
	-- 	for _, w in pairs(widths) do
	-- 		add('<col width="' .. string.format("%d%%", w * 100) .. '" />')
	-- 	end
	-- end

	local header_row = {}
	local empty_header = true

	for i, h in pairs(headers) do
		if i == 1 then
			table.insert(header_row, h)
		else
			table.insert(header_row, "&" .. h)
		end
		-- empty_header = empty_header and h == "&
	end

	if empty_header then
		head = ""
	end
	table.insert(header_row, "\\\\")
	add(table.concat(header_row, ""))

	add('\\midrule%')

	for _, row in pairs(rows) do

		local row_buffer = {}
		for i,c in pairs(row) do

--			add('<td align="' .. html_align(aligns[i]) .. '">' .. c .. '</td>')


			-- if we have the first element in row then dont prepend `&`
			if i == 1 then
				table.insert(row_buffer, c)
			else
				table.insert(row_buffer, "&")
				table.insert(row_buffer, c)
			end
    	end

    	table.insert(row_buffer, '\t\\\\')
    	add(table.concat(row_buffer, ""))
	end

	add('\\bottomrule%')
	add('\\end{tabular}%')
	add('\\end{table}%')
	add("\\clearpage%")
	add("}")
	return table.concat(table_buffer,'\n')
end

function Div(s, attr)
	if attr.id == "refs" then
		local buffer = {}
		table.insert(buffer, "\\chapter{References}")
		table.insert(buffer, "\\setlength{\\parindent}{0pt} % Reset indentation for references...")
		table.insert(buffer, "\\small")
		table.insert(buffer, "\\beginsinglespace")
		table.insert(buffer, "\\raggedright")
		table.insert(buffer, "\\setlength{\\parskip}{0.3cm}")
		table.insert(buffer, s)
		return  table.concat(buffer, "\n")

	elseif string.find(attr.id, "ref") == 1 then
		return "\\hangindent=1.25em \n\\hangafter=1 \n\\hypertarget{" .. attr.id .. "}{}" .. s
	end
end

function RawInline(format, str)
	if format == "tex" or format == "latex" then
		return str
	else
		-- TODO: escape newlines? is this necessary?
		return "% " .. escape(str).."\n"
	end
end

function RawBlock(format, str)
	if format == "tex" or format == "latex" then
		return str
	else
		-- TODO: escape newlines? is this necessary?
		return "% " .. escape(str) .. "\n"
	end
end

function LineBlock(ls)
	return table.concat(ls, '\\ \n')
end

-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
    return function() return "" end
  end
setmetatable(_G, meta)
