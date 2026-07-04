CLASS /eacm/cl_template_builder DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ts_result,
        file_name      TYPE c LENGTH 255,
        file_type      TYPE c LENGTH 4,
        content_base64 TYPE string,
      END OF ts_result.

    CLASS-METHODS build
      IMPORTING iv_table         TYPE tabname
                iv_file_type     TYPE string
      RETURNING VALUE(rs_result) TYPE ts_result
      RAISING   /eacm/cx_upload.

  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF mc_file_type,
        csv  TYPE string VALUE `CSV`,
        xlsx TYPE string VALUE `XLSX`,
      END OF mc_file_type.

    CLASS-METHODS get_exportable_fields
      IMPORTING iv_table         TYPE tabname
      RETURNING VALUE(rt_fields) TYPE string_table
      RAISING   /eacm/cx_upload.

    CLASS-METHODS build_csv
      IMPORTING it_fields         TYPE string_table
      RETURNING VALUE(rv_content) TYPE xstring
      RAISING   /eacm/cx_upload.

    CLASS-METHODS build_xlsx
      IMPORTING it_fields         TYPE string_table
      RETURNING VALUE(rv_content) TYPE xstring
      RAISING   /eacm/cx_upload.

    CLASS-METHODS is_technical_field
      IMPORTING iv_name        TYPE abap_compname
      RETURNING VALUE(rv_skip) TYPE abap_bool.

ENDCLASS.



CLASS /EACM/CL_TEMPLATE_BUILDER IMPLEMENTATION.


  METHOD build.
    DATA(lv_type) = to_upper( iv_file_type ).
    IF lv_type IS INITIAL.
      lv_type = mc_file_type-csv.
    ENDIF.

    DATA(lt_fields) = get_exportable_fields( iv_table ).

    DATA lv_bin TYPE xstring.
    CASE lv_type.
      WHEN mc_file_type-csv.
        lv_bin = build_csv( lt_fields ).
        rs_result-file_type = mc_file_type-csv.
        rs_result-file_name = |{ iv_table }_template.csv|.
      WHEN mc_file_type-xlsx.
        lv_bin = build_xlsx( lt_fields ).
        rs_result-file_type = mc_file_type-xlsx.
        rs_result-file_name = |{ iv_table }_template.xlsx|.
      WHEN OTHERS.
        RAISE EXCEPTION NEW /eacm/cx_upload(
          iv_detail = |Unsupported template file type: { lv_type }| ).
    ENDCASE.

    rs_result-content_base64 = cl_web_http_utility=>encode_x_base64( lv_bin ).
  ENDMETHOD.


  METHOD is_technical_field.
    DATA(lv_name) = to_upper( CONV string( iv_name ) ).
    rv_skip = xsdbool(
         lv_name = 'MANDT'
      OR lv_name = 'CLIENT'
      OR lv_name CP 'LOCAL_LAST_CHANGED_*'
      OR lv_name CP 'LAST_CHANGED_*'
      OR lv_name CP 'CREATED_*'
      OR lv_name CP 'CHANGED_*' ).
  ENDMETHOD.


  METHOD build_xlsx.
    TRY.
        DATA(lo_write) = xco_cp_xlsx=>document->empty( )->write_access( ).
        DATA(lo_workbook) = lo_write->get_workbook( ).
        DATA(lo_sheet) = lo_workbook->add_new_sheet( `Template` ).

        DATA(lv_col) = 1.
        LOOP AT it_fields INTO DATA(lv_field).
          DATA(lo_cursor) = lo_sheet->cursor(
            io_column = xco_cp_xlsx=>coordinate->for_numeric_value( lv_col )
            io_row    = xco_cp_xlsx=>coordinate->for_numeric_value( 1 ) ).
          lo_cursor->get_cell( )->value->write_from( lv_field ).
          lv_col = lv_col + 1.
        ENDLOOP.

        rv_content = lo_write->get_file_content( ).
      CATCH cx_root INTO DATA(lx_root).
        RAISE EXCEPTION NEW /eacm/cx_upload(
          previous  = lx_root
          iv_detail = |XLSX template build failed: { lx_root->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.


  METHOD build_csv.
    DATA lv_line TYPE string.
    DATA lv_text TYPE string.
    DATA lv_sep  TYPE string.

    lv_sep = ``.
    LOOP AT it_fields INTO DATA(lv_field).
      lv_line = |{ lv_line }{ lv_sep }{ lv_field }|.
      lv_sep = `;`.
    ENDLOOP.

    lv_text = |{ lv_line }{ cl_abap_char_utilities=>cr_lf }|.

    TRY.
        DATA(lo_conv) = cl_abap_conv_codepage=>create_out( codepage = `UTF-8` ).
        rv_content = lo_conv->convert( lv_text ).
        DATA(lv_bom) = CONV xstring( 'EFBBBF' ).
        rv_content = lv_bom && rv_content.
      CATCH cx_root INTO DATA(lx_conv).
        RAISE EXCEPTION NEW /eacm/cx_upload(
          previous  = lx_conv
          iv_detail = |CSV encoding failed: { lx_conv->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_exportable_fields.
    TRY.
        DATA(lo_type) = cl_abap_typedescr=>describe_by_name( iv_table ).
        DATA(lo_struct) = CAST cl_abap_structdescr( lo_type ).
      CATCH cx_root INTO DATA(lx_rtti).
        RAISE EXCEPTION NEW /eacm/cx_upload(
          previous  = lx_rtti
          iv_table  = iv_table
          iv_detail = |Table { iv_table } does not exist| ).
    ENDTRY.

    LOOP AT lo_struct->components ASSIGNING FIELD-SYMBOL(<ls_comp>).
      IF is_technical_field( <ls_comp>-name ) = abap_true.
        CONTINUE.
      ENDIF.
      APPEND to_lower( CONV string( <ls_comp>-name ) ) TO rt_fields.
    ENDLOOP.

    IF rt_fields IS INITIAL.
      RAISE EXCEPTION NEW /eacm/cx_upload(
        iv_table  = iv_table
        iv_detail = `No exportable fields found (all technical)` ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
