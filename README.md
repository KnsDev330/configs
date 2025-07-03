# configs
This repository contains various configuration files used for personal development setups and other environments.

It includes settings for editors, shells, and other tools to help streamline and standardize the development workflow.



<br>













<details>
<summary>New Linux Desktop Setup</summary>
<blockquote>



<details>
<summary>Add User to Sudoers</summary>

```bash
nano /etc/sudoers
```
```bash
USER_NAME  ALL=(ALL) NOPASSWD:ALL
```
</details>


<details>
<summary>Update</summary>

```bash
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y build-essential git-all curl wget vim tmux htop tree python3-pip python3-venv
```
</details>


<details>
<summary>Install Chrome</summary>

```bash
wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
sudo dpkg -i chrome-remote-desktop_current_amd64.deb
sudo apt install -f
sudo dpkg -i chrome-remote-desktop_current_amd64.deb
sudo apt install -f
sudo rm chrome-remote-desktop_current_amd64.deb
```
</details>





</details>
<br>























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



<details>
<summary>Validator sample</summary>

```cpp
#include <bits/stdc++.h>

#include "testlib.h"

int main(int argc, char* argv[]) {
	registerValidation(argc, argv);

	int tolTC = 1;
	// tolTC = inf.readInt(1, 1000, "~tolTC~");
	// inf.readEoln();

	for(int i = 1; i <= tolTC; i++) {
		setTestCase(i);
		int y = inf.readInt(1, 3000, "y");
		inf.readEoln();
	}

	inf.readEof();


	// vector<int> ints = inf.readInts(sz, mn, mx, "name");
	// inf.readEof();
	// inf.readEoln();
	// inf.readSpace();
}

```
</details>

<details>
<summary>Checker sample</summary>

```cpp
#include <bits/stdc++.h>

#include "testlib.h"


int main(int argc, char *argv[]) {
	registerTestlibCmd(argc, argv);

	int tolTC = 1;
	// tolTC = inf.readInt(1, 1000);

	int curTC = 0;
	while(++curTC <= tolTC) {
		setTestCase(curTC);

		pattern ptn("[Yy][Es][Ss]|[Nn][Oo]");

		std::string j = ans.readLine(ptn, "j");
		std::string p = ouf.readLine(ptn, "p");

		transform(j.begin(), j.end(), j.begin(), ::tolower);
		transform(p.begin(), p.end(), p.begin(), ::tolower);

		if(j != p) {
			ouf.quitf(_wa, "expected: %s, found: %s", j.c_str(), p.c_str());
		}
	}

	quitf(_ok, "");
}

```
</details>

<details>
<summary>Generator sample</summary>

```cpp
#include <bits/stdc++.h>

#include "testlib.h"

int main(int argc, char* argv[]) {
	registerGen(argc, argv, 1);

	std::vector<std::string> manual = {};

	int tci = std::stoi(std::string(argv[1]));
	int mtc = int(manual.size());

	if(tci <= mtc) {
		println(manual[tci - 1]);
		return 0;
	}


	int n = rnd.next(1, 1000);
	println(n);

	while(n--) {
		println(rnd.next(1, 3000));
	}


	// rnd.next(100)    .................random number in range [0, 99]
	// rnd.next(10, 20)    ..............random number in range [10, 20]
	// rnd.next("[A-Za-z0-9]{5,10}")  ...random string of length 5 to 10 with alphanumeric characters
	// rnd.next("A{3,5}B{2,4}")    ......random string with 3 to 5 'A's followed by 2 to 4 'B's
	// rnd.next("one|two|three")    .....random word out of 'one', 'two' and 'three'
	// rnd.next("[1-9][0-9]{99}")    ....random 100-digit number as a string
}

```
</details>

<details>
<summary>Add problem bashrc</summary>

