# quarto-d2 1.1.0

## NEW FUNCTIONALITY

- When the output type is html and the image format is svg, also setting the `embed_type="raw"` will embed the svg directly into the html document (#1). This is useful enabling interactive content such as hover or links to work.


# quarto-d2 1.0.0

Initial release. Main features:

- Render [D2](https://d2lang.com) diagrams directly within your [Quarto](https://quarto.org) markdown documents. 
- Control the appearance and layout of your diagrams using global settings or code block attributes.
- Tune the width and height of the resulting figures using the "width" and "height" arguments.