%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);
extern int yylineno;

typedef struct Table {
    char *name;
    int ncols;
    char **colnames;
    int nrows;
    int rowcap;
    char ***rows;
    struct Table *next;
} Table;

Table *db_head = NULL;

Table* find_table(const char *name);
void create_table(const char *name, char **cols, int ncols);
void drop_table(const char *name);
void insert_into(const char *name, char **values, int nvals);
void select_from(const char *name, char **cols, int ncols, const char *where_col, const char *where_val);
void update_table(const char *name, char **assign_cols, char **assign_vals, int nassign, const char *where_col, const char *where_val);
void delete_from(const char *name, const char *where_col, const char *where_val);
char *strdup_safe(const char *s);
%}

%union {
    char *s;
    char **ss;
    int ival;
}

%token CREATE TABLE INSERT INTO VALUES SELECT FROM WHERE UPDATE SET DELETE DROP
%token COMMA SEMICOLON LP RP STAR EQ
%token IDENTIFIER STRING NUMBER
%type <s> IDENTIFIER STRING
%type <ss> id_list val_list assign_list select_list

%%

input:
  | input stmt
  ;

stmt:
    sql_stmt SEMICOLON    {}
  ;

sql_stmt:
    create_stmt
  | insert_stmt
  | select_stmt
  | update_stmt
  | delete_stmt
  | drop_stmt
  ;

create_stmt:
    CREATE TABLE IDENTIFIER LP id_list RP
    {
        create_table($3, $5, (int) (intptr_t) NULL);
    }
  ;

insert_stmt:
    INSERT INTO IDENTIFIER LP id_list RP VALUES LP val_list RP
    {
        insert_into($3, $8, (int) (intptr_t) NULL);
    }
  ;

select_stmt:
    SELECT select_list FROM IDENTIFIER WHERE IDENTIFIER EQ STRING
    {
        select_from($4, $2, (int) (intptr_t) NULL, $6, $8);
    }
  | SELECT STAR FROM IDENTIFIER
    {
        select_from($3, NULL, 0, NULL, NULL);
    }
  ;

update_stmt:
    UPDATE IDENTIFIER SET assign_list WHERE IDENTIFIER EQ STRING
    {
        update_table($2, $4, NULL, (int) (intptr_t) NULL, $6, $8);
    }
  ;

delete_stmt:
    DELETE FROM IDENTIFIER WHERE IDENTIFIER EQ STRING
    {
        delete_from($3, $5, $7);
    }
  ;

drop_stmt:
    DROP TABLE IDENTIFIER
    {
        drop_table($3);
    }
  ;


id_list:
    IDENTIFIER
    {
        char **arr = malloc(2 * sizeof(char*));
        arr[0] = strdup_safe($1);
        arr[1] = NULL;
        $$ = arr;
    }
  | id_list COMMA IDENTIFIER
    {
        
        int cnt = 0; while ($1[cnt]) cnt++;
        char **arr = realloc($1, (cnt + 2) * sizeof(char*));
        arr[cnt] = strdup_safe($3);
        arr[cnt+1] = NULL;
        $$ = arr;
    }
  ;

val_list:
    STRING
    {
        char **arr = malloc(2 * sizeof(char*));
        arr[0] = strdup_safe($1);
        arr[1] = NULL;
        $$ = arr;
    }
  | val_list COMMA STRING
    {
        int cnt = 0; while ($1[cnt]) cnt++;
        char **arr = realloc($1, (cnt + 2) * sizeof(char*));
        arr[cnt] = strdup_safe($3);
        arr[cnt+1] = NULL;
        $$ = arr;
    }
  ;

select_list:
    IDENTIFIER
    {
        char **arr = malloc(2*sizeof(char*));
        arr[0] = strdup_safe($1);
        arr[1] = NULL;
        $$ = arr;
    }
  | select_list COMMA IDENTIFIER
    {
        int cnt=0; while ($1[cnt]) cnt++;
        char **arr = realloc($1, (cnt+2)*sizeof(char*));
        arr[cnt] = strdup_safe($3);
        arr[cnt+1] = NULL;
        $$ = arr;
    }
  ;

