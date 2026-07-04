CLASS lhc_uploadlog DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR uploadlog RESULT result.
    METHODS upload_file FOR MODIFY
      IMPORTING keys FOR ACTION uploadlog~uploadfile RESULT result.
ENDCLASS.

CLASS lhc_uploadlog IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD upload_file.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      DATA lv_content_x TYPE xstring.
      TRY.
          lv_content_x = cl_web_http_utility=>decode_x_base64( <ls_key>-%param-file_content ).
        CATCH cx_root INTO DATA(lx_decode).
          APPEND VALUE #(
            %cid  = <ls_key>-%cid
            %param = VALUE #(
              status  = 'E'
              message = |Base64 decode failed: { lx_decode->get_text( ) }| ) ) TO result.
          CONTINUE.
      ENDTRY.

      DATA(ls_res) = /eacm/cl_table_uploader=>upload(
        VALUE #(
          table        = CONV tabname( <ls_key>-%param-target_table )
          file_name    = CONV string( <ls_key>-%param-file_name )
          file_type    = CONV string( <ls_key>-%param-file_type )
          file_content = lv_content_x
          mode         = CONV string( <ls_key>-%param-upload_mode )
          transport    = <ls_key>-%param-transport ) ).

      APPEND VALUE #(
        %cid   = <ls_key>-%cid
        %param = VALUE #(
          upload_id     = ls_res-upload_id
          status        = ls_res-status
          rows_in_file  = ls_res-rows_in_file
          rows_inserted = ls_res-rows_inserted
          message       = ls_res-message ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

