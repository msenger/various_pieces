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

Tento skript pracuje s daty ze serveru labgpx.cz, ke kterému musíte mít přístup (username a heslo). Tento přístup se dá zadat na příkazové řádce, ale lepší bude uložit username a heslo do souboru authfile.txt (jehož vzorem je template.authfile.txt, kde je vidět i další vyžadovaný údaj, consumer key).

get-lab.pl
==========

Vytáhne z LAB-API data pro všechny labky dané série (otázky, obrázky a texty z denníčků).
Možné volby zobrazíte takto: perl get-lab.pl -help.
Nespojuje se s labgpx.cz, takže nepotřebuje autorizační soubor authfile.txt. Ale potřebuje údaj consumer key, a ten se bere z příkazové řádky nebo také ze souboru authfile.txt.

wrap-and-email.pl
=================

Používá se k odeslání toho, co zjistí hledač nových sérií (skript find-mew-labs.pl). Emaily se po každém ukončení hledače posílají buď všem, kdo pak nově nalezené série publikuje, nebo adminovi, objevila-li se nějaká chyba (tento druhý případ se indikuje parametrem "-admin". Adresáty emilů i SMTP podrobnosti se dají skriptu zadat parametry pčíkazové řádky. Možné volby se zobrazí takto: perl wrap-and-email.pl -help.

Co zadat crontabu (k pravidelnému opakování hledání nových sérií)
=================================================================

Under Windows: notify.bat
Under Linux:   export ERR_TMP=err.tmp ; perl find-new-labs.pl -nget -q 2> $ERR_TMP | perl wrap-and-email.pl ; perl wrap-and-email.pl -admin < $ERR_TMP











