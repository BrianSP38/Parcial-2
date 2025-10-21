from collections import defaultdict

class CYKParser:
    def __init__(self, grammar):
        self.grammar = grammar
        self.rhs_to_lhs = defaultdict(list)
        for lhs, rhss in grammar.items():
            for rhs in rhss:
                self.rhs_to_lhs[tuple(rhs)].append(lhs)

    def parse(self, w):
        n = len(w)
        P = [[set() for _ in range(n)] for _ in range(n)]

        for i, terminal in enumerate(w):
            for lhs, rhss in self.grammar.items():
                for rhs in rhss:
                    if len(rhs) == 1 and rhs[0] == terminal:
                        P[i][i].add(lhs)

        for l in range(2, n+1):
            for i in range(n - l + 1):
                j = i + l - 1
                for k in range(i, j):
                    for B in P[i][k]:
                        for C in P[k+1][j]:
                            if (B, C) in self.rhs_to_lhs:
                                for A in self.rhs_to_lhs[(B, C)]:
                                    P[i][j].add(A)

        return 'E' in P[0][n-1]


if __name__ == "__main__":
    grammar = {
        'E': [['T', 'E\'']],
        'E\'': [['+', 'T', 'E\''], ['ε']],
        'T': [['F', 'T\'']],
        'T\'': [['*', 'F', 'T\''], ['ε']],
        'F': [['id'], ['(', 'E', ')']]
    }

    cyk = CYKParser(grammar)
    print(cyk.parse(['id', '+', 'id', '*', 'id']))
