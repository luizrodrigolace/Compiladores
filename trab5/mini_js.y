%{

#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include <map>

#include <string>
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

void print( vector<string> code );

void variavelDeclarada(Atributos att_variavel);

void variavelNaoDeclarada(Atributos att_variavel);

string trim( char *texto );

vector<string> split( string code );

vector<string> novo;
map<string, int> variaveis;

vector<string> funcoes;
int linha = 1;
int nparametros = 0;
vector<vector<string>> elementos;
vector<vector<string>> parametros;

%}

%token TRUE FALSE SETA ABRE_PAR_SETA ASM FUNCTION RETURN NUM ID STRING LET IF IGUAL ELSE MENOR_IGUAL MAIOR_IGUAL WHILE FOR FUNCTION_ANON

%right '='
%right SETA
%nonassoc '<' '>' IGUAL MAIOR_IGUAL MENOR_IGUAL
%left '+' '-'
%left '*' '/' '%'

%start S

%%

S : CMDS { print( resolveEnderecos($1.c + "." + funcoes) ); }
  ;

CMDS : CMD CMDS   { $$.c = $1.c + $2.c; }
     | CMD        { $$.c = $1.c; }
     ;
 
CMD : E ';'                            { $$.c = $1.c + "^"; }
    | ID ASM ';' 	                   { $$.c = $1.c + "@" + $2.c + "^"; }
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
    | FUNCTION ID '(' ')' BLOCO                 { string begin = geraLabel($2.c[0]);
                                                  vector<string> retorno = novo + "undefined" + "@" + "'&retorno'" + "@" + "~";
                                                  funcoes = funcoes + (":" + begin) + $5.c + retorno;
                                                  vector<string> endereco_declaracao = $2.c + "&" + $2.c + "{}" + "=" + "'&funcao'" + begin + "[=]" + "^";
                                                  $$.c = endereco_declaracao; nparametros = 0; }
    | FUNCTION ID '(' DECL_PARAMETROS ')' BLOCO { string begin = geraLabel($2.c[0]);
                                                  vector<string> retorno = novo + "undefined" + "@" + "'&retorno'" + "@" + "~";
                                                  funcoes = funcoes + (":" + begin) + $4.c + $6.c + retorno;
                                                  $$.c = $2.c + "&" + $2.c + "{}" + "=" + "'&funcao'" + begin + "[=]" + "^"; /*cout << "terminou a função" << endl;*/ }
    ;

BLOCO : '{' CMDS '}'            { $$.c = $2.c; /*cout << "comandos para bloco" << endl;*/ }
      | CMD                     { $$.c = $1.c; }
      | BLOCOVAZIO              { $$.c = novo; }
      ;

BLOCOVAZIO : '{' '}' ;

DECL_PARAMETROS : DECL_PARAMETRO  { vector<string> decl_parametros;
                                    int tamanho = parametros.size() / 2;
                                    /*cout << "resolvendo os parametros" << endl;*/
                                    for (int i = 0; i < tamanho; i++) {
                                      vector<string> valor_padrao = parametros.back(); parametros.pop_back();
                                      vector<string> id = parametros.back(); parametros.pop_back();

                                      if (valor_padrao.size() == 0) {
                                        decl_parametros = decl_parametros + id + "&" + id + "arguments" + "@" + to_string(i) + "[@]" + "=" + "^";
                                      } else {
                                        string elseif = geraLabel("else_if");
                                        string continueif = geraLabel("continue_if");

                                        vector<string> padrao = novo + "arguments" + "@" + to_string(i) + "[@]" + "undefined" + "@" + "==" + "!" + elseif + "?" + id + "&" + id + valor_padrao + "=" + "^" ;
                                        vector<string> nao_padrao = novo + continueif + "#" + (":" + elseif) + id + "&" + id + "arguments" + "@" + to_string(i) + "[@]" + "=" + "^" + (":" + continueif);
                                        decl_parametros = decl_parametros + padrao + nao_padrao;
                                      }
                                    }
                                    parametros.clear(); 
                                    $$.c = decl_parametros; }
                ;

DECL_PARAMETRO : ID '=' E ',' DECL_PARAMETRO    { parametros.push_back($1.c);
                                                  parametros.push_back($3.c);
                                                  $$.c = $1.c + $3.c + $5.c; /*cout << "chegou nos parametros" << endl;*/}
                | ID ',' DECL_PARAMETRO         { parametros.push_back($1.c);
                                                  parametros.push_back(novo);
                                                  $$.c = $1.c + $3.c; /*cout << "chegou nos parametros" << endl;*/}
                | ID '=' E                      { parametros.push_back($1.c);
                                                  parametros.push_back($3.c);
                                                  $$.c = $1.c + $3.c; /*cout << "chegou nos parametros" << endl;*/}
                | ID                            { parametros.push_back($1.c);
                                                  parametros.push_back(novo);
                                                  $$.c = $1.c; /*cout << "chegou nos parametros" << endl;*/}
                ;

PARAMETROS : E ',' PARAMETROS { $$.c = $1.c + $3.c; nparametros++; }
           | E                { $$.c = $1.c; nparametros++; }
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

CHAMA_FUNCAO: ID '(' PARAMETROS ')' { $$.c = $3.c + to_string(nparametros) + $1.c + "@" + "$"; nparametros = 0;}
            | ID '(' ')'            { $$.c = novo + "0" + $1.c + "@" + "$";}
            | LVALUEPROP '(' PARAMETROS ')' { $$.c = $3.c + to_string(nparametros) + $1.c + "[@]" + "$"; nparametros = 0;}
            | LVALUEPROP '(' ')'            { $$.c = novo + "0" + $1.c + "[@]" + "$";}
            ;

