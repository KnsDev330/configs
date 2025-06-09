# configs
This repository contains various configuration files used for personal development setups and other environments.

It includes settings for editors, shells, and other tools to help streamline and standardize the development workflow.

<details>




<summary>Competetive Programming</summary>
<blockquote>


<details>
<summary>.bashrc</summary>

```bash
sol() {
	local src="sol.cpp"
	local input=""

	if [[ $# -eq 1 ]]; then
		input="$1"
	elif [[ $# -eq 2 ]]; then
		src="$1"
		input="$2"
	else
		echo "Usage: sol [source.cpp] input_file"
		return 1
	fi

	local exe="${src%.cpp}"

	if g++ "$src" -o -DLOCAL "$exe"; then
		echo "Compiled $src → $exe"
		echo "Running $exe with input <$input>"
		./"$exe" < "$input" > out.txt 2> err.txt
		echo "✓ Execution completed!"
	else
		echo "❌ Compilation failed!"
	fi
}

```
</details>


<details>
<summary>.vscode/cpp.code-snippets</summary>

```json
"c++ cp template": {
	"prefix": "cpt",
	"body": [
		"#include <bits/stdc++.h>",
		"using namespace std;",
		"using ll = long long;",
		"",
		"using vi  = vector<int>;",
		"using vll = vector<ll>;",
		"",
		"#define FOR(i, a, b) for(int i = (a); i < (b); ++i)",
		"#define ROF(i, a, b) for(int i = (a); i >= (b); --i)",
		"",
		"#ifdef LOCAL",
		"#include \"../debug.h\"",
		"#else",
		"#define debug(...)",
		"#endif",
		"",
		"",
		"int main() {",
		"\tios::sync_with_stdio(0), cin.tie(0);",
		"\tint tt;",
		"\tcin >> tt;",
		"",
		"\twhile(tt--) {",
		"\t\t$0",
		"\t}",
		"",
		"\treturn 0;",
		"}",
		""
	],
	"description": "c++ cp template"
}
```
</details>


<details>
<summary>.vscode/settings.json</summary>

```json
{
	"editor.formatOnSave": true,
	"editor.tabSize": 3,
	"editor.insertSpaces": false,
	"editor.detectIndentation": true,
}
```
</details>


<details>
<summary>.clang_format</summary>

```sh
Language: Cpp
BasedOnStyle: Google
IndentWidth: 3
TabWidth: 3
AlignAfterOpenBracket: BlockIndent
AlignConsecutiveDeclarations: false
AlignEscapedNewlinesLeft: true
AlignOperands: true
ColumnLimit: 120
AlignTrailingComments: true
AllowAllParametersOfDeclarationOnNextLine: false
AllowShortBlocksOnASingleLine: false
AllowShortCaseLabelsOnASingleLine: false
AllowShortFunctionsOnASingleLine: None
AllowShortLoopsOnASingleLine: false
AlwaysBreakAfterDefinitionReturnType: None
AlwaysBreakAfterReturnType: None
AlwaysBreakBeforeMultilineStrings: false
AlwaysBreakTemplateDeclarations: true
UseTab: ForIndentation
MaxEmptyLinesToKeep: 2
SpaceBeforeParens: false
AllowShortIfStatementsOnASingleLine: AllIfsAndElse

BreakBeforeBraces: Custom
BraceWrapping:
	AfterCaseLabel: false
	AfterClass: false
	AfterEnum: false
	AfterFunction: false
	AfterNamespace: false
	AfterStruct: false
	AfterUnion: false
	AfterExternBlock: false
	BeforeCatch: true
	BeforeElse: true
	BeforeLambdaBody: false
	BeforeWhile: true

InsertBraces: false

AlignConsecutiveAssignments:
	Enabled: true
	AcrossEmptyLines: false
	AcrossComments: false
	AlignCompound: true
	AlignFunctionPointers: false

EmptyLineBeforeAccessModifier: Always

IndentAccessModifiers: true
```
</details>


<details>
<summary>debug.h</summary>

