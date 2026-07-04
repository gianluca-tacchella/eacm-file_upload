@EndUserText.label: 'Preview Request'
define abstract entity /EACM/A_PRV_REQ
{
  table_name   : tabname;
  top          : abap.int4;
  filters_json : abap.string(0);
}
