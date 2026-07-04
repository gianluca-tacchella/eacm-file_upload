@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'eACM Upload Log'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.usageType.serviceQuality: #D
@ObjectModel.usageType.sizeCategory: #S
@ObjectModel.usageType.dataClass: #TRANSACTIONAL
@UI.headerInfo: { typeName: 'Upload', typeNamePlural: 'Uploads', title: { type: #STANDARD, value: 'file_name' } }
define root view entity /EACM/C_UPLOAD_LOG
  provider contract transactional_query
  as projection on /EACM/I_UPLOAD_LOG
{
      @UI.facet: [
        { id: 'Identification', type: #IDENTIFICATION_REFERENCE, label: 'Upload', position: 10 }
      ]
      @UI.lineItem:      [ { position: 10, label: 'Upload ID' } ]
      @UI.identification:[ { position: 10 } ]
  key upload_id,

      @UI.lineItem:      [ { position: 20, label: 'Uploaded At' } ]
      @UI.identification:[ { position: 20 } ]
      uploaded_at,

      @UI.lineItem:      [ { position: 30, label: 'User' } ]
      @UI.identification:[ { position: 30 } ]
      uploaded_by,

      @UI.lineItem:      [ { position: 40, label: 'Target Table' } ]
      @UI.identification:[ { position: 40 } ]
      @UI.selectionField:[ { position: 10 } ]
      target_table,

      @UI.lineItem:      [ { position: 50, label: 'File' } ]
      @UI.identification:[ { position: 50 } ]
      file_name,

      @UI.lineItem:      [ { position: 60, label: 'Type' } ]
      file_type,

      @UI.lineItem:      [ { position: 70, label: 'Mode' } ]
      upload_mode,

      @UI.lineItem:      [ { position: 80, label: 'Rows' } ]
      rows_in_file,

      @UI.lineItem:      [ { position: 90, label: 'Inserted' } ]
      rows_inserted,

      @UI.lineItem:      [ { position: 100, label: 'Status', criticality: 'status' } ]
      @UI.selectionField:[ { position: 20 } ]
      status,

      @UI.lineItem:      [ { position: 110, label: 'Message' } ]
      @UI.identification:[ { position: 110 } ]
      message,

      @UI.lineItem:      [ { position: 120, label: 'Transport' } ]
      @UI.identification:[ { position: 120 } ]
      transport
}
