@ECHO OFF
set MY_ERR=err.tmp
set MY_STD=std.tmp
perl test1.pl -stderr -stdout 2> "%MY_ERR%" 1> "%MY_STD%"
perl wrap-and-email.pl < "%MY_STD%"
perl wrap-and-email.pl -admin < "%MY_ERR%"
