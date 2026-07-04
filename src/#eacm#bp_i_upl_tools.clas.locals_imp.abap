CLASS lhc_uploadtools DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_tables FOR READ
      IMPORTING keys FOR FUNCTION uploadtools~gettables RESULT result.

    METHODS preview_table FOR READ
      IMPORTING keys FOR FUNCTION uploadtools~previewtable RESULT result.

    METHODS get_transports FOR READ
      IMPORTING keys FOR FUNCTION uploadtools~gettransports RESULT result.

    METHODS download_template FOR MODIFY
      IMPORTING keys FOR ACTION uploadtools~downloadtemplate RESULT result.

    METHODS delete_rows FOR MODIFY
      IMPORTING keys FOR ACTION uploadtools~deleterows RESULT result.

ENDCLASS.

CLASS lhc_uploadtools IMPLEMENTATION.

  METHOD get_tables.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      DATA(lt_tables) = /eacm/cl_table_directory=>list_tables(
        iv_prefix = CONV string( <ls_key>-%param-prefix ) ).

      LOOP AT lt_tables ASSIGNING FIELD-SYMBOL(<ls_tab>).
        APPEND VALUE #(
          %cid   = <ls_key>-%cid
          %param = VALUE #(
            table_name  = <ls_tab>-table_name
            description = <ls_tab>-description
            category    = <ls_tab>-category
            field_count = <ls_tab>-field_count ) ) TO result.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD preview_table.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      TRY.
          DATA(ls_res) = /eacm/cl_table_preview=>read(
            iv_table        = CONV tabname( <ls_key>-%param-table_name )
            iv_top          = <ls_key>-%param-top
            iv_filters_json = <ls_key>-%param-filters_json ).

          APPEND VALUE #(
            %cid   = <ls_key>-%cid
            %param = VALUE #(
              table_name   = ls_res-table_name
              row_count    = ls_res-row_count
              columns_json = ls_res-columns_json
              keys_json    = ls_res-keys_json
              rows_json    = ls_res-rows_json ) ) TO result.

        CATCH /eacm/cx_upload INTO DATA(lx_prev).
          APPEND VALUE #(
            %cid   = <ls_key>-%cid
            %param = VALUE #(
              table_name   = <ls_key>-%param-table_name
              row_count    = 0
              columns_json = `[]`
              keys_json    = `[]`
              rows_json    = |\{"error":"{ lx_prev->get_text( ) }"\}| ) ) TO result.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_transports.
    DATA(lt_trps) = /eacm/cl_transport_helper=>list_open( ).
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      LOOP AT lt_trps ASSIGNING FIELD-SYMBOL(<ls_trp>).
        APPEND VALUE #(
          %cid   = <ls_key>-%cid
          %param = VALUE #(
            trkorr      = <ls_trp>-trkorr
            description = <ls_trp>-description
            target      = <ls_trp>-target
            owner       = <ls_trp>-owner ) ) TO result.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_rows.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      DATA(ls_res) = /eacm/cl_table_deleter=>delete_rows(
        VALUE #(
          table     = CONV tabname( <ls_key>-%param-table_name )
          rows_json = <ls_key>-%param-rows_json
          transport = CONV trkorr( <ls_key>-%param-transport ) ) ).

      APPEND VALUE #(
        %cid   = <ls_key>-%cid
        %param = VALUE #(
          upload_id    = ls_res-upload_id
          status       = ls_res-status
          rows_in_file = ls_res-rows_in_file
          rows_deleted = ls_res-rows_deleted
          message      = ls_res-message ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD download_template.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      TRY.
          DATA(ls_res) = /eacm/cl_template_builder=>build(
            iv_table     = CONV tabname( <ls_key>-%param-table_name )
            iv_file_type = CONV string( <ls_key>-%param-file_type ) ).

          APPEND VALUE #(
            %cid   = <ls_key>-%cid
            %param = VALUE #(
              file_name      = ls_res-file_name
              file_type      = ls_res-file_type
              content_base64 = ls_res-content_base64 ) ) TO result.

        CATCH /eacm/cx_upload INTO DATA(lx_tpl).
          APPEND VALUE #(
            %cid   = <ls_key>-%cid
            %param = VALUE #(
              file_name = |error.txt|
              file_type = 'CSV'
              content_base64 = cl_web_http_utility=>encode_x_base64(
                CONV xstring( cl_abap_conv_codepage=>create_out( )->convert(
                  lx_tpl->get_text( ) ) ) ) ) ) TO result.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
