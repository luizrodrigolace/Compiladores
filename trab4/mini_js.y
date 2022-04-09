%{
#include <iostream>
#include <string>
#include <stdio.h>

#include <stdlib.h>
#include <vector>
#include <map>

using namespace std;

struct Atributos {
  vector<string> c;
};

#define YYSTYPE Atributos

int yylex();
int yyparse();
void yyerror(const char *);

vector<string> concatena( vector<string> a, vector<string> b );
vector<string> operator+( vector<string> a, vector<string> b );
vector<string> operator+( vector<string> a, string b );

string geraLabel( string prefixo );

vector<string> resolveEnderecos( vector<string> entrada );

void print( vector<string> codigo );
void variavelDeclarada(Atributos att_variavel);
void variavelNaoDeclarada(Atributos att_variavel);

string trim( char *texto );
vector<string> split( string codigo );

vector<string> novo;
map<string, int> variaveis;

vector<string> funcoes;
int linha = 1;
int qtd_parametros = 0;

%}

%token ASM FUNCTION RETURN NUM ID STRING LET IF IGUAL ELSE MENOR_IGUAL MAIOR_IGUAL NUM_NEG WHILE FOR

%right '='
%left '<' '>' IGUAL MAIOR_IGUAL MENOR_IGUAL
%left '+' '-'
%left '*' '/' '%'
%right '^'

%start S

%%

S : CMDS { print( resolveEnderecos($1.c + "." + funcoes) ); }
  ;

CMDS : CMD CMDS   { $$.c = $1.c + $2.c; }
     | CMD        { $$.c = $1.c; }
     ;
 
CMD : E ';'                            { $$.c = $1.c + "^"; }
    | E ASM ';' 	                     { $$.c = $1.c + $2.c + "^"; }
    | LET DECLARACOES ';'              { $$.c = $2.c; }
    | RETURN E ';'                     { $$.c = novo + $2.c + "'&retorno'" + "@" + "~"; }
    | IF '(' E ')' BLOCO ELSE BLOCO    { string elseif = geraLabel("else_if");
                                         string continueif = geraLabel("continue_if");
                                         $$.c = $3.c + "!" + elseif + "?" + $5.c + continueif + "#" + (":" + elseif) + $7.c + (":" + continueif); }
    | IF '(' E ')' BLOCO               { string endif = geraLabel("end_if");
                                         $$.c = $3.c + "!" + endif + "?" + $5.c + (":" + endif); }
    | WHILE '(' E ')' BLOCO            { string testwhile = geraLabel("test_while");
                                         string endwhile = geraLabel("end_while");
                                         $$.c = novo + (":" + testwhile) + $3.c + "!" + endwhile + "?" + $5.c + testwhile + "#" + (":" + endwhile); }
    | FOR '(' CMD  E ';' E  ')' BLOCO  { string testfor = geraLabel("test_for");
                                         string endfor = geraLabel("end_for");
                                         $$.c = $3.c + (":" + testfor) + $4.c + "!" + endfor + "?" + $8.c + $6.c + "^" + testfor + "#" + (":" + endfor); }
    | FUNCTION ID '(' ')' BLOCO      { string begin = geraLabel($2.c[0]);
                                                
                                                vector<string> retorno = novo + "undefined" + "@" + "'&retorno'" + "@" + "~";
                                                funcoes = funcoes + (":" + begin) + $5.c + retorno;
                                                vector<string> endereco_declaracao = $2.c + "&" + $2.c + "{}" + "=" + "'&funcao'" + begin + "[=]" + "^";
                                                $$.c = endereco_declaracao; }
    | FUNCTION ID '(' DECL_PARAMETROS ')' BLOCO      { string begin = geraLabel($2.c[0]);
                                                vector<string> parametros;
                                                for (int i = 0; i < $4.c.size(); i++) {
                                                  parametros = parametros + $4.c[i] + "&" + $4.c[i] + "arguments" + "@" + to_string(i) + "[@]" + "=" + "^";
                                                }
                                                vector<string> retorno = novo + "undefined" + "@" + "'&retorno'" + "@" + "~";
                                                funcoes = funcoes + (":" + begin) + parametros + $6.c + retorno;
                                                vector<string> endereco_declaracao = $2.c + "&" + $2.c + "{}" + "=" + "'&funcao'" + begin + "[=]" + "^";
                                                $$.c = endereco_declaracao; }
    ;

BLOCO : '{' CMDS '}'            { $$.c = $2.c; }
      | CMD                     { $$.c = $1.c; }
      | BLOCOVAZIO              { $$.c = novo; }
      ;

BLOCOVAZIO : '{' '}' ;

DECL_PARAMETROS : ID ',' DECL_PARAMETROS { $$.c = $1.c + $3.c; }
           | ID                { $$.c = $1.c; }
           ;

PARAMETROS : E ',' PARAMETROS { $$.c = $1.c + $3.c; qtd_parametros++; }
           | E                { $$.c = $1.c; qtd_parametros++; }
           ;

DECLARACOES: DECLARACAO ',' DECLARACOES  { $$.c = $1.c + $3.c; }
           | DECLARACAO
           ;

DECLARACAO : LVALUE '=' E   { $$.c = $1.c + "&" + $1.c + $3.c + "=" + "^";
                              variaveis[$1.c[0]] = linha;
                            }
           | LVALUE         { $$.c = $1.c + "&";
                              variaveis[$1.c[0]] = linha;
                            }
           ;

