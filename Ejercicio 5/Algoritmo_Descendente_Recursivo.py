tokens = []
index = 0

def match(expected):
    global index
    if index < len(tokens) and tokens[index] == expected:
        index += 1
    else:
        raise Exception(f"Error de sintaxis, se esperaba {expected}")

def F():
    global index
    if tokens[index] == 'id':
        match('id')
    elif tokens[index] == '(':
        match('(')
        E()
        match(')')
    else:
        raise Exception("Error en F")

def T():
    F()
    while index < len(tokens) and tokens[index] == '*':
        match('*')
        F()

def E():
    T()
    while index < len(tokens) and tokens[index] == '+':
        match('+')
        T()

def parse(input_tokens):
    global tokens, index
    tokens = input_tokens + ['$']
    index = 0
    E()
    if tokens[index] == '$':
        print("✔ Cadena aceptada")
    else:
        print("❌ Cadena no aceptada")

if __name__ == "__main__":
    parse(['id', '+', 'id', '*', 'id'])
