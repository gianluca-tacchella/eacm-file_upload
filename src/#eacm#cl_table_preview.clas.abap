CLASS /eacm/cl_table_preview DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ts_result,
        table_name   TYPE tabname,
        row_count    TYPE i,
        columns_json TYPE string,
        keys_json    TYPE string,
        rows_json    TYPE string,
      END OF ts_result.

    CONSTANTS mc_default_top TYPE i VALUE 100.
    CONSTANTS mc_max_top     TYPE i VALUE 1000.

    CLASS-METHODS read
      IMPORTING iv_table         TYPE tabname
                iv_top           TYPE i      DEFAULT mc_default_top
                iv_filters_json  TYPE string OPTIONAL
      RETURNING VALUE(rs_result) TYPE ts_result
      RAISING   /eacm/cx_upload.

  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS mc_namespace TYPE string VALUE `/EACM/`.

    CLASS-METHODS validate_table
      IMPORTING iv_table TYPE tabname
      RAISING   /eacm/cx_upload.

    CLASS-METHODS build_columns_json
      IMPORTING io_struct      TYPE REF TO cl_abap_structdescr
      RETURNING VALUE(rv_json) TYPE string.

    CLASS-METHODS build_keys_json
      IMPORTING iv_table       TYPE tabname
      RETURNING VALUE(rv_json) TYPE string.

    CLASS-METHODS build_where
      IMPORTING iv_table        TYPE tabname
                iv_filters_json TYPE string
                io_struct       TYPE REF TO cl_abap_structdescr
      RETURNING VALUE(rv_where) TYPE string
      RAISING   /eacm/cx_upload.

ENDCLASS.



CLASS /eacm/cl_table_preview IMPLEMENTATION.


  METHOD read.
    validate_table( iv_table ).

    DATA(lv_top) = COND i( WHEN iv_top <= 0         THEN mc_default_top
                           WHEN iv_top > mc_max_top THEN mc_max_top
                           ELSE iv_top ).

    DATA(lo_type)   = cl_abap_typedescr=>describe_by_name( iv_table ).
    DATA(lo_struct) = CAST cl_abap_structdescr( lo_type ).

    DATA lr_tab TYPE REF TO data.
    CREATE DATA lr_tab TYPE STANDARD TABLE OF (iv_table).
    ASSIGN lr_tab->* TO FIELD-SYMBOL(<lt_data>).

    DATA(lv_where) = build_where( iv_table        = iv_table
                                  iv_filters_json = iv_filters_json
                                  io_struct       = lo_struct ).



**********************************************************************
    DATA lv_table TYPE string.
    TRY.
        lv_table =
          cl_abap_dyn_prg=>check_table_or_view_name_str(
            val = iv_table
            packages = '/EACM/CORE, /EACM/APP_COMMISSION'
            incl_sub_packages = abap_true ).
      CATCH cx_abap_not_a_table
            cx_abap_not_in_package INTO DATA(lo_cx).
        DATA(msg) = lo_cx->get_text( ).
        RETURN.
    ENDTRY.
