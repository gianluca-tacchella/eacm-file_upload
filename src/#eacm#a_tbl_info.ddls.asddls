@EndUserText.label: 'Table Info (Autocomplete)'
define abstract entity /EACM/A_TBL_INFO
{
  table_name  : tabname;
  description : abap.char(60);
  category    : abap.char(20);
  field_count : abap.int4;
}
