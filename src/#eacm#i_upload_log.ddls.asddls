@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'eACM Upload Log'
@Metadata.allowExtensions: true
define root view entity /EACM/I_UPLOAD_LOG
  as select from /eacm/upl_log
{
  key upload_id,
      uploaded_at,
      uploaded_by,
      target_table,
      file_name,
      file_type,
      upload_mode,
      rows_in_file,
      rows_inserted,
      status,
      message,
      transport
}
