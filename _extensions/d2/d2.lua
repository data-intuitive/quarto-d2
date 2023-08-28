-- Enum for D2Theme
local D2Theme = {
    NeutralDefault = 0,
    NeutralGrey = 1,
    FlagshipTerrastruct = 3,
    CoolClassics = 4,
    MixedBerryBlue = 5,
    GrapeSoda = 6,
    Aubergine = 7,
    ColorblindClear = 8,
    VanillaNitroCola = 100,
    OrangeCreamsicle = 101,
    ShirelyTemple = 102,
    EarthTones = 103,
    EvergladeGreen = 104,
    ButteredToast = 105,
    DarkMauve = 200,
    Terminal = 300,
    TerminalGrayscale = 301,
    Origami = 302
}

-- Enum for D2Layout
local D2Layout = {
    dagre = 'dagre',
    elk = 'elk'
}

-- Enum for D2Format
local D2Format = {
    svg = 'svg',
    png = 'png',
    pdf = 'pdf'
}

-- Helper function to copy a table
function copyTable(obj, seen)
  -- Handle non-tables and previously-seen tables.
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end

  -- New table; mark it as seen and copy recursively.
  local s = seen or {}
  local res = {}
  s[obj] = res
  for k, v in pairs(obj) do res[copyTable(k, s)] = copyTable(v, s) end
  return setmetatable(res, getmetatable(obj))
end

-- Helper function for debugging
function dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
     end
     return s .. '} '
  else
     return tostring(o)
  end
end


-- Counter for the diagram files
local counter = 0

local function render_graph(globalOptions)
  local filter = {
    CodeBlock = function(cb)
      -- Check if the CodeBlock has the 'd2' class
      if not cb.classes:includes('d2') or cb.text == nil then
        return nil
      end

      counter = counter + 1

      -- Initialise options table
      local options = copyTable(globalOptions)

      -- Process codeblock attributes
      for k, v in pairs(cb.attributes) do
        options[k] = v
      end

      if options.theme ~= nil and type(options.theme) == "string" then
        options.theme = D2Theme[options.theme]
      end
      if options.layout ~= nil and type(options.layout) == "string" then
        options.layout = D2Layout[options.layout]
      end
      if options.format ~= nil and type(options.format) == "string" then
        options.format = D2Format[options.format]
      end
      if options.sketch ~= nil and type(options.sketch) == "string" then
        options.sketch = options.sketch == "true"
      end
      if options.pad ~= nil and type(options.pad) == "string" then
        options.pad = tonumber(options.pad)
      end
      if options.echo ~= nil and type(options.echo) == "string" then
        options.echo = options.echo == "true"
      end

      -- Set default filename
      if options.filename == nil then
        options.filename = "diagram-" .. counter
      end

        -- Set the default folder to ./images since inline images are not supported
      if not quarto.doc.is_format("html") then
        options.folder = "./images"
      end
      -- Set the default format to pdf since svg is not supported
      if quarto.doc.is_format("latex") then
        options.format = D2Format.pdf
      end

      -- Determine output path
      local outputPath
      if options.folder ~= nil then
        os.execute("mkdir -p " .. options.folder)
        outputPath = options.folder .. "/" .. options.filename .. "." .. options.format
      else
        local prefix = os.tmpname()
        outputPath = prefix .. "_" .. counter .. "." .. options.format
      end

      -- Generate diagram using `d2` CLI utility
      local result = pandoc.system.with_temporary_directory('svg-convert', function (tmpdir)     
        local tempPath = pandoc.path.join({tmpdir, "temp_" .. counter .. ".txt"})
        
        local tmpFile = io.open(tempPath, "w")
        if tmpFile == nil then
          print("Error: Could not open file for writing")
          return nil
        end
        tmpFile:write(cb.text)
        tmpFile:close()
        
        os.execute(
          "d2" ..
          " --theme=" .. options.theme ..
          " --layout=" .. options.layout ..
          " --sketch=" .. tostring(options.sketch) .. 
          " --pad=" .. options.pad ..
          " " .. tempPath .. 
          " " .. outputPath
        )

        return outputPath
      end)

      -- Read the generated output if need be
      if options.folder == nil then
        local file = io.open(result, "rb")
        if file then
          data = file:read('*all')
          file:close()
        end
        os.remove(result)  -- Remove the output file since it'll be inline
        
        if options.format == "svg" then
          imageData = "data:image/svg+xml;base64," .. quarto.base64.encode(data)
        elseif options.format == "pdf" then
          imageData = result
        else
          imageData = "data:image/png;base64," .. quarto.base64.encode(data)
        end
      else
        imageData = result
      end

      -- Read the generated output into a Pandoc Image element
      local img = pandoc.Image({}, imageData)


      -- Set the width and height attributes, if they exist
      if options.width ~= nil then
        img.attributes.width = options.width
      end

      if options.height ~= nil then
        img.attributes.height = options.height
      end

      if options.caption ~= '' then
        img.caption = pandoc.Str(options.caption)
      end

      -- Wrap the Image element in a Para element and return it
      local output = pandoc.Para({img})
      if options.echo then
        local codeBlock = pandoc.CodeBlock(cb.text, cb.attr)
        output = pandoc.Div({codeBlock, output})
      end
      return output
    end
  }
  return filter
end


function Pandoc(doc)

  local options = {
    theme = D2Theme.NeutralDefault,
    layout = D2Layout.dagre,
    format = D2Format.svg,
    sketch = false,
    pad = 100,
    folder = nil,
    filename = nil,
    caption = '',
    width = nil,
    height = nil,
    echo = false
  }

  -- Process global attributes
  local globalOptions = doc.meta["d2"]
  if type(globalOptions) == "table" then
    for k, v in pairs(globalOptions) do
      options[k] = pandoc.utils.stringify(v)
    end
  end

  return doc:walk(render_graph(options))
end