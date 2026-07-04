CLASS /eacm/cl_parser_xlsx DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /eacm/if_file_parser.

  PROTECTED SECTION.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ts_row_50,
        c01 TYPE string, c02 TYPE string, c03 TYPE string, c04 TYPE string, c05 TYPE string,
        c06 TYPE string, c07 TYPE string, c08 TYPE string, c09 TYPE string, c10 TYPE string,
        c11 TYPE string, c12 TYPE string, c13 TYPE string, c14 TYPE string, c15 TYPE string,
        c16 TYPE string, c17 TYPE string, c18 TYPE string, c19 TYPE string, c20 TYPE string,
        c21 TYPE string, c22 TYPE string, c23 TYPE string, c24 TYPE string, c25 TYPE string,
        c26 TYPE string, c27 TYPE string, c28 TYPE string, c29 TYPE string, c30 TYPE string,
        c31 TYPE string, c32 TYPE string, c33 TYPE string, c34 TYPE string, c35 TYPE string,
        c36 TYPE string, c37 TYPE string, c38 TYPE string, c39 TYPE string, c40 TYPE string,
        c41 TYPE string, c42 TYPE string, c43 TYPE string, c44 TYPE string, c45 TYPE string,
        c46 TYPE string, c47 TYPE string, c48 TYPE string, c49 TYPE string, c50 TYPE string,
      END OF ts_row_50,
      tt_rows_50 TYPE STANDARD TABLE OF ts_row_50 WITH DEFAULT KEY.

ENDCLASS.



CLASS /EACM/CL_PARSER_XLSX IMPLEMENTATION.


  METHOD /eacm/if_file_parser~parse.
    TRY.
        DATA(lo_workbook) = xco_cp_xlsx=>document->for_file_content( iv_content )->read_access( )->get_workbook( ).
        DATA(lo_worksheet) = lo_workbook->worksheet->at_position( 1 ).
        IF lo_worksheet->exists( ) = abap_false.
          RAISE EXCEPTION NEW /eacm/cx_upload( iv_detail = `XLSX file has no worksheet` ).
        ENDIF.

        DATA(lo_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
        DATA(lo_selection) = lo_worksheet->select( lo_pattern ).

        DATA lt_rows TYPE tt_rows_50.
        lo_selection->row_stream( )->operation->write_to( REF #( lt_rows ) )->execute( ).

        DATA(lo_struct) = CAST cl_abap_structdescr(
          cl_abap_typedescr=>describe_by_name( 'TS_ROW_50' ) ).

        LOOP AT lt_rows ASSIGNING FIELD-SYMBOL(<ls_src>).
          DATA ls_out TYPE /eacm/if_file_parser=>ty_row.
          CLEAR ls_out.
          DATA lv_has_value TYPE abap_bool.
          LOOP AT lo_struct->components ASSIGNING FIELD-SYMBOL(<ls_comp>).
            ASSIGN COMPONENT <ls_comp>-name OF STRUCTURE <ls_src> TO FIELD-SYMBOL(<lv_val>).
            APPEND CONV string( <lv_val> ) TO ls_out.
            IF <lv_val> IS NOT INITIAL.
              lv_has_value = abap_true.
            ENDIF.
          ENDLOOP.
          IF lv_has_value = abap_true.
            APPEND ls_out TO rt_rows.
          ENDIF.
        ENDLOOP.

      CATCH /eacm/cx_upload INTO DATA(lx_upload).
        RAISE EXCEPTION lx_upload.
      CATCH cx_root INTO DATA(lx_root).
        RAISE EXCEPTION TYPE /eacm/cx_upload
          EXPORTING previous  = lx_root
                    iv_detail = |XLSX parse failed: { lx_root->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