LVALUE : ID   { $$.c = $1.c; }
       ;

LVALUEPROP : LVALUE PROPS    { $$.c = $1.c + "@" + $2.c; }
           ;

PROPS : '[' E ']' PROPS           { $$.c = $2.c + "[@]" + $4.c; }
      | '.' ID PROPS              { $$.c = $2.c + "[@]" + $3.c; }
      | '[' E ']'                 { $$.c = $2.c; }
      | '.' ID                    { $$.c = $2.c; }
      ;

CHAMA_FUNCAO: ID '(' PARAMETROS ')' { $$.c = $3.c + to_string(qtd_parametros) + $1.c + "@" + "$"; qtd_parametros = 0;}
            | ID '(' ')'            { $$.c = novo + "0" + $1.c + "@" + "$";}
            | LVALUEPROP '(' PARAMETROS ')' { $$.c = $3.c + to_string(qtd_parametros) + $1.c + "[@]" + "$"; qtd_parametros = 0;}
            | LVALUEPROP '(' ')'            { $$.c = novo + "0" + $1.c + "[@]" + "$";}
            ;

E : E '<' E             { $$.c = $1.c + $3.c + "<"; }
  | E '>' E             { $$.c = $1.c + $3.c + ">"; }
  | E MAIOR_IGUAL E     { $$.c = $1.c + $3.c + ">="; }
  | E MENOR_IGUAL E     { $$.c = $1.c + $3.c + "<="; }
  | E IGUAL E           { $$.c = $1.c + $3.c + "=="; }
  | E '^' E             { $$.c = $1.c + $3.c + "^"; }
  | E '*' E             { $$.c = $1.c + $3.c + "*"; }
  | E '+' E             { $$.c = $1.c + $3.c + "+"; }
  | E '-' E             { $$.c = $1.c + $3.c + "-"; }
  | E '/' E             { $$.c = $1.c + $3.c + "/"; }
  | E '%' E             { $$.c = $1.c + $3.c + "%"; }
  | LVALUEPROP '=' E    { $$.c = $1.c + $3.c + "[=]"; }
  | LVALUE '=' E        { $$.c = $1.c + $3.c + "="; }
  | LVALUEPROP          { $$.c = $1.c + "[@]"; }
  | LVALUE              { $$.c = $1.c + "@"; }
  | F
  ;

F : NUM             { $$.c = $1.c; }
  | STRING          { $$.c = $1.c; }
  | BLOCOVAZIO      { $$.c = novo + "{}"; }
  | '['']'          { $$.c = novo + "[]"; }
  | '(' E ')'       { $$ = $2; }
  | NUM_NEG         { $$.c = novo + "0" + $1.c + "-"; }
  | CHAMA_FUNCAO    { $$ = $1; }
  ;

%%

#include "lex.yy.c"

vector<string> concatena( vector<string> a, vector<string> b ) {
  for(int i = 0; i < b.size(); i++ )
    a.push_back( b[i] );
  return a;
}

vector<string> operator+( vector<string> a, vector<string> b ) {
  return concatena( a, b );
}

vector<string> operator+( vector<string> a, string b ) {
  a.push_back( b );
  return a;
}

string geraLabel( string prefixo ) {
  static int n = 0;
  return prefixo + "_" + to_string( ++n ) + ":";
}

vector<string> resolveEnderecos( vector<string> entrada ) {
  map<string,int> label;
  vector<string> saida;
  for( int i = 0; i < entrada.size(); i++ ) 
    if( entrada[i][0] == ':' ) 
        label[entrada[i].substr(1)] = saida.size();
    else
      saida.push_back( entrada[i] );
  
  for( int i = 0; i < saida.size(); i++ ) 
    if( label.count( saida[i] ) > 0 )
        saida[i] = to_string(label[saida[i]]);
    
  return saida;
}

void variavelDeclarada(Atributos att_variavel) {
    string variavel = att_variavel.c[0];

    if( variaveis.count( variavel ) == 1 ) {
        cout << "Erro: a variável '" << variavel << "' já foi declarada na linha " << variaveis[variavel] << "." << endl;
        exit(1);
    }
}

void variavelNaoDeclarada(Atributos att_variavel) {
    string variavel = att_variavel.c[0];

    if (variaveis.count( variavel ) == 0) {
        cout << "Erro: a variável '" << variavel << "' não foi declarada." << endl;
        exit(1);
    }
}

void print( vector<string> codigo ) {
    for (int i = 0; i < codigo.size(); i++) {
        cout << codigo[i] << " ";
    }
}



void yyerror( const char* st ) {
   puts( st ); 
   printf( "ERRO DE COMPILAÇÃO (linha %d) Proximo a: %s\n", linha, yytext );
   exit( 1 );
}




string trim( char *txt ) {
  string a = txt;
  return a.erase(a.size() - 1, a.size());
}

vector<string> split( string code ) {
  vector<std::string> tokens;
  size_t start = 0, end = 0;

  while ((end = code.find(" ", start)) != string::npos)
  {
      tokens.push_back(code.substr(start, end - start));
      start = end + 1;
  }

  tokens.push_back(code.substr(start));
  return tokens;
}

int main( int argc, char* argv[] ) {
  yyparse();
  
  return 0;
}