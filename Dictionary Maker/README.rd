# dictionaryMaker
App that speeds up the creation of Mac dictionaries.

## NOT COMPLETE TO-DO LIST (as of Thursday, August 18th, 2016)
1. Auto-saving.
2. Undo/Redo.
3. UI/UX Improvements.
4. App Icon creation.
5. Some controls do absolutely nothing right now.
6. Addendums Insert button needs to search the entries for
already existing words, and insert them and that whole thing.
7. Probably should add a DTD checker and some other
"wellformedness" checker.
8. Pronunciation, Search Terms, and Addendums don't work but
they just need to be set up in the "complier". That stuff is
already worked out (see below).
9. Front/Back matter TextView doesn't do anything. Also needs
a ruler and the system provided controls (since it'll just
create HTML from RTF text).



## UPDATES
### (Posted: Thursday, August 18th, 2016)
This is an app that I built to help speed up the process of
creating the XML files for Mac dictionaries. I didn't feel like
writing the XML by hand for a dictionary that needed a huge
amount of entries so I wrote this app really fast and dirty in
Objective-C and why not make it open source.

There's a lot of stuff missing and the UI needs some work, but
when it does what I need it to do I'm pretty much going never
going to touch it again unless I need it. Maybe I might rewrite
it in Swift.

There's a "custom language" that I wrote when writing
definitions so here's the quick language guide rundown.

#### LANGUAGE GUIDE RUNDOWN (SUPER COOL NAME)
Pronunciation, Search Terms, and Addendums TextViews are
simple; every entry is divided by newline characters and the
app creates the XML for you.

Addendums are kinda weird in that they aren't exactly saved to
the XML, becuase Addendums are a quick way to add additional
words. For example I have a root word "kick", but also need the
entries "kicking", "kicks", etc.
The Addendums TextView is where I write the endings and click
the 'Insert' button. The app scans the file to see if the root
plus the root and the endings already exist in the file. If
they don't, those entries are automatically created and they
get added to the root words Search Terms TextView, updating
the XML.

EXAMPLE (NOT EXACT "CODE"):
```
Word: "Kick"
Pronunciation: ""
Search Terms: ""
Addendums: "ing \n s"
Definitions and Examples: ""
```

Definitions and Examples are entirely different. You must
"declare" definitions and examples follow after them. You must
provide **_at least one_** definition (though it may be empty). Examples are **_not_** required.

You declare definitions by using an arabic numeral (1234567890)
of it's placement in an ordered list followed by a period. **It is important that you don't add a space between the period and the definition text becuase it'll add a space at the start of the rendered text, unless that's something you want.**

EXAMPLE; WORD IS KICK
```
1.Strike or propel forcibly with the foot.
2.Succeed in giving up (a habit or addiction).
```

Examples follow definitions by being separated by newlines.

EXAMPLE; WORD IS KICK
```
1.Strike or propel forcibly with the foot.
Police kicked down the door\.
"I really want to kick you right now\."
2.Succeed in giving up (a habit or addiction).
```

The first definition now has two examples. You can have
as many examples as you want, the just must be on their own
lines.

Notice the backslash before the period. The backslash is
how you escape characters. The only characters you need to
escape are:

Characters | Reason 
--- | ---
\ | Used to escape characters.
. | Used in dictionary definitions.
{ | Denotes start italics.
} | Denotes end italics.
[ | Denotes start bold.
] | Denotes end bold.
1 | Used in dictionary definitions.
2 | Used in dictionary definitions.
3 | Used in dictionary definitions.
4 | Used in dictionary definitions.
5 | Used in dictionary definitions.
6 | Used in dictionary definitions.
7 | Used in dictionary definitions.
8 | Used in dictionary definitions.
9 | Used in dictionary definitions.
0 | Used in dictionary definitions.

Of course becuase I'm a noob this leads to weird behavior.
If you, for whatever reason, require 10+ definitions,
chances are the app will crash becuase the "compiler"
(I don't think it counts as a compiler) separates
things into arrays based on arabic numerals. Entry "10."
will create the array ["", "", "."] which also gets
edited but it does cause a crash becuase of empty
strings. Hopefully someone better at this stuff than me
sets this straight (or replaces it with a better
language). It'll also require wierd stuff like if you want
the literal number 10 in the text you need to type "\1\0".
You can't type "\10".

There is a bit of a "syntax checker thing", if the
"compiler" finds an error the text in the TextView turns
red, otherwise it's black.

EXAMPLE
```
1.Chicken
{open but no close
```

makes the text red becuase a closing brace is missing.
It'll go away if you escape the opening brace or add
the closing brace, but those mean different things.

I haven't completely tested it so chances are you'll find
weird logic loopholes that are correct but cause the app
to crash or something.

EXAMPLE SHOWCASING EVERYTHING
```
1.Definition One\.
[Bold], {Italic}, \{\1\0\} ten in braces text\.
\[\1\.\1\] one point one in brackets text\.
2.Definition Two (has no example)\.
3.Definition Three also has no example\.
```

#### IMPORTING FILES
One of the major reasons for this was to import a massive list
of entries that were in a text file instead of typing that list
by hand while worrying about XML. So importing files "works",
though it may not be handled safely. Right now if you want to
import files, stick to TXT files and they must follow the
convention that each entry must be on it's own line.

EXAMPLE
```
Entry1
Entry2
Entry3
Entry4
```

The app will automatically create the correct amount of
entries. I haven't tried RTF files, even though the code
says you can select them.
