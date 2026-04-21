# franC-compiler

**franC** is a custom, lightweight interpreted programming language built from scratch using **C, Flex, and Bison**. It was developed as a final Mini-Project for an engineering compilation techniques course.

The language features a French-based syntax and includes an Abstract Syntax Tree (AST) execution engine capable of handling variables, mathematical/logical expressions, control flow, and parameter-less functions.

---

## 🚀 Features

- **Data Types:** Supports integers (`entier`), floats (`reel`), characters (`caractere`), and strings (`chaine`).
- **Constants:** Immutable variables using the `constante` keyword.
- **Control Structures:** Conditionals (`si`, `sinon si`, `sinon`) and loops (`tant_que`).
- **Logical & Mathematical Operators:** `+`, `-`, `*`, `/`, `<`, `>`, `<=`, `>=`, `==`, `!=`, `et` (or `&&`), `ou` (or `||`).
- **Functions:** Declaration of parameter-less functions and explicit `retourne` statements with execution short-circuiting.
- **Built-in I/O:** Type-aware console output using `afficher()`.
- **Robust Error Handling:** Detects lexical typos, syntax errors, and semantic violations (e.g., undeclared variables, modifying constants, division by zero).

---

## 🛠️ Prerequisites

To compile and run the franC interpreter, your system must have the following tools installed:

- **GCC** (GNU Compiler Collection)
- **Flex** (Fast Lexical Analyzer Generator)
- **Bison** (GNU Parser Generator)
- **Make** (Build automation tool)

_On Debian/Ubuntu, you can install these via:_
`sudo apt-get install gcc flex bison make`

---

## 📦 Installation & Build

The project uses a standard `Makefile` that securely separates generated source files into a dedicated `build/` directory.

1. Clone the repository and navigate to the root directory:

   ```bash
   git clone https://github.com/AhmedCha/franC-compiler.git
   cd franC-compiler
   ```

2. Compile the engine:

   ```bash
   make
   ```

3. (Optional) To clean up all generated files:

   ```bash
   make clean
   ```

---

## 💻 Usage

Once compiled, you can execute any `.franc` script by passing it as an argument to the interpreter.

```bash
./franc my_script.franc
```

### Code Example

Here is an example of what **franC** syntax looks like:

```c
// Variables and Strings
chaine message = "Bienvenue dans franC !";
afficher(message);

constante reel PI = 3.1415;
entier rayon = 10;

// Functions and Logic
fonction calculer_surface() {
    si (rayon > 0 et PI == 3.1415) {
        retourne PI * (rayon * rayon);
    } sinon {
        retourne 0;
    }
}

// Execution and Output
reel surface = calculer_surface();
afficher("La surface est :");
afficher(surface);

// Loops
entier compteur = 3;
tant_que (compteur > 0) {
    afficher(compteur);
    compteur = compteur - 1;
}
```

More example codes can be found in the test folder.

---

## 🏗️ Architecture overview

- **`franc.l`**: The Flex lexer that tokenizes the input text.
- **`franc.y`**: The Bison parser that defines the grammar and constructs the AST.
- **`ast.c` / `ast.h`**: The AST nodes, constructors, and the main evaluation engine (`executer_ast`).
- **`symbole.c` / `symbole.h`**: Memory management mapping variables and functions for semantic validation and retrieval.
