CLASS /eacm/cl_table_uploader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF mc_mode,
        insert  TYPE string VALUE `INSERT`,
        upsert  TYPE string VALUE `UPSERT`,
        replace TYPE string VALUE `REPLACE`,
      END OF mc_mode,
      BEGIN OF mc_status,
        success TYPE c LENGTH 1 VALUE 'S',
        error   TYPE c LENGTH 1 VALUE 'E',
      END OF mc_status.

    TYPES:
      BEGIN OF ts_result,
        upload_id     TYPE sysuuid_x16,
        status        TYPE c LENGTH 1,
        rows_in_file  TYPE i,
        rows_inserted TYPE i,
        message       TYPE string,
      END OF ts_result.

    TYPES:
      BEGIN OF ts_upload_req,
        table        TYPE tabname,
        file_name    TYPE string,
        file_type    TYPE string,
        file_content TYPE xstring,
        mode         TYPE string,
        transport    TYPE trkorr,
      END OF ts_upload_req.

    CLASS-METHODS upload
      IMPORTING is_request       TYPE ts_upload_req
      RETURNING VALUE(rs_result) TYPE ts_result.

  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS mc_namespace TYPE string VALUE `/EACM/`.

    CLASS-METHODS validate_inputs
      IMPORTING iv_table TYPE tabname
                iv_mode  TYPE string
      RAISING   /eacm/cx_upload.

    CLASS-METHODS check_authorization
      IMPORTING iv_table TYPE tabname
                iv_mode  TYPE string
      RAISING   /eacm/cx_upload.

    CLASS-METHODS build_data_table
      IMPORTING it_rows          TYPE /eacm/if_file_parser=>ty_matrix
                iv_table         TYPE tabname
      EXPORTING er_data          TYPE REF TO data
                ev_row_count     TYPE i
      RAISING   /eacm/cx_upload.

    CLASS-METHODS persist
      IMPORTING ir_data            TYPE REF TO data
                iv_table           TYPE tabname
                iv_mode            TYPE string
      RETURNING VALUE(rv_inserted) TYPE i
      RAISING   /eacm/cx_upload.

    CLASS-METHODS write_log
      IMPORTING is_result  TYPE ts_result
                is_request TYPE ts_upload_req.

ENDCLASS.



CLASS /EACM/CL_TABLE_UPLOADER IMPLEMENTATION.


  METHOD upload.
    TRY.
        rs_result-upload_id = cl_system_uuid=>create_uuid_x16_static( ).

        validate_inputs( iv_table = is_request-table iv_mode = is_request-mode ).
        check_authorization( iv_table = is_request-table iv_mode = is_request-mode ).

        IF /eacm/cl_transport_helper=>is_customizing( is_request-table ) = abap_true
           AND is_request-transport IS INITIAL.
          RAISE EXCEPTION NEW /eacm/cx_upload(
            iv_table  = is_request-table
            iv_detail = |Transport is required for customizing table { is_request-table }| ).
        ENDIF.

        DATA(lo_parser) = /eacm/cl_parser_factory=>create( is_request-file_type ).
        DATA(lt_rows) = lo_parser->parse( is_request-file_content ).

        IF lines( lt_rows ) < 2.
          RAISE EXCEPTION NEW /eacm/cx_upload(
            iv_detail = `File must contain at least header row and one data row` ).
        ENDIF.

        build_data_table( EXPORTING it_rows = lt_rows iv_table = is_request-table
                          IMPORTING er_data = DATA(lr_data) ev_row_count = DATA(lv_count) ).

        rs_result-rows_in_file  = lv_count.
        rs_result-rows_inserted = persist( ir_data = lr_data iv_table = is_request-table iv_mode = is_request-mode ).

        IF is_request-transport IS NOT INITIAL.
          /eacm/cl_transport_helper=>record_entries(
            iv_transport = is_request-transport
            iv_table     = is_request-table
            ir_data      = lr_data ).
        ENDIF.

        rs_result-status  = mc_status-success.
        rs_result-message = |{ rs_result-rows_inserted } row(s) processed in mode { is_request-mode }|.

      CATCH /eacm/cx_upload INTO DATA(lx_upload).
        rs_result-status  = mc_status-error.
        rs_result-message = lx_upload->get_text( ).
      CATCH cx_root INTO DATA(lx_root).
        rs_result-status  = mc_status-error.
        rs_result-message = lx_root->get_text( ).
    ENDTRY.

    write_log( is_result = rs_result is_request = is_request ).
  ENDMETHOD.


  METHOD validate_inputs.
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

    IF iv_mode <> mc_mode-insert AND iv_mode <> mc_mode-upsert AND iv_mode <> mc_mode-replace.
      RAISE EXCEPTION NEW /eacm/cx_upload(
        iv_detail = |Mode must be INSERT, UPSERT or REPLACE (got { iv_mode })| ).
    ENDIF.
  ENDMETHOD.


  METHOD check_authorization.
    DATA lv_actvt TYPE activ_auth.
    lv_actvt = SWITCH #( iv_mode
      WHEN mc_mode-insert  THEN '02'
      WHEN mc_mode-upsert  THEN '24'
      WHEN mc_mode-replace THEN '06' ).

