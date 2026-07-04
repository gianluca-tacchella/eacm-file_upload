@EndUserText.label: 'Upload Request'
define abstract entity /EACM/A_UPL_REQ
{
  target_table : tabname;
  file_name    : abap.char(255);
  file_type    : abap.char(4);
  upload_mode  : abap.char(10);
  file_content : abap.string(0);
  transport    : trkorr;
}
