//Luiz Rodrigo Lacé Rodrigues
//DRE:118049873
//Gerador de Forma Intermediária

%{

#include <stdio.h>
#include <string>
#include <map>
#include <iostream>
#include <stdlib.h>

using namespace std;

int token;

//Declaração das funções
void P();
void S();
void A();
void E();
void E_linha();
void T();
void T_linha();
void F();
void erro();
void casa( int );

//tokens identificáveis
enum { tk_int = 256, tk_id, tk_num, tk_print, tk_string, tk_func, tk_endl};

string lexema;

map<int,string> nome_tokens = {
  { tk_id, "Nome de Identificador" },
  { tk_num, "Número" },
  { tk_print, "Funcao Print" },
  { tk_string, "String" },
  { tk_func, "Função" },
  { tk_endl, "Ponto e Virgula" }
};

%}

WS	[ \n\t]
DIGITO	[0-9]
LETRA	[A-Za-z_]

NUM	{DIGITO}+("."{DIGITO}+)?
ID	{LETRA}({LETRA}|{DIGITO})*

ENDL [;]

STRING ["]({ID}|{NUM}|[ !,.?:])*["]

%%

{WS}  		{ }
{NUM} 		{ return tk_num; }
{ENDL}    { return tk_endl; }
"print"   { return tk_print; }
{ID}/[(]  { return tk_func; }
{STRING}  { return tk_string; }
{ID}		  { return tk_id; }

.		{ return yytext[0]; }

%%

int next_token() {
  int yylex_temp = yylex();
  lexema = yytext;
  return yylex_temp;
}

string nome_token( int token ) {
  if( nome_tokens.find( token ) != nome_tokens.end() )
    return nome_tokens[token];
  else {
    string r;
    
    r = token;
    return r;
  }
}

void print(string x){
  cout << x + " ";
}


void S() {
  switch(token) {
    case tk_id:
      A();
      S();
      break;
    case tk_print:
      P();
      S();
      break;
    case tk_endl:
      //Casa o ";"
      casa (tk_endl);
      S();
      break;
    case 13:
      //Conserta erro
      casa (13);
      S();
      break;
  }
}

void P() {
  casa( tk_print );
  E();
  print( "print #" );
}

void A() {
// lexema é guardado,visto que a função 'casa' altera o seu valor.
  string temp = lexema;
  casa( tk_id );
  print( temp );
  casa( '=' );
  E();
  print( "=" );
}

void E() {
  T();
  E_linha();
}

void E_linha() {
  switch( token ) {
    case '+' : casa( '+' ); T(); print( "+"); E_linha(); break;
    case '-' : casa( '-' ); T(); print( "-"); E_linha(); break;
  }
}
void T_linha() {
  switch( token ) {
    case '*' : casa( '*' ); F(); print( "*"); T_linha(); break;
    case '/' : casa( '/' ); F(); print( "/"); T_linha(); break;
  }
}

void T() {
  F();
  T_linha();
}



void F() {
  switch( token ) {
    case tk_id: {
      string temp = lexema;
      casa( tk_id ); 
      print( temp + " @" ); } 
      break;
    case tk_num: {
      string temp = lexema;
      casa( tk_num ); 
      print( temp ); }
      break;
    case tk_string: {
      string temp = lexema;
      casa( tk_string ); 
      print( temp ); }
      break;
    case '(': {
      //Exclui os parenteses, pois não aparecem na NPR
      casa( '(' ); 
      E(); 
      casa ( ')' ); }
      break;
    case tk_func:{
      string temp = lexema;
      casa(tk_func); 
      casa( '(' );
      E();
      while (lexema == ","){
        casa ( ',' );
        E();
      }
      casa ( ')' );
      print( temp + " #" );
    }
      break;
    default:
      erro();
  }
}

void casa( int esperado ) {
  if( token == esperado || token == 13 )
    token = next_token();
  else {
      cout << "Esperado " << nome_token( esperado ) 
	   << " , encontrado: " << nome_token( token ) << endl;
    exit( 1 );
  }
}

void erro() {
  cout << "*** Erro: ***" << endl;
  exit( 1 );
}

int main() {
  token = next_token();
  S();
  
  return 0;
}