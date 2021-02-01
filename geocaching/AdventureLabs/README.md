Skripty (command-line programy) pro práci s AdventureLab keškami (labkami).

Tyto skripty jsou vesměs napsané v Perlu, pod Windows používám "strawberry" distribuci Perlu (https://strawberryperl.com/). Je třeba k nim při prvním použití doinstalovat dodatečné Perl module. Což je nejlépe udělat pomoci "cpanm" (ten by měl být součástí strawerry Perl). Asi takto:

cpanm JSON
cpanm Text::CSV
...
...

Skripty se pod windows pak spouštějí takto: perl <jméno skriptu>, např. perl find-new-labs.pl.

find-new-labs.pl
================

Najde nové série labek v daném okolí, vypíše jejich labid, případně i spustí pro každou z nich další skript get-lab.pl. Parametry pro spuštění se zobrazí takto: perl find-new-labs.pl -help.

Tento skript pracuje s daty ze serveru labgpx.cz, ke kterému musíte mít přístup (username a heslo). Tento přístup se dá zadat na příkazové řádce, ale lepší bude uložit username a heslo do souboru authfile.txt (jehož vzorem je template.authfile.txt).

get-lab.pl
==========

Vytáhne z API data pro všechny labky dané série (otázky, obrázky a texty z denníčků).
Možné volby zobrazíte takto: perl get-lab.pl -help.
Nespojuje se s labgpx.cz, takže nepotřebuje autorizační soubor authfile.txt.

smart-to-labid.pl
=================

Převede zadaný smart link na labid. Volby ukáže: perl smart-to-labid.pl -help.

wrap-and-email.pl
=================

Takhle to funguje v crontabu:

15 6-23 * * * cd /home/senger/alabs ; perl find-new-labs.pl -nget -q 2>&1 | perl wrap-and-email.pl