```h
// clang-format off
#ifndef DEBUG_H
#define DEBUG_H

#include<bits/stdc++.h>
using namespace std;

#define debug0() \
	cerr << endl;

#define debug1(x) \
	cerr << #x << " = "; _print(x); cerr << endl;

#define debug2(x, y) \
	cerr << #x << " = "; _print(x); cerr << ", " \
			<< #y << " = "; _print(y); cerr << endl;

#define debug3(x, y, z) \
	cerr << #x << " = "; _print(x); cerr << ", " \
			<< #y << " = "; _print(y); cerr << ", " \
			<< #z << " = "; _print(z); cerr << endl;

#define debug4(x, y, z, w) \
	cerr << #x << " = "; _print(x); cerr << ", " \
			<< #y << " = "; _print(y); cerr << ", " \
			<< #z << " = "; _print(z); cerr << ", " \
			<< #w << " = "; _print(w); cerr << endl;

#define GET_MACRO(_1, _2, _3, _4, NAME, ...) NAME
#define debug(...) GET_MACRO(__VA_ARGS__, debug4, debug3, debug2, debug1, debug0)(__VA_ARGS__)

void _print(int x) {cerr << x;}
void _print(long x) {cerr << x;}
void _print(long long x) {cerr << x;}
void _print(unsigned x) {cerr << x;}
void _print(unsigned long x) {cerr << x;}
void _print(unsigned long long x) {cerr << x;}
void _print(float x) {cerr << x;}
void _print(double x) {cerr << x;}
void _print(long double x) {cerr << x;}
void _print(char x) {cerr << '\'' << x << '\'';}
void _print(const char *x) {cerr << '\"' << x << '\"';}
void _print(const string &x) {cerr << '\"' << x << '\"';}
void _print(bool x) {cerr << (x ? "T" : "F");}


template <typename T>
struct is_vector : std::false_type {};

template <typename T, typename A>
struct is_vector<std::vector<T, A>> : std::true_type {};

template <typename T>
inline constexpr bool is_vector_v = is_vector<T>::value;


template <typename T, typename V>
void _print(const pair<T, V> &x) {
	cerr << '(';
	_print(x.first);
	cerr << ", ";
	_print(x.second);
	cerr << ')';
}

template <typename T>
void _print(const vector<T> &v) {
	if constexpr (is_vector_v<T>) {
		cerr << '\n';
		for (const auto &row : v) {
			cerr << "  ";
			_print(row);
			cerr << '\n';
		}
	}
	else {
		cerr << '[';
		for (size_t i = 0; i < v.size(); ++i) {
			if (i > 0) cerr << ", ";
			_print(v[i]);
		}
		cerr << ']';
	}
}

template <typename T>
void _print(const set<T> &v) {
	cerr << '{';
	for (auto it = v.begin(); it != v.end(); ++it) {
		if (it != v.begin()) cerr << ", ";
		_print(*it);
	}
	cerr << '}';
}

template <typename T, typename V>
void _print(const map<T, V> &v) {
	cerr << '{';
	for (auto it = v.begin(); it != v.end(); ++it) {
		if (it != v.begin()) cerr << ", ";
		_print(it->first);
		cerr << ": ";
		_print(it->second);
	}
	cerr << '}';
}

template <typename T>
void _print(const unordered_set<T> &v) {
	cerr << '{';
	for (auto it = v.begin(); it != v.end(); ++it) {
		if (it != v.begin()) cerr << ", ";
		_print(*it);
	}
	cerr << '}';
}

template <typename T, typename V>
void _print(const unordered_map<T, V> &v) {
	cerr << '{';
	for (auto it = v.begin(); it != v.end(); ++it) {
		if (it != v.begin()) cerr << ", ";
		_print(it->first);
		cerr << ": ";
		_print(it->second);
	}
	cerr << '}';
}

template <typename T>
void _print(const deque<T> &v) {
	cerr << '[';
	for (size_t i = 0; i < v.size(); ++i) {
		if (i > 0) cerr << ", ";
		_print(v[i]);
	}
	cerr << ']';
}

template <typename T>
void _print([[maybe_unused]] stack<T> v) {
	cerr << '[';
	while(!v.empty()) {
		_print(v.top());
		if (v.size() > 1) cerr << ", ";
		v.pop();
	}
	cerr << ']';
}

template <typename T>
void _print(queue<T> v) {
	cerr << '[';
	while(!v.empty()) {
		_print(v.front());
		if (v.size() > 1) cerr << ", ";
		v.pop();
	}
	cerr << ']';
}

template <typename T>
void _print(priority_queue<T> v) {
	cerr << '[';
	bool first = true;
	while (!v.empty()) {
		if (!first) cerr << ", ";
		first = false;
		_print(v.top());
		v.pop();
	}
	cerr << ']';
}

template <typename Tuple, size_t Index = 0>
void _print_tuple(const Tuple &t) {
	if constexpr (Index < std::tuple_size<Tuple>::value) {
		if (Index > 0) cerr << ", ";
		_print(std::get<Index>(t));
		_print_tuple<Tuple, Index + 1>(t);
	}
}

template <typename... Args>
void _print(const tuple<Args...> &t) {
	cerr << '(';
	_print_tuple(t);
	cerr << ')';
}

#endif
```
</details>


<details>
<summary>template.cpp</summary>

```cpp
#include <bits/stdc++.h>
using namespace std;
using ll = long long;

using vi  = vector<int>;
using vll = vector<ll>;

#define FOR(i, a, b) for(int i = (a); i < (b); ++i)
#define ROF(i, a, b) for(int i = (a); i >= (b); --i)

#ifdef LOCAL
#include "../debug.h"
#else
#define debug(...)
#endif


int main() {
	ios::sync_with_stdio(0), cin.tie(0);
	int tt;
	cin >> tt;

	while(tt--) {
		
	}

	return 0;
}

```
</details>


</blockquote>





</details>
