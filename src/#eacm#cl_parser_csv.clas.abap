CLASS /eacm/cl_parser_csv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /eacm/if_file_parser.

  PROTECTED SECTION.

  PRIVATE SECTION.
    METHODS to_text
      IMPORTING iv_content     TYPE xstring
      RETURNING VALUE(rv_text) TYPE string
      RAISING   /eacm/cx_upload.

    METHODS detect_delim
      IMPORTING iv_text         TYPE string
      RETURNING VALUE(rv_delim) TYPE string.

    METHODS split_line
      IMPORTING iv_line         TYPE string
                iv_delim        TYPE string
      RETURNING VALUE(rt_cells) TYPE /eacm/if_file_parser=>ty_row.

ENDCLASS.



CLASS /eacm/cl_parser_csv IMPLEMENTATION.


  METHOD /eacm/if_file_parser~parse.
    DATA(lv_text) = to_text( iv_content ).
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_text WITH cl_abap_char_utilities=>newline.

    DATA(lv_delim) = detect_delim( lv_text ).

    SPLIT lv_text AT cl_abap_char_utilities=>newline INTO TABLE DATA(lt_lines).
    LOOP AT lt_lines ASSIGNING FIELD-SYMBOL(<lv_line>).
      IF <lv_line> IS INITIAL.
        CONTINUE.
      ENDIF.
      APPEND split_line( iv_line = <lv_line> iv_delim = lv_delim ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.


  METHOD to_text.
    DATA(lv_xstring) = iv_content.
    IF xstrlen( lv_xstring ) >= 3
       AND lv_xstring(3) = cl_abap_char_utilities=>byte_order_mark_utf8.
      lv_xstring = lv_xstring+3.
    ENDIF.

    TRY.
        rv_text = cl_abap_conv_codepage=>create_in( codepage = 'UTF-8' )->convert( source = lv_xstring ).
        RETURN.
      CATCH cx_root INTO DATA(lo_cx).
        DATA(msg) = lo_cx->get_text( ).
    ENDTRY.

    TRY.
        rv_text = cl_abap_conv_codepage=>create_in( codepage = '1160' )->convert( source = lv_xstring ).
        RETURN.
      CATCH cx_root INTO lo_cx.
        msg = lo_cx->get_text( ).
    ENDTRY.

    TRY.
        rv_text = cl_abap_conv_codepage=>create_in( codepage = '1100' )->convert( source = lv_xstring ).
      CATCH cx_root INTO DATA(lx_root).
        RAISE EXCEPTION TYPE /eacm/cx_upload
          EXPORTING
            previous  = lx_root
            iv_detail = |CSV decode failed (tried UTF-8, CP1252, Latin-1): { lx_root->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.


  METHOD detect_delim.
    DATA(lv_sample_len) = COND i( WHEN strlen( iv_text ) > 2000 THEN 2000
                                  ELSE strlen( iv_text ) ).
    DATA(lv_sample) = substring( val = iv_text off = 0 len = lv_sample_len ).
    DATA(lv_commas) = count( val = lv_sample sub = `,` ).
    DATA(lv_semi)   = count( val = lv_sample sub = `;` ).
    rv_delim = COND #( WHEN lv_semi > lv_commas THEN ';' ELSE ',' ).
  ENDMETHOD.


  METHOD split_line.
    DATA lv_cell TYPE string.
    DATA lv_in_quotes TYPE abap_bool.
    DATA(lv_len) = strlen( iv_line ).
    DATA lv_idx TYPE i.

    WHILE lv_idx < lv_len.
      DATA(lv_ch) = substring( val = iv_line off = lv_idx len = 1 ).
      IF lv_in_quotes = abap_true.
        IF lv_ch = '"'.
          IF lv_idx + 1 < lv_len AND substring( val = iv_line off = lv_idx + 1 len = 1 ) = '"'.
            lv_cell = lv_cell && '"'.
            lv_idx = lv_idx + 1.
          ELSE.
            lv_in_quotes = abap_false.
          ENDIF.
        ELSE.
          lv_cell = lv_cell && lv_ch.
        ENDIF.
      ELSE.
        IF lv_ch = '"'.
          lv_in_quotes = abap_true.
        ELSEIF lv_ch = iv_delim.
          APPEND lv_cell TO rt_cells.
          CLEAR lv_cell.
        ELSE.
          lv_cell = lv_cell && lv_ch.
        ENDIF.
      ENDIF.
      lv_idx = lv_idx + 1.
    ENDWHILE.
    APPEND lv_cell TO rt_cells.
  ENDMETHOD.
ENDCLASS.