**********************************************************************
    TRY.
        IF lv_where IS INITIAL.
          SELECT FROM (lv_table)
            FIELDS *
            INTO TABLE @<lt_data>
            UP TO @lv_top ROWS.
        ELSE.
          SELECT FROM (lv_table)
            FIELDS *
            WHERE (lv_where)
            INTO TABLE @<lt_data>
            UP TO @lv_top ROWS.
        ENDIF.
      CATCH cx_sy_dynamic_osql_error INTO DATA(lx_sql).
        RAISE EXCEPTION NEW /eacm/cx_upload( previous  = lx_sql
                                             iv_table  = iv_table
                                             iv_detail = |Read error: { lx_sql->get_text( ) }| ).
    ENDTRY.

    rs_result-table_name   = iv_table.
    rs_result-row_count    = lines( <lt_data> ).
    rs_result-columns_json = build_columns_json( lo_struct ).
    rs_result-keys_json    = build_keys_json( iv_table ).

    DATA(lo_writer) = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_json ).
    CALL TRANSFORMATION id SOURCE data = <lt_data> RESULT XML lo_writer.
    DATA(lv_xjson) = lo_writer->get_output( ).

    TRY.
        DATA(lo_conv) = cl_abap_conv_codepage=>create_in( codepage = `UTF-8` ).
        rs_result-rows_json = lo_conv->convert( lv_xjson ).
      CATCH cx_root INTO DATA(lx_conv).
        RAISE EXCEPTION NEW /eacm/cx_upload( previous  = lx_conv
                                             iv_detail = |JSON conversion failed: { lx_conv->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.


  METHOD validate_table.
    IF strlen( iv_table ) < 6
       OR substring( val = iv_table off = 0 len = 6 ) <> mc_namespace.
      RAISE EXCEPTION NEW /eacm/cx_upload( iv_table  = iv_table
                                           iv_detail = |Table must be in { mc_namespace } namespace| ).
    ENDIF.

    TRY.
        DATA(lo_descr) = cl_abap_typedescr=>describe_by_name( iv_table ).
        IF lo_descr->kind <> cl_abap_typedescr=>kind_struct.
          RAISE EXCEPTION NEW /eacm/cx_upload( iv_table  = iv_table
                                               iv_detail = |{ iv_table } is not a structured table type| ).
        ENDIF.
      CATCH cx_sy_rtti_syntax_error INTO DATA(lx_rtti).
        RAISE EXCEPTION NEW /eacm/cx_upload( previous  = lx_rtti
                                             iv_table  = iv_table
                                             iv_detail = |Table { iv_table } does not exist| ).
    ENDTRY.
  ENDMETHOD.


  METHOD build_columns_json.
    DATA lv_sep TYPE string VALUE ``.
    rv_json = `[`.
    LOOP AT io_struct->components ASSIGNING FIELD-SYMBOL(<ls_comp>).
      rv_json = |{ rv_json }{ lv_sep }"{ to_lower( CONV string( <ls_comp>-name ) ) }"|.
      lv_sep = `,`.
    ENDLOOP.
    rv_json = |{ rv_json }]|.
  ENDMETHOD.


  METHOD build_keys_json.
    DATA lv_sep TYPE string VALUE ``.
    rv_json = `[`.

    TRY.
        DATA lv_name TYPE sxco_dbt_object_name.
        lv_name = iv_table.
        DATA(lo_tab) = xco_cp_abap_dictionary=>database_table( lv_name ).
        DATA(lt_fields) = lo_tab->fields->all->get( ).
        LOOP AT lt_fields ASSIGNING FIELD-SYMBOL(<lo_field>).
          IF <lo_field>->content( )->get_key_indicator( ) = abap_true.
            rv_json = |{ rv_json }{ lv_sep }"{ to_lower( CONV string( <lo_field>->name ) ) }"|.
            lv_sep = `,`.
          ENDIF.
        ENDLOOP.
      CATCH cx_root INTO DATA(lo_cx).
        DATA(msg) = lo_cx->get_text( ).
    ENDTRY.

    rv_json = |{ rv_json }]|.
  ENDMETHOD.


  METHOD build_where.
    IF iv_filters_json IS INITIAL OR iv_filters_json = `{}` OR iv_filters_json = `` .
      rv_where = ``.
      RETURN.
    ENDIF.

    " Parse flat JSON object {"field":"value",...} via regex
    DATA(lo_regex) = cl_abap_regex=>create_pcre(
      pattern = `"([^"\\]*(?:\\.[^"\\]*)*)"\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"`
      ignore_case = abap_false ).
    DATA(lo_matcher) = lo_regex->create_matcher( text = iv_filters_json ).

    DATA lv_sep TYPE string VALUE ``.
    WHILE lo_matcher->find_next( ) = abap_true.
      DATA(lv_raw_field) = lo_matcher->get_submatch( 1 ).
      DATA(lv_raw_value) = lo_matcher->get_submatch( 2 ).
      REPLACE ALL OCCURRENCES OF `\"` IN lv_raw_value WITH `"`.
      REPLACE ALL OCCURRENCES OF `\\` IN lv_raw_value WITH `\`.

      IF lv_raw_value IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_col) = to_upper( lv_raw_field ).
      TRY.
          cl_abap_dyn_prg=>check_column_name( val = lv_col ).
        CATCH cx_abap_invalid_name INTO DATA(lx_name).
          RAISE EXCEPTION NEW /eacm/cx_upload( previous  = lx_name
                                               iv_table  = iv_table
                                               iv_column = lv_col
                                               iv_detail = |Invalid filter column name: { lv_col }| ).
      ENDTRY.
      IF NOT line_exists( io_struct->components[ name = lv_col ] ).
        CONTINUE.
      ENDIF.
      DATA(lv_escaped) = cl_abap_dyn_prg=>escape_quotes( lv_raw_value ).
      rv_where = |{ rv_where }{ lv_sep }{ lv_col } = '{ lv_escaped }'|.
      lv_sep = ` AND `.
    ENDWHILE.
  ENDMETHOD.
ENDCLASS.
