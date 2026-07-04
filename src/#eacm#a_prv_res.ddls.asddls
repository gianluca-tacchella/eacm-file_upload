@EndUserText.label: 'Preview Response'
define abstract entity /EACM/A_PRV_RES
{
  table_name   : tabname;
  row_count    : abap.int4;
  columns_json : abap.string(0);
  keys_json    : abap.string(0);
  rows_json    : abap.string(0);
}
