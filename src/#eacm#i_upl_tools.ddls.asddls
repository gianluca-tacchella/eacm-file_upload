@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'eACM Upload Tools (RAP host)'
define root view entity /EACM/I_UPL_TOOLS
  as select from /eacm/upl_tools
{
  key id
}
