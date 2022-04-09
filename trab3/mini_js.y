%{
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <vector>
#include <map>
#include <algorithm>

using namespace std;

typedef vector<string> strList;

struct Atributos {
    strList c; 
    int l; 
};

#define YYSTYPE Atributos

int yylex();
int yyparse();
void yyerror(const char *);

strList operator+(strList a, string b);
strList operator+(string a, strList b);
strList concatena(strList a, strList b);
strList operator+(strList a, strList b);


string generateLabel(string prefixo);

void print(strList source);

strList resolve_enderecos(strList entrada);
strList novo;

int linha = 1, coluna = 1;
int token(int tk);

void generateVariable(Atributos var);
void checkVariable(Atributos var);
map<string, int> vars;

bool is_function_scope = false;
int argCallCounter = 0;
int argCounter = 0;
strList argList = {};
strList funcSource = {};

string trim(string str, string charsToRemove);
strList tokeniza(string asmLine);

%}

%token tokenIF tokenELSE TK_ASM
%token tokenNUM TK_ID tokenLET tokenWHILE tokenFOR TK_STR TK_ARRAY TK_ARROW tokenFUNCTION tokenRETURN
%token tokenMAIS tokenMENOS tokenMUL tokenDIV tokenMODULO
%token TK_MAIOR TK_MENOR TK_MEIG TK_MAIG TK_IGUAL TK_DIFF TK_AND TK_OR
%token TK_OBJECT TK_OPENBRACE TK_CLOSEBRACE


%nonassoc TK_MAIOR TK_MENOR TK_MEIG TK_MAIG TK_IGUAL TK_DIFF
%nonassoc tokenIF tokenELSE tokenWHILE tokenFOR
%left TK_AND TK_OR
%left tokenMAIS tokenMENOS
%left tokenMUL tokenDIV tokenMODULO

%start S 


%%

S : CMDs  { $$.c = $1.c + "." + funcSource; print( resolve_enderecos($$.c) ); }
  ;

CMDs : CMD ';' CMDs    { $$.c = $1.c + $3.c; }
	 | FLOW_CMD CMDs   { $$.c = $1.c + $2.c; }
	 | FUNC_DECL CMDs  { $$.c = $1.c + $2.c; }
     |                 { $$.c = novo; }
     ;
	 
ARGS : R ',' ARGS { $$.c = $1.c + $3.c; argCounter++; is_function_scope = true;
					if($1.c.size() >= 2) argList.push_back($1.c.rbegin()[1]); }
					
	 | R          { $$ = $1; argCounter++; is_function_scope = true;
					if($1.c.size() >= 2) argList.push_back($1.c.rbegin()[1]); }
					
	 |            { $$.c = novo; is_function_scope = true; }
	 ;
	 
ARGS_CALL : R ',' ARGS_CALL   { $$.c = $1.c + $3.c; argCallCounter++; }
          | R                 { $$ = $1; argCallCounter++; }
		  |                   { $$.c = novo; }
		  ;

CMD : A                        { $$.c = $1.c + "^"; }
    | tokenLET DECLVARS          { $$ = $2; }
	| tokenRETURN R              { $$.c = $2.c + "'&retorno'" + "@" + "~"; }
	| E TK_ASM                 { $$.c = $1.c + $2.c + "^"; }
    ;
	
FLOW_CMD : tokenIF '(' R ')' BODY OPT_ELSE
			{
				string endif = generateLabel("end_if");
				string dps_else = generateLabel("dps_else");
				$$.c = $3.c + "!" + endif + "?" + $5.c + dps_else + "#" + (":" + endif) + $6.c + (":" + dps_else) ;
			}
			
		 | tokenWHILE '(' R ')' BODY
			{
				string endwhile = generateLabel("end_while");
				string beginwhile = generateLabel("begin_while");
				$$.c = (":" + beginwhile) + $3.c + "!" + endwhile + "?" + $5.c + beginwhile + "#" + (":" + endwhile);
			}
			
		 | tokenFOR '(' CMD ';' R ';' A ')' BODY
		  {
		   string endfor = generateLabel("end_for");
		   string beginfor = generateLabel("begin_for");
		   $$.c = $3.c + (":" + beginfor) + $5.c + "!" + endfor + "?" + $9.c + $7.c + "^" + beginfor + "#" + (":" + endfor);
		  }
		 ;
		   
OPT_ELSE : tokenELSE BODY  { $$ = $2; }
		 |               { $$.c = novo; }
		 ;
	
BODY : CMD ';'     { $$ = $1; }
	 | BLOCK
	 | FLOW_CMD
	 ;
	 
FUNC_CALL : LVALUE '(' ARGS_CALL ')'
			{
				$$.c = $3.c + to_string(argCallCounter) + $1.c + "@" + "$";
				argCallCounter = 0;
			}
		  | LVALUEPROP '(' ARGS_CALL ')'
			{
				$$.c = $3.c + to_string(argCallCounter) + $1.c + "[@]" + "$";
				argCallCounter = 0;
			}
	      ;
		  
FUNC_DECL : tokenFUNCTION LVALUE '(' ARGS ')' BLOCK
			{
				string beginfunc = generateLabel("begin_func");
				$$.c = $2.c + "&" + $2.c + "{}" + "=" + "'&funcao'" + beginfunc + "[=]" + "^";
				
				funcSource.push_back(":"+beginfunc);
				
				for(int i = 0; i < argCounter; i++){
					strList tmp = {argList.at(argCounter-i-1), "&", argList.at(argCounter-i-1), "arguments", "@", to_string(i), "[@]", "=", "^"};
					funcSource.insert(funcSource.end(), tmp.begin(), tmp.end());
				}
				
				funcSource.insert(funcSource.end(), $6.c.begin(), $6.c.end());
				
				strList finalReturn = {"undefined", "@", "'&retorno'", "@", "~"};
				funcSource.insert(funcSource.end(), finalReturn.begin(), finalReturn.end());
				
				argCounter = 0; argList.clear(); is_function_scope = false;
			}
		  ;
			
BLOCK : TK_OPENBRACE CMDs TK_CLOSEBRACE { $$ = $2; }
	  ;
	  
EMPTY_BLOCK : TK_OPENBRACE TK_CLOSEBRACE
			;

DECLVARS : DECLVAR ',' DECLVARS  { $$.c = $1.c + $3.c; }
         | DECLVAR               { $$ = $1; }
         ;

DECLVAR : LVALUE '=' R  { generateVariable($1); $$.c = $1.c + "&" + $1.c + $3.c + "=" + "^"; }
        | LVALUE        { generateVariable($1); $$.c = $1.c + "&"; }
        ;

A : LVALUE '=' A                   { if(!is_function_scope) checkVariable($1); $$.c = $1.c + $3.c + "="; }
  | LVALUEPROP '=' A               { $$.c = $1.c + $3.c + "[=]"; }
  | R                              { $$ = $1; }
  ;

R : E TK_MEIG E        { $$.c = $1.c + $3.c + "<="; }
  | E TK_MAIG E        { $$.c = $1.c + $3.c + ">="; }
  |	E TK_MENOR E       { $$.c = $1.c + $3.c + "<"; }
  | E TK_MAIOR E       { $$.c = $1.c + $3.c + ">"; }
  | E TK_IGUAL E       { $$.c = $1.c + $3.c + "=="; }
  | E TK_DIFF E        { $$.c = $1.c + $3.c + "!="; }
  | E                  { $$ = $1; }
  ;

E : LVALUE '=' E       { $$.c = $1.c + $3.c + "=" ; }
  | LVALUEPROP '=' E   { $$.c = $1.c + $3.c + "[=]"; }
  | E tokenMAIS E        { $$.c = $1.c + $3.c + "+"; }
  | E tokenMENOS E       { $$.c = $1.c + $3.c + "-"; }
  | E tokenMUL E        { $$.c = $1.c + $3.c + "*"; }
  | E tokenDIV E         { $$.c = $1.c + $3.c + "/"; }
  | E tokenMODULO E      { $$.c = $1.c + $3.c + "%"; }
  | tokenMENOS E         { $$.c = "0" + $2.c + "-"; }
  | LVALUE             { $$.c = $1.c + "@"; }
  | LVALUEPROP         { $$.c = $1.c + "[@]"; }
  | F                  { $$ = $1; }
  ;
  
LVALUE : TK_ID
	   ;
	   
LVALUEPROP : E '[' E ']'    { $$.c = $1.c + $3.c; }
		   | E '.' LVALUE   { $$.c = $1.c + $3.c; }
		   ;

F : tokenNUM          { $$.c = $1.c; }
  | TK_STR          { $$.c = $1.c; }
  | '(' E ')'       { $$ = $2; }
  | TK_OBJECT       { $$.c = novo + $1.c; }
  | TK_ARRAY        { $$.c = novo + $1.c; }
  | FUNC_CALL       { $$ = $1; }
  ;

%%

#include "lex.yy.c"

strList concatena(strList a, strList b) {
  for(int i(0); i < b.size(); i++ ) a.push_back( b[i] );
  return a;
}

strList operator+(strList a, strList b) {
  return concatena(a, b);
}

strList operator+(strList a, string b) {
  a.push_back(b);
  return a;
}

strList operator+(string a, strList b) {
  strList c;
  c.push_back(a);
  return c + b;
}

void generateVariable(Atributos var){
  if(vars.count(var.c.back()) == 0){
	vars[var.c.back()] = var.l;
  }
  else {
	cout << "Erro: a variável '" << var.c.back() << "' já foi declarada na linha " << vars[var.c.back()] << "." << endl;
	exit(1);
  }
}

void checkVariable(Atributos var){
	
	if(vars.count(var.c.back()) == 0){
		cout << "Erro: a variável '" << var.c.back() << "' não foi declarada." << endl;
		exit(1);
	}
}

string generateLabel(string prefixo){
  static int n = 0;
  return prefixo + "_" + to_string(++n) + ":";
}

void print(strList source){
  for(int i(0); i < source.size(); i++) cout << source[i] << endl;
}

strList resolve_enderecos(strList entrada) {
	vector<string> exit;
	map<string,int> label;

  for( int i = 0; i < entrada.size(); i++ ){
    if( entrada[i][0] == ':' ){
		label[entrada[i].substr(1)] = exit.size();
	}
    else{
		exit.push_back( entrada[i] );
	}
  }
  
  for( int i = 0; i < exit.size(); i++ ) 
    if( label.count( exit[i] ) > 0 )
        exit[i] = to_string(label[exit[i]]);
    
  return exit;
}

void yyerror( const char* st ) {
   puts( st ); 
   printf( "Proximo a: %s, linha: %d, coluna: %d\n", yytext, linha, coluna);
   exit( 1 );
}

int token(int tk) {
    yylval.c = novo + yytext;
    yylval.l = linha;
    coluna += strlen(yytext);
    return tk;
}

string trim(string str, string charsToRemove){
	for(auto c : charsToRemove){
		str.erase(remove(str.begin(), str.end(), c), str.end());
	}
	return str;
}

strList tokeniza(string asmLine){

	strList instructions;

	string word = "";

	for(auto c : asmLine){
		if(c != ' '){
			word = word + c;
		}
		else {
			instructions.push_back(word);
			word = "";
		}
	}
	instructions.push_back(word);
	return instructions;
}

int main( int argc, char** argv ) {
  yyparse();
  return 0;
}