@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS Help ZPRDO/ZPRDP'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity /EACM/upl_H_dodp
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: '/EACM/UPL_D_DODP')
{
      @UI.hidden: true
  key domain_name,

      @UI.hidden: true
  key value_position,
      @Semantics.language: true
      @UI.hidden: true
  key language,
      @UI.hidden: true
      value_low,
      @Semantics.text: true
      text
}
