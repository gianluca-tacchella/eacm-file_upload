@EndUserText.label: 'Upload Result'
define abstract entity /EACM/A_UPL_RES
{
  upload_id     : sysuuid_x16;
  status        : abap.char(1);
  rows_in_file  : abap.int4;
  rows_inserted : abap.int4;
  message       : abap.string(0);
}
