@EndUserText.label: 'Delete Rows Request'
define abstract entity /EACM/A_DEL_REQ
{
  table_name : tabname;
  rows_json  : abap.string(0);
  transport  : trkorr;
}
