%{
#include "db.tab.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

extern char **last_id_list;
extern char **last_val_list;
extern char **last_assign_list;
int yylineno = 1;
%}

%%

[ \t\r\n]+        { if(yytext[0]=='\n') yylineno++;  }
"/*"([^*]|\*+[^*/])*\*+ "/"   {  }
"//".*            {  }

[Cc][Rr][Ee][Aa][Tt][Ee]     { return CREATE; }
[Tt][Aa][Bb][Ll][Ee]         { return TABLE; }
[Vv][Aa][Ll][Uu][Ee][Ss]     { return VALUES; }
[Ii][Nn][Ss][Ee][Rr][Tt]     { return INSERT; }
[Ii][Nn][Tt][Oo]             { return INTO; }
[Ss][Ee][Ll][Ee][Cc][Tt]     { return SELECT; }
[Ff][Rr][Oo][Mm]             { return FROM; }
[Ww][Hh][Ee][Rr][Ee]         { return WHERE; }
[Uu][Pp][Dd][Aa][Tt][Ee]     { return UPDATE; }
[Ss][Ee][Tt]                 { return SET; }
[Dd][Ee][Ll][Ee][Tt][Ee]     { return DELETE; }
[Dd][Rr][Oo][Pp]             { return DROP; }

","              { return COMMA; }
";"              { return SEMICOLON; }
"("              { return LP; }
")"              { return RP; }
"*"              { return STAR; }
"="              { return EQ; }

\'([^\'\\]|\\.)*\'    {
                        int len = yyleng;
                        char *s = malloc(len-1);
                        int j=0;
                        for(int i=1;i<yyleng-1;i++){
                            if(yytext[i]=='\\' && i+1<yyleng-1){ i++; s[j++]=yytext[i]; }
                            else s[j++]=yytext[i];
                        }
                        s[j]=0;
                        yylval.s = s;
                        last_val_list = last_val_list;
                        return STRING;
                     }

[A-Za-z_][A-Za-z0-9_]* {
    char *s = strdup(yytext);
    yylval.s = s;
    return IDENTIFIER;
}

[0-9]+ {
    char *s = strdup(yytext);
    yylval.s = s;
    return NUMBER;
}

.   { return yytext[0]; }

%%

int yywrap() { return 1; }
