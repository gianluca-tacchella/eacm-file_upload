@EndUserText.label: 'Transport Info'
define abstract entity /EACM/A_TRP_INFO
{
  trkorr      : trkorr;
  description : abap.char(60);
  target      : abap.char(10);
  owner       : syuname;
}
