DIGITO  [0-9]
LETRA   [A-Za-z_]


NUM     {DIGITO}+("."{DIGITO}+)?
ID      {LETRA}({LETRA}|{DIGITO})*
STR     (\"([^\"\n]|(\\\")|\"\")+\")|(\'([^\'\n]|(\\\')|\'\')+\')

%%

"\t"        { coluna += 4; }
"\n"        { linha++; coluna = 1; }
" "         { coluna++; }
{NUM}       { return token(tokenNUM); }


"if"        { return token(tokenIF); }
"else"      { return token(tokenELSE); }
"while"     { return token(tokenWHILE); }
"for"       { return token(tokenFOR); }
"let"	    { return token(tokenLET); }
"function"  { return token(tokenFUNCTION); }
"return"    { return token(tokenRETURN); }


"+"         { return token(tokenMAIS); }
"-"         { return token(tokenMENOS); }
"*"         { return token(tokenMUL); }
"/"         { return token(tokenDIV); }
"%"         { return token(tokenMODULO); }

"<"         { return token(TK_MENOR); }
">"         { return token(TK_MAIOR); }

"=>"        { return token(TK_ARROW); }
"<="        { return token(TK_MEIG); }
">="        { return token(TK_MAIG); }
"=="        { return token(TK_IGUAL); }

"!="        { return token(TK_DIFF); }
"&&"        { return token(TK_AND); }
"||"        { return token(TK_OR); }

"{"         { return token(TK_OPENBRACE); }
"}"         { return token(TK_CLOSEBRACE); }
"[]"        { return token(TK_ARRAY); }
"{}"        { return token(TK_OBJECT); }



"asm{".*"}" {  string lexema = trim(yytext + 3, "{}" );
               yylval.c = tokeniza(lexema);
               coluna += strlen(yytext); 
               return TK_ASM;}

{STR}       { return token(TK_STR); }
{ID}        { return token(TK_ID); }
.           { return token(*yytext); }

%%