```bash
add-q() {
   if [ -z "$1" ]; then
      echo "Usage: add-q name_of_question"
      return 1
   fi

   local question_name="$1"
   mkdir -p ~/supc/basic/"$question_name"

   echo -e "#include <bits/stdc++.h>\nusing namespace std;\n\nint main() {\n\n\tint tt;\n\tcin >> tt;\n\n\twhile(tt--) {\n\t\t\n\t}\n\n\treturn 0;\n}" | tee ~/supc/basic/$question_name/$question_name.cpp
   echo -e "#include <bits/stdc++.h>\n\n#include \"testlib.h\"\n\nint main(int argc, char* argv[]) {\n\tregisterValidation(argc, argv);\n\n\tint tolTC = 1;\n\t// tolTC = inf.readInt(1, 1000, \"~tolTC~\");\n\t// inf.readEoln();\n\n\tfor(int i = 1; i <= tolTC; i++) {\n\t\tsetTestCase(i);\n\t\tint y = inf.readInt(1, 3000, \"y\");\n\t\tinf.readEoln();\n\t}\n\n\tinf.readEof();\n\n\n\t// vector<int> ints = inf.readInts(sz, mn, mx, \"name\");\n\t// inf.readEof();\n\t// inf.readEoln();\n\t// inf.readSpace();\n}\n" | tee ~/supc/basic/$question_name/validator.cpp
   touch ~/supc/basic/"$question_name"/{gen,checker}.cpp
   echo -e "#include <bits/stdc++.h>\n\n#include \"testlib.h\"\n\n\nint main(int argc, char *argv[]) {\n\tregisterTestlibCmd(argc, argv);\n\n\tint tolTC = 1;\n\t// tolTC = inf.readInt(1, 1000);\n\n\tint curTC = 0;\n\twhile(++curTC <= tolTC) {\n\t\tsetTestCase(curTC);\n\n\t\tpattern ptn(\"[YESyesNOno]+\");\n\n\t\tstd::string j = ans.readLine(ptn, \"j\");\n\t\tstd::string p = ouf.readLine(ptn, \"p\");\n\n\t\ttransform(j.begin(), j.end(), j.begin(), ::tolower);\n\t\ttransform(p.begin(), p.end(), p.begin(), ::tolower);\n\n\t\tif(j != p) {\n\t\t\touf.quitf(_wa, \"expected: %s, found: %s\", j.c_str(), p.c_str());\n\t\t}\n\t}\n\n\tquitf(_ok, \"\");\n}\n" | tee ~/supc/basic/"$question_name"/checker.cpp
   echo -e "#include <bits/stdc++.h>\n\n#include \"testlib.h\"\n\n\nint main(int argc, char* argv[]) {\n\tregisterGen(argc, argv, 1);\n\n\tstd::vector<std::string> manual = {};\n\n\tint tci = std::stoi(std::string(argv[1]));\n\tint mtc = int(manual.size());\n\n\tif(tci <= mtc) {\n\t\tprintln(manual[tci - 1]);\n\t\treturn 0;\n\t}\n\n\n\tint n = rnd.next(1, 1000);\n\tprintln(n);\n\n\twhile(n--) {\n\t\tprintln(rnd.next(1, 3000));\n\t}\n\n\n\t// rnd.next(100)    .................random number in range [0, 99]\n\t// rnd.next(10, 20)    ..............random number in range [10, 20]\n\t// rnd.next(\"[A-Za-z0-9]{5,10}\")  ...random string of length 5 to 10 with alphanumeric characters\n\t// rnd.next(\"A{3,5}B{2,4}\")    ......random string with 3 to 5 'A's followed by 2 to 4 'B's\n\t// rnd.next(\"one|two|three\")    .....random word out of 'one', 'two' and 'three'\n\t// rnd.next(\"[1-9][0-9]{99}\")    ....random 100-digit number as a string\n}\n" | tee ~/supc/basic/"$question_name"/gen.cpp
   touch ~/supc/basic/"$question_name"/"$question_name".cpp
   echo "Files created for question: $question_name"
}
```
</details>







</blockquote>
</details>
<br>



<details>
<summary>Bash Configs</summary>
<blockquote>


<details>
<summary>Shell</summary>

```bash
sudo apt-get install git-all -y
sudo mkdir -p /usr/share/git-core/contrib/completion/
sudo wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -O /usr/share/git-core/contrib/completion/git-prompt.sh
```
```bash
if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
fi

if [ -f /usr/share/bash-completion/completions/git ]; then
  . /usr/share/bash-completion/completions/git
fi

source /usr/share/git-core/contrib/completion/git-prompt.sh
export PATH=$PATH:/usr/bin/git
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]$(__git_ps1 " (%s)")\[\033[00m\]\n\$ '
```
</details>


<details>
<summary>CustomBashRc</summary>

```bash
desktop-entry() {
	while true; do
		read -p "Enter the path to the desktop entry file (or 'exit' to quit): " entry_filename
		if [ "$entry_filename" = "exit" ]; then
			echo "Exiting..."
			return 0
		elif [ -f "/usr/share/applications/$entry_filename.desktop" ]; then
			echo "Desktop entry already exists at $entry_filename"
			return 0
		elif [ -d "/usr/share/applications/$entry_filename.desktop" ]; then
			echo "Path is a directory, please provide a file path."
		elif [ -z "$entry_filename" ]; then
			echo "Path cannot be empty, please provide a valid file path."
		else
			break
		fi
	done

	while true; do
	  	read -p "Enter the name of the application: " app_name
		if [ -z "$app_name" ]; then
			echo "Application name cannot be empty, please provide a valid name."
		else
			break
		fi
	done

	while true; do
		read -p "Enter the executable path: " exec_path
		if [ -z "$exec_path" ]; then
			echo "Executable path cannot be empty, please provide a valid path."
		elif [ ! -f "$exec_path" ]; then
			echo "Executable not found at $exec_path, please provide a valid path."
		elif [ ! -x "$exec_path" ]; then
			echo "File at $exec_path is not executable, please provide a valid executable path."
		else
			break
		fi
	done

	while true; do
		read -p "Enter the icon path (or leave empty for no icon): " icon_path
		if [ -z "$icon_path" ]; then
			icon_path=""
			break
		elif [ ! -f "$icon_path" ]; then
			echo "Icon not found at $icon_path, please provide a valid path or leave empty."
		else
			break
		fi
	done

	{
		echo "[Desktop Entry]"
		echo "Name=$app_name"
		echo "Exec=$exec_path"
		[ -n "$icon_path" ] && echo "Icon=$icon_path"
		echo "Type=Application"
		echo "Categories=Utility;"
		echo "Comment=Custom application entry for $app_name"
	} | sudo tee "/usr/share/applications/$entry_filename.desktop" > /dev/null

	echo "Desktop entry created at /usr/share/applications/$entry_filename.desktop"
	echo "You can now find $app_name in your application menu."
}

authbind-add() {
	if [ -z "$1" ]; then
		echo "Usage: authbind-add <port>"
		return 1
	fi
	sudo touch /etc/authbind/byport/$1
	sudo chown $USER /etc/authbind/byport/$1
	sudo chmod 500 /etc/authbind/byport/$1

	echo "Port $1 added to authbind"
}

authbind-remove() {
	if [ -z "$1" ]; then
	echo "Usage: authbind-remove <port>"
	return 1
	fi
	sudo rm -f /etc/authbind/byport/$1

	echo "Port $1 removed from authbind"
}
```
</details>


