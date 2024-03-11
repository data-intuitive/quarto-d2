# quarto-d2 (development)

- Make SVG as the default diagram format when using the [Typst output format](https://quarto.org/docs/output-formats/typst.html).
- Add support for reading d2 diagrams from external files using `file` parameter. Block text is ignored if file parameter is supplied.
- Add support for alternate code block syntax without curly braces.
- Insert rendered diagrams into the Pandoc mediabag when `embed_type="link"`
- Refactor to add helper functions `setPreD2RenderOptions`, `setD2RenderFormat`, and `is_nonempty_string`

# quarto-d2 1.1.0

## NEW FUNCTIONALITY

- When the output type is html and the image format is svg, also setting the `embed_type="raw"` will embed the svg directly into the html document (#1). This is useful enabling interactive content such as hover or links to work.


# quarto-d2 1.0.0

Initial release. Main features:

- Render [D2](https://d2lang.com) diagrams directly within your [Quarto](https://quarto.org) markdown documents. 
- Control the appearance and layout of your diagrams using global settings or code block attributes.
- Tune the width and height of the resulting figures using the "width" and "height" arguments.