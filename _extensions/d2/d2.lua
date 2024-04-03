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
  DarkFlagshipTerrastruct = 201,
  Terminal = 300,
  TerminalGrayscale = 301,
  Origami = 302
}

-- Enum for D2Layout
local D2Layout = {
  dagre = 'dagre',
  elk = 'elk',
  tala = 'tala'
}

-- Enum for D2Format
local D2Format = {
  svg = 'svg',
  png = 'png',
  gif = 'gif',
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

-- Helper for non empty string
function is_nonempty_string(x)
  return x ~= nil and type(x) == "string"
end

-- Counter for the diagram files
local counter = 0

-- Transform and validate options
function setD2Options(options)
  
  -- Check rendering options
  if is_nonempty_string(options.theme) then
    assert(D2Theme[options.theme] ~= nil,
      "Invalid theme: " .. options.theme .. ". Options are: " .. dump(D2Theme))
    options.theme = D2Theme[options.theme]
  end
  if is_nonempty_string(options.layout) then
    assert(D2Layout[string.lower(options.layout)] ~= nil,
      "Invalid layout: " .. options.layout .. ". Options are: " .. dump(D2Layout))
    options.layout = D2Layout[string.lower(options.layout)]
  end
  if is_nonempty_string(options.sketch) then
    assert(options.sketch == "true" or options.sketch == "false",
      "Invalid sketch: " .. options.sketch .. ". Options are: true, false")
    options.sketch = tostring(options.sketch == "true")
  end
  if is_nonempty_string(options.pad) then
    assert(tonumber(options.pad) ~= nil,
      "Invalid pad: " .. options.pad .. ". Must be a number")
  end
  if is_nonempty_string(options.echo) then
    assert(options.echo == "true" or options.echo == "false",
      "Invalid echo: " .. options.echo .. ". Options are: true, false")
    options.echo = options.echo == "true"
  end
  if is_nonempty_string(options.animate_interval) and options.format == D2Format.gif then
    assert(tonumber(options.animate_interval) > 0,
      "Invalid animate_interval: " .. options.animate_interval .. ". Must be greater than 0 for .gif outputs")
  end
  -- Check file extension
  if is_nonempty_string(options.file) then
    local d2path,d2ext = pandoc.path.split_extension(options.file)
    assert(d2ext == ".d2" or d2ext == ".txt",
      "Invalid file: " .. options.file .. ". Must use a 'd2' or 'txt' file extension")
  end
  
  -- Set filename
  if is_nonempty_string(options.filename) then
    -- If filename option uses an extension, remove it
    local fnamepath,fnameext = pandoc.path.split_extension(options.filename)
    if is_nonempty_string(fnameext) then
      options.filename = fnamepath
    end
  else
    -- Set default filename
    options.filename = "diagram-" .. counter
  end
  
  -- Check format and embed_mode options
  if is_nonempty_string(options.format) then
    assert(D2Format[options.format] ~= nil,
      "Invalid format: " .. options.format .. ". Options are: " .. dump(D2Format))
    options.format = D2Format[options.format]
  end
  if is_nonempty_string(options.embed_mode) then
    assert(EmbedMode[options.embed_mode] ~= nil,
      "Invalid embed_mode: " .. options.embed_mode .. ". Options are: " .. dump(EmbedMode))
    options.embed_mode = EmbedMode[options.embed_mode]
  end

  -- Set the default format to pdf since svg is not supported in PDF output
  if options.format == D2Format.svg and quarto.doc.is_format("latex") then
    options.format = D2Format.pdf
  end
  -- Set the default format to svg since pdf is not supported in Typst output
  if options.format == D2Format.pdf and quarto.doc.is_format("typst") then
    options.format = D2Format.svg
  end
  -- Set the default embed_mode to link if the quarto format is not html or the figure format is pdf
  if not quarto.doc.is_format("html") or options.format == D2Format.pdf then
    options.embed_mode = EmbedMode.link
  end

  return options
end

-- Set D2 rendered diagram output path
function setD2outputPath(options, tmpdir)

  -- determine path name of output file
  local outputFilename = options.filename .. "." .. options.format
  local outputFolder = tmpdir
  
  if options.folder ~= nil then
    os.execute("mkdir -p " .. options.folder)
    outputFolder = options.folder
  elseif quarto.project.output_directory ~= nil and options.embed_mode == EmbedMode.link then
    -- Set the default folder to project output directory when embed_mode is link
    outputFolder = quarto.project.output_directory
  end

  -- Set default folder to resource_path
  return pandoc.path.join({outputFolder, outputFilename})
end
  
local function render_graph(globalOptions)
  local CodeBlock = function(cb)
      -- Check if the CodeBlock has the 'd2' class
      if not cb.classes:includes('d2') then
        return nil
      end

      counter = counter + 1

      -- Initialise options table
      local options = copyTable(globalOptions)

      -- Process codeblock attributes
      for k, v in pairs(cb.attributes) do
        options[k] = v
      end
      
      if options.file == nil and cb.text == nil then
        return nil
      end
      
      options = setD2Options(options)

      -- add classes for code folding
      if options.echo then
        cb.classes:insert("sourceCode")
        cb.classes:insert("cell-code")
      end
      
      -- Generate diagram using `d2` CLI utility
      local result = pandoc.system.with_temporary_directory('d2-render', function (tmpdir)
        -- determine path name of input file
        local inputPath = pandoc.path.join({tmpdir, "diagram-" .. counter .. ".d2"})

        -- write graph text to file
        local tmpFile = io.open(inputPath, "w")
        if tmpFile == nil then
          print("Error: Could not open file for writing")
          return nil
        end

        if is_nonempty_string(options.file) then
          local d2File = io.open(options.file)
          assert(d2File ~= nil,
             "Error: Diagram file " .. options.file .. " can't be opened")

          local d2Text = d2File:read('*all')
          cb.text = d2Text
          cb.attributes.filename = pandoc.path.filename(options.file)
        end
        
        tmpFile:write(cb.text)
        tmpFile:close()
          
        -- determine path name of output file
        local outputPath = setD2outputPath(options, tmpdir)

        -- run d2
        os.execute(
          "d2" ..
          " --theme=" .. options.theme ..
          " --layout=" .. options.layout ..
          " --sketch=" .. tostring(options.sketch) .. 
          " --pad=" .. options.pad ..
          " --animate-interval=" .. options.animate_interval ..
          " " .. inputPath .. 
          " " .. outputPath
        )

        local outputFile = io.open(outputPath, "rb")
        local data
        
        if outputFile then
          data = outputFile:read('*all')
          outputFile:close()
        end
        
        -- default for png and gif format
        local mimetype = "image/" .. options.format

        -- replace if svg or pdf format
        if options.format == "svg" then
          mimetype = "image/svg+xml"
        elseif options.format == "pdf" then
          mimetype = "application/pdf"
        end

        if options.embed_mode == EmbedMode.link and options.folder ~= nil then
          return outputPath
        end
        
        os.remove(outputPath)
        
        if options.embed_mode == EmbedMode.link then
          local outputFilename = pandoc.path.filename(outputPath)
          pandoc.mediabag.insert(outputFilename, mimetype, data)
          return outputFilename
        elseif options.embed_mode == EmbedMode.raw then
          return data
        elseif options.embed_mode == EmbedMode.inline then
          assert(options.format ~= "pdf",
             "Error: pdf is an unsupported format for inline `embed_mode`")
          return "data:" .. mimetype .. ";base64," .. quarto.base64.encode(data)
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
        local image = pandoc.Image({
          classes = cb.classes,
          identifier = cb.identifier
        }, result)

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
    -- see https://github.com/quarto-dev/quarto-cli/discussions/8926#discussioncomment-8624950
  local DecoratedCodeBlock = function(node)
    return CodeBlock(node.code_block)
  end
  
  return {
    CodeBlock = CodeBlock,
    DecoratedCodeBlock = DecoratedCodeBlock
  }
end


function Pandoc(doc)

  local options = {
    theme = D2Theme.NeutralDefault,
    layout = D2Layout.dagre,
    format = D2Format.svg,
    sketch = false,
    pad = 100,
    folder = nil,
    file = nil,
    filename = nil,
    caption = '',
    width = nil,
    height = nil,
    echo = false,
    animate_interval = 0,
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