E : E '<' E             { $$.c = $1.c + $3.c + "<"; }
  | E '>' E             { $$.c = $1.c + $3.c + ">"; }
  | E MAIOR_IGUAL E     { $$.c = $1.c + $3.c + ">="; }
  | E MENOR_IGUAL E     { $$.c = $1.c + $3.c + "<="; }
  | E IGUAL E           { $$.c = $1.c + $3.c + "=="; }
  | E '*' E             { $$.c = $1.c + $3.c + "*"; }
  | E '+' E             { $$.c = $1.c + $3.c + "+"; }
  | E '-' E             { $$.c = $1.c + $3.c + "-"; }
  | E '/' E             { $$.c = $1.c + $3.c + "/"; }
  | E '%' E             { $$.c = $1.c + $3.c + "%"; }
  | LVALUEPROP '=' E    { $$.c = $1.c + $3.c + "[=]"; }
  | LVALUE '=' E        { $$.c = $1.c + $3.c + "="; }
  | LVALUEPROP          { $$.c = $1.c + "[@]"; }
  | LVALUE              { $$.c = $1.c + "@"; }
  | OBJ                 { $$ = $1; }
  | F
  ;

F : NUM             { $$.c = $1.c; }
  | STRING          { $$.c = $1.c; }
  | TRUE            { $$.c = $1.c; }
  | FALSE           { $$.c = $1.c; }
  | '(' E ')'       { $$ = $2; }
  /* | NUM_NEG         { $$.c = novo + "0" + $1.c + "-"; } */
  | CHAMA_FUNCAO    { $$ = $1; }
  | ARRAY           { $$ = $1; }
  | FUNC_ANON       { $$ = $1; }
  | FUNCAO_SETA     { $$ = $1; }
  ;

FUNCAO_SETA : HEAD SETA E     { string begin = geraLabel("anonima");
                                vector<string> retorno = novo + $3.c + "'&retorno'" + "@" + "~";
                                funcoes = funcoes + (":" + begin) + $1.c + retorno;
                                $$.c = novo + "{}" + "'&funcao'" + begin + "[<=]"; /*cout << "terminou a função seta" << endl;*/}
            /* | HEAD SETA BLOCO { string begin = geraLabel("anonima");
                                vector<string> retorno = novo + "undefined" + "@" + "'&retorno'" + "@" + "~";
                                funcoes = funcoes + (":" + begin) + $1.c + $3.c + retorno;
                                $$.c = novo + "{}" + "'&funcao'" + begin + "[<=]"; } */
            ;

HEAD : ID                                 { $$.c = $1.c + "&" + $1.c + "arguments" + "@" + "0" + "[@]" + "=" + "^"; }
     | '(' ')'                            { $$.c = novo; }
     | ABRE_PAR_SETA DECL_PARAMETROS  ')' { $$.c = $2.c; }
     ;

FUNC_ANON : FUNCTION_ANON ')' BLOCO                   { string begin = geraLabel("anonima");
                                                        vector<string> retorno = novo + "undefined" + "@" + "'&retorno'" + "@" + "~";
                                                        funcoes = funcoes + (":" + begin) + $3.c + retorno;
                                                        $$.c = novo + "{}" + "'&funcao'" + begin + "[<=]"; }
          | FUNCTION_ANON DECL_PARAMETROS ')' BLOCO   { string begin = geraLabel("anonima");
                                                        
                                                        vector<string> retorno = novo + "undefined" + "@" + "'&retorno'" + "@" + "~";
                                                        funcoes = funcoes + (":" + begin) + $2.c + $4.c + retorno;
                                                        $$.c = novo + "{}" + "'&funcao'" + begin + "[<=]"; }
          ;

ARRAY: '[' ELEMENTOS ']' { $$.c = novo + "[]";
                           int tamanho = elementos.size();
                           for (int i = 0; i < tamanho; i++) {
                             $$.c = $$.c + to_string(i) + elementos.back() + "[<=]";
                             elementos.pop_back();
                           }
                         }
     | '['']'            { $$.c = novo + "[]"; }
     ;

ELEMENTOS: E ',' ELEMENTOS  { elementos.push_back($1.c); }
         | E                { elementos.push_back($1.c); }
         ;

OBJ : '{' ATRIBUTOS '}' { $$.c = novo + "{}" + $2.c; }
    | BLOCOVAZIO        { $$.c = novo + "{}"; }
    ;

ATRIBUTOS : ID ':' E ',' ATRIBUTOS  { $$.c = $1.c + $3.c + "[<=]" + $5.c; }
          | ID ':' E                { $$.c = $1.c + $3.c + "[<=]"; }
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


void variavelNaoDeclarada(Atributos att_variavel) {
    string variavel = att_variavel.c[0];

    if (variaveis.count( variavel ) == 0) {
        cout << "Erro: a variável '" << variavel << "' não foi declarada." << endl;
        exit(1);
    }
}

void variavelDeclarada(Atributos att_variavel) {
    string variavel = att_variavel.c[0];

    if( variaveis.count( variavel ) == 1 ) {
        cout << "Erro: a variável '" << variavel << "' já foi declarada na linha " << variaveis[variavel] << "." << endl;
        exit(1);
    }
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

void print( vector<string> code ) {
    for (int i = 0; i < code.size(); i++) {
        cout << code[i] << " ";
    }
}

string trim( char *texto ) {
  string a = texto;
  return a.erase(a.size() - 1, a.size());
}

void yyerror( const char* st ) {
   puts( st ); 
   printf( "ERRO NA COMPILAÇÃO (linha %d) Proximo a: %s\n", linha, yytext );
   exit( 1 );
}

int main( int argc, char* argv[] ) {
  yyparse();
  
  return 0;
}