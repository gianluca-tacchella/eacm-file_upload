@EndUserText.label: 'Template Response'
define abstract entity /EACM/A_TPL_RES
{
  file_name      : abap.char(255);
  file_type      : abap.char(4);
  content_base64 : abap.string(0);
}