</blockquote>
</details>







<br>








<details>
<summary>Server</summary>
<blockquote>


<details>
<summary>Update</summary>

```bash
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y zip apache2 screen mariadb-server mariadb-client curl software-properties-common lsb-release ca-certificates apt-transport-https
```
</details>


<details>
<summary>PHP</summary>

```bash
PHP_VER=8.2
```
```bash
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php$PHP_VER php$PHP_VER-cli php$PHP_VER-common php$PHP_VER-mbstring php$PHP_VER-xml php$PHP_VER-curl php$PHP_VER-mysql php$PHP_VER-zip
sudo update-alternatives --install /usr/bin/php php /usr/bin/php$PHP_VER 100
sudo service apache2 restart 2>/dev/null
```
```bash
sudo update-alternatives --config php
```
</details>


<details>
<summary>Database (MariaDB)</summary>

```bash
sudo mysql_secure_installation
```
```bash
DB_NEW_USER=
```
```bash
DB_NEW_USER_PASS=
```
```bash
mysql -u root -p
```
```bash
CREATE USER '$DB_NEW_USER'@'localhost' IDENTIFIED BY '$DB_NEW_USER_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$DB_NEW_USER'@'localhost';
FLUSH PRIVILEGES;
```
</details>


<details>
<summary>PHPMyAdmin</summary>

```bash
sudo apt-get install phpmyadmin -y
sudo ln -s /usr/share/phpmyadmin /var/www/html/pma
sudo service apache2 reload 2>/dev/null
```
</details>


<details>
<summary>Composer</summary>

```bash
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" == "$ACTUAL_CHECKSUM" ]
then
	php composer-setup.php
	sudo mv composer.phar /usr/local/bin/composer
else
	echo 'ERROR: Invalid installer checksum'
fi
rm composer-setup.php
```
</details>


<details>
<summary>Node.js</summary>

```bash
NODEJS_VERSION_TO_INSTALL=
```
```bash
curl -fsSL https://deb.nodesource.com/setup_$NODEJS_VERSION_TO_INSTALL.x -o nodesource_setup.sh;
sudo -E bash nodesource_setup.sh
sudo apt-get install -y nodejs
node -v
```
</details>


<details>
<summary>Reverse Proxy</summary>

```bash
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer
sudo a2enmod lbmethod_byrequests
```
```bash
sudo systemctl restart apache2
```
```bash
sudo nano /etc/apache2/sites-available/000-default.conf
```
```bash
<VirtualHost *:80>
	ServerName DOMAIN_NAME
	ProxyPreserveHost On
	ProxyPass / http://127.0.0.1:PORT/
	ProxyPassReverse / http://127.0.0.1:PORT/
</VirtualHost>
```
```bash
sudo systemctl restart apache2
```
</details>


<details>
<summary>Authbind</summary>

```bash
sudo apt install authbind -y
sudo chmod +x /usr/bin/authbind
sudo chown $USER /usr/bin/authbind
```
```bash
sudo systemctl restart apache2
```
```bash
sudo nano /etc/apache2/sites-available/000-default.conf
```
```bash
<VirtualHost *:80>
	ServerName DOMAIN_NAME
	ProxyPreserveHost On
	ProxyPass / http://127.0.0.1:PORT/
	ProxyPassReverse / http://127.0.0.1:PORT/
</VirtualHost>
```
```bash
sudo systemctl restart apache2
```
</details>




</blockquote>
</details>


<details>
<summary>Mount drive read write mode</summary>

```bash
sudo mount -o rw,uid=$(id -u),gid=$(id -g),user,exec,umask=003,blksize=4096 /dev/sdX1 /media/my_drive/
```
get user id from `id` command
</details>



















<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
.
