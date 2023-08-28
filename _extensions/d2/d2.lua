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

-- Counter for the diagram files
local counter = 0

-- The main filter function
function CodeBlock (cb)
  -- Check if the CodeBlock has the 'd2' class
  if not cb.classes:includes('d2') or cb.text == nil then
    return nil
  end

  counter = counter + 1
  local options = {
    theme = D2Theme.NeutralDefault,
    layout = D2Layout.elk,
    format = D2Format.svg,
    sketch = false,
    pad = 100,
    folder = nil,
    filename = "diagram-" .. counter,
    caption = ''
  }

  if not quarto.doc.is_format("html") then
    -- Set the default folder to ./images since inline images are not supported
    options.folder = "./images"
  end
  if quarto.doc.is_format("latex") then
    -- Set the default format to pdf since svg is not supported
    options.format = D2Format.pdf
  end

  -- Process attributes
  for k, v in pairs(cb.attributes) do
    if k == 'theme' then
      if D2Theme[v] then
        options.theme = D2Theme[v]
      end
    elseif k == 'layout' then
      if D2Layout[v] then
        options.layout = D2Layout[v]
      end
    elseif k == 'format' then
      if D2Format[v] then
        options.format = D2Format[v]
      end
    elseif k == 'sketch' then
      options.sketch = v == 'true'
    elseif k == 'pad' then
      options.pad = tonumber(v)
    else
      options[k] = v
    end
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

  if options.caption ~= '' then
    img.caption = pandoc.Str(options.caption)
  end

  -- Wrap the Image element in a Para element and return it
  return pandoc.Para({img})
end
