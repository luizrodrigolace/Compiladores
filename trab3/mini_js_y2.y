%{
#include <map>
#include <stdio.h>
#include <iostream>
#include <string>

#include <stdlib.h>
#include <vector>


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

void imprime ( vector<string> codigo );
void variavelDeclarada ( Atributos att_variavel );
void variavelNaoDeclarada (Atributos att_variavel);

vector<string> novo;

map<string, int> variaveis;

int linha = 1;

%}

%token NUM ID STRING LET IF IGUAL ELSE MENOR_IGUAL MAIOR_IGUAL NUM_NEG WHILE FOR

%nonassoc '[' ']' '.'

%right '='
%left '<' '>' IGUAL MAIOR_IGUAL MENOR_IGUAL
%left '+' '-'
%left '*' '/' '%'
%right '^'

%nonassoc IF ELSE

%start S

%%

S : CMDS { imprime( resolveEnderecos($1.c) ); }
  ;


CMDS : CMD CMDS   { $$.c = $1.c + $2.c; }
     | CMD        { $$.c = $1.c; }
     ;


CMD : ATRIB ';'                          { $$.c = $1.c + "^"; }
    | LET DECLARACOES ';'                { $$.c = $2.c; }
    | IF '(' R ')' BLOCO ELSE BLOCO      { string elseif = geraLabel("else_if");
                                           string continueif = geraLabel("continue_if");
                                           $$.c = $3.c + "!" + elseif + "?" + $5.c + continueif + "#" + (":" + elseif) + $7.c + (":" + continueif); }
    | IF '(' R ')' BLOCO                 { string endif = geraLabel("end_if");
                                           $$.c = $3.c + "!" + endif + "?" + $5.c + (":" + endif); }
    | WHILE '(' R ')' BLOCO              { string testwhile = geraLabel("test_while");
                                           string endwhile = geraLabel("end_while");
                                           $$.c = novo + (":" + testwhile) + $3.c + "!" + endwhile + "?" + $5.c + testwhile + "#" + (":" + endwhile); }
    | FOR '(' CMD  R ';' R  ')' BLOCO    { string testfor = geraLabel("test_for");
                                           string endfor = geraLabel("end_for");
                                           $$.c = $3.c + (":" + testfor) + $4.c + "!" + endfor + "?" + $8.c + $6.c + "^" + testfor + "#" + (":" + endfor); }
    ;


BLOCOVAZIO : '{' '}' ;

BLOCO : '{' CMDS '}'                     { $$.c = $2.c; }
      | CMD                              { $$.c = $1.c; }
      | BLOCOVAZIO                       { $$.c = novo + ""; }
      ;


DECLARACOES: DECLARACAO ',' DECLARACOES  { $$.c = $1.c + $3.c; }

           | DECLARACAO
           ;


DECLARACAO : LVALUE '=' R                { $$.c = $1.c + "&" + $1.c + $3.c + "=" + "^";
                                           variavelDeclarada($1);
                                          variaveis[$1.c[0]] = linha;
                                         }
           | LVALUE                      { $$.c = $1.c + "&";
                                           variavelDeclarada($1);
                                           variaveis[$1.c[0]] = linha;
                                         }
           ;

LVALUE : ID                              { $$.c = $1.c; }
       ;


ATRIB : R                                { $$.c = $1.c; }
      ;


LVALUEPROP : LVALUE PROPS                { $$.c = $1.c + "@" + $2.c; }
           ;


PROPS : '[' R ']' PROPS                  { $$.c = $2.c + "[@]" + $4.c; }
      | '.' ID PROPS                     { $$.c = $2.c + "[@]" + $3.c; }
      | '[' R ']'                        { $$.c = $2.c; }
      | '.' ID                           { $$.c = $2.c; }
      ;


R : E '<' E                              { $$.c = $1.c + $3.c + "<"; }
  | E '>' E                              { $$.c = $1.c + $3.c + ">"; }
  | E MAIOR_IGUAL E                      { $$.c = $1.c + $3.c + ">="; }
  | E MENOR_IGUAL E                      { $$.c = $1.c + $3.c + "<="; }
  | E IGUAL E                            { $$.c = $1.c + $3.c + "=="; }
  | E                                    { $$ = $1; }
  ;


E : E '^' E                              { $$.c = $1.c + $3.c + "^"; }
  | E '*' E                              { $$.c = $1.c + $3.c + "*"; }
  | E '+' E                              { $$.c = $1.c + $3.c + "+"; }
  | E '-' E                              { $$.c = $1.c + $3.c + "-"; }
  | E '/' E                              { $$.c = $1.c + $3.c + "/"; }
  | E '%' E                              { $$.c = $1.c + $3.c + "%"; }
  | LVALUEPROP '=' ATRIB                 { $$.c = $1.c + $3.c + "[=]"; }
  | LVALUE '=' ATRIB                     { $$.c = $1.c + $3.c + "=";variavelNaoDeclarada($1);}
  | LVALUEPROP                           { $$.c = $1.c + "[@]"; }
  | LVALUE                               { $$.c = $1.c + "@";variavelNaoDeclarada($1);}
  | F
  ;


F : NUM                                  { $$.c = $1.c; }

  | STRING                               { $$.c = $1.c; }

  | BLOCOVAZIO                           { $$.c = novo + "{}"; }

  | '['']'                               { $$.c = novo + "[]"; }

  | '(' E ')'                            { $$ = $2; }

  | NUM_NEG                              { $$.c = novo + "0" + $1.c + "-"; }
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

void imprime( vector<string> codigo ) {
    for (int i = 0; i < codigo.size(); i++) {
        //cout << i << " - " << codigo[i] << " " << endl;
        cout << codigo[i] << " ";
    }
    cout << "." << endl;
}

void yyerror( const char* st ) {
   puts( st );
   printf( "Proximo a: %s\n", yytext );
   
   exit( 1 );
}

int main( int argc, char* argv[] ) {
  yyparse();

  return 0;
}