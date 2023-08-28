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
-- Enum for Embed mode
local EmbedMode = {
  inline = "inline",
  link = "link",
  raw = "raw"
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

      -- Transform options
      if options.theme ~= nil and type(options.theme) == "string" then
        assert(D2Theme[options.theme] ~= nil, "Invalid theme: " .. options.theme .. ". Options are: " .. dump(D2Theme))
        options.theme = D2Theme[options.theme]
      end
      if options.layout ~= nil and type(options.layout) == "string" then
        assert(D2Layout[options.layout] ~= nil, "Invalid layout: " .. options.layout .. ". Options are: " .. dump(D2Layout))
        options.layout = D2Layout[options.layout]
      end
      if options.format ~= nil and type(options.format) == "string" then
        assert(D2Format[options.format] ~= nil, "Invalid format: " .. options.format .. ". Options are: " .. dump(D2Format))
        options.format = D2Format[options.format]
      end
      if options.embed_mode ~= nil and type(options.embed_mode) == "string" then
        assert(EmbedMode[options.embed_mode] ~= nil, "Invalid embed_mode: " .. options.embed_mode .. ". Options are: " .. dump(EmbedMode))
        options.embed_mode = EmbedMode[options.embed_mode]
      end
      if options.sketch ~= nil and type(options.sketch) == "string" then
        assert(options.sketch == "true" or options.sketch == "false", "Invalid sketch: " .. options.sketch .. ". Options are: true, false")
        options.sketch = options.sketch == "true"
      end
      if options.pad ~= nil and type(options.pad) == "string" then
        assert(tonumber(options.pad) ~= nil, "Invalid pad: " .. options.pad .. ". Must be a number")
        options.pad = tonumber(options.pad)
      end
      if options.echo ~= nil and type(options.echo) == "string" then
        assert(options.echo == "true" or options.echo == "false", "Invalid echo: " .. options.echo .. ". Options are: true, false")
        options.echo = options.echo == "true"
      end

      -- Set default filename
      if options.filename == nil then
        options.filename = "diagram-" .. counter
      end

      -- Set the default format to pdf since svg is not supported in PDF output
      if options.format == D2Format.svg and quarto.doc.is_format("latex") then
        options.format = D2Format.pdf
      end
      -- Set the default embed_mode to link if the quarto format is not html or the figure format is pdf
      if not quarto.doc.is_format("html") or options.format == D2Format.pdf then
        options.embed_mode = EmbedMode.link
      end

      -- Set the default folder to ./images when embed_mode is link
      if options.folder == nil and options.embed_mode == EmbedMode.link then
        options.folder = "./images"
      end

      -- Generate diagram using `d2` CLI utility
      local result = pandoc.system.with_temporary_directory('svg-convert', function (tmpdir)
        -- determine path name of input file
        local inputPath = pandoc.path.join({tmpdir, "temp_" .. counter .. ".txt"})

        -- determine path name of output file
        local outputPath
        if options.folder ~= nil then
          os.execute("mkdir -p " .. options.folder)
          outputPath = options.folder .. "/" .. options.filename .. "." .. options.format
        else
          outputPath = pandoc.path.join({tmpdir, options.filename .. "." .. options.format})
        end

        -- write graph text to file
        local tmpFile = io.open(inputPath, "w")
        if tmpFile == nil then
          print("Error: Could not open file for writing")
          return nil
        end
        tmpFile:write(cb.text)
        tmpFile:close()
        
        -- run d2
        os.execute(
          "d2" ..
          " --theme=" .. options.theme ..
          " --layout=" .. options.layout ..
          " --sketch=" .. tostring(options.sketch) .. 
          " --pad=" .. options.pad ..
          " " .. inputPath .. 
          " " .. outputPath
        )

        if options.embed_mode == EmbedMode.link then
          return outputPath
        else
          local file = io.open(outputPath, "rb")
          local data
          if file then
            data = file:read('*all')
            file:close()
          end
          os.remove(outputPath)

          if options.embed_mode == EmbedMode.raw then
            return data
          elseif options.embed_mode == EmbedMode.inline then
            dump(options)
            
            if options.format == "svg" then
              return "data:image/svg+xml;base64," .. quarto.base64.encode(data)
            elseif options.format == "png" then
              return "data:image/png;base64," .. quarto.base64.encode(data)
            else
              print("Error: Unsupported format")
              return nil
            end
          end
        end
      end)

      -- Read the generated output into a Pandoc Image element
      local output
      if options.embed_mode == EmbedMode.raw then
        output = pandoc.Div({pandoc.RawInline("html", result)})
        
        if options.width ~= nil then
          output.attributes.style = "width: " .. options.width .. ";"
        end
        if options.height ~= nil then
          output.attributes.style = output.attributes.style .. "height: " .. options.height .. ";"
        end
        
      else
        local image = pandoc.Image({}, result)

        -- Set the width and height attributes, if they exist
        if options.width ~= nil then
          image.attributes.width = options.width
        end

        if options.height ~= nil then
          image.attributes.height = options.height
        end

        if options.caption ~= '' then
          image.caption = pandoc.Str(options.caption)
        end

        output = pandoc.Para({image})
      end

      -- Wrap the Image element in a Para element and return it
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
    echo = false,
    embed_mode = "inline"
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