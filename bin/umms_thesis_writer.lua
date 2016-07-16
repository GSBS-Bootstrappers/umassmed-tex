-- markdown to latex handout custom writer...

-- work in progress 


-- HTML Character escaping
-- TODO: add latex character escaping
local function escape(s, in_attribute)
 return s:gsub("[<>&\\\"']",
   function(x)
     if x == '<' then
       return '&lt;'
     elseif x == '>' then
       return '&gt;'
     elseif x == '&' then
       return '&amp;'
     elseif x == '"' then
       return '&quot;'
     elseif x == "'" then
       return '&#39;'
     elseif x == "\\" then
     	return '&#92;'
     else
       return x
     end
   end)
end

-- Helper function to convert an attributes table into
-- a string that can be put into HTML tags.
local function attributes(attr)
  local attr_table = {}
  for x,y in pairs(attr) do
    if y and y ~= "" then
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

-- this function returns what is ultimately but into the 
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
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.

function Str(s)
	return s:gsub(" ", "~")
	
-- TODO: att a prettyfy function that deals with " and other common symbols
end

function Space()
  return " "
end

function SoftBreak()
  return "\n"
end

function LineBreak()
  return "\\newline"
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


-- TODO: assure that the template has \usepackage[normalem]{ulem}
-- \sout{ text to be stricken out}
function Strikeout(s)
  return '\\sout{' .. s .. '}'
end

-- TODO: latex-ify
function Link(s, src, tit, attr)
  return "<a href='" .. escape(src,true) .. "' title='" ..
         escape(tit,true) .. "'>" .. s .. "</a>"
end

-- TODO: latex-ify
function Image(s, src, tit, attr)
  return "<img src='" .. escape(src,true) .. "' title='" ..
         escape(tit,true) .. "'/>"
end

-- TODO: latex-ify the second part
function Code(s, attr)

	-- inline code overloading: if inline code has an attribute of "abbr" then it is 
	-- treated as an abbreviation instead of code	
	if attr.abbr ~= '' then
--		TODO: add processing of abbreviation
		local buffer = {}
		short = pipe("pandoc -f markdown -t latex", s)
		short = short:gsub("\n","")
		
		long = pipe("pandoc -f markdown -t latex", attr.abbr)
		long = long:gsub("\n", "")
		
		table.insert(buffer, short)
		table.insert(buffer, "\\nomenclature{"..short.."}{"..long.."}")
		return table.concat(buffer,'')
	end
  return "<code" .. attributes(attr) .. ">" .. escape(s) .. "</code>"
  
end

function InlineMath(s)
  return "\\(" .. escape(s) .. "\\)"
end

function DisplayMath(s)
  return "\\[" .. escape(s) .. "\\]"
end


-- TODO: latex-ify
-- function called for footnotes ("lorum ipsum[^1] ...\n [^1]: this is footnote")
function Note(s)
  local num = #notes + 1
  -- insert the back reference right before the final closing tag.
  s = string.gsub(s,
          '(.*)</', '%1 <a href="#fnref' .. num ..  '">&#8617;</a></')
  -- add a list item with the note to the note table.
  table.insert(notes, '<li id="fn' .. num .. '">' .. s .. '</li>')
  -- return the footnote reference, linked to the note.
  return '<a id="fnref' .. num .. '" href="#fn' .. num ..
            '"><sup>' .. num .. '</sup></a>'
end

-- TODO: latex-ify
function Span(s, attr)
  return "<span" .. attributes(attr) .. ">" .. s .. "</span>"
end

-- this takes the string inside the cite object (md: "[@blah]", 
-- for latex s is the result of RawInline() call on the content "\cite{@blah}"...which is 
-- usually "\\cite{@blah}"
-- cs is the list of citation objects 
function Cite(s, cs)
  local ids = {}
  for _,cit in ipairs(cs) do
    table.insert(ids, cit.citationId)
    -- Question: what else is in this 'cit' object?
  end
  return "\\cite{" .. table.concat(ids, ",") .."}"
end

function Plain(s)
  return s
end

function Para(s)
  return "\n" .. s .. "\n"
end

-- lev is an integer, the header level.
function Header(lev, s, attr)
	if lev == 1 then
		return "\\chapter{"..s.."}\\label{"..attr.id.."}"
	elseif lev == 2 then
		return "\\section{"..s.."}\\label{"..attr.id.."}"
	elseif lev == 3 then
		return "\\subsection{"..s.."}\\label{"..attr.id.."}"
	elseif lev == 4 then
		return "\\subsubsection{"..s.."}\\label{"..attr.id.."}"
	elseif lev == 5 then 
		return "\\paragraph{"..s.."}\\label{"..attr.id.."}"
	elseif lev == 6 then
		return "\\subparagraph{"..s.."}\\label{"..attr.id.."}"
	else
		return error
	end
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
	if attr.class ~= "" then
		local code = pipe("highlighting-kate -F latex -f -s " .. attr.class, s) 
		return code
	
	-- if the attribute string contains an id starting with "eq" it is a latex equation 
	-- if an env attribute it set, use that as the enclosing environment, otherwise 
	-- default to "\begin{equation}...\end{equation}"
	elseif string.sub(attr.id,1,2) == "eq" then
		-- TODO: strip off newlines at the beginning and end of string ...somehow
		local env = "equation"
		
		if attr.env ~= "" then
			env = attr.env
		end
		
		local buffer = {}
		table.insert(buffer, "\\begin{" .. env .. "}" .. "\\label{" .. attr.id .. "}")
		table.insert(buffer, s)
		table.insert(buffer, "\\end{" .. env .. "}")
		return table.concat(buffer, "\n")
	end
end

function BulletList(items)
  local buffer = {}
  local count = 0
  for _, item in pairs(items) do
   		table.insert(buffer, "\t\\item " .. item .."\n")
  end
  
	return "\\begin{itemize}\n" .. table.concat(buffer) .. "\\end{itemize}"
end

function OrderedList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "\t\\item" .. item .. "\n")
  end
  return "\\begin{enumerate}\n" .. table.concat(buffer) .. "\n\\end{enumerate}"
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

--	if attr.caption then
--		if attr.caption == "side" then
--		
--		else if attr.caption == "below" then
--		end
--	end
--
--		this is the standard figure option:
--
	local buffer = {}
	table.insert(buffer, "\\begin{figure}[h!]")
	table.insert(buffer, "\\centering")
	table.insert(buffer, "\\label{"..attr.id.."}")
	table.insert(buffer, "\\includegraphics[width=\\textwidth]{"..src.."}")
	table.insert(buffer, "\\caption["..attr.short.."]{"..caption.."}")
	table.insert(buffer, "\\end{figure}")
	return table.concat(buffer,'\n')

--
-- ffbox figure option:

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
-- TODO: add parsing of the caption to look for an attribute string, with a title in it
-- eg: Table: this is the table caption {title="this is the short caption"}
function Table(caption, aligns, widths, headers, rows)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add("\\begin{table}")
  if caption ~= "" then
    add("\\caption{" .. caption .. "}")
  end
  if widths and widths[1] ~= 0 then
    for _, w in pairs(widths) do
      add('<col width="' .. string.format("%d%%", w * 100) .. '" />')
    end
  end
  local header_row = {}
  local empty_header = true
  for i, h in pairs(headers) do
    local align = html_align(aligns[i])
    table.insert(header_row,'<th align="' .. align .. '">' .. h .. '</th>')
    empty_header = empty_header and h == ""
  end
  if empty_header then
    head = ""
  else
    add('<tr class="header">')
    for _,h in pairs(header_row) do
      add(h)
    end
    add('</tr>')
  end
  local class = "even"
  for _, row in pairs(rows) do
    class = (class == "even" and "odd") or "even"
    add('<tr class="' .. class .. '">')
    for i,c in pairs(row) do
      add('<td align="' .. html_align(aligns[i]) .. '">' .. c .. '</td>')
    end
    add('</tr>')
  end
  add('</table')
  return table.concat(buffer,'\n')
end

function Div(s, attr)
  return "<div" .. attributes(attr) .. ">\n" .. s .. "</div>"
end

function RawInline(format, str)
	if format == "tex" then
		return str
	else 
		-- TODO: escape newlines? is this necessary?
		return "% " .. escape(str)
	end
end

function RawBlock(format, str)
	if format == "tex" then
		return str
	else 
		-- TODO: escape newlines? is this necessary?
		return "% " .. escape(str)
	end
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

