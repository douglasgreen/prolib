%%
% <module> Prolog lexer
%
% See:
% https://www.swi-prolog.org/pldoc/man?section=syntax
%
% @author Douglas S. Green
% @license GPL

:- module(prolog_lexer, [
        tokens/3
    ]
).

%! tokens(Tokens:list)
% Match a list of all tokens including whitespace.
tokens([Token|Tokens]) -->
    token(Token),
    tokens(Tokens).
tokens(Tokens) -->
    [S],
    {char_type(S, space)},
    tokens(Tokens).
tokens([]) -->  [].

%! chars(Cs:codes, Type:atom|compound)
% Match a list of character codes.
chars([C|Cs], Type) -->
    char(C, Type),
    chars(Cs, Type).
chars([], _) --> [].

%! line_chars(Cs:codes)
% Match a list of character codes up to a new line.
line_chars([C|Cs]) -->
	[C],
    {\+ char_type(C, end_of_line)},
	line_chars(Cs).
line_chars([]) --> [].

%! multiline_chars(Cs:codes)
% Match a list of character codes up to a the end of a multi-line comment.
multiline_chars([C|Cs]) -->
    [C],
    {\+ char_code('*', C)},
    multiline_chars(Cs).
multiline_chars([C1,C2|Cs]), [C2] -->
    [C1],
    {char_code('*', C1)},
    [C2],
    {\+ char_code('/', C2)},
    multiline_chars(Cs).
multiline_chars([]) -->
    `*`,
    `/`.

%! octal_digit(D:code)
% Match an octal digit character code.
octal_digit(D) -->
    [D],
    {
        char_type(D, digit(W)),
        W < 8
    }.

%! octal_digits(Ds:codes)
% Match a list of one or more octal digit codes.
octal_digits([D|Ds]) -->
    octal_digit(D),
    octal_digits(Ds).
octal_digits([D]) -->
    octal_digit(D).

%! quoted_chars(Quote:atom, Cs:codes)
% Match a list of character codes up to a the end of a quoted string.
quoted_chars(Quote, [C|Cs]) -->
    [C],
    {
        \+ char_code('\\', C),
        \+ char_code(Quote, C)
    },
    quoted_chars(Quote, Cs).
quoted_chars(Quote, [C1, C2|Cs]) -->
    [C1],
    {char_code('\\', C1)},
    [C2],
    {char_code('x', C2)},
    hex_chars(HexChars),
    [C3],
    {char_code('\\', C3)},
    quoted_chars(Quote, Rest),
    {append(HexChars, [C3|Rest], Cs)}.
quoted_chars(Quote, [C|Cs]) -->
    [C],
    {char_code('\\', C)},
    octal_digits(Ds),
    {writeln(Ds)},
    quoted_chars(Quote, Rest),
    {append(Ds, Rest, Cs)}.
quoted_chars(Quote, [C1, C2, C3, C4, C5, C6|Cs]) -->
    [C1],
    {char_code('\\', C1)},
    [C2],
    {char_code('u', C2)},
    hex_char(C3),
    hex_char(C4),
    hex_char(C5),
    hex_char(C6),
    quoted_chars(Quote, Cs).
quoted_chars(Quote, [C1, C2, C3, C4, C5, C6, C7, C8, C9, C10|Cs]) -->
    [C1],
    {char_code('\\', C1)},
    [C2],
    {char_code('U', C2)},
    hex_char(C3),
    hex_char(C4),
    hex_char(C5),
    hex_char(C6),
    hex_char(C7),
    hex_char(C8),
    hex_char(C9),
    hex_char(C10),
    quoted_chars(Quote, Cs).
quoted_chars(Quote, [C1, C2|Cs]) -->
    [C1],
    {char_code('\\', C1)},
    [C2],
    quoted_chars(Quote, Cs).
quoted_chars(Quote, [C, C|Cs]) -->
    [C],
    {char_code(Quote, C)},
    [C],
    quoted_chars(Quote, Cs).
quoted_chars(Quote, []) -->
    [C],
    {char_code(Quote, C)}.

%! token(Token:compound)
% Match a single token.
token(line_comment(Comment)) -->
    `%`,
	line_chars(Cs),
	`\n`,
    !,
    {atom_chars(Comment, Cs)}.
token(multiline_comment(Comment)) -->
    `/`,
    `*`,
	multiline_chars(Cs),
    !,
    {atom_chars(Comment, Cs)}.
