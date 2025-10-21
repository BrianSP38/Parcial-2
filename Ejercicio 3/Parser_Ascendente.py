class ParserAscendente:
    def __init__(self, tokens):
        self.tokens = tokens + ['$']
        self.stack = ['$','E']
        self.index = 0

    def top(self):
        return self.stack[-1]

    def current_token(self):
        return self.tokens[self.index]

    def pop(self):
        return self.stack.pop()

    def push(self, symbols):
        if symbols != ['ε']:
            self.stack.extend(reversed(symbols))

    def tabla_prediccion(self):
        return {
            ('E', 'id'): ['T', 'E\''],
            ('E', '('): ['T', 'E\''],

            ('E\'', '+'): ['+', 'T', 'E\''],
            ('E\'', ')'): ['ε'],
            ('E\'', '$'): ['ε'],

            ('T', 'id'): ['F', 'T\''],
            ('T', '('): ['F', 'T\''],

            ('T\'', '*'): ['*', 'F', 'T\''],
            ('T\'', '+'): ['ε'],
            ('T\'', ')'): ['ε'],
            ('T\'', '$'): ['ε'],

            ('F', 'id'): ['id'],
            ('F', '('): ['(', 'E', ')']
        }

    def parse(self):
        tabla = self.tabla_prediccion()
        print(f"{'Pila':<25}{'Entrada':<25}{'Acción'}")
        while True:
            top = self.top()
            token = self.current_token()

            print(f"{' '.join(self.stack):<25}{' '.join(self.tokens[self.index:]):<25}", end='')

            if top == token == '$':
                print("✔ Cadena aceptada")
                return True

            elif top == token:
                print(f"Emparejar '{token}'")
                self.pop()
                self.index += 1

            elif (top, token) in tabla:
                produccion = tabla[(top, token)]
                print(f"{top} → {' '.join(produccion)}")
                self.pop()
                self.push(produccion)

            else:
                print(f"❌ Error: No hay regla para ({top}, {token})")
                return False


# PRUEBA
if __name__ == "__main__":
    tokens = ['id', '+', 'id', '*', 'id']
    parser = ParserAscendente(tokens)
    parser.parse()
