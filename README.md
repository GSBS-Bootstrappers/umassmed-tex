# UMass Med GSBS PhD Thesis template

This is a template and compilation pipeline designed to make writing your thesis just a bit more enjoyable, and perhaps not a terrible ordeal. 

This template uses a number of well-tested open-source tools to take a series of simple text files, your figure image files, and your provided metadata and stitch them together into a great looking pdf that is ready for printing.

## Getting started

### Prerequisites

There are a few pieces of software that you need in order for the UMMSThesis template to work properly:

- a TeX distributions 
- pandoc
- pandoc-citeproc
- highlighting-kate (available on homebrew)
- python

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
└── resources/
    ├── ummsthesis.lua                   (custom writer for pandoc)
    ├── ummsthesis-template.latex        (custom template for pandoc)
    ├── nih-citation-styles.csl          (citation styles format....not decided on this yet)
    └── compile                          (python script that pulls everything together and 
                                          sends it to pandoc, and then saves the pdf properly)
```                                          
                                          

## Writing in markdown

Microsft Word and word processor like it are considered "What You See is What You Get" (WYSIWYG... pronounced *whizy-whig*), meaning the program displays to you the user what you should expect to get our of it. More often then not, this is works well. But when working with large or complex documents, otften problems arise, with figures getting moved out of place, or numbering of elements, or simply just crashing.

In contrast to WYSIWYG, is WYSIWYM (what you see is what you mean). Instead of trying to get the document on the screen to look write while typing, you provide explicit instructions to the computer, and once your document is compiled you get our the product you asked for. 

Markdown takes the WYSIWYM concept one step further by providing some simple syntax for expliciting formatting text. 

<!--TODO: add a good example of why WYSIWYM is better-->

### standard features

#### inline markup:

- bold font: `**cat**` results in **cat**
- italics: `*cat*` results in *cat*
- verbatim (aka, monospaced, aka code)`` `cat` `` results in `cat`
- small caps: `<span style:"font-variant:small-caps">Cat</span>` results in <span style="font-variant:small-caps;">Cat</span>

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
some *markup*](figures/western-blot.pdf){short="This is a short caption"}

This is a new paragraph.
```
Notice how a blank line is present above and below the figure. This is required to designate that the figure should standalone.

The long caption will be prepended by the "Figure" and the correct figure number automatically, and then added to the page just below the figure. 

The short caption, will be used in the *List of Figures* in the frontmatter of the thesis. 

### thesis-specific extras (how is this different from Pandoc's standard markdown)

#### figures

standard markdown notation has been appended every so slightly to allow for a short caption, which will be displayed in the "List of Figures".

To use a short caption, simply add a `short="this is a short caption"` element to the end of the figure, like so:

``` markdown
... this ends a paragraph.

![This is a rather lengthy caption
that can go on for a while](figures/western-blot.jpg){#fig:western-blot short="this is a short caption"}

And then the next paragraph can start here...
```

#### internal references


```
\cite{fig:one}

\citepage{fig:one}

\cite{eq:probability}

\cite{ch:project-one}

```

#### math

In order to allow for your equations to be numbered and labeled properly so that they can be referenced easily elsewhere in your thesis you can include your LaTeX math code inside a code environment labelled with an id field (which starts with an `#eq:`). This id, can then be used for references later.

~~~markdown
```{#eq:einstein}
E = mc^2
``` 
~~~

And that this id can be used to reference your equation:


~~~
As can be seen in Equation \ref{eq:einstein}, 
the energy of something is directly 
proportional to its mass.
~~~

The above `\ref{..}` segment will automatically get replaced with the correct equation number for the Einstein equation. You can also use `\pageref{...}` command to insert the page of the identified equation:

~~~ markdown
As can be seen in Equation \ref{eq:einstein} on 
Page \pageref{#eq:einstein}, the energy of 
something is directly proportional to its mass.
~~~

##### Using other equation environments

**NOTE*: still under development - haven't figured out how to properly address labels yet*

The above examples result in the standard LaTeX `equation` environment. If you need a different environment, like `align` or `gather`, or something else, you can just supply that in an attribute string like so:

~~~ markdown
``` {.latex-math env=align}
E &= mc^2  	\label(eq:einsteins} \\ 
E &= h\nu 	\label{eq:energy-to-light}
```
~~~

#### abbreviations (Under development)

*this is not functioning yet, but the proposed syntax is below:*

In order to have an abbreviation show up in the list of abbreviations, when it is first introduced you can mark it as an abbreviation, and Pandoc and LaTeX will do the rest.

~~~ markdown
```
`DNA`{abbr="deoxyribonucleic acid"}
```
~~~

This will insert the text "DNA" into your documnet, while also adding "DNA" and "deoxyribonucleic acid" to your list of abbreviations (found after the list of figures and list of tables). You only need to do this once for each abbreviation, generally the first time an abbreviation is used.


### Notes for developers:

Several components of the Pandoc AST were overloaded and specially processed in the ummsthesis.lua custom writer, in order to allow for figure short captions, labelling of math, internal references, and the like. 

- a `short` attribute was added to the figure markup, to allow used to explicitly provide a short caption for the list of figures

- a special class of inline code (`.latex-math`) is processed to allow for users to explicitly label individual equations, and also to use specialty equation environments via the `env` attribute. Any code block with an id value (a `#` value) that begins with `eq:` is automatically processed as latex math. The default equation environment is `begin{equation}...\end{equation}`

- abbreviations are provided by overloading the inline code sytnac (`` putting `code` in single backticks``) and then adding a `abbr` attribute, which is looked for in the writer and used to process the string not as code, but instead as an abbreviation.

You can take a look at the source code for `ummsthesis.lua` to learn more. Ideas suggestion and contributions are always welcome. 
