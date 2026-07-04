@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: '/EACM/UPL_DODP'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity /EACM/C_UPL_DODP
  provider contract transactional_query
  as projection on /EACM/I_UPL_DODP
  association [1..1] to /EACM/I_UPL_DODP as _BaseEntity on $projection.FileID = _BaseEntity.FileID
{
  key FileID,
      EndUser,
      FileStatus,
      @Semantics.largeObject: {
          mimeType: 'Mimetype',
          fileName: 'Filename',
          acceptableMimeTypes: [ 'text/plain', 'text/csv' ],
          contentDispositionPreference: #INLINE
      }
      Attachment,
      Mimetype,
      Filename,
      Dodp,
      TestMode,
      Tbdel,
      @Semantics: {
        user.createdBy: true
      }
      LocalCreatedBy,
      @Semantics: {
        systemDateTime.createdAt: true
      }
      LocalCreatedAt,
      @Semantics: {
        user.localInstanceLastChangedBy: true
      }
      LocalLastChangedBy,
      @Semantics: {
        systemDateTime.localInstanceLastChangedAt: true
      }
      LocalLastChangedAt,
      @Semantics: {
        systemDateTime.lastChangedAt: true
      }
      LastChangedAt,
      _BaseEntity
}