assign_list:
    IDENTIFIER EQ STRING
    {
       
        char **arr = malloc(3*sizeof(char*));
        arr[0] = strdup_safe($1);
        arr[1] = strdup_safe($3);
        arr[2] = NULL;
        $$ = arr;
    }
  | assign_list COMMA IDENTIFIER EQ STRING
    {
        int cnt=0; while ($1[cnt]) cnt++;
        
        char **arr = realloc($1, (cnt+3)*sizeof(char*));
        arr[cnt] = strdup_safe($3);
        arr[cnt+1] = strdup_safe($5);
        arr[cnt+2] = NULL;
        $$ = arr;
    }
  ;

%%



void yyerror(const char *s) {
    fprintf(stderr, "ERROR: %s at line %d\n", s, yylineno);
}


char *strdup_safe(const char *s){
    if(!s) return NULL;
    char *r = malloc(strlen(s)+1);
    strcpy(r, s);
    return r;
}


Table* find_table(const char *name){
    Table *t = db_head;
    while(t){
        if(strcmp(t->name, name)==0) return t;
        t = t->next;
    }
    return NULL;
}


char **last_id_list = NULL;
char **last_val_list = NULL;
char **last_assign_list = NULL;

void create_table(const char *name, char **cols, int ncols){
    (void)ncols;
    if(find_table(name)){
        printf("Tabla %s ya existe.\n", name);
        return;
    }
    Table *t = malloc(sizeof(Table));
    t->name = strdup_safe(name);
    
    int cnt=0; while(last_id_list && last_id_list[cnt]) cnt++;
    t->ncols = cnt;
    t->colnames = malloc(sizeof(char*)*t->ncols);
    for(int i=0;i<t->ncols;i++) t->colnames[i]=strdup_safe(last_id_list[i]);
    t->nrows = 0;
    t->rowcap = 4;
    t->rows = malloc(sizeof(char**)*t->rowcap);
    t->next = db_head;
    db_head = t;
    printf("Tabla %s creada con %d columnas.\n", name, t->ncols);
    
    for(int i=0;i<cnt;i++) free(last_id_list[i]);
    free(last_id_list);
    last_id_list = NULL;
}

void drop_table(const char *name){
    Table **p = &db_head;
    while(*p){
        if(strcmp((*p)->name, name)==0){
            Table *t = *p;
            *p = t->next;
            
            free(t->name);
            for(int i=0;i<t->ncols;i++) free(t->colnames[i]);
            free(t->colnames);
            for(int r=0;r<t->nrows;r++){
                for(int c=0;c<t->ncols;c++) free(t->rows[r][c]);
                free(t->rows[r]);
            }
            free(t->rows);
            free(t);
            printf("Tabla %s eliminada.\n", name);
            return;
        }
        p = &(*p)->next;
    }
    printf("Tabla %s no encontrada.\n", name);
}

void insert_into(const char *name, char **values, int nvals){
    (void)nvals;
    Table *t = find_table(name);
    if(!t){ printf("Tabla %s no existe.\n", name); return; }
    
    int cnt=0; while(last_val_list && last_val_list[cnt]) cnt++;
    if(cnt != t->ncols){ printf("Número de valores (%d) no coincide con columnas (%d).\n", cnt, t->ncols); 
        for(int i=0;i<cnt;i++) free(last_val_list[i]);
        free(last_val_list);
        last_val_list = NULL;
        return;
    }
    if(t->nrows == t->rowcap){
        t->rowcap *= 2;
        t->rows = realloc(t->rows, sizeof(char**)*t->rowcap);
    }
    char **row = malloc(sizeof(char*)*t->ncols);
    for(int i=0;i<t->ncols;i++) row[i] = strdup_safe(last_val_list[i]);
    t->rows[t->nrows++] = row;
    printf("Insertado en %s: %d columnas.\n", name, t->ncols);
    for(int i=0;i<cnt;i++) free(last_val_list[i]);
    free(last_val_list);
    last_val_list = NULL;
}

