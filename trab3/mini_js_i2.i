DIGITO	[0-9]
LETRA	[A-Za-z_$]

WS          [ \t]
NUM         {DIGITO}+("."{DIGITO}+)?([Ee]("+"|"-")?{DIGITO}+)?
NUM_NEG     ("-"){DIGITO}+("."{DIGITO}+)?([Ee]("+"|"-")?{DIGITO}+)?
ID          {LETRA}({LETRA}|{DIGITO})*
STRING      ([\"]([^\"\n]*(\"\")*(\\\")*)*[\"])|([\']([^\'\n]*(\'\')*(\\\')*)*[\'])

%%

"\n"        { linha++; }
{WS}        { }
{NUM}       { yylval.c = novo + yytext; return NUM; }
{NUM_NEG}   { yylval.c = novo + (yytext + 1); return NUM_NEG; }

"if"        { yylval.c = novo + "if"; return IF; }   
"else"      { yylval.c = novo + "else"; return ELSE; }
"while"     { yylval.c = novo + "while"; return WHILE; }
"for"       { yylval.c = novo + "for"; return FOR; }
"let"	    { yylval.c = novo + "let"; return LET; }

"=="        { yylval.c = novo + "=="; return IGUAL; }
"<="        { yylval.c = novo + "<="; return MENOR_IGUAL; }
">="        { yylval.c = novo + "<="; return MAIOR_IGUAL; }

{STRING}    { yylval.c = novo + yytext; return STRING; }
{ID}        { yylval.c = novo + yytext; return ID; }
.           { yylval.c = novo + yytext; return *yytext; }


"function"   { yylval.c = novo + "function"; return FUNCTION; }
"return"     { yylval.c = novo + "return"; return RETURN; }
"asm{".*"}"  {  yylval.c = split( trim( yytext + 4 ) ); return ASM; }

%%