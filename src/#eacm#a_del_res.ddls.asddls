@EndUserText.label: 'Delete Rows Response'
define abstract entity /EACM/A_DEL_RES
{
  upload_id    : sysuuid_x16;
  status       : abap.char(1);
  rows_in_file : abap.int4;
  rows_deleted : abap.int4;
  message      : abap.string(0);
}