void print_row(Table *t, char **row, char **cols, int ncols){
    if(cols==NULL){
        
        for(int c=0;c<t->ncols;c++){
            printf("%s=%s ", t->colnames[c], row[c]);
        }
        printf("\n");
    } else {
        for(int i=0;i<ncols;i++){
            
            int idx=-1;
            for(int c=0;c<t->ncols;c++) if(strcmp(t->colnames[c], cols[i])==0) { idx=c; break; }
            if(idx==-1) printf("%s=NULL ", cols[i]);
            else printf("%s=%s ", cols[i], row[idx]);
        }
        printf("\n");
    }
}

void select_from(const char *name, char **cols, int ncols, const char *where_col, const char *where_val){
    (void)ncols;
    Table *t = find_table(name);
    if(!t){ printf("Tabla %s no existe.\n", name); return; }
    int where_idx = -1;
    if(where_col){
        for(int c=0;c<t->ncols;c++) if(strcmp(t->colnames[c], where_col)==0) { where_idx = c; break; }
        if(where_idx==-1){ printf("Columna %s no encontrada.\n", where_col); return; }
    }
    for(int r=0;r<t->nrows;r++){
        if(where_col){
            if(strcmp(t->rows[r][where_idx], where_val)==0){
                print_row(t, t->rows[r], cols, 0);
            }
        } else {
            print_row(t, t->rows[r], cols, 0);
        }
    }
}

void update_table(const char *name, char **assign_cols, char **assign_vals, int nassign, const char *where_col, const char *where_val){
    (void)assign_vals; (void)nassign;
    Table *t = find_table(name);
    if(!t){ printf("Tabla %s no existe.\n", name); return; }
    int assign_count = 0;
    if(last_assign_list){
        while(last_assign_list[assign_count]) assign_count++;
    } else {
        printf("Nada que asignar.\n");
        return;
    }
    
    int where_idx = -1;
    if(where_col){
        for(int c=0;c<t->ncols;c++) if(strcmp(t->colnames[c], where_col)==0) { where_idx = c; break; }
        if(where_idx==-1){ printf("Columna WHERE %s no encontrada.\n", where_col); return; }
    }
    int changed = 0;
    for(int r=0;r<t->nrows;r++){
        if(where_col && strcmp(t->rows[r][where_idx], where_val)!=0) continue;
        
        for(int i=0;i<assign_count;i+=2){
            char *acol = last_assign_list[i];
            char *aval = last_assign_list[i+1];
            int aidx=-1;
            for(int c=0;c<t->ncols;c++) if(strcmp(t->colnames[c], acol)==0) { aidx=c; break; }
            if(aidx==-1) continue;
            free(t->rows[r][aidx]);
            t->rows[r][aidx] = strdup_safe(aval);
            changed++;
        }
    }
    printf("UPDATE: filas modificadas (aprox): %d\n", changed);
    for(int i=0;i<assign_count;i++) free(last_assign_list[i]);
    free(last_assign_list);
    last_assign_list = NULL;
}

void delete_from(const char *name, const char *where_col, const char *where_val){
    Table *t = find_table(name);
    if(!t){ printf("Tabla %s no existe.\n", name); return; }
    int where_idx=-1;
    if(where_col){
        for(int c=0;c<t->ncols;c++) if(strcmp(t->colnames[c], where_col)==0) { where_idx=c; break; }
        if(where_idx==-1){ printf("Columna WHERE %s no encontrada.\n", where_col); return; }
    } else {
        printf("DELETE sin WHERE no permitido en esta demo.\n");
        return;
    }
    int w=0;
    for(int r=0;r<t->nrows;r++){
        if(strcmp(t->rows[r][where_idx], where_val)==0){
            
            for(int c=0;c<t->ncols;c++) free(t->rows[r][c]);
            free(t->rows[r]);
            
            t->rows[r] = t->rows[t->nrows-1];
            t->nrows--;
            r--;
            w++;
        }
    }
    printf("DELETE: filas eliminadas: %d\n", w);
}


int main(int argc, char **argv){
    printf("Mini-DB parser (bison+flex). Termina con Ctrl+D. Escribe comandos SQL terminados en ;\n");
    yyparse();
    return 0;
}
