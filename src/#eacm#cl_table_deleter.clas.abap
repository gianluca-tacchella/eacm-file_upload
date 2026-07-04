CLASS /eacm/cl_table_deleter DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ts_result,
        upload_id     TYPE sysuuid_x16,
        status        TYPE c LENGTH 1,
        rows_deleted  TYPE i,
        rows_in_file  TYPE i,
        message       TYPE string,
      END OF ts_result,
      BEGIN OF ts_request,
        table     TYPE tabname,
        rows_json TYPE string,
        transport TYPE trkorr,
      END OF ts_request.

    CLASS-METHODS delete_rows
      IMPORTING is_request       TYPE ts_request
      RETURNING VALUE(rs_result) TYPE ts_result.

  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS:
      mc_namespace TYPE string VALUE `/EACM/`,
      BEGIN OF mc_status,
        success TYPE c LENGTH 1 VALUE 'S',
        error   TYPE c LENGTH 1 VALUE 'E',
      END OF mc_status.

    CLASS-METHODS validate
      IMPORTING iv_table TYPE tabname
      RAISING   /eacm/cx_upload.

    CLASS-METHODS check_authorization
      IMPORTING iv_table TYPE tabname
      RAISING   /eacm/cx_upload.

    CLASS-METHODS parse_rows
      IMPORTING iv_rows_json TYPE string
                iv_table     TYPE tabname
      EXPORTING er_data      TYPE REF TO data
                ev_count     TYPE i
      RAISING   /eacm/cx_upload.

    CLASS-METHODS write_log
      IMPORTING is_result  TYPE ts_result
                is_request TYPE ts_request.

ENDCLASS.



CLASS /EACM/CL_TABLE_DELETER IMPLEMENTATION.


  METHOD delete_rows.
    TRY.
        rs_result-upload_id = cl_system_uuid=>create_uuid_x16_static( ).

        validate( is_request-table ).
        check_authorization( is_request-table ).

        IF /eacm/cl_transport_helper=>is_customizing( is_request-table ) = abap_true
           AND is_request-transport IS INITIAL.
          RAISE EXCEPTION NEW /eacm/cx_upload(
            iv_table  = is_request-table
            iv_detail = |Transport is required for customizing table { is_request-table }| ).
        ENDIF.

        parse_rows( EXPORTING iv_rows_json = is_request-rows_json
                              iv_table     = is_request-table
                    IMPORTING er_data      = DATA(lr_data)
                              ev_count     = DATA(lv_count) ).

        rs_result-rows_in_file = lv_count.
        IF lv_count = 0.
          RAISE EXCEPTION NEW /eacm/cx_upload(
            iv_table  = is_request-table
            iv_detail = `No rows provided for deletion` ).
        ENDIF.

        FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
        ASSIGN lr_data->* TO <lt_data>.

        TRY.
            DATA(lv_safe_table) = cl_abap_dyn_prg=>check_table_name_str(
                                    val = is_request-table packages = '/EACM/CORE' incl_sub_packages = abap_true ).
            DELETE (lv_safe_table) FROM TABLE @<lt_data>.
            rs_result-rows_deleted = sy-dbcnt.
          CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
            RAISE EXCEPTION NEW /eacm/cx_upload(
              previous  = lx_sql
              iv_table  = is_request-table
              iv_detail = |DB delete error: { lx_sql->get_text( ) }| ).
        ENDTRY.

        IF is_request-transport IS NOT INITIAL.
          /eacm/cl_transport_helper=>record_entries(
            iv_transport = is_request-transport
            iv_table     = is_request-table
            ir_data      = lr_data ).
        ENDIF.

        rs_result-status  = mc_status-success.
        rs_result-message = |{ rs_result-rows_deleted } row(s) deleted from { is_request-table }|.

      CATCH /eacm/cx_upload INTO DATA(lx_del).
        rs_result-status  = mc_status-error.
        rs_result-message = lx_del->get_text( ).
      CATCH cx_root INTO DATA(lx_root).
        rs_result-status  = mc_status-error.
        rs_result-message = lx_root->get_text( ).
    ENDTRY.

    write_log( is_result = rs_result is_request = is_request ).
  ENDMETHOD.


  METHOD validate.
    IF strlen( iv_table ) < 6 OR substring( val = iv_table off = 0 len = 6 ) <> mc_namespace.
      RAISE EXCEPTION NEW /eacm/cx_upload(
        iv_table  = iv_table
        iv_detail = |Table must be in { mc_namespace } namespace| ).
    ENDIF.

    TRY.
        DATA(lo_descr) = cl_abap_typedescr=>describe_by_name( iv_table ).
        IF lo_descr->kind <> cl_abap_typedescr=>kind_struct.
          RAISE EXCEPTION NEW /eacm/cx_upload(
            iv_table  = iv_table
            iv_detail = |{ iv_table } is not a structured table type| ).
        ENDIF.
      CATCH cx_sy_rtti_syntax_error INTO DATA(lx_rtti).
        RAISE EXCEPTION NEW /eacm/cx_upload(
          previous  = lx_rtti
          iv_table  = iv_table
          iv_detail = |Table { iv_table } does not exist| ).
    ENDTRY.
  ENDMETHOD.


  METHOD check_authorization.
*    AUTHORITY-CHECK OBJECT '/EACM/UPL'
*      ID 'TABNAME' FIELD iv_table
*      ID 'ACTVT'   FIELD '06'.
*    IF sy-subrc = 4.
*      RAISE EXCEPTION NEW /eacm/cx_upload(
*        iv_table  = iv_table
*        iv_detail = |User not authorized to delete from table { iv_table }| ).
*    ENDIF.
  ENDMETHOD.


  METHOD parse_rows.
    CREATE DATA er_data TYPE STANDARD TABLE OF (iv_table).
    FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
    ASSIGN er_data->* TO <lt_data>.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json = iv_rows_json pretty_name = /ui2/cl_json=>pretty_mode-none
          CHANGING  data = <lt_data> ).
      CATCH cx_root INTO DATA(lx_json).
        RAISE EXCEPTION NEW /eacm/cx_upload(
          previous  = lx_json
          iv_table  = iv_table
          iv_detail = |Row JSON parse failed: { lx_json->get_text( ) }| ).
    ENDTRY.

    ev_count = lines( <lt_data> ).
  ENDMETHOD.


  METHOD write_log.
    DATA ls_log TYPE /eacm/upl_log.
    ls_log-upload_id     = is_result-upload_id.
    GET TIME STAMP FIELD ls_log-uploaded_at.
    ls_log-uploaded_by   = sy-uname.
    ls_log-target_table  = is_request-table.
    ls_log-file_name     = `(delete)`.
    ls_log-file_type     = 'DEL'.
    ls_log-upload_mode   = 'DELETE'.
    ls_log-rows_in_file  = is_result-rows_in_file.
    ls_log-rows_inserted = is_result-rows_deleted.
    ls_log-status        = is_result-status.
    ls_log-message       = is_result-message.
    ls_log-transport     = is_request-transport.

    INSERT /eacm/upl_log FROM @ls_log.
  ENDMETHOD.
ENDCLASS.
