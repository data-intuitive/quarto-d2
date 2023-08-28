# D2 Extension For Quarto

The [Quarto](https://quarto.org) extension that allows you to generate [D2](https://d2lang.com) diagrams directly within your markdown documents. You can specify various attributes to control the appearance and layout of the diagrams. 

This extension draws inspiration from [`ram02z/d2-filter`](https://github.com/ram02z/d2-filter).

## Installing

Before you can use this extension, you'll need to make sure you've installed the d2 CLI utility.

Next, use the `quarto add` command to install the extension:

```bash
quarto add data-intuitive/quarto-d2
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Usage

### Basic Use

To use the d2 filter, add the d2 class to your code blocks and write your diagram code inside the code block. Here is a basic example:

````markdown
```{.d2}
x -> y
```
````

```{.d2}
x -> y
```

### Adding Attributes

You can specify additional attributes to control the appearance and layout of the diagram.

- `theme`: Specifies the theme of the diagram. Default is `NeutralDefault`.
- `layout`: Specifies the layout algorithm to use. Default is `dagre`.
- `format`: Specifies the format of the output image. Default is `svg`.
- `sketch`: Whether to use a "sketch" style for the diagram. Default is `false`.
- `pad`: Amount of padding around the diagram. Default is `100`.

Here's an example that uses multiple attributes:

````markdown
```{.d2 theme="CoolClassics" layout="elk" pad=20}
x -> y
```
````

```{.d2 theme="CoolClassics" layout="elk" pad=20}
x -> y
```


### Using Captions

You can also add captions to your diagrams by using the `caption` attribute.

````markdown
```{.d2 pad=20 caption="This is a caption"}
x -> y
```
````

```{.d2 pad=20 caption="This is a caption"}
x -> y
```


### Setting Output Folder and File Name

You can specify a folder where the generated diagram will be saved using the `folder` attribute. The `filename` attribute allows you to set a custom name for the output file.

````markdown
```{.d2 folder="./images" filename="my_diagram"}
x -> y
```
````

```{.d2 folder="./images" filename="my_diagram"}
x -> y
```

Note: If the `folder` attribute is not provided, the image will be embedded inline in the document.


## Example

Here is the source code for a [minimal example](example.qmd):


````markdown
---
title: "D2 Example"
filters:
  - d2
---

This is one code block

```{.d2 pad=20 caption="This is a caption"}
x -> y
```
````

With this setup, the `d2` filter will process any code blocks with the `.d2` class, applying the attributes you specify.

That's it! Now you know how to use the `d2` filter to generate diagrams in your quarto documents.