*    AUTHORITY-CHECK OBJECT '/EACM/UPL'
*      ID 'TABNAME' FIELD iv_table
*      ID 'ACTVT'   FIELD lv_actvt.
*    IF sy-subrc = 4.
*      RAISE EXCEPTION NEW /eacm/cx_upload(
*        iv_table  = iv_table
*        iv_detail = |User not authorized to { iv_mode } table { iv_table }| ).
*    ENDIF.
  ENDMETHOD.


  METHOD build_data_table.
    DATA(lo_type) = cl_abap_typedescr=>describe_by_name( iv_table ).
    DATA(lo_struct) = CAST cl_abap_structdescr( lo_type ).

    FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
    CREATE DATA er_data TYPE STANDARD TABLE OF (iv_table).
    ASSIGN er_data->* TO <lt_data>.

    DATA lr_row TYPE REF TO data.
    CREATE DATA lr_row TYPE (iv_table).
    ASSIGN lr_row->* TO FIELD-SYMBOL(<ls_row>).

    DATA(ls_header) = VALUE /eacm/if_file_parser=>ty_row( ).
    READ TABLE it_rows INTO ls_header INDEX 1.

    TYPES: BEGIN OF ts_col_map,
             col_idx    TYPE i,
             field_name TYPE abap_compname,
           END OF ts_col_map.
    DATA lt_map TYPE STANDARD TABLE OF ts_col_map WITH EMPTY KEY.

    LOOP AT ls_header ASSIGNING FIELD-SYMBOL(<lv_header>).
      DATA(lv_field_up) = to_upper( condense( val = <lv_header> ) ).
      IF lv_field_up IS INITIAL.
        CONTINUE.
      ENDIF.
      IF line_exists( lo_struct->components[ name = lv_field_up ] ).
        APPEND VALUE #( col_idx = sy-tabix field_name = lv_field_up ) TO lt_map.
      ENDIF.
    ENDLOOP.

    IF lt_map IS INITIAL.
      RAISE EXCEPTION NEW /eacm/cx_upload(
        iv_table  = iv_table
        iv_detail = `No header columns match target table fields` ).
    ENDIF.

    LOOP AT it_rows ASSIGNING FIELD-SYMBOL(<ls_src>) FROM 2.
      CLEAR <ls_row>.
      DATA(lv_row_no) = sy-tabix.
      LOOP AT lt_map INTO DATA(ls_map).
        READ TABLE <ls_src> INTO DATA(lv_val) INDEX ls_map-col_idx.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        ASSIGN COMPONENT ls_map-field_name OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_target>).
        IF sy-subrc = 0.
          TRY.
              <lv_target> = lv_val.
            CATCH cx_sy_conversion_no_number cx_sy_conversion_error INTO DATA(lx_conv).
              RAISE EXCEPTION NEW /eacm/cx_upload(
                previous  = lx_conv
                iv_table  = iv_table
                iv_row    = lv_row_no
                iv_column = CONV #( ls_map-field_name )
                iv_detail = |Conversion error for value '{ lv_val }'| ).
          ENDTRY.
        ENDIF.
      ENDLOOP.
      INSERT <ls_row> INTO TABLE <lt_data>.
    ENDLOOP.

    ev_row_count = lines( <lt_data> ).
  ENDMETHOD.


  METHOD persist.
    FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
    ASSIGN ir_data->* TO <lt_data>.

    TRY.
        DATA lv_safe_table TYPE string.
        TRY.
            lv_safe_table = cl_abap_dyn_prg=>check_table_name_str(
                              val = iv_table packages = '/EACM/CORE' incl_sub_packages = abap_true ).
          CATCH cx_abap_not_a_table cx_abap_not_in_package INTO DATA(lx_tab).
            RAISE EXCEPTION NEW /eacm/cx_upload(
              previous = lx_tab iv_table = iv_table
              iv_detail = |Table { iv_table } is not a valid table in /EACM/CORE| ).
        ENDTRY.
        CASE iv_mode.
          WHEN mc_mode-insert.
            INSERT (lv_safe_table) FROM TABLE @<lt_data>.
          WHEN mc_mode-upsert.
            MODIFY (lv_safe_table) FROM TABLE @<lt_data>.
          WHEN mc_mode-replace.
            MODIFY (lv_safe_table) FROM TABLE @<lt_data>.
        ENDCASE.
        rv_inserted = sy-dbcnt.
      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
        RAISE EXCEPTION NEW /eacm/cx_upload(
          previous  = lx_sql
          iv_table  = iv_table
          iv_detail = |DB error: { lx_sql->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.


  METHOD write_log.
    DATA ls_log TYPE /eacm/upl_log.
    ls_log-upload_id     = is_result-upload_id.
    GET TIME STAMP FIELD ls_log-uploaded_at.
    ls_log-uploaded_by   = sy-uname.
    ls_log-target_table  = is_request-table.
    ls_log-file_name     = is_request-file_name.
    ls_log-file_type     = is_request-file_type.
    ls_log-upload_mode   = is_request-mode.
    ls_log-rows_in_file  = is_result-rows_in_file.
    ls_log-rows_inserted = is_result-rows_inserted.
    ls_log-status        = is_result-status.
    ls_log-message       = is_result-message.
    ls_log-transport     = is_request-transport.

    INSERT /eacm/upl_log FROM @ls_log.
  ENDMETHOD.
ENDCLASS.