token(back_quoted_string(String)) -->
    [C],
    {char_code('`', C)},
	quoted_chars('`', Cs),
    !,
    {atom_chars(String, Cs)}.
token(double_quoted_string(String)) -->
    [C],
    {char_code('"', C)},
	quoted_chars('"', Cs),
    !,
    {atom_chars(String, Cs)}.
token(single_quoted_string(String)) -->
    [C],
    {char_code('\'', C)},
	quoted_chars('\'', Cs),
    !,
    {atom_chars(String, Cs)}.
token(hex_value(Hex)) -->
    `0x`,
    hex_chars(Cs),
    !,
    {atom_chars(Hex, Cs)}.
token(operator(O, Associativity)) -->
    chars(Ps, punct),
    {
        atom_chars(O, Ps),
        operator(_, Associativity, O)
    },
    !.
token(mark(M)) -->
    char(P, punct),
    !,
    {atom_chars(M, [P])}.
token(lower(W)) -->
    char(C, lower),
    chars(Cs, csym),
    !,
    {atom_chars(W, [C|Cs])}.
token(word(W)) -->
    char(C, csymf),
    chars(Cs, csym),
    !,
    {atom_chars(W, [C|Cs])}.

%! char(C:code)
% Match a single character code.
char(C, Type) -->
    [C],
    {char_type(C, Type)}.

%! hex_char(C:code)
% Match and lowercase a hexadecimal character code.
hex_char(C) -->
    [Upper],
    {
        char_type(Upper, xdigit(_)),
        to_lower(Upper, C)
    }.

%! hex_chars(Cs:codes)
% Match and lowercase a list of one or more hexadecimal character codes.
hex_chars([C|Cs]) -->
    hex_char(C),
    hex_chars(Cs).
hex_chars([C]) -->
    hex_char(C).

%! operator(Predecence:int, Associativity:atom, Name:atom)
% List of operators
operator(1200, 'xfx', '-->').
operator(1200, 'xfx', ':-').
operator(1200, 'fx', ':-').
operator(1200, 'fx', '?-').
operator(1150, 'fx', 'dynamic').
operator(1150, 'fx', 'discontiguous').
operator(1150, 'fx', 'initialization').
operator(1150, 'fx', 'meta_predicate').
operator(1150, 'fx', 'module_transparent').
operator(1150, 'fx', 'multifile').
operator(1150, 'fx', 'public').
operator(1150, 'fx', 'thread_local').
operator(1150, 'fx', 'thread_initialization').
operator(1150, 'fx', 'volatile').
operator(1105, 'xfy', '|').
operator(1100, 'xfy', ';').
operator(1050, 'xfy', '->').
operator(1050, 'xfy', '*->').
operator(1000, 'xfy', ',').
operator(990, 'xfx', ':=').
operator(900, 'fy', '\\+').
operator(700, 'xfx', '<').
operator(700, 'xfx', '=').
operator(700, 'xfx', '=..').
operator(700, 'xfx', '=@=').
operator(700, 'xfx', '\\=@=').
operator(700, 'xfx', '=:=').
operator(700, 'xfx', '=<').
operator(700, 'xfx', '==').
operator(700, 'xfx', '=\\=').
operator(700, 'xfx', '>').
operator(700, 'xfx', '>=').
operator(700, 'xfx', '@<').
operator(700, 'xfx', '@=<').
operator(700, 'xfx', '@>').
operator(700, 'xfx', '@>=').
operator(700, 'xfx', '\\=').
operator(700, 'xfx', '\\==').
operator(700, 'xfx', 'as').
operator(700, 'xfx', 'is').
operator(700, 'xfx', '>:<').
operator(700, 'xfx', ':<').
operator(600, 'xfy', ':').
operator(500, 'yfx', '+').
operator(500, 'yfx', '-').
operator(500, 'yfx', '/\\').
operator(500, 'yfx', '\\/').
operator(500, 'yfx', 'xor').
operator(500, 'fx', '?').
operator(400, 'yfx', '*').
operator(400, 'yfx', '/').
operator(400, 'yfx', '//').
operator(400, 'yfx', 'div').
operator(400, 'yfx', 'rdiv').
operator(400, 'yfx', '<<').
operator(400, 'yfx', '>>').
operator(400, 'yfx', 'mod').
operator(400, 'yfx', 'rem').
operator(200, 'xfx', '**').
operator(200, 'xfy', '^').
operator(200, 'fy', '+').
operator(200, 'fy', '-').
operator(200, 'fy', '\\').
operator(100, 'yfx', '.').
operator(1, 'fx', '$').