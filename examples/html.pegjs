start
    = __ tags: tags? __ {
        return tags;
    }

tags
    = start: tag rest: (__ tag: tag __ { return tag; }) * {
        return rest.unshift(start) && rest;
    }

tag
    = doctype / comment / html / text_tag

doctype
    = '<!DOCTYPE'i __ text: $(!'>' .)* '>' {
        return {type: 'doctype', value: text};
    }
    / '<?xml'i __ (!'?>' .)* '?>' {
        return {type: 'doctype', value: 'xml'};
    }

comment
    = '<!--' __ text: $(!'-->' .)* __ '-->' {
        return {type: 'comment', value: text.split('\n')};
    }

////////////////////
// html tag start //
////////////////////
html
    = '<' name: identifier __ attr: html_attr? __ '>' __ tags: tags? __ '</' close: identifier & {
        return close === name;
    } _ '>' {
        return {type: 'html', name: name, attributes: attr, children: tags || [], selfClosing: false};
    }
    / '<' name: identifier __ attr: html_attr? __ '/>' {
        return {type: 'html', name: name, attributes: attr, selfClosing: true};
    }
    / '<' name: self_closing __ attr: html_attr? __ '>' {
        return {type: 'html', name: name, attributes: attr, selfClosing: true};
    }

self_closing 'Self-closing tags'
    = 'area' / 'base' / 'br' / 'col' / 'command'
    / 'embed' / 'hr' / 'img' / 'input' / 'keygen'
    / 'link' / 'meta' / 'param' / 'source' / 'track' / 'wbr'

bool_attrs
    = 'readonly' / 'disabled' / 'checked' /  'selected' / 'required'
    / 'allowfullscreen' / 'autofocus' / 'autoplay' / 'compact' / 'controls'
    / 'default' / 'formnovalidate' / 'hidden' / 'inert' / 'ismap' / 'itemscope'
    / 'loop' / 'multiple' / 'muted' / 'noresize' / 'noshade' / 'novalidate' / 'nowrap'
    / 'open' / 'reversed' / 'seamless' / 'sortable' / 'truespeed' / 'typemustmatch'

html_attr
    = first: ha rest: (__ h: ha {return h;})* {
        return rest.unshift(first) && rest;
    }

ha 'html attribute'
    = name: bool_attrs __ value: bav {
         return {type: 'boolean_attribute', name: name, value: 'true'}
    }
    / name: identifier __ '=' __ value: hav {
        return {type: 'html_attribute', name: name, value: value}
    }

bav 'boolean attribute value'
    = "='" sqhav "'"
    / '="' dqhav '"'
    / '=""' / "=''"
    / "="
    / ''

hav 'html attribute value'
    = "'" q: sqhav "'" {return q;}
    / '"' q: dqhav '"' {return q;}
    / '""' {return null;} / "''" {return null;}
    / $(![ \'\">/] .)+ {
        return [{type: 'text', value: text()}];
    }

sqhav 'single quoted html attribute value'
    = first: sqhavc rest: sqhavc* {
        return rest.unshift(first) && rest;
    }

sqhavc 'single quoted html attribute value child'
    = text: $(!(tag_start / "'") .)+ {
        return {type: 'text', value: text};
    }

dqhav 'double quoted html attribute value'
    = first: dqhavc rest: dqhavc* {
        return rest.unshift(first) && rest;
    }

dqhavc 'single quoted html attribute value child'
    = text: $(!(tag_start / '"') .)+ {
        return {type: 'text', value: text};
    }
//////////////////
// html tag end //
//////////////////

ai "Attribute identifier"
    = [a-zA-Z$@_] [a-zA-Z0-9$@_.-]* { return text(); }

text_tag
    = text: $(!tag_start .)+ {
        return {type: 'text', value: text.trim().split('\n')}
    }

tag_start
    = '<!--' / '<!' / html_start


html_start
    = ( '</' / '<') & identifier



///////////////////////
// basic rules start //
///////////////////////

_
    = ws*

__ "White spaces"
    = (ws / eol)*

identifier "Identifier"
    = start: [a-zA-Z$@_] rest: $[a-zA-Z0-9$_-]* {
        return start + rest;
    }

text_to_end "Text to end of line"
    = (!eol .)* {
        return text();
    }

eol "End of line"
    = '\n' / '\r' / '\r\n'

ws "Whitespace"
    = '\t' / ' ' / '\v' / '\f'

quoted_string "Quoted string"
    = '"' chars: $dqs* '"' { return chars; }
    / "'" chars: $sqs* "'" { return chars; }

dqs "Double quoted string char"
    = !('"' / '\\' / eol) . { return text(); }
    / '\\' char: ec { return char; }

sqs "Single quoted string char"
    = !("'" / '\\' / eol) . { return text(); }
    / '\\' char: ec { return char; }

ec "Escaped char"
    = '0' ![0-9] { return '\0' }
    / '"' / "'" / '\\'
    / c: [bnfrt] { return '\\' + c; }
    / 'b' { return '\x0B' }

number
    = sign:[+-]? n: number_def {
        return sign === '-' ? -n : n;
    }

number_def
    = '0x'i [0-9a-f]i+ {
        return parseInt(text(), 16);
    }
    / '0' [0-7]+ {
        return parseInt(text(), 8);
    }
    / int? '.' [0-9]+ exponent?  {
        return parseFloat(text())
    }
    / int exponent? {
        return parseFloat(text())
    }

int
    = [1-9] [0-9]* / '0'

exponent
    = 'e'i [+-]? int

/////////////////////
// basic rules end //
/////////////////////