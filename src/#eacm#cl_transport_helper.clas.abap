CLASS /eacm/cl_transport_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ts_transport,
        trkorr      TYPE trkorr,
        description TYPE c LENGTH 60,
        target      TYPE c LENGTH 10,
        owner       TYPE syuname,
      END OF ts_transport,
      tt_transport TYPE STANDARD TABLE OF ts_transport WITH EMPTY KEY.

    CLASS-METHODS is_customizing
      IMPORTING iv_table       TYPE tabname
      RETURNING VALUE(rv_cust) TYPE abap_bool.

    CLASS-METHODS list_open
      RETURNING VALUE(rt_transports) TYPE tt_transport.

    CLASS-METHODS record_entries
      IMPORTING iv_transport TYPE trkorr
                iv_table     TYPE tabname
                ir_data      TYPE REF TO data
      RAISING   /eacm/cx_upload.

ENDCLASS.



CLASS /EACM/CL_TRANSPORT_HELPER IMPLEMENTATION.


  METHOD is_customizing.
    TRY.
        DATA(lo_table) = xco_cp_abap_dictionary=>database_table( CONV #( iv_table ) ).
        IF lo_table->exists( ) = abap_false.
          rv_cust = abap_false.
          RETURN.
        ENDIF.
        DATA(lv_class) = lo_table->content( )->get_delivery_class( )->value.
        rv_cust = xsdbool( lv_class = 'C' OR lv_class = 'G' OR lv_class = 'E' ).
      CATCH cx_root.
        rv_cust = abap_false.
    ENDTRY.
  ENDMETHOD.


  METHOD list_open.
    TRY.
        DATA(lt_filters) = VALUE sxco_t_tr_filters(
          ( xco_cp_transport=>filter->status(
              xco_cp_transport=>status->modifiable ) )
          ( xco_cp_transport=>filter->owner(
              xco_cp_abap_sql=>constraint->equal( CONV string( sy-uname ) ) ) )
          ( xco_cp_transport=>filter->kind(
              xco_cp_transport=>kind->request ) )
          ( xco_cp_transport=>filter->type(
              xco_cp_transport=>type->customizing_request ) ) ).

        DATA(lt_transports) = xco_cp_cts=>transports->where( lt_filters
                                )->resolve( xco_cp_transport=>resolution->request ).

        LOOP AT lt_transports INTO DATA(lo_transport).
          DATA(lo_request) = lo_transport->get_request( ).
          DATA(ls_props)   = lo_request->properties( )->get( ).

          APPEND VALUE #(
            trkorr      = lo_request->value
            description = ls_props-short_description
            target      = COND #( WHEN ls_props-target IS BOUND
                                  THEN ls_props-target->value )
            owner       = COND #( WHEN ls_props-owner IS BOUND
                                  THEN ls_props-owner->name ) ) TO rt_transports.
        ENDLOOP.
      CATCH cx_root.
        CLEAR rt_transports.
    ENDTRY.
  ENDMETHOD.


  METHOD record_entries.
    IF iv_transport IS INITIAL.
      RETURN.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
