CLASS /eacm/cl_upl_tools_qry DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.



CLASS /EACM/CL_UPL_TOOLS_QRY IMPLEMENTATION.


  METHOD if_rap_query_provider~select.
    io_response->set_total_number_of_records( 0 ).
  ENDMETHOD.
ENDCLASS.
