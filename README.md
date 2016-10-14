# UMass Med GSBS PhD Thesis template

This is a template and compilation pipeline designed to make writing your thesis just a bit less terrible. and perhaps even a bit enjoyable.

This template uses a number of well-tested open-source tools to take a series of simple text files, your figure image files, and your provided metadata and stitch them together into a great looking pdf file that is ready for printing.

## Getting started

### Prerequisites

There are a few pieces of software that you need in order for the UMMSThesis template to work properly:

- a TeX distribution (MacTeX, TeXLive, or MikTeX, etc.)
- pandoc
- pandoc-citeproc
- highlighting-kate (only if you are using code highlighting)
- python
- computer modern unicode font (http://cm-unicode.sourceforge.net/install.html)

The layout of this demonstration directory is as follows:

```
├── metadata.yaml (author, title, readers, date, chapter file names, etc.)
├── acknowledgements.md
├── dedication.md
├── abstract.md
├── chapter-project-one.md
├── project-two.md
├── introduction.md
├── ...
├── ...
└── figures/
|   ├── western-blot.pdf
|   ├── qpcr.pdf
|   └── gene-pile-up.pdf
└── bin/
    ├── ummsthesis.lua                   (custom writer for pandoc)
    ├── ummsthesis-template.latex        (custom template for pandoc)
    ├── nih-citation-styles.csl          (citation styles format....not decided on this yet)
    └── compile                          (python script that pulls everything together and 
                                          sends it to pandoc, and then saves the pdf properly)
```                                          

There is a ".md" file for each section in the thesis. ".md" means they are markdown files, this is described just below. Additonally your figures files as ".pdf", ".eps", ".jpg" and the like are all together in a figures folder. You can put figures elsewhere, you just need to make sure you use the correct path, when inserting them into a chapter.

The `metadata.yaml` file hold all of the extra information about your particular thesis: title, author, readers, date, etc. It also lists your chapter files. This list of "chapters" is used to insert and compile your chapters in the correct order. 

The `bin` folder has the resources that will be used to compile your thesis. Simply put you should be able to build your thesis by running `$ bin/compile` on a unix machine or `> bin\compile` on a windows machine from the thesis directory. If this is confusing to you, ask for help. A tutorial is forthcoming.

## Writing in markdown

Microsoft Word and word processor like it are considered "What You See is What You Get" (WYSIWYG... pronounced *whizy-whig*) programs, meaning that the program displays to you the user what you should expect to get out of it. More often then not, this works well. However, when it doesn't work, it often fails spectacularly. This is frequently experienced with large or complex documents (of which your thesis is surely one), and often manifests with figures unpredictably jumping moving out of place, incorrect ordering of number elements (figures, chapters, etc), or simply buggy or sluggish behaviour.

In contrast to WYSIWYG, is WYSIWYM (what you see is what you mean). Instead of trying to get the document on the screen to look correct while typing, you provide explicit instructions to the computer in plain text, and once your document is compiled you get out the product you asked for. 

Markdown takes the WYSIWYM concept one step further by providing some simple syntax for explicating formatting text. 

<!--TODO: add a good example of why WYSIWYM is better-->

### standard features

#### inline markup:

- bold font: `**cat**` results in **cat**
- italics: `*cat*` results in *cat*
- verbatim (aka, monospaced, aka code)`` `cat` `` results in `cat`
- small caps: `<span style:"font-valueriant:small-caps">Cat</span>` should result in ![](docs/smallcaps.png)

#### block level markup:

- sections begin with `#` characters, and the number of `#`'s signifies the level:
    - `# chapter title` : results in a chapter title (aka level 1)
    - `## section title`: is a section title within a chapter (aka level 2)
    - you can go all the way to 6 levels:
        - `###### this is a subparagraph header`

- to create new paragraphs just skip a line

```markdown
This is a paragraph with
a few lines in it.

This is a new paragraph.
```

- to add a figure, you first need the name and location of the figure file.
- once you have that you can insert a figure by writing:

```markdown
This is a paragraph with
a few lines in it.

![This is a long caption for the figure. It can have many sentences, and 
some *markup*](figures/western-blot.pdf){#fig:western-blot short="This is a short caption"}

This is a new paragraph.
```
There are a few things going on here.

First, notice how a blank line is present above and below the figure. This is required to designate that the figure should standalone.

The figure starts with an exclamation point `!`, the continues with the figure caption in square brackets `[...]`. This is followed by the location of the figure relative to your main thesis folder. Most standard image formats should work here. Next the curly brackets `{...}` contain two additional pieces of information. The first is a `#` followed by a unique figure identifier. This identifier should be unique to this figure, and can contain hyphens, but not spaces. By convention this identifier should start with "fig:". The unique identifier can be used to as a placeholder for the figure number or the page that the figure is on through the document. Finally a `short="..."` contains a short caption for the figure. This short caption is used to automatically generate the *List of Figures* in the frontmatter during compilation.

### thesis-specific extras (is how is this different makdown different from Pandoc's standard version)

#### figures

standard markdown notation has been appended every so slightly to allow for a short caption, which is used in the "List of Figures". 

To use a short caption, simply add a `short="this is a short caption"` element to the end of the figure, like so:

``` markdown
... this ends a paragraph.

![This is a rather lengthy caption
that can go on for a while](figures/western-blot.jpg){#fig:western-blot short="this is a short caption"}

And then the next paragraph can start here...
```

#### internal references
a work in progress

```
\cite{fig:one}

\citepage{fig:one}

\cite{eq:probability}

\cite{ch:project-one}

```

#### math

In order to allow for your equations to be numbered and labeled properly so that they can be referenced easily elsewhere in your thesis you can include your LaTeX math code inside a code environment labelled with an `#eq:` ID field. This ID, can then be used for referenced later.

    ```{#eq:einstein}
    E = mc^2
    ``` 

And that this id can be used to reference your equation elsewhere:


```latex
As can be seen in Equation \ref{eq:einstein}, 
the energy of something is directly 
proportional to its mass.
```

The above `\ref{..}` segment will automatically get replaced with the correct equation number for the Einstein equation. You can also use `\pageref{...}` command to insert the page of the identified equation:

``` markdown
As can be seen in Equation \ref{eq:einstein} on 
Page \pageref{#eq:einstein}, the energy of 
something is directly proportional to its mass.
```

##### Using other equation environments

**NOTE*: still under development - haven't figured out how to properly address labels yet*

The above examples result in the standard LaTeX `equation` environment. If you need a different environment, like `align` or `gather`, or something else, you can just supply that in an attribute string along with a `.latex-math` like so:

    ``` {.latex-math env=align}
    E &= mc^2    {#eq:einsteins}    \\ 
    E &= h\nu     {#eq:energy-to-light}
    ```
Notice as well that in the above example, the `align` LaTeX environment numbers each equation separately. For this reason you can provide separate ID's via the `{#eq: ...}` syntax.

#### abbreviations (Under development)

*this is not functioning yet, but the proposed syntax is below:*

In order to have an abbreviation show up in the list of abbreviations, when it is first introduced you can mark it as an abbreviation as shown below, and Pandoc and LaTeX will do the rest.

```markdown
`DNA`{abbr="deoxyribonucleic acid"}
```

This will insert the text "DNA" into your document, while also adding "DNA" and "deoxyribonucleic acid" to your list of abbreviations (found after the list of figures and list of tables). You only need to do this once for each abbreviation, generally the first time an abbreviation is used.

You can also include markup within your abbreviated statement, or its expanded form:

```markdown
`*H. sapiens*`{abbr="*Homo sapiens* is the genus and species of humans"}
```

I don't have have an image yet of what this should result in...

### Notes for developers:

Several components of the Pandoc AST have been overloaded and in the umms_thesis_writer.lua custom writer, in order to allow for figure short captions, labelling of math, internal references, and the like. 

- a `short` attribute was added to the figure markup, to allow used to explicitly provide a short caption for the list of figures

- a special class of inline code (`.latex-math`) is processed to allow for users to explicitly label individual equations, and also to use specialty equation environments via the `env` attribute. Any code block with an id value (a `#` value) that begins with `eq:` is automatically processed as latex math. The default LaTeX equation environment is `begin{equation}...\end{equation}`

- abbreviations are provided by overloading the inline code sytnax (`` putting `code` in single backticks``) and then adding a `abbr` attribute, which is looked for in the writer and used to process the string not as code, but instead as an abbreviation.

You can take a look at the source code for `ummsthesis.lua` to learn more. Ideas suggestion and contributions are always welcome. 